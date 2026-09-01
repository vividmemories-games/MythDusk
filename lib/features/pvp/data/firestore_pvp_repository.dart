import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/battle_action.dart';
import '../domain/pvp_models.dart';
import 'pvp_repository.dart';

class FirestorePvpRepository implements PvpRepository {
  FirestorePvpRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _db.collection('challenges');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('matches');

  @override
  Future<PvpChallenge> createChallenge({
    required String challengerUid,
    required PvpLoadout loadout,
  }) async {
    final now = DateTime.now().toUtc();
    final ref = _challenges.doc();
    final challenge = PvpChallenge(
      id: ref.id,
      challengerUid: challengerUid,
      joinCode: PvpIds.joinCode(),
      seed: now.microsecondsSinceEpoch & 0x7fffffff,
      loadoutA: loadout,
      createdAt: now,
      expiresAt: now.add(pvpInviteTtl),
    );
    await ref.set(challenge.toJson());
    return challenge;
  }

  @override
  Future<PvpMatch> acceptChallenge({
    required String joinCode,
    required String inviteeUid,
    required PvpLoadout loadout,
  }) async {
    final query = await _challenges
        .where('joinCode', isEqualTo: joinCode)
        .where('status', isEqualTo: PvpChallengeStatus.open.name)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw StateError('No live challenge for that code.');
    }
    final doc = query.docs.first;
    final data = doc.data();
    if (data['challengerUid'] == inviteeUid) {
      throw StateError('Cannot accept your own challenge.');
    }
    final now = DateTime.now().toUtc();
    final challenge = PvpChallenge(
      id: doc.id,
      challengerUid: data['challengerUid'] as String,
      inviteeUid: inviteeUid,
      joinCode: joinCode,
      seed: (data['seed'] as num).toInt(),
      loadoutA: PvpLoadout.fromJson(
        Map<String, dynamic>.from(data['loadoutA'] as Map),
      ),
      loadoutB: loadout,
      status: PvpChallengeStatus.accepted,
      createdAt: DateTime.parse(data['createdAt'] as String),
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
    final matchRef = _matches.doc();
    final match = PvpMatch(
      id: matchRef.id,
      uidA: challenge.challengerUid,
      uidB: inviteeUid,
      seed: challenge.seed,
      loadoutA: challenge.loadoutA,
      loadoutB: loadout,
      currentUid: challenge.challengerUid,
      heartbeatA: now,
      heartbeatB: now,
    );
    final batch = _db.batch();
    batch.update(doc.reference, {
      'inviteeUid': inviteeUid,
      'loadoutB': loadout.toJson(),
      'status': PvpChallengeStatus.accepted.name,
      'matchId': match.id,
    });
    batch.set(matchRef, {
      ...match.toJson(),
      'challengeId': challenge.id,
    });
    await batch.commit();
    return match;
  }

  @override
  Future<void> cancelChallenge(String challengeId) {
    return _challenges.doc(challengeId).update({
      'status': PvpChallengeStatus.cancelled.name,
    });
  }

  @override
  Stream<PvpChallenge?> watchChallenge(String challengeId) {
    return _challenges.doc(challengeId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      return PvpChallenge(
        id: snap.id,
        challengerUid: data['challengerUid'] as String,
        inviteeUid: data['inviteeUid'] as String?,
        joinCode: data['joinCode'] as String,
        seed: (data['seed'] as num).toInt(),
        loadoutA: PvpLoadout.fromJson(
          Map<String, dynamic>.from(data['loadoutA'] as Map),
        ),
        loadoutB: data['loadoutB'] == null
            ? null
            : PvpLoadout.fromJson(
                Map<String, dynamic>.from(data['loadoutB'] as Map),
              ),
        status: PvpChallengeStatus.values.firstWhere(
          (value) => value.name == data['status'],
          orElse: () => PvpChallengeStatus.open,
        ),
        createdAt: DateTime.parse(data['createdAt'] as String),
        expiresAt: DateTime.parse(data['expiresAt'] as String),
        matchId: data['matchId'] as String?,
      );
    });
  }

  @override
  Stream<PvpMatch?> watchMatch(String matchId) {
    return _matches.doc(matchId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return PvpMatch.fromJson(snap.id, snap.data()!);
    });
  }

  @override
  Future<void> appendAction({
    required String matchId,
    required BattleAction action,
    required String nextUid,
    PvpMatchStatus? status,
  }) {
    return _db.runTransaction((tx) async {
      final ref = _matches.doc(matchId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final match = PvpMatch.fromJson(snap.id, snap.data()!);
      if (!match.isLive) return;
      tx.update(ref, {
        'actionLog': [
          for (final item in match.actionLog) item.toJson(),
          action.toJson(),
        ],
        'currentUid': nextUid,
        if (status != null) 'status': status.name,
      });
    });
  }

  @override
  Future<void> heartbeat({
    required String matchId,
    required String uid,
  }) async {
    final snap = await _matches.doc(matchId).get();
    if (!snap.exists) return;
    final match = PvpMatch.fromJson(snap.id, snap.data()!);
    final key = uid == match.uidA ? 'heartbeatA' : 'heartbeatB';
    await snap.reference.update({
      key: DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> forfeit({
    required String matchId,
    required String uid,
  }) {
    return appendAction(
      matchId: matchId,
      action: BattleAction.forfeit(actorUid: uid),
      nextUid: uid,
      status: PvpMatchStatus.forfeited,
    );
  }
}
