import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/remote_config_keys.dart';
import '../features/auth/domain/auth_identity.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/battle/domain/battle_run_settlement.dart';
import '../features/profile/providers/mock_profile_provider.dart';
import 'cloud_functions_client.dart';
import 'firebase_bootstrap.dart';

final cloudFunctionsClientProvider = Provider<CloudFunctionsClient>((ref) {
  return CloudFunctionsClient();
});

/// Gate for W1 server settlement. Remote Config default is true.
bool useServerSettlementEnabled() {
  if (!FirebaseBootstrap.isReady) return false;
  try {
    return FirebaseRemoteConfig.instance
        .getBool(RemoteConfigKeys.useServerSettlement);
  } catch (_) {
    return true;
  }
}

final useServerSettlementProvider = Provider<bool>((ref) {
  return useServerSettlementEnabled();
});

/// Ensures cloud user exists and hydrates local cache from server.
class AuthProfileSync {
  AuthProfileSync(this._ref);

  final Ref _ref;
  String? _lastSyncedUid;

  Future<void> syncForUid(String uid) async {
    if (!useServerSettlementEnabled()) return;
    if (_lastSyncedUid == uid) return;
    final client = _ref.read(cloudFunctionsClientProvider);
    final profile = _ref.read(profileProvider);
    final notifier = _ref.read(profileProvider.notifier);
    try {
      final bootstrap = ServerUserProfile.bootstrapFromLocal(
        coins: profile.coins,
        gems: profile.gems,
        lives: profile.lives,
        completedNodeIds: profile.completedNodeIds,
        displayName: profile.displayName,
        selectedHeroId: profile.selectedHeroId,
      );
      final ensured = await client.ensureUser(bootstrap: bootstrap);
      final remote = ensured.profile ?? await client.fetchUserProfile(uid);
      if (remote != null) {
        await _applyRemote(notifier, remote);
      }
      _lastSyncedUid = uid;
    } catch (error, stack) {
      logSettlementError(error, stack);
    }
  }

  void clear() {
    _lastSyncedUid = null;
  }

  Future<void> _applyRemote(
    ProfileNotifier notifier,
    ServerUserProfile remote,
  ) {
    return applyServerUserProfile(notifier, remote);
  }
}

Future<void> applyServerUserProfile(
  ProfileNotifier notifier,
  ServerUserProfile remote,
) {
  final regen = remote.lastLifeRegenAt == null
      ? null
      : DateTime.tryParse(remote.lastLifeRegenAt!);
  return notifier.applyServerEconomy(
    coins: remote.coins,
    gems: remote.gems,
    lives: remote.lives,
    completedNodeIds: remote.completedNodeIds,
    displayName: remote.displayName,
    selectedHeroId: remote.selectedHeroId,
    lastLifeRegenAt: regen,
    clearLastLifeRegenAt: regen == null,
    gemLifeRefillDay: remote.gemLifeRefillDay,
    gemLifeRefillCount: remote.gemLifeRefillCount,
    claimedStarterPackIds: remote.claimedStarterPackIds,
    claimedCosmeticIds: remote.claimedCosmeticIds,
  );
}

final authProfileSyncProvider = Provider<AuthProfileSync>((ref) {
  final sync = AuthProfileSync(ref);
  ref.listen<AsyncValue<AuthIdentity?>>(
    authIdentityProvider,
    (previous, next) {
      final identity = next.asData?.value;
      if (identity == null) {
        sync.clear();
        return;
      }
      // Fire-and-forget; UI keeps local cache until hydrate lands.
      sync.syncForUid(identity.uid);
    },
    fireImmediately: true,
  );
  return sync;
});

/// Campaign PvE settlement via battle_runs + submitBattleRun.
class CampaignServerSettlement {
  CampaignServerSettlement(this._ref);

  final Ref _ref;

  Future<SubmitBattleRunResult?> settle({
    required String nodeId,
    required String heroId,
    required bool won,
    required int coinReward,
  }) async {
    if (!useServerSettlementEnabled()) return null;
    final identity = _ref.read(authIdentityProvider).asData?.value;
    if (identity == null) return null;

    final client = _ref.read(cloudFunctionsClientProvider);
    final notifier = _ref.read(profileProvider.notifier);
    final runId =
        '${identity.uid}_${nodeId}_${DateTime.now().millisecondsSinceEpoch}';
    final submission = BattleRunSubmission(
      runId: runId,
      uid: identity.uid,
      nodeId: nodeId,
      heroId: heroId,
      won: won,
      coinReward: coinReward,
      clientVersion: '0.1.5',
      mode: 'pve',
    );
    try {
      final result = await client.submitBattleRun(submission: submission);
      if (result.coins != null &&
          result.lives != null &&
          result.completedNodeIds != null) {
        final local = _ref.read(profileProvider);
        await applyServerUserProfile(
          notifier,
          ServerUserProfile(
            coins: result.coins!,
            gems: local.gems,
            lives: result.lives!,
            completedNodeIds: result.completedNodeIds!,
            displayName: local.displayName,
            selectedHeroId: local.selectedHeroId,
            lastLifeRegenAt: local.lastLifeRegenAt?.toIso8601String(),
            gemLifeRefillDay: local.gemLifeRefillDay,
            gemLifeRefillCount: local.gemLifeRefillCount,
            claimedStarterPackIds: local.claimedStarterPackIds,
            claimedCosmeticIds: local.claimedCosmeticIds,
          ),
        );
      } else {
        final remote = await client.fetchUserProfile(identity.uid);
        if (remote != null) await applyServerUserProfile(notifier, remote);
      }
      return result;
    } catch (error, stack) {
      logSettlementError(error, stack);
      rethrow;
    }
  }
}

final campaignServerSettlementProvider =
    Provider<CampaignServerSettlement>((ref) {
  return CampaignServerSettlement(ref);
});
