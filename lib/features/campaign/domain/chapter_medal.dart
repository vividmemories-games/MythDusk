import '../../battle/domain/battle_objective.dart';

/// Locked v1 chapter-medal condition kinds (8 types).
enum ChapterMedalType {
  matchTilesColor('match_tiles_color'),
  breakOverlays('break_overlays'),
  winsAboveHpPct('wins_above_hp_pct'),
  winsWithoutPrep('wins_without_prep'),
  bossFormUnderTurns('boss_form_under_turns'),
  chapterTotalPlayerTurns('chapter_total_player_turns'),
  generateResource('generate_resource'),
  castSkills('cast_skills');

  const ChapterMedalType(this.wireName);
  final String wireName;

  static ChapterMedalType parse(Object? raw) {
    for (final t in values) {
      if (t.wireName == raw || t.name == raw) return t;
    }
    throw FormatException('Unknown chapter medal type: $raw');
  }
}

/// One chapter-scoped medal definition.
class ChapterMedalDefinition {
  const ChapterMedalDefinition({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.type,
    required this.target,
    this.colorId,
    this.resourceId,
    this.bossForm,
    this.minHpPct = 50,
    this.coinReward = 25,
    this.masteryXp = 1,
  });

  final String id;
  final String chapterId;
  final String title;
  final ChapterMedalType type;
  final int target;
  final String? colorId;
  final String? resourceId;
  final int? bossForm;
  final int minHpPct;
  final int coinReward;
  final int masteryXp;

  String progressLabel(int current) =>
      '$title · ${current.clamp(0, target)}/$target';
}

/// Cumulative counters for one chapter's medal track.
class ChapterMedalCounters {
  const ChapterMedalCounters({
    this.tilesByColor = const {},
    this.overlaysBroken = 0,
    this.winsAboveHpPct = 0,
    this.winsWithoutPrep = 0,
    this.bossFormTurns = const {},
    this.totalPlayerTurns = 0,
    this.resourcesGenerated = const {},
    this.skillsCast = 0,
  });

  final Map<String, int> tilesByColor;
  final int overlaysBroken;
  final int winsAboveHpPct;
  final int winsWithoutPrep;

  /// bossForm → best (lowest) player-turn count on a winning clear of that form.
  final Map<String, int> bossFormTurns;
  final int totalPlayerTurns;
  final Map<String, int> resourcesGenerated;
  final int skillsCast;

  int valueFor(ChapterMedalDefinition def) {
    return switch (def.type) {
      ChapterMedalType.matchTilesColor =>
        tilesByColor[def.colorId ?? 'red'] ?? 0,
      ChapterMedalType.breakOverlays => overlaysBroken,
      ChapterMedalType.winsAboveHpPct => winsAboveHpPct,
      ChapterMedalType.winsWithoutPrep => winsWithoutPrep,
      ChapterMedalType.bossFormUnderTurns =>
        bossFormTurns['${def.bossForm ?? 4}'] ?? 9999,
      ChapterMedalType.chapterTotalPlayerTurns => totalPlayerTurns,
      ChapterMedalType.generateResource =>
        resourcesGenerated[def.resourceId ?? 'mana'] ?? 0,
      ChapterMedalType.castSkills => skillsCast,
    };
  }

  bool isMet(
    ChapterMedalDefinition def, {
    bool chapterComplete = false,
  }) {
    final v = valueFor(def);
    return switch (def.type) {
      ChapterMedalType.bossFormUnderTurns =>
        bossFormTurns.containsKey('${def.bossForm ?? 4}') && v <= def.target,
      ChapterMedalType.chapterTotalPlayerTurns =>
        chapterComplete && totalPlayerTurns > 0 && v <= def.target,
      _ => v >= def.target,
    };
  }

  ChapterMedalCounters copyWith({
    Map<String, int>? tilesByColor,
    int? overlaysBroken,
    int? winsAboveHpPct,
    int? winsWithoutPrep,
    Map<String, int>? bossFormTurns,
    int? totalPlayerTurns,
    Map<String, int>? resourcesGenerated,
    int? skillsCast,
  }) {
    return ChapterMedalCounters(
      tilesByColor: tilesByColor ?? this.tilesByColor,
      overlaysBroken: overlaysBroken ?? this.overlaysBroken,
      winsAboveHpPct: winsAboveHpPct ?? this.winsAboveHpPct,
      winsWithoutPrep: winsWithoutPrep ?? this.winsWithoutPrep,
      bossFormTurns: bossFormTurns ?? this.bossFormTurns,
      totalPlayerTurns: totalPlayerTurns ?? this.totalPlayerTurns,
      resourcesGenerated: resourcesGenerated ?? this.resourcesGenerated,
      skillsCast: skillsCast ?? this.skillsCast,
    );
  }

  Map<String, dynamic> toJson() => {
        'tilesByColor': tilesByColor,
        'overlaysBroken': overlaysBroken,
        'winsAboveHpPct': winsAboveHpPct,
        'winsWithoutPrep': winsWithoutPrep,
        'bossFormTurns': bossFormTurns,
        'totalPlayerTurns': totalPlayerTurns,
        'resourcesGenerated': resourcesGenerated,
        'skillsCast': skillsCast,
      };

  factory ChapterMedalCounters.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ChapterMedalCounters();
    Map<String, int> mapOf(Object? raw) {
      if (raw is! Map) return {};
      return {
        for (final e in raw.entries) e.key.toString(): (e.value as num).toInt(),
      };
    }

    return ChapterMedalCounters(
      tilesByColor: mapOf(json['tilesByColor']),
      overlaysBroken: (json['overlaysBroken'] as num?)?.toInt() ?? 0,
      winsAboveHpPct: (json['winsAboveHpPct'] as num?)?.toInt() ?? 0,
      winsWithoutPrep: (json['winsWithoutPrep'] as num?)?.toInt() ?? 0,
      bossFormTurns: mapOf(json['bossFormTurns']),
      totalPlayerTurns: (json['totalPlayerTurns'] as num?)?.toInt() ?? 0,
      resourcesGenerated: mapOf(json['resourcesGenerated']),
      skillsCast: (json['skillsCast'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Folds a winning campaign battle into chapter medal counters.
abstract final class ChapterMedalFold {
  static ChapterMedalCounters applyVictory({
    required ChapterMedalCounters current,
    required BattleProgress progress,
    required int heroHp,
    required int heroMaxHp,
    required bool usedPrep,
    int? bossForm,
  }) {
    final tiles = Map<String, int>.from(current.tilesByColor);
    progress.tilesClearedByColor.forEach((k, v) {
      tiles[k] = (tiles[k] ?? 0) + v;
    });
    final resources = Map<String, int>.from(current.resourcesGenerated);
    progress.resourcesGenerated.forEach((k, v) {
      resources[k] = (resources[k] ?? 0) + v;
    });

    final hpPct = heroMaxHp <= 0 ? 0 : ((heroHp / heroMaxHp) * 100).round();
    final bossTurns = Map<String, int>.from(current.bossFormTurns);
    if (bossForm != null) {
      final key = '$bossForm';
      final prev = bossTurns[key];
      if (prev == null || progress.playerTurnNumber < prev) {
        bossTurns[key] = progress.playerTurnNumber;
      }
    }

    return current.copyWith(
      tilesByColor: tiles,
      overlaysBroken: current.overlaysBroken + progress.overlaysBroken,
      winsAboveHpPct: current.winsAboveHpPct + (hpPct >= 50 ? 1 : 0),
      winsWithoutPrep: current.winsWithoutPrep + (usedPrep ? 0 : 1),
      bossFormTurns: bossTurns,
      totalPlayerTurns: current.totalPlayerTurns + progress.playerTurnNumber,
      resourcesGenerated: resources,
      skillsCast: current.skillsCast + progress.skillsCastCount,
    );
  }
}
