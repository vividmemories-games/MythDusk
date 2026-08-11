/// Stub hero definition for Phase 1 (single hero in battle).
class HeroDef {
  const HeroDef({
    required this.id,
    required this.name,
    required this.movesPerTurn,
    required this.maxAp,
    required this.maxHp,
    required this.primaryResources,
    required this.skills,
  });

  final String id;
  final String name;
  final int movesPerTurn;
  final int maxAp;
  final int maxHp;
  final List<String> primaryResources;

  /// Full kit in catalog; battle instances may be filtered to the equipped pair.
  final List<SkillDef> skills;

  /// Applies coin-upgrade multipliers (Balancing Bible §5.3).
  HeroDef withCombatMultipliers({
    double hpMult = 1,
    double damageMult = 1,
    double shieldMult = 1,
  }) {
    if (hpMult == 1 && damageMult == 1 && shieldMult == 1) return this;
    return HeroDef(
      id: id,
      name: name,
      movesPerTurn: movesPerTurn,
      maxAp: maxAp,
      maxHp: (maxHp * hpMult).round().clamp(1, 9999),
      primaryResources: primaryResources,
      skills: [
        for (final s in skills)
          SkillDef(
            id: s.id,
            name: s.name,
            apCost: s.apCost,
            resourceCosts: s.resourceCosts,
            damage: (s.damage * damageMult).round(),
            heal: s.heal,
            shield: (s.shield * shieldMult).round(),
          ),
      ],
    );
  }

  /// Replaces the skill list (catalog filtering / loadouts).
  HeroDef withSkills(List<SkillDef> next) {
    return HeroDef(
      id: id,
      name: name,
      movesPerTurn: movesPerTurn,
      maxAp: maxAp,
      maxHp: maxHp,
      primaryResources: primaryResources,
      skills: next,
    );
  }

  /// Keeps only [skillIds] (order preserved). Unknown ids are skipped.
  HeroDef withEquippedSkillIds(List<String> skillIds) {
    final byId = {for (final s in skills) s.id: s};
    final equipped = <SkillDef>[
      for (final id in skillIds)
        if (byId[id] case final skill?) skill,
    ];
    if (equipped.isEmpty) return this;
    return withSkills(equipped);
  }

  bool hasSkill(String skillId) => skills.any((s) => s.id == skillId);
}

class SkillDef {
  const SkillDef({
    required this.id,
    required this.name,
    required this.apCost,
    required this.resourceCosts,
    required this.damage,
    this.heal = 0,
    this.shield = 0,
  });

  final String id;
  final String name;
  final int apCost;

  /// resourceId → amount (attack, mana, healing, shield, ultimate)
  final Map<String, int> resourceCosts;
  final int damage;
  final int heal;
  final int shield;
}

/// Placeholder roster — numbers from docs/GAMEPLAY.md.
///
/// Each hero has four catalog skills; battles equip exactly two ([HeroLoadout]).
/// Skill 4 is mastery-gated (see MasteryCatalog).
///
/// Skills 1–3 cost **two** gem resources (split from older mono costs) so every
/// match color can matter. Skill 4 costs three resources + higher AP.
abstract final class HeroCatalog {
  static const mage = HeroDef(
    id: 'mage',
    name: 'Mage',
    movesPerTurn: 5,
    maxAp: 8,
    maxHp: 80,
    primaryResources: ['mana', 'ultimate'],
    skills: [
      SkillDef(
        id: 'fireball',
        name: 'Fireball',
        apCost: 2,
        resourceCosts: {'mana': 4, 'healing': 4},
        damage: 24,
      ),
      SkillDef(
        id: 'arcane_bolt',
        name: 'Arcane Bolt',
        apCost: 1,
        resourceCosts: {'ultimate': 2, 'healing': 2},
        damage: 12,
      ),
      SkillDef(
        id: 'frost_ward',
        name: 'Frost Ward',
        apCost: 2,
        resourceCosts: {'attack': 3, 'shield': 3},
        damage: 0,
        shield: 18,
      ),
      SkillDef(
        id: 'meteor_shard',
        name: 'Meteor Shard',
        apCost: 4,
        resourceCosts: {'mana': 4, 'shield': 3, 'healing': 3},
        damage: 36,
      ),
    ],
  );

  static const knight = HeroDef(
    id: 'knight',
    name: 'Knight',
    movesPerTurn: 4,
    maxAp: 6,
    maxHp: 120,
    primaryResources: ['attack', 'shield'],
    skills: [
      SkillDef(
        id: 'basic_slash',
        name: 'Basic Slash',
        apCost: 1,
        resourceCosts: {'attack': 2, 'shield': 2},
        damage: 14,
      ),
      SkillDef(
        id: 'shield_wall',
        name: 'Shield Wall',
        apCost: 2,
        resourceCosts: {'shield': 4, 'attack': 4},
        damage: 0,
        shield: 20,
      ),
      SkillDef(
        id: 'rallying_cry',
        name: 'Rallying Cry',
        apCost: 1,
        resourceCosts: {'shield': 3, 'healing': 2},
        damage: 0,
        heal: 12,
      ),
      SkillDef(
        id: 'bulwark_slam',
        name: 'Bulwark Slam',
        apCost: 4,
        resourceCosts: {'attack': 4, 'shield': 3, 'healing': 3},
        damage: 22,
        shield: 12,
      ),
    ],
  );

  static const ranger = HeroDef(
    id: 'ranger',
    name: 'Ranger',
    movesPerTurn: 5,
    maxAp: 7,
    maxHp: 90,
    primaryResources: ['attack', 'healing'],
    skills: [
      SkillDef(
        id: 'arrow_shot',
        name: 'Arrow Shot',
        apCost: 1,
        resourceCosts: {'attack': 3, 'healing': 2},
        damage: 16,
      ),
      SkillDef(
        id: 'marked_shot',
        name: 'Marked Shot',
        apCost: 2,
        resourceCosts: {'attack': 4, 'ultimate': 4},
        damage: 26,
      ),
      SkillDef(
        id: 'natures_salve',
        name: "Nature's Salve",
        apCost: 1,
        resourceCosts: {'healing': 3, 'mana': 3},
        damage: 0,
        heal: 14,
      ),
      SkillDef(
        id: 'volley_rain',
        name: 'Volley Rain',
        apCost: 4,
        resourceCosts: {'attack': 4, 'healing': 3, 'shield': 3},
        damage: 34,
      ),
    ],
  );

  static const priest = HeroDef(
    id: 'priest',
    name: 'Priest',
    movesPerTurn: 4,
    maxAp: 8,
    maxHp: 95,
    primaryResources: ['healing', 'mana'],
    skills: [
      SkillDef(
        id: 'smite',
        name: 'Smite',
        apCost: 1,
        resourceCosts: {'mana': 2, 'attack': 2},
        damage: 12,
      ),
      SkillDef(
        id: 'mend',
        name: 'Mend',
        apCost: 2,
        resourceCosts: {'healing': 4, 'shield': 4},
        damage: 0,
        heal: 22,
      ),
      SkillDef(
        id: 'holy_barrier',
        name: 'Holy Barrier',
        apCost: 2,
        resourceCosts: {'mana': 3, 'shield': 3},
        damage: 0,
        shield: 18,
      ),
      SkillDef(
        id: 'sanctuary',
        name: 'Sanctuary',
        apCost: 4,
        resourceCosts: {'healing': 4, 'mana': 3, 'shield': 3},
        damage: 0,
        heal: 28,
        shield: 14,
      ),
    ],
  );

  static const ninja = HeroDef(
    id: 'ninja',
    name: 'Ninja',
    movesPerTurn: 6,
    maxAp: 7,
    maxHp: 85,
    primaryResources: ['attack', 'ultimate'],
    skills: [
      SkillDef(
        id: 'dagger_flurry',
        name: 'Dagger Flurry',
        apCost: 1,
        resourceCosts: {'attack': 2, 'ultimate': 2},
        damage: 14,
      ),
      SkillDef(
        id: 'shadow_strike',
        name: 'Shadow Strike',
        apCost: 2,
        resourceCosts: {'ultimate': 3, 'mana': 3},
        damage: 28,
      ),
      SkillDef(
        id: 'smoke_bomb',
        name: 'Smoke Bomb',
        apCost: 1,
        resourceCosts: {'ultimate': 2, 'shield': 2},
        damage: 0,
        shield: 14,
      ),
      SkillDef(
        id: 'shadow_bind',
        name: 'Shadow Bind',
        apCost: 4,
        resourceCosts: {'attack': 3, 'ultimate': 4, 'mana': 3},
        damage: 32,
      ),
    ],
  );

  static const all = [mage, knight, ranger, priest, ninja];

  static HeroDef byId(String id) {
    final hero = tryById(id);
    if (hero == null) throw StateError('Unknown hero id: $id');
    return hero;
  }

  static HeroDef? tryById(String id) {
    for (final h in all) {
      if (h.id == id) return h;
    }
    return null;
  }
}
