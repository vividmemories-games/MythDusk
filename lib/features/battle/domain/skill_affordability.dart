import '../../heroes/domain/hero_def.dart';
import '../domain/battle_state.dart';

/// Pure affordability check for skill dock UI (no Flutter).
class SkillAffordability {
  const SkillAffordability({
    required this.canCast,
    required this.apHave,
    required this.apNeed,
    required this.resourceLines,
    this.blockingReason,
  });

  final bool canCast;
  final int apHave;
  final int apNeed;

  /// Display lines like `mana 5/8`.
  final List<SkillResourceLine> resourceLines;

  /// Short reason when [canCast] is false (e.g. `Need 3 more mana`).
  final String? blockingReason;

  bool get apOk => apHave >= apNeed;

  static SkillAffordability evaluate(SkillDef skill, BattleState battle) {
    final apHave = battle.ap;
    final apNeed = skill.apCost;
    final lines = <SkillResourceLine>[];
    String? blocking;

    for (final e in skill.resourceCosts.entries) {
      final have = battle.resources[e.key] ?? 0;
      final need = e.value;
      final ok = have >= need;
      lines.add(SkillResourceLine(
        resourceId: e.key,
        have: have,
        need: need,
        ok: ok,
      ));
      if (!ok && blocking == null) {
        final short = e.key;
        blocking = 'Need ${need - have} more $short';
      }
    }

    if (blocking == null && apHave < apNeed) {
      blocking = 'Need ${apNeed - apHave} more AP';
    }

    final canCast = battle.phase == BattlePhase.playerTurn &&
        apHave >= apNeed &&
        lines.every((l) => l.ok);

    return SkillAffordability(
      canCast: canCast,
      apHave: apHave,
      apNeed: apNeed,
      resourceLines: lines,
      blockingReason: canCast ? null : blocking,
    );
  }
}

class SkillResourceLine {
  const SkillResourceLine({
    required this.resourceId,
    required this.have,
    required this.need,
    required this.ok,
  });

  final String resourceId;
  final int have;
  final int need;
  final bool ok;

  String get label => '$have/$need';
}
