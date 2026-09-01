import '../domain/battle_action.dart';
import '../domain/pvp_models.dart';

abstract class PvpRepository {
  Future<PvpChallenge> createChallenge({
    required String challengerUid,
    required PvpLoadout loadout,
  });

  Future<PvpMatch> acceptChallenge({
    required String joinCode,
    required String inviteeUid,
    required PvpLoadout loadout,
  });

  Future<void> cancelChallenge(String challengeId);

  Stream<PvpChallenge?> watchChallenge(String challengeId);

  Stream<PvpMatch?> watchMatch(String matchId);

  Future<void> appendAction({
    required String matchId,
    required BattleAction action,
    required String nextUid,
    PvpMatchStatus? status,
  });

  Future<void> heartbeat({
    required String matchId,
    required String uid,
  });

  Future<void> forfeit({
    required String matchId,
    required String uid,
  });
}
