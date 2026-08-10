import '../../battle/domain/battle_objective.dart';
import '../../battle/domain/enemy_def.dart';
import 'daily_battle_medal.dart';

/// One Daily Contract (single battle for the local calendar day).
class DailyContract {
  const DailyContract({
    required this.dayKey,
    required this.templateId,
    required this.title,
    required this.blurb,
    required this.enemyId,
    required this.enemyName,
    required this.coinReward,
    required this.objective,
    required this.medals,
  });

  final String dayKey;
  final String templateId;
  final String title;
  final String blurb;
  final String enemyId;
  final String enemyName;
  final int coinReward;
  final BattleObjective objective;
  final List<DailyMedalDefinition> medals;
}

/// Optional per-battle medal on a Daily Contract.
class DailyMedalDefinition {
  const DailyMedalDefinition({
    required this.id,
    required this.title,
    required this.type,
    required this.target,
    this.colorId,
    this.resourceId,
    this.minHpPct = 50,
    this.coinReward = 15,
  });

  final String id;
  final String title;
  final DailyBattleMedalType type;
  final int target;
  final String? colorId;
  final String? resourceId;
  final int minHpPct;
  final int coinReward;
}

/// Daily balance + route id.
abstract final class DailyBalance {
  static const battleNodeId = 'daily';
  static const baseCoinReward = 35;
  static const medalCoinBonus = 15;
}

/// Seeded rotating Daily contracts (7 templates).
abstract final class DailySchedule {
  static String dayKey(DateTime local) {
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  }

  static int _hash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  static DailyContract forDate(DateTime local) {
    final key = dayKey(local);
    final idx = _hash(key) % _templates.length;
    final t = _templates[idx];
    final enemy = EnemyCatalog.byId(t.enemyId);
    return DailyContract(
      dayKey: key,
      templateId: t.id,
      title: t.title,
      blurb: t.blurb,
      enemyId: t.enemyId,
      enemyName: enemy.name,
      coinReward: DailyBalance.baseCoinReward,
      objective: t.objective,
      medals: [
        for (final m in t.medals)
          DailyMedalDefinition(
            id: '${key}_${m.idSuffix}',
            title: m.title,
            type: m.type,
            target: m.target,
            colorId: m.colorId,
            resourceId: m.resourceId,
            minHpPct: m.minHpPct,
            coinReward: DailyBalance.medalCoinBonus,
          ),
      ],
    );
  }

  static const _templates = <_DailyTemplate>[
    _DailyTemplate(
      id: 'daily_survive_mire',
      title: 'Hold the Marsh',
      blurb: 'Survive the mire long enough to claim today’s contract.',
      enemyId: 'mire_spawn',
      objective: BattleObjective(
        type: BattleObjectiveType.surviveTurns,
        target: 6,
      ),
      medals: [
        _MedalStub(
          idSuffix: 'hp',
          title: 'Steady Boots',
          type: DailyBattleMedalType.finishAboveHpPct,
          target: 1,
          minHpPct: 50,
        ),
        _MedalStub(
          idSuffix: 'green',
          title: 'Reed Matches',
          type: DailyBattleMedalType.matchTilesColor,
          target: 18,
          colorId: 'green',
        ),
        _MedalStub(
          idSuffix: 'cast',
          title: 'Cast Twice',
          type: DailyBattleMedalType.castSkills,
          target: 2,
        ),
      ],
    ),
    _DailyTemplate(
      id: 'daily_clear_scout',
      title: 'Sweep the Ridge',
      blurb: 'Clear tiles before the scout overwhelms you.',
      enemyId: 'goblin',
      objective: BattleObjective(
        type: BattleObjectiveType.clearTiles,
        target: 48,
      ),
      medals: [
        _MedalStub(
          idSuffix: 'turns',
          title: 'Quick Sweep',
          type: DailyBattleMedalType.underPlayerTurns,
          target: 7,
        ),
        _MedalStub(
          idSuffix: 'mana',
          title: 'Mana Stockpile',
          type: DailyBattleMedalType.generateResource,
          target: 20,
          resourceId: 'mana',
        ),
        _MedalStub(
          idSuffix: 'noprep',
          title: 'No Prep',
          type: DailyBattleMedalType.finishWithoutPrep,
          target: 1,
        ),
      ],
    ),
    _DailyTemplate(
      id: 'daily_survive_wolf',
      title: 'Howl Watch',
      blurb: 'Survive the pack’s pressure.',
      enemyId: 'wolf',
      objective: BattleObjective(
        type: BattleObjectiveType.surviveTurns,
        target: 7,
      ),
      medals: [
        _MedalStub(
          idSuffix: 'blue',
          title: 'Blue Gale',
          type: DailyBattleMedalType.matchTilesColor,
          target: 20,
          colorId: 'blue',
        ),
        _MedalStub(
          idSuffix: 'skills',
          title: 'Both Skills',
          type: DailyBattleMedalType.castDistinctSkills,
          target: 2,
        ),
        _MedalStub(
          idSuffix: 'hp',
          title: 'Unscuffed',
          type: DailyBattleMedalType.finishAboveHpPct,
          target: 1,
          minHpPct: 60,
        ),
      ],
    ),
    _DailyTemplate(
      id: 'daily_clear_hexer',
      title: 'Break the Hex',
      blurb: 'Clear the board while the hexer warps the spawn.',
      enemyId: 'hexer',
      objective: BattleObjective(
        type: BattleObjectiveType.clearTiles,
        target: 52,
      ),
      medals: [
        _MedalStub(
          idSuffix: 'purple',
          title: 'Purple Warp',
          type: DailyBattleMedalType.matchTilesColor,
          target: 16,
          colorId: 'purple',
        ),
        _MedalStub(
          idSuffix: 'cast',
          title: 'Skill Barrage',
          type: DailyBattleMedalType.castSkills,
          target: 3,
        ),
        _MedalStub(
          idSuffix: 'turns',
          title: 'Under Pressure',
          type: DailyBattleMedalType.underPlayerTurns,
          target: 8,
        ),
      ],
    ),
    _DailyTemplate(
      id: 'daily_survive_leech',
      title: 'Leech Line',
      blurb: 'Survive while the wisp drains your stores.',
      enemyId: 'leech_wisp',
      objective: BattleObjective(
        type: BattleObjectiveType.surviveTurns,
        target: 6,
      ),
      medals: [
        _MedalStub(
          idSuffix: 'healing',
          title: 'Healing Kept',
          type: DailyBattleMedalType.generateResource,
          target: 16,
          resourceId: 'healing',
        ),
        _MedalStub(
          idSuffix: 'noprep',
          title: 'Bare Hands',
          type: DailyBattleMedalType.finishWithoutPrep,
          target: 1,
        ),
        _MedalStub(
          idSuffix: 'hp',
          title: 'Vital Line',
          type: DailyBattleMedalType.finishAboveHpPct,
          target: 1,
          minHpPct: 40,
        ),
      ],
    ),
    _DailyTemplate(
      id: 'daily_clear_shaman',
      title: 'Shatter Totems',
      blurb: 'Clear tiles through shaman pressure.',
      enemyId: 'shaman',
      objective: BattleObjective(
        type: BattleObjectiveType.clearTiles,
        target: 50,
      ),
      medals: [
        _MedalStub(
          idSuffix: 'red',
          title: 'Ember Clears',
          type: DailyBattleMedalType.matchTilesColor,
          target: 18,
          colorId: 'red',
        ),
        _MedalStub(
          idSuffix: 'attack',
          title: 'Attack Stock',
          type: DailyBattleMedalType.generateResource,
          target: 22,
          resourceId: 'attack',
        ),
        _MedalStub(
          idSuffix: 'skills',
          title: 'Dual Cast',
          type: DailyBattleMedalType.castDistinctSkills,
          target: 2,
        ),
      ],
    ),
    _DailyTemplate(
      id: 'daily_survive_brute',
      title: 'Stone Stand',
      blurb: 'Survive the brute’s slow crush.',
      enemyId: 'brute',
      objective: BattleObjective(
        type: BattleObjectiveType.surviveTurns,
        target: 8,
      ),
      medals: [
        _MedalStub(
          idSuffix: 'yellow',
          title: 'Shield Matches',
          type: DailyBattleMedalType.matchTilesColor,
          target: 16,
          colorId: 'yellow',
        ),
        _MedalStub(
          idSuffix: 'shield',
          title: 'Shield Stock',
          type: DailyBattleMedalType.generateResource,
          target: 18,
          resourceId: 'shield',
        ),
        _MedalStub(
          idSuffix: 'cast',
          title: 'Three Casts',
          type: DailyBattleMedalType.castSkills,
          target: 3,
        ),
      ],
    ),
  ];
}

class _DailyTemplate {
  const _DailyTemplate({
    required this.id,
    required this.title,
    required this.blurb,
    required this.enemyId,
    required this.objective,
    required this.medals,
  });

  final String id;
  final String title;
  final String blurb;
  final String enemyId;
  final BattleObjective objective;
  final List<_MedalStub> medals;
}

class _MedalStub {
  const _MedalStub({
    required this.idSuffix,
    required this.title,
    required this.type,
    required this.target,
    this.colorId,
    this.resourceId,
    this.minHpPct = 50,
  });

  final String idSuffix;
  final String title;
  final DailyBattleMedalType type;
  final int target;
  final String? colorId;
  final String? resourceId;
  final int minHpPct;
}

/// Evaluates Daily medals from a finished [BattleProgress] snapshot.
abstract final class DailyMedalEval {
  static bool isMet(
    DailyMedalDefinition medal, {
    required BattleProgress progress,
    required int heroHp,
    required int heroMaxHp,
  }) {
    final hpPct = heroMaxHp <= 0 ? 0 : ((heroHp / heroMaxHp) * 100).round();
    return switch (medal.type) {
      DailyBattleMedalType.matchTilesColor =>
        (progress.tilesClearedByColor[medal.colorId ?? 'red'] ?? 0) >=
            medal.target,
      DailyBattleMedalType.breakOverlays =>
        progress.overlaysBroken >= medal.target,
      DailyBattleMedalType.finishAboveHpPct => hpPct >= medal.minHpPct,
      DailyBattleMedalType.finishWithoutPrep => !progress.usedPrep,
      DailyBattleMedalType.underPlayerTurns => progress.playerTurnNumber > 0 &&
          progress.playerTurnNumber <= medal.target,
      DailyBattleMedalType.generateResource =>
        (progress.resourcesGenerated[medal.resourceId ?? 'mana'] ?? 0) >=
            medal.target,
      DailyBattleMedalType.castSkills =>
        progress.skillsCastCount >= medal.target,
      DailyBattleMedalType.castDistinctSkills =>
        progress.distinctSkillsCast.length >= medal.target,
    };
  }
}
