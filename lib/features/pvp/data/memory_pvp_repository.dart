import 'dart:async';
import 'dart:math';

import '../domain/battle_action.dart';
import '../domain/pvp_models.dart';
import 'pvp_repository.dart';

/// In-process live 1v1. Used by tests and when Firebase is not ready.
class MemoryPvpRepository implements PvpRepository {
  MemoryPvpRepository({Random? random}) : _random = random ?? Random();

  final Random _random;
  final _challenges = <String, PvpChallenge>{};
  final _matches = <String, PvpMatch>{};
  final _challengeCtrls = <String, StreamController<PvpChallenge?>>{};
  final _matchCtrls = <String, StreamController<PvpMatch?>>{};

  @override
  Future<PvpChallenge> createChallenge({
    required String challengerUid,
    required PvpLoadout loadout,
  }) async {
    final id = 'chal_${_random.nextInt(1 << 32)}';
    final now = DateTime.now().toUtc();
    final challenge = PvpChallenge(
      id: id,
      challengerUid: challengerUid,
      joinCode: PvpIds.joinCode(_random),
      seed: _random.nextInt(1 << 32),
      loadoutA: loadout,
      createdAt: now,
      expiresAt: now.add(pvpInviteTtl),
    );
    _challenges[id] = challenge;
    _emitChallenge(challenge);
    return challenge;
  }

  @override
  Future<PvpMatch> acceptChallenge({
    required String joinCode,
    required String inviteeUid,
    required PvpLoadout loadout,
  }) async {
    final now = DateTime.now().toUtc();
    PvpChallenge? challenge;
    for (final candidate in _challenges.values) {
      if (candidate.joinCode == joinCode &&
          candidate.status == PvpChallengeStatus.open &&
          !candidate.isExpired(now)) {
        challenge = candidate;
        break;
      }
    }
    if (challenge == null) {
      throw StateError('No live challenge for that code.');
    }
    if (challenge.challengerUid == inviteeUid) {
      throw StateError('Cannot accept your own challenge.');
    }
    final matchId = 'match_${challenge.id}';
    final match = PvpMatch(
      id: matchId,
      uidA: challenge.challengerUid,
      uidB: inviteeUid,
      seed: challenge.seed,
      loadoutA: challenge.loadoutA,
      loadoutB: loadout,
      currentUid: challenge.challengerUid,
      heartbeatA: now,
      heartbeatB: now,
    );
    _matches[matchId] = match;
    _challenges[challenge.id] = PvpChallenge(
      id: challenge.id,
      challengerUid: challenge.challengerUid,
      inviteeUid: inviteeUid,
      joinCode: challenge.joinCode,
      seed: challenge.seed,
      loadoutA: challenge.loadoutA,
      loadoutB: loadout,
      status: PvpChallengeStatus.accepted,
      createdAt: challenge.createdAt,
      expiresAt: challenge.expiresAt,
      matchId: matchId,
    );
    _emitChallenge(_challenges[challenge.id]!);
    _emitMatch(match);
    return match;
  }

  @override
  Future<void> cancelChallenge(String challengeId) async {
    final current = _challenges[challengeId];
    if (current == null) return;
    _challenges[challengeId] = PvpChallenge(
      id: current.id,
      challengerUid: current.challengerUid,
      inviteeUid: current.inviteeUid,
      joinCode: current.joinCode,
      seed: current.seed,
      loadoutA: current.loadoutA,
      loadoutB: current.loadoutB,
      status: PvpChallengeStatus.cancelled,
      createdAt: current.createdAt,
      expiresAt: current.expiresAt,
    );
    _emitChallenge(_challenges[challengeId]!);
  }

  @override
  Stream<PvpChallenge?> watchChallenge(String challengeId) {
    final controller =
        _challengeCtrls.putIfAbsent(challengeId, StreamController.broadcast);
    scheduleMicrotask(() => controller.add(_challenges[challengeId]));
    return controller.stream;
  }

  @override
  Stream<PvpMatch?> watchMatch(String matchId) {
    final controller =
        _matchCtrls.putIfAbsent(matchId, StreamController.broadcast);
    scheduleMicrotask(() => controller.add(_matches[matchId]));
    return controller.stream;
  }

  @override
  Future<void> appendAction({
    required String matchId,
    required BattleAction action,
    required String nextUid,
    PvpMatchStatus? status,
  }) async {
    final current = _matches[matchId];
    if (current == null || !current.isLive) return;
    final next = current.copyWith(
      actionLog: [...current.actionLog, action],
      currentUid: nextUid,
      status: status ?? current.status,
    );
    _matches[matchId] = next;
    _emitMatch(next);
  }

  @override
  Future<void> heartbeat({
    required String matchId,
    required String uid,
  }) async {
    final current = _matches[matchId];
    if (current == null) return;
    final now = DateTime.now().toUtc();
    final next = current.copyWith(
      heartbeatA: uid == current.uidA ? now : current.heartbeatA,
      heartbeatB: uid == current.uidB ? now : current.heartbeatB,
    );
    _matches[matchId] = next;
    _emitMatch(next);
  }

  @override
  Future<void> forfeit({
    required String matchId,
    required String uid,
  }) async {
    await appendAction(
      matchId: matchId,
      action: BattleAction.forfeit(actorUid: uid),
      nextUid: uid,
      status: PvpMatchStatus.forfeited,
    );
  }

  void _emitChallenge(PvpChallenge challenge) {
    _challengeCtrls[challenge.id]?.add(challenge);
  }

  void _emitMatch(PvpMatch match) {
    _matchCtrls[match.id]?.add(match);
  }
}
