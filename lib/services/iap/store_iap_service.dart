import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../features/shop/domain/iap_catalog.dart';
import '../../firebase/cloud_functions_client.dart';
import '../../firebase/firebase_bootstrap.dart';
import 'iap_service.dart';

/// StoreKit / Play Billing bridge → [CloudFunctionsClient.validateIapReceipt].
class StoreIapService {
  StoreIapService({
    InAppPurchase? store,
    CloudFunctionsClient? functions,
  })  : _store = store ?? InAppPurchase.instance,
        _functions = functions ?? CloudFunctionsClient();

  final InAppPurchase _store;
  final CloudFunctionsClient _functions;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _products = <String, ProductDetails>{};
  final _pending = <String, Completer<IapPurchaseResult>>{};
  var _ready = false;

  bool get isAvailable => _ready;

  ProductDetails? productDetails(String productId) => _products[productId];

  String? localizedPrice(String productId) => _products[productId]?.price;

  Future<void> initialize() async {
    if (_subscription != null) return;
    final available = await _store.isAvailable();
    if (!available) {
      _ready = false;
      return;
    }
    _subscription = _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object error, StackTrace stack) {
        debugPrint('IAP purchaseStream error: $error');
        debugPrint('$stack');
      },
    );
    await queryProducts();
    _ready = true;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> queryProducts() async {
    final ids = IapCatalog.all.map((p) => p.id).toSet();
    final response = await _store.queryProductDetails(ids);
    if (response.error != null) {
      debugPrint('IAP query error: ${response.error}');
    }
    _products
      ..clear()
      ..addEntries(
        response.productDetails.map((p) => MapEntry(p.id, p)),
      );
  }

  Future<IapPurchaseResult> buy(String productId) async {
    await initialize();
    final def = IapCatalog.byId(productId);
    if (def == null) {
      return IapPurchaseResult(
        success: false,
        productId: productId,
        message: 'Unknown product.',
      );
    }
    if (!_ready || !FirebaseBootstrap.isReady) {
      return IapPurchaseResult(
        success: false,
        productId: productId,
        message: 'Store billing is not available.',
      );
    }
    final details = _products[productId];
    if (details == null) {
      await queryProducts();
    }
    final product = _products[productId];
    if (product == null) {
      return IapPurchaseResult(
        success: false,
        productId: productId,
        message: 'Product not found in store.',
      );
    }

    final existing = _pending[productId];
    if (existing != null) return existing.future;

    final completer = Completer<IapPurchaseResult>();
    _pending[productId] = completer;

    final param = PurchaseParam(productDetails: product);
    final ok = def.kind == IapProductKind.consumable
        ? await _store.buyConsumable(purchaseParam: param)
        : await _store.buyNonConsumable(purchaseParam: param);
    if (!ok) {
      _pending.remove(productId);
      return IapPurchaseResult(
        success: false,
        productId: productId,
        message: 'Store rejected the purchase request.',
      );
    }
    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        _pending.remove(productId);
        return IapPurchaseResult(
          success: false,
          productId: productId,
          message: 'Purchase timed out.',
        );
      },
    );
  }

  Future<List<IapPurchaseResult>> restore() async {
    await initialize();
    if (!_ready) return const [];
    await _store.restorePurchases();
    // Restored purchases arrive on purchaseStream and are validated there.
    await Future<void>.delayed(const Duration(seconds: 2));
    return const [];
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    if (purchase.status == PurchaseStatus.pending) return;

    if (purchase.status == PurchaseStatus.error ||
        purchase.status == PurchaseStatus.canceled) {
      _completePending(
        productId,
        IapPurchaseResult(
          success: false,
          productId: productId,
          message: purchase.error?.message ?? 'Purchase canceled.',
        ),
      );
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      return;
    }

    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return;
    }

    try {
      final receiptId = purchase.purchaseID?.isNotEmpty == true
          ? purchase.purchaseID!
          : '${purchase.productID}_${purchase.verificationData.serverVerificationData.hashCode}';
      final platform =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      final result = await _functions.validateIapReceipt(
        productId: productId,
        receiptId: receiptId,
        platform: platform,
        verificationData: purchase.verificationData.serverVerificationData,
      );
      _completePending(
        productId,
        IapPurchaseResult(
          success: true,
          productId: productId,
          alreadyProcessed: result.alreadyProcessed,
        ),
      );
    } catch (error) {
      _completePending(
        productId,
        IapPurchaseResult(
          success: false,
          productId: productId,
          message: error.toString(),
        ),
      );
    } finally {
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  void _completePending(String productId, IapPurchaseResult result) {
    final completer = _pending.remove(productId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }
}
