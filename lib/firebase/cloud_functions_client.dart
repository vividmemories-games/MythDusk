import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../features/battle/domain/battle_run_settlement.dart';
import 'firebase_bootstrap.dart';

/// Thin callable + Firestore client for W1 settlement.
class CloudFunctionsClient {
  CloudFunctionsClient({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  bool get isAvailable => FirebaseBootstrap.isReady;

  Future<EnsureUserResult> ensureUser({
    Map<String, dynamic>? bootstrap,
  }) async {
    final callable = _functions.httpsCallable('ensureUser');
    final response = await callable.call(<String, dynamic>{
      if (bootstrap != null) 'bootstrap': bootstrap,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return EnsureUserResult.fromMap(data);
  }

  Future<ServerUserProfile?> fetchUserProfile(String uid) async {
    final snap = await _firestore.doc('users/$uid').get();
    if (!snap.exists || snap.data() == null) return null;
    return ServerUserProfile.fromMap(snap.data()!);
  }

  Future<SubmitBattleRunResult> submitBattleRun({
    required BattleRunSubmission submission,
  }) async {
    final runRef = _firestore.doc('battle_runs/${submission.runId}');
    await runRef.set({
      ...submission.toCreatePayload(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
    final callable = _functions.httpsCallable('submitBattleRun');
    final response = await callable.call(<String, dynamic>{
      'runId': submission.runId,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return SubmitBattleRunResult.fromMap(data);
  }

  Future<TickLivesResult> tickLives() async {
    final callable = _functions.httpsCallable('tickLives');
    final response = await callable.call();
    final data = Map<String, dynamic>.from(response.data as Map);
    return TickLivesResult(
      lives: (data['lives'] as num?)?.toInt() ?? 0,
      lastLifeRegenAt: data['lastLifeRegenAt'] as String?,
    );
  }

  Future<RefillLivesResult> refillLivesWithGems() async {
    final callable = _functions.httpsCallable('refillLivesWithGems');
    final response = await callable.call();
    final data = Map<String, dynamic>.from(response.data as Map);
    return RefillLivesResult(
      lives: (data['lives'] as num?)?.toInt() ?? 0,
      gems: (data['gems'] as num?)?.toInt() ?? 0,
    );
  }
}

class EnsureUserResult {
  const EnsureUserResult({
    required this.created,
    required this.uid,
    required this.profile,
  });

  factory EnsureUserResult.fromMap(Map<String, dynamic> data) {
    final profileRaw = data['profile'];
    return EnsureUserResult(
      created: data['created'] == true,
      uid: data['uid'] as String? ?? '',
      profile: profileRaw is Map
          ? ServerUserProfile.fromMap(Map<String, dynamic>.from(profileRaw))
          : null,
    );
  }

  final bool created;
  final String uid;
  final ServerUserProfile? profile;
}

class ServerUserProfile {
  const ServerUserProfile({
    required this.coins,
    required this.gems,
    required this.lives,
    required this.completedNodeIds,
    required this.displayName,
    required this.selectedHeroId,
    this.lastLifeRegenAt,
    this.gemLifeRefillDay = '',
    this.gemLifeRefillCount = 0,
    this.claimedStarterPackIds = const {},
    this.claimedCosmeticIds = const {},
  });

  factory ServerUserProfile.fromMap(Map<String, dynamic> data) {
    return ServerUserProfile(
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      gems: (data['gems'] as num?)?.toInt() ?? 0,
      lives: (data['lives'] as num?)?.toInt() ?? 0,
      lastLifeRegenAt: data['lastLifeRegenAt'] as String?,
      gemLifeRefillDay: data['gemLifeRefillDay'] as String? ?? '',
      gemLifeRefillCount: (data['gemLifeRefillCount'] as num?)?.toInt() ?? 0,
      displayName: data['displayName'] as String? ?? 'Wanderer',
      selectedHeroId: data['selectedHeroId'] as String? ?? 'mage',
      completedNodeIds: {
        for (final id
            in (data['completedNodeIds'] as List<dynamic>? ?? const [])
                .whereType<String>())
          id,
      },
      claimedStarterPackIds: {
        for (final id
            in (data['claimedStarterPackIds'] as List<dynamic>? ?? const [])
                .whereType<String>())
          id,
      },
      claimedCosmeticIds: {
        for (final id
            in (data['claimedCosmeticIds'] as List<dynamic>? ?? const [])
                .whereType<String>())
          id,
      },
    );
  }

  final int coins;
  final int gems;
  final int lives;
  final String? lastLifeRegenAt;
  final String gemLifeRefillDay;
  final int gemLifeRefillCount;
  final String displayName;
  final String selectedHeroId;
  final Set<String> completedNodeIds;
  final Set<String> claimedStarterPackIds;
  final Set<String> claimedCosmeticIds;

  /// Payload for first-time [CloudFunctionsClient.ensureUser] bootstrap.
  static Map<String, dynamic> bootstrapFromLocal({
    required int coins,
    required int gems,
    required int lives,
    required Set<String> completedNodeIds,
    required String displayName,
    required String selectedHeroId,
  }) {
    return {
      'coins': coins,
      'gems': gems,
      'lives': lives,
      'completedNodeIds': completedNodeIds.toList(),
      'displayName': displayName,
      'selectedHeroId': selectedHeroId,
    };
  }
}

class SubmitBattleRunResult {
  const SubmitBattleRunResult({
    required this.alreadyProcessed,
    required this.grantCoins,
    required this.completedNode,
    this.coins,
    this.lives,
    this.completedNodeIds,
  });

  factory SubmitBattleRunResult.fromMap(Map<String, dynamic> data) {
    final ids = data['completedNodeIds'];
    return SubmitBattleRunResult(
      alreadyProcessed: data['alreadyProcessed'] == true,
      grantCoins: (data['grantCoins'] as num?)?.toInt() ?? 0,
      completedNode: data['completedNode'] == true,
      coins: (data['coins'] as num?)?.toInt(),
      lives: (data['lives'] as num?)?.toInt(),
      completedNodeIds:
          ids is List ? {for (final id in ids.whereType<String>()) id} : null,
    );
  }

  final bool alreadyProcessed;
  final int grantCoins;
  final bool completedNode;
  final int? coins;
  final int? lives;
  final Set<String>? completedNodeIds;
}

class TickLivesResult {
  const TickLivesResult({required this.lives, this.lastLifeRegenAt});

  final int lives;
  final String? lastLifeRegenAt;
}

class RefillLivesResult {
  const RefillLivesResult({required this.lives, required this.gems});

  final int lives;
  final int gems;
}

/// Logs callable failures without crashing the UI path.
void logSettlementError(Object error, StackTrace stack) {
  debugPrint('Server settlement error: $error');
  debugPrint('$stack');
  if (!FirebaseBootstrap.isReady || kDebugMode) return;
  FirebaseCrashlytics.instance.recordError(
    error,
    stack,
    reason: 'server_settlement',
    fatal: false,
  );
}
