/// Serializable player inputs for live 1v1 replay.
enum BattleActionType { swap, activate, castSkill, endTurn, forfeit }

class BattleAction {
  const BattleAction({
    required this.type,
    required this.actorUid,
    this.rowA,
    this.colA,
    this.rowB,
    this.colB,
    this.skillId,
  });

  final BattleActionType type;
  final String actorUid;
  final int? rowA;
  final int? colA;
  final int? rowB;
  final int? colB;
  final String? skillId;

  (int, int) get cellA => (rowA ?? 0, colA ?? 0);
  (int, int) get cellB => (rowB ?? 0, colB ?? 0);

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'actorUid': actorUid,
        if (rowA != null) 'rowA': rowA,
        if (colA != null) 'colA': colA,
        if (rowB != null) 'rowB': rowB,
        if (colB != null) 'colB': colB,
        if (skillId != null) 'skillId': skillId,
      };

  factory BattleAction.fromJson(Map<String, dynamic> json) {
    return BattleAction(
      type: BattleActionType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => BattleActionType.endTurn,
      ),
      actorUid: json['actorUid'] as String? ?? '',
      rowA: (json['rowA'] as num?)?.toInt(),
      colA: (json['colA'] as num?)?.toInt(),
      rowB: (json['rowB'] as num?)?.toInt(),
      colB: (json['colB'] as num?)?.toInt(),
      skillId: json['skillId'] as String?,
    );
  }

  static BattleAction swap({
    required String actorUid,
    required (int, int) a,
    required (int, int) b,
  }) {
    return BattleAction(
      type: BattleActionType.swap,
      actorUid: actorUid,
      rowA: a.$1,
      colA: a.$2,
      rowB: b.$1,
      colB: b.$2,
    );
  }

  static BattleAction activate({
    required String actorUid,
    required (int, int) pos,
  }) {
    return BattleAction(
      type: BattleActionType.activate,
      actorUid: actorUid,
      rowA: pos.$1,
      colA: pos.$2,
    );
  }

  static BattleAction cast({
    required String actorUid,
    required String skillId,
  }) {
    return BattleAction(
      type: BattleActionType.castSkill,
      actorUid: actorUid,
      skillId: skillId,
    );
  }

  static BattleAction endTurn({required String actorUid}) {
    return BattleAction(type: BattleActionType.endTurn, actorUid: actorUid);
  }

  static BattleAction forfeit({required String actorUid}) {
    return BattleAction(type: BattleActionType.forfeit, actorUid: actorUid);
  }
}
