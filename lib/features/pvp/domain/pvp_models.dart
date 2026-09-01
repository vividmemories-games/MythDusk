import 'dart:math';

import '../../heroes/domain/hero_def.dart';
import 'battle_action.dart';

const pvpInviteTtl = Duration(seconds: 60);
const pvpHeartbeatTimeout = Duration(seconds: 20);

enum PvpChallengeStatus { open, pending, accepted, expired, cancelled }

enum PvpMatchStatus { live, finished, forfeited }

class PvpLoadout {
  const PvpLoadout({
    required this.heroId,
    required this.skillIds,
  });

  final String heroId;
  final List<String> skillIds;

  HeroDef get hero {
    final base = HeroCatalog.byId(heroId);
    return base.withEquippedSkillIds(skillIds);
  }

  Map<String, dynamic> toJson() => {
        'heroId': heroId,
        'skillIds': skillIds,
      };

  factory PvpLoadout.fromJson(Map<String, dynamic> json) {
    return PvpLoadout(
      heroId: json['heroId'] as String? ?? 'mage',
      skillIds: (json['skillIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

class PvpChallenge {
  const PvpChallenge({
    required this.id,
    required this.challengerUid,
    required this.joinCode,
    required this.seed,
    required this.loadoutA,
    required this.createdAt,
    required this.expiresAt,
    this.inviteeUid,
    this.loadoutB,
    this.status = PvpChallengeStatus.open,
    this.matchId,
  });

  final String id;
  final String challengerUid;
  final String? inviteeUid;
  final String joinCode;
  final int seed;
  final PvpLoadout loadoutA;
  final PvpLoadout? loadoutB;
  final PvpChallengeStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? matchId;

  bool isExpired(DateTime now) =>
      status == PvpChallengeStatus.expired || now.isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'challengerUid': challengerUid,
        'inviteeUid': inviteeUid,
        'joinCode': joinCode,
        'seed': seed,
        'loadoutA': loadoutA.toJson(),
        'loadoutB': loadoutB?.toJson(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        if (matchId != null) 'matchId': matchId,
      };
}

class PvpMatch {
  const PvpMatch({
    required this.id,
    required this.uidA,
    required this.uidB,
    required this.seed,
    required this.loadoutA,
    required this.loadoutB,
    required this.currentUid,
    this.actionLog = const [],
    this.status = PvpMatchStatus.live,
    this.heartbeatA,
    this.heartbeatB,
  });

  final String id;
  final String uidA;
  final String uidB;
  final int seed;
  final PvpLoadout loadoutA;
  final PvpLoadout loadoutB;
  final String currentUid;
  final List<BattleAction> actionLog;
  final PvpMatchStatus status;
  final DateTime? heartbeatA;
  final DateTime? heartbeatB;

  bool get isLive => status == PvpMatchStatus.live;

  bool isMyTurn(String uid) => isLive && currentUid == uid;

  String opponentUid(String uid) => uid == uidA ? uidB : uidA;

  PvpLoadout loadoutFor(String uid) => uid == uidA ? loadoutA : loadoutB;

  PvpLoadout opponentLoadout(String uid) => uid == uidA ? loadoutB : loadoutA;

  bool heartbeatTimedOut(String uid, DateTime now) {
    final beat = uid == uidA ? heartbeatA : heartbeatB;
    if (beat == null) return false;
    return now.difference(beat) > pvpHeartbeatTimeout;
  }

  PvpMatch copyWith({
    List<BattleAction>? actionLog,
    String? currentUid,
    PvpMatchStatus? status,
    DateTime? heartbeatA,
    DateTime? heartbeatB,
  }) {
    return PvpMatch(
      id: id,
      uidA: uidA,
      uidB: uidB,
      seed: seed,
      loadoutA: loadoutA,
      loadoutB: loadoutB,
      currentUid: currentUid ?? this.currentUid,
      actionLog: actionLog ?? this.actionLog,
      status: status ?? this.status,
      heartbeatA: heartbeatA ?? this.heartbeatA,
      heartbeatB: heartbeatB ?? this.heartbeatB,
    );
  }

  Map<String, dynamic> toJson() => {
        'uidA': uidA,
        'uidB': uidB,
        'seed': seed,
        'loadoutA': loadoutA.toJson(),
        'loadoutB': loadoutB.toJson(),
        'currentUid': currentUid,
        'actionLog': [for (final a in actionLog) a.toJson()],
        'status': status.name,
        'heartbeatA': heartbeatA?.toIso8601String(),
        'heartbeatB': heartbeatB?.toIso8601String(),
      };

  factory PvpMatch.fromJson(String id, Map<String, dynamic> json) {
    return PvpMatch(
      id: id,
      uidA: json['uidA'] as String? ?? '',
      uidB: json['uidB'] as String? ?? '',
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      loadoutA: PvpLoadout.fromJson(
        Map<String, dynamic>.from(json['loadoutA'] as Map? ?? {}),
      ),
      loadoutB: PvpLoadout.fromJson(
        Map<String, dynamic>.from(json['loadoutB'] as Map? ?? {}),
      ),
      currentUid: json['currentUid'] as String? ?? '',
      actionLog: [
        for (final raw in (json['actionLog'] as List<dynamic>? ?? const []))
          BattleAction.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      status: PvpMatchStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => PvpMatchStatus.live,
      ),
      heartbeatA: DateTime.tryParse(json['heartbeatA'] as String? ?? ''),
      heartbeatB: DateTime.tryParse(json['heartbeatB'] as String? ?? ''),
    );
  }
}

abstract final class PvpIds {
  static String joinCode([Random? random]) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = random ?? Random();
    return String.fromCharCodes(
      List.generate(
          6, (_) => alphabet.codeUnitAt(rng.nextInt(alphabet.length))),
    );
  }
}
