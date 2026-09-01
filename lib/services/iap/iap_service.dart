import '../../features/shop/domain/iap_catalog.dart';

class IapPurchaseRequest {
  const IapPurchaseRequest({
    required this.productId,
    required this.receiptId,
    this.qaToken,
  });

  final String productId;
  final String receiptId;
  final String? qaToken;
}

class IapPurchaseResult {
  const IapPurchaseResult({
    required this.success,
    required this.productId,
    this.alreadyProcessed = false,
    this.message,
  });

  final bool success;
  final String productId;
  final bool alreadyProcessed;
  final String? message;
}

/// Client never chooses grant amounts. Functions look up [IapGrantTable].
abstract class IapPurchasePort {
  Future<IapPurchaseResult> purchase(IapPurchaseRequest request);
  Future<List<IapPurchaseResult>> restore();
}

class UnavailableIapPurchasePort implements IapPurchasePort {
  const UnavailableIapPurchasePort();

  @override
  Future<IapPurchaseResult> purchase(IapPurchaseRequest request) async {
    return IapPurchaseResult(
      success: false,
      productId: request.productId,
      message: 'Store billing is not configured yet.',
    );
  }

  @override
  Future<List<IapPurchaseResult>> restore() async => const [];
}

/// Emulator / QA receipt that Functions will honor.
class CallableIapPurchasePort implements IapPurchasePort {
  CallableIapPurchasePort(this._call);

  final Future<Map<String, dynamic>> Function(IapPurchaseRequest request) _call;

  @override
  Future<IapPurchaseResult> purchase(IapPurchaseRequest request) async {
    if (IapCatalog.byId(request.productId) == null) {
      return IapPurchaseResult(
        success: false,
        productId: request.productId,
        message: 'Unknown product.',
      );
    }
    final payload = await _call(request);
    return IapPurchaseResult(
      success: true,
      productId: request.productId,
      alreadyProcessed: payload['alreadyProcessed'] == true,
    );
  }

  @override
  Future<List<IapPurchaseResult>> restore() async => const [];
}
