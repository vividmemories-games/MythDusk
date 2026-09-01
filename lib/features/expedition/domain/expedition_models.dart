import '../../battle/domain/enemy_def.dart';

/// Relic effect kinds (expedition-only; never match-damage).
enum RelicEffectType {
  firstBlueMatchAp,
  matchFiveBonusMove,
  overlayBreakMana,
  lowHpSkillPower,
  greenMatchAp,
}

class RelicDefinition {
  const RelicDefinition({
    required this.id,
    required this.name,
    required this.blurb,
    required this.effect,
    this.tags = const [],
    this.schemaVersion = 1,
  });

  final String id;
  final String name;
  final String blurb;
  final RelicEffectType effect;
  final List<String> tags;
  final int schemaVersion;
}

abstract final class RelicCatalog {
  static const all = <RelicDefinition>[
    RelicDefinition(
      id: 'relic_first_blue_ap',
      name: 'Azure Spark',
      blurb: 'First blue match each turn grants +1 AP.',
      effect: RelicEffectType.firstBlueMatchAp,
      tags: ['ap'],
    ),
    RelicDefinition(
      id: 'relic_five_match_move',
      name: 'Cascade Step',
      blurb: 'Clearing 5+ tiles in one match grants +1 Move next turn.',
      effect: RelicEffectType.matchFiveBonusMove,
      tags: ['moves'],
    ),
    RelicDefinition(
      id: 'relic_overlay_mana',
      name: 'Rune Siphon',
      blurb: 'Breaking an overlay grants +2 Mana.',
      effect: RelicEffectType.overlayBreakMana,
      tags: ['mana'],
    ),
    RelicDefinition(
      id: 'relic_bloodied_power',
      name: 'Bloodied Edge',
      blurb: 'Below 50% HP, skill damage is increased.',
      effect: RelicEffectType.lowHpSkillPower,
      tags: ['damage'],
    ),
    RelicDefinition(
      id: 'relic_green_cascade_ap',
      name: 'Verdant Pulse',
      blurb: 'Green matches grant bonus AP.',
      effect: RelicEffectType.greenMatchAp,
      tags: ['ap', 'green'],
    ),
    RelicDefinition(
      id: 'relic_intent_focus',
      name: 'Keen Eye',
      blurb: 'Your first blue match each turn sparks +1 AP.',
      effect: RelicEffectType.firstBlueMatchAp,
      tags: ['ap', 'unique_peek'],
    ),
  ];

  static RelicDefinition? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Three deterministic offers from [seed] that avoid duplicate tags when possible.
  static List<RelicDefinition> offerThree({
    required int seed,
    required Set<String> ownedIds,
  }) {
    final pool = [
      for (final r in all)
        if (!ownedIds.contains(r.id)) r,
    ];
    if (pool.isEmpty) return const [];
    final picked = <RelicDefinition>[];
    final usedTags = <String>{};
    var cursor = seed & 0x7fffffff;
    var guard = 0;
    while (picked.length < 3 && guard < 64) {
      guard++;
      cursor = (cursor * 1103515245 + 12345) & 0x7fffffff;
      final candidate = pool[cursor % pool.length];
      if (picked.any((p) => p.id == candidate.id)) continue;
      final clash = candidate.tags.any(usedTags.contains);
      if (clash && picked.length + (pool.length - picked.length) > 3) {
        // Prefer non-clashing if alternatives remain.
        final alt = pool.where(
          (r) =>
              !picked.any((p) => p.id == r.id) &&
              !r.tags.any(usedTags.contains),
        );
        if (alt.isNotEmpty) {
          final a = alt.elementAt(cursor % alt.length);
          picked.add(a);
          usedTags.addAll(a.tags);
          continue;
        }
      }
      picked.add(candidate);
      usedTags.addAll(candidate.tags);
    }
    return List.unmodifiable(picked);
  }
}

enum ExpeditionPhase {
  hub,
  battle,
  relicPick,
  settled,
  failed,
}

/// Persisted expedition run.
class ExpeditionRunState {
  const ExpeditionRunState({
    required this.runId,
    required this.seed,
    required this.heroId,
    required this.battleIndex,
    required this.phase,
    this.relicIds = const [],
    this.retryUsed = false,
    this.pendingRelicOffers = const [],
  });

  final String runId;
  final int seed;
  final String heroId;

  /// 0..3 (3 trash + boss).
  final int battleIndex;
  final ExpeditionPhase phase;
  final List<String> relicIds;
  final bool retryUsed;
  final List<String> pendingRelicOffers;

  static const battleCount = 4;

  bool get isBossFight => battleIndex >= battleCount - 1;
  bool get isComplete => phase == ExpeditionPhase.settled;
  bool get isFailed => phase == ExpeditionPhase.failed;
  bool get isInProgress => !isComplete && !isFailed;

  ExpeditionEncounter get encounter {
    final encounters = ExpeditionBalance.encounters;
    final idx = battleIndex.clamp(0, encounters.length - 1);
    return encounters[idx];
  }

  ExpeditionRunState copyWith({
    int? battleIndex,
    ExpeditionPhase? phase,
    List<String>? relicIds,
    bool? retryUsed,
    List<String>? pendingRelicOffers,
  }) {
    return ExpeditionRunState(
      runId: runId,
      seed: seed,
      heroId: heroId,
      battleIndex: battleIndex ?? this.battleIndex,
      phase: phase ?? this.phase,
      relicIds: relicIds ?? this.relicIds,
      retryUsed: retryUsed ?? this.retryUsed,
      pendingRelicOffers: pendingRelicOffers ?? this.pendingRelicOffers,
    );
  }

  Map<String, dynamic> toJson() => {
        'runId': runId,
        'seed': seed,
        'heroId': heroId,
        'battleIndex': battleIndex,
        'phase': phase.name,
        'relicIds': relicIds,
        'retryUsed': retryUsed,
        'pendingRelicOffers': pendingRelicOffers,
      };

  factory ExpeditionRunState.fromJson(Map<String, dynamic> json) {
    final phaseName = json['phase'] as String? ?? 'hub';
    final phase = ExpeditionPhase.values.firstWhere(
      (p) => p.name == phaseName,
      orElse: () => ExpeditionPhase.hub,
    );
    return ExpeditionRunState(
      runId: json['runId'] as String? ?? 'run',
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      heroId: json['heroId'] as String? ?? 'mage',
      battleIndex: (json['battleIndex'] as num?)?.toInt() ?? 0,
      phase: phase,
      relicIds: [
        for (final e in (json['relicIds'] as List<dynamic>? ?? const []))
          e.toString(),
      ],
      retryUsed: json['retryUsed'] as bool? ?? false,
      pendingRelicOffers: [
        for (final e
            in (json['pendingRelicOffers'] as List<dynamic>? ?? const []))
          e.toString(),
      ],
    );
  }

  static ExpeditionRunState start({
    required String heroId,
    required int seed,
  }) {
    return ExpeditionRunState(
      runId: 'exp_$seed',
      seed: seed,
      heroId: heroId,
      battleIndex: 0,
      phase: ExpeditionPhase.hub,
    );
  }
}

class ExpeditionEncounter {
  const ExpeditionEncounter({
    required this.enemyId,
    required this.label,
    this.isBoss = false,
  });

  final String enemyId;
  final String label;
  final bool isBoss;
}

abstract final class ExpeditionBalance {
  static const minCampaignClears = 10;
  static const battleNodeId = 'expedition';
  static const clearCoinReward = 120;
  static const failCoinReward = 20;

  static const encounters = <ExpeditionEncounter>[
    ExpeditionEncounter(enemyId: 'mire_spawn', label: 'Mire Path'),
    ExpeditionEncounter(enemyId: 'leech_wisp', label: 'Leech Hollow'),
    ExpeditionEncounter(enemyId: 'hexer', label: 'Hex Crossing'),
    ExpeditionEncounter(
      enemyId: 'pack_alpha',
      label: 'Expedition Boss',
      isBoss: true,
    ),
  ];

  static EnemyDef enemyFor(ExpeditionEncounter encounter) {
    final base = EnemyCatalog.byId(encounter.enemyId);
    if (!encounter.isBoss) return base;
    return base.scaled(hpMult: 1.35, damageMult: 1.2);
  }
}

/// Pure relic hooks for battle resolution.
abstract final class RelicRuntime {
  static bool has(List<String> relicIds, RelicEffectType type) {
    for (final id in relicIds) {
      final def = RelicCatalog.byId(id);
      if (def?.effect == type) return true;
    }
    return false;
  }

  static int bonusApFromMatch({
    required List<String> relicIds,
    required Map<String, int> resourceGains,
    required bool firstBlueThisTurn,
  }) {
    var ap = 0;
    if (has(relicIds, RelicEffectType.firstBlueMatchAp) &&
        firstBlueThisTurn &&
        (resourceGains['mana'] ?? 0) > 0) {
      ap += 1;
    }
    if (has(relicIds, RelicEffectType.greenMatchAp) &&
        (resourceGains['healing'] ?? 0) > 0) {
      ap += 1;
    }
    return ap;
  }

  static int bonusManaFromOverlays({
    required List<String> relicIds,
    required int overlaysBroken,
  }) {
    if (!has(relicIds, RelicEffectType.overlayBreakMana)) return 0;
    return overlaysBroken * 2;
  }

  static bool grantsNextTurnMove({
    required List<String> relicIds,
    required int tilesInMatch,
  }) {
    return has(relicIds, RelicEffectType.matchFiveBonusMove) &&
        tilesInMatch >= 5;
  }

  static double skillDamageMult({
    required List<String> relicIds,
    required int heroHp,
    required int heroMaxHp,
  }) {
    if (!has(relicIds, RelicEffectType.lowHpSkillPower)) return 1;
    if (heroMaxHp <= 0) return 1;
    final pct = heroHp / heroMaxHp;
    return pct < 0.5 ? 1.25 : 1;
  }
}
