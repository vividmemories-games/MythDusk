import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_providers.dart';
import '../../core/analytics/gameplay_analytics.dart';
import '../../core/config/app_flavor.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/profile/providers/mock_profile_provider.dart';
import '../../firebase/firebase_bootstrap.dart';
import '../../firebase/server_settlement.dart';
import 'iap_service.dart';
import 'store_iap_service.dart';

final storeIapServiceProvider = Provider<StoreIapService>((ref) {
  final service = StoreIapService();
  ref.onDispose(service.dispose);
  return service;
});

final storeIapReadyProvider = FutureProvider<bool>((ref) async {
  if (!FirebaseBootstrap.isReady) return false;
  final service = ref.watch(storeIapServiceProvider);
  await service.initialize();
  return service.isAvailable;
});

/// Buys via store, validates on server, hydrates local profile.
class IapCheckout {
  IapCheckout(this._ref);

  final Ref _ref;

  Future<IapPurchaseResult> buy(String productId) async {
    final analytics = _ref.read(gameplayAnalyticsProvider);
    analytics.log(GameplayAnalyticsEvents.iapStarted, {'productId': productId});
    final store = _ref.read(storeIapServiceProvider);
    try {
      final result = await store.buy(productId);
      if (result.success) {
        analytics.log(
          GameplayAnalyticsEvents.iapSucceeded,
          {
            'productId': productId,
            'alreadyProcessed': result.alreadyProcessed ? 1 : 0,
          },
        );
        await _hydrate();
      } else {
        analytics.log(
          GameplayAnalyticsEvents.iapFailed,
          {
            'productId': productId,
            'message': result.message ?? '',
          },
        );
      }
      return result;
    } catch (error) {
      analytics.log(
        GameplayAnalyticsEvents.iapFailed,
        {'productId': productId, 'message': '$error'},
      );
      return IapPurchaseResult(
        success: false,
        productId: productId,
        message: '$error',
      );
    }
  }

  Future<void> restore() async {
    final analytics = _ref.read(gameplayAnalyticsProvider);
    analytics.log(GameplayAnalyticsEvents.iapRestored, {'phase': 'started'});
    final store = _ref.read(storeIapServiceProvider);
    await store.restore();
    await _hydrate();
    analytics.log(GameplayAnalyticsEvents.iapRestored, {'phase': 'done'});
  }

  /// Debug-only local claim for emulator/QA without store.
  Future<IapPurchaseResult> qaClaim(String productId) async {
    if (!AppFlavor.showQaTools) {
      return IapPurchaseResult(
        success: false,
        productId: productId,
        message: 'QA claims are debug-only.',
      );
    }
    final projectId = FirebaseBootstrap.isReady
        ? const String.fromEnvironment('FIREBASE_PROJECT_ID',
            defaultValue: 'mythdusk-ec0c7')
        : 'mythdusk-ec0c7';
    final client = _ref.read(cloudFunctionsClientProvider);
    try {
      final result = await client.validateIapReceipt(
        productId: productId,
        receiptId: 'qa_${productId}_${DateTime.now().millisecondsSinceEpoch}',
        platform: 'qa',
        verificationData: 'qa',
        qaToken: 'qa-$projectId',
      );
      await _hydrate();
      return IapPurchaseResult(
        success: true,
        productId: productId,
        alreadyProcessed: result.alreadyProcessed,
      );
    } catch (error) {
      return IapPurchaseResult(
        success: false,
        productId: productId,
        message: '$error',
      );
    }
  }

  Future<void> _hydrate() async {
    final identity = _ref.read(authIdentityProvider).asData?.value;
    if (identity == null) return;
    final client = _ref.read(cloudFunctionsClientProvider);
    final remote = await client.fetchUserProfile(identity.uid);
    if (remote == null) return;
    await applyServerUserProfile(_ref.read(profileProvider.notifier), remote);
  }
}

final iapCheckoutProvider = Provider<IapCheckout>((ref) => IapCheckout(ref));
