import '../../heroes/domain/hero_def.dart';

/// Mastery track condition kinds.
enum MasteryConditionType {
  winsWithHero,
  skillsCastWithHero,
  expeditionClearsWithHero,
}

/// Reward granted when a mastery tier is claimed.
enum MasteryRewardType {
  unlockSkill,
  cosmeticTitle,
  cosmeticFrame,
}

class MasteryDefinition {
  const MasteryDefinition({
    required this.id,
    required this.heroId,
    required this.tier,
    required this.title,
    required this.condition,
    required this.target,
    required this.rewardType,
    this.rewardSkillId,
    this.rewardCosmeticId,
  });

  final String id;
  final String heroId;
  final int tier;
  final String title;
  final MasteryConditionType condition;
  final int target;
  final MasteryRewardType rewardType;
  final String? rewardSkillId;
  final String? rewardCosmeticId;
}

/// Per-hero counters for mastery conditions.
class HeroMasteryCounters {
  const HeroMasteryCounters({
    this.wins = 0,
    this.skillsCast = 0,
    this.expeditionClears = 0,
  });

  final int wins;
  final int skillsCast;
  final int expeditionClears;

  int valueFor(MasteryConditionType type) => switch (type) {
        MasteryConditionType.winsWithHero => wins,
        MasteryConditionType.skillsCastWithHero => skillsCast,
        MasteryConditionType.expeditionClearsWithHero => expeditionClears,
      };

  HeroMasteryCounters copyWith({
    int? wins,
    int? skillsCast,
    int? expeditionClears,
  }) {
    return HeroMasteryCounters(
      wins: wins ?? this.wins,
      skillsCast: skillsCast ?? this.skillsCast,
      expeditionClears: expeditionClears ?? this.expeditionClears,
    );
  }

  Map<String, dynamic> toJson() => {
        'wins': wins,
        'skillsCast': skillsCast,
        'expeditionClears': expeditionClears,
      };

  factory HeroMasteryCounters.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HeroMasteryCounters();
    return HeroMasteryCounters(
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      skillsCast: (json['skillsCast'] as num?)?.toInt() ?? 0,
      expeditionClears: (json['expeditionClears'] as num?)?.toInt() ?? 0,
    );
  }
}

abstract final class MasteryCatalog {
  static List<MasteryDefinition> forHero(String heroId) =>
      all.where((m) => m.heroId == heroId).toList(growable: false);

  static MasteryDefinition? byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Skill 4 ids (mastery-gated) for each hero.
  static const skill4ByHero = <String, String>{
    'mage': 'meteor_shard',
    'knight': 'bulwark_slam',
    'ranger': 'volley_rain',
    'priest': 'sanctuary',
    'ninja': 'shadow_bind',
  };

  static final all = <MasteryDefinition>[
    for (final hero in HeroCatalog.all) ...[
      MasteryDefinition(
        id: 'mastery_${hero.id}_t1',
        heroId: hero.id,
        tier: 1,
        title: 'Proven ${hero.name}',
        condition: MasteryConditionType.winsWithHero,
        target: 3,
        rewardType: MasteryRewardType.cosmeticTitle,
        rewardCosmeticId: 'title_${hero.id}_proven',
      ),
      MasteryDefinition(
        id: 'mastery_${hero.id}_t2',
        heroId: hero.id,
        tier: 2,
        title: '${hero.name} Technique',
        condition: MasteryConditionType.skillsCastWithHero,
        target: 12,
        rewardType: MasteryRewardType.unlockSkill,
        rewardSkillId: skill4ByHero[hero.id],
      ),
      MasteryDefinition(
        id: 'mastery_${hero.id}_t3',
        heroId: hero.id,
        tier: 3,
        title: '${hero.name} Expeditioner',
        condition: MasteryConditionType.expeditionClearsWithHero,
        target: 1,
        rewardType: MasteryRewardType.cosmeticFrame,
        rewardCosmeticId: 'frame_${hero.id}_expedition',
      ),
    ],
  ];
}
