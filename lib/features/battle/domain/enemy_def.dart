import 'enemy_effect.dart';

/// Enemy skill — weights/damage from Balancing Bible; optional [effects].
class EnemySkill {
  const EnemySkill({
    required this.id,
    required this.name,
    required this.damage,
    required this.weight,
    this.effects = const [],
  });

  final String id;
  final String name;
  final int damage;
  final int weight;
  final List<EnemyEffect> effects;

  /// Player-facing telegraph (intent badge / briefing).
  String get intentLabel {
    final parts = <String>[];
    if (damage > 0) parts.add('$damage dmg');
    for (final e in effects) {
      parts.add(e.describe());
    }
    if (parts.isEmpty) return name;
    return '$name — ${parts.join(' · ')}';
  }
}

class EnemyDef {
  const EnemyDef({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.skills,
    this.blurb = '',
    this.isBoss = false,
  });

  final String id;
  final String name;
  final int maxHp;
  final List<EnemySkill> skills;
  final String blurb;
  final bool isBoss;

  /// Highest-damage skill — used as intent telegraph stub.
  EnemySkill get heaviestSkill {
    var best = skills.first;
    for (final s in skills) {
      if (s.damage > best.damage) best = s;
    }
    return best;
  }

  /// Scales HP and skill damage (weekly toughness, future balance knobs).
  EnemyDef scaled({double hpMult = 1, double damageMult = 1}) {
    if (hpMult == 1 && damageMult == 1) return this;
    return EnemyDef(
      id: id,
      name: name,
      maxHp: (maxHp * hpMult).round().clamp(1, 9999),
      isBoss: isBoss,
      blurb: blurb,
      skills: [
        for (final s in skills)
          EnemySkill(
            id: s.id,
            name: s.name,
            damage: (s.damage * damageMult).round().clamp(1, 999),
            weight: s.weight,
            effects: [
              for (final e in s.effects) e.scaled(damageMultiplier: damageMult),
            ],
          ),
      ],
    );
  }
}

abstract final class EnemyCatalog {
  static const goblin = EnemyDef(
    id: 'goblin',
    name: 'Goblin Scout',
    maxHp: 50,
    blurb: 'A skittish scout with a mean nick.',
    skills: [
      EnemySkill(id: 'nick', name: 'Nick', damage: 4, weight: 45),
      EnemySkill(id: 'slash', name: 'Slash', damage: 8, weight: 40),
      EnemySkill(id: 'heavy', name: 'Heavy Swing', damage: 14, weight: 15),
    ],
  );

  static const wolf = EnemyDef(
    id: 'wolf',
    name: 'Dusk Wolf',
    maxHp: 60,
    blurb: 'Fast bites; watch your shield.',
    skills: [
      EnemySkill(id: 'snap', name: 'Snap', damage: 6, weight: 40),
      EnemySkill(id: 'maul', name: 'Maul', damage: 11, weight: 40),
      EnemySkill(id: 'pounce', name: 'Pounce', damage: 16, weight: 20),
    ],
  );

  static const shaman = EnemyDef(
    id: 'shaman',
    name: 'Bog Shaman',
    maxHp: 60,
    blurb: 'Hexes that sting harder than they look.',
    skills: [
      EnemySkill(id: 'hex', name: 'Hex', damage: 7, weight: 45),
      EnemySkill(id: 'bolt', name: 'Bog Bolt', damage: 12, weight: 35),
      EnemySkill(id: 'curse', name: 'Curse', damage: 18, weight: 20),
    ],
  );

  static const mireSpawn = EnemyDef(
    id: 'mire_spawn',
    name: 'Mire Spawn',
    maxHp: 60,
    blurb: 'A dripping reedling from the Mistfen.',
    skills: [
      EnemySkill(id: 'drip', name: 'Drip', damage: 5, weight: 40),
      EnemySkill(id: 'lash', name: 'Reed Lash', damage: 9, weight: 35),
      EnemySkill(
        id: 'smother',
        name: 'Smother',
        damage: 8,
        weight: 25,
        effects: [
          ApplyOverlayEffect(
            overlayId: 'ovl_poison',
            count: 2,
          ),
        ],
      ),
    ],
  );

  /// Mistfen trash — drains healing energy and restores own HP.
  static const leechWisp = EnemyDef(
    id: 'leech_wisp',
    name: 'Leech Wisp',
    maxHp: 55,
    blurb: 'A hungry mist that drinks green energy.',
    skills: [
      EnemySkill(id: 'sting', name: 'Sting', damage: 5, weight: 40),
      EnemySkill(id: 'sip', name: 'Sip', damage: 8, weight: 35),
      EnemySkill(
        id: 'leech',
        name: 'Leech',
        damage: 6,
        weight: 25,
        effects: [
          DrainResourceEffect(resource: BattleResource.healing, amount: 4),
          HealSelfEffect(amount: 8),
        ],
      ),
    ],
  );

  /// Mid-campaign hexer — warps board spawn weights for the rest of battle.
  static const hexer = EnemyDef(
    id: 'hexer',
    name: 'Bog Hexer',
    maxHp: 58,
    blurb: 'Twists the marsh so purple seeps in and green fades.',
    skills: [
      EnemySkill(id: 'jab', name: 'Jab', damage: 6, weight: 40),
      EnemySkill(id: 'bolt', name: 'Hex Bolt', damage: 10, weight: 30),
      EnemySkill(
        id: 'warp',
        name: 'Warp Hex',
        damage: 5,
        weight: 30,
        effects: [
          ModifySpawnWeightsEffect(
            weights: {'purple': 3.0, 'green': 0.25},
          ),
        ],
      ),
    ],
  );

  static const ridgeHawk = EnemyDef(
    id: 'ridge_hawk',
    name: 'Ridge Hawk',
    maxHp: 60,
    blurb: 'A wind-carried hawk from Howling Ridge.',
    skills: [
      EnemySkill(id: 'dive', name: 'Dive', damage: 6, weight: 45),
      EnemySkill(id: 'talons', name: 'Talons', damage: 10, weight: 40),
      EnemySkill(id: 'gust', name: 'Gust Strike', damage: 16, weight: 15),
    ],
  );

  static const brute = EnemyDef(
    id: 'brute',
    name: 'Stone Brute',
    maxHp: 65,
    blurb: 'Slow, heavy, and hard to ignore.',
    skills: [
      EnemySkill(id: 'shove', name: 'Shove', damage: 8, weight: 40),
      EnemySkill(id: 'smash', name: 'Smash', damage: 14, weight: 40),
      EnemySkill(id: 'quake', name: 'Quake', damage: 22, weight: 20),
    ],
  );

  static const cryptSkel = EnemyDef(
    id: 'crypt_skel',
    name: 'Crypt Skeleton',
    maxHp: 70,
    blurb: 'A candle-ribbed minion from Candlecrypt.',
    skills: [
      EnemySkill(id: 'rattle', name: 'Rattle', damage: 7, weight: 45),
      EnemySkill(id: 'slash', name: 'Bone Slash', damage: 12, weight: 40),
      EnemySkill(id: 'flare', name: 'Candle Flare', damage: 18, weight: 15),
    ],
  );

  static const forgeImp = EnemyDef(
    id: 'forge_imp',
    name: 'Forge Imp',
    maxHp: 70,
    blurb: 'An ember pest from the Eclipse Forge.',
    skills: [
      EnemySkill(id: 'spark', name: 'Spark', damage: 7, weight: 45),
      EnemySkill(id: 'pinch', name: 'Tongs Pinch', damage: 12, weight: 40),
      EnemySkill(id: 'cinder', name: 'Cinder Burst', damage: 19, weight: 15),
    ],
  );

  static const warchief = EnemyDef(
    id: 'warchief',
    name: 'Warchief Ruk',
    maxHp: 140,
    isBoss: true,
    blurb: 'Chapter boss — punish hesitation.',
    skills: [
      EnemySkill(id: 'bark', name: 'War Bark', damage: 10, weight: 35),
      EnemySkill(id: 'cleave', name: 'Cleave', damage: 16, weight: 40),
      EnemySkill(id: 'execute', name: 'Execute', damage: 26, weight: 25),
    ],
  );

  // --- Chapter boss stubs (HP/skills → Balancing Bible) ---

  static const mirelord = EnemyDef(
    id: 'mirelord',
    name: 'Mirelord',
    maxHp: 160,
    isBoss: true,
    blurb: 'Mistfen toad-king — sticky and patient.',
    skills: [
      EnemySkill(id: 'spit', name: 'Mire Spit', damage: 11, weight: 40),
      EnemySkill(id: 'slam', name: 'Reed Slam', damage: 17, weight: 40),
      EnemySkill(id: 'deluge', name: 'Deluge', damage: 28, weight: 20),
    ],
  );

  static const packAlpha = EnemyDef(
    id: 'pack_alpha',
    name: 'Pack Alpha',
    maxHp: 175,
    isBoss: true,
    blurb: 'Howling Ridge wind-wolf.',
    skills: [
      EnemySkill(id: 'gust', name: 'Gust Bite', damage: 12, weight: 40),
      EnemySkill(
        id: 'howl',
        name: 'Pack Howl',
        damage: 14,
        weight: 35,
        effects: [
          ModifyMovesEffect(amount: -1),
        ],
      ),
      EnemySkill(id: 'storm', name: 'Storm Pounce', damage: 30, weight: 25),
    ],
  );

  static const quarryOverseer = EnemyDef(
    id: 'quarry_overseer',
    name: 'Quarry Overseer',
    maxHp: 190,
    isBoss: true,
    blurb: 'Ashen stone golem with a heavy pick.',
    skills: [
      EnemySkill(id: 'chip', name: 'Chip', damage: 13, weight: 40),
      EnemySkill(id: 'crush', name: 'Ore Crush', damage: 19, weight: 40),
      EnemySkill(id: 'cavein', name: 'Cave-In', damage: 32, weight: 20),
    ],
  );

  static const boneSeer = EnemyDef(
    id: 'bone_seer',
    name: 'Bone Seer',
    maxHp: 180,
    isBoss: true,
    blurb: 'Candlecrypt prophet of purple flame.',
    skills: [
      EnemySkill(id: 'wick', name: 'Wick Burn', damage: 14, weight: 40),
      EnemySkill(id: 'omen', name: 'Omen', damage: 20, weight: 35),
      EnemySkill(id: 'rite', name: 'Final Rite', damage: 34, weight: 25),
    ],
  );

  static const lakeWraith = EnemyDef(
    id: 'lake_wraith',
    name: 'Lake Wraith',
    maxHp: 200,
    isBoss: true,
    blurb: 'Mirror Lake reflection that strikes twice.',
    skills: [
      EnemySkill(id: 'shard', name: 'Mirror Shard', damage: 14, weight: 40),
      EnemySkill(id: 'echo', name: 'Echo Strike', damage: 21, weight: 40),
      EnemySkill(id: 'shatter', name: 'Shatter', damage: 35, weight: 20),
    ],
  );

  static const gildedFence = EnemyDef(
    id: 'gilded_fence',
    name: 'Gilded Fence',
    maxHp: 210,
    isBoss: true,
    blurb: 'Thornmarket crook with heavy purses.',
    skills: [
      EnemySkill(id: 'tax', name: 'Coin Tax', damage: 15, weight: 40),
      EnemySkill(id: 'bribe', name: 'Bribe Blade', damage: 22, weight: 35),
      EnemySkill(id: 'seize', name: 'Seize', damage: 36, weight: 25),
    ],
  );

  static const siegeCaptain = EnemyDef(
    id: 'siege_captain',
    name: 'Siege Captain',
    maxHp: 220,
    isBoss: true,
    blurb: 'Skybridge banner-bearer.',
    skills: [
      EnemySkill(id: 'thrust', name: 'Banner Thrust', damage: 16, weight: 40),
      EnemySkill(id: 'volley', name: 'Bridge Volley', damage: 23, weight: 40),
      EnemySkill(id: 'breach', name: 'Breach', damage: 38, weight: 20),
    ],
  );

  static const emberSmith = EnemyDef(
    id: 'ember_smith',
    name: 'Ember Smith',
    maxHp: 240,
    isBoss: true,
    blurb: 'Eclipse Forge hammer-lord.',
    skills: [
      EnemySkill(id: 'spark', name: 'Spark', damage: 17, weight: 40),
      EnemySkill(id: 'temper', name: 'Temper', damage: 24, weight: 35),
      EnemySkill(id: 'slag', name: 'Slag Storm', damage: 40, weight: 25),
    ],
  );

  static const mythspireTyrant = EnemyDef(
    id: 'mythspire_tyrant',
    name: 'Mythspire Tyrant',
    maxHp: 260,
    isBoss: true,
    blurb: 'Final gatekeeper of the dusk crown.',
    skills: [
      EnemySkill(id: 'dread', name: 'Dread', damage: 18, weight: 35),
      EnemySkill(id: 'ruin', name: 'Ruin Blow', damage: 26, weight: 40),
      EnemySkill(id: 'eclipse', name: 'Eclipse', damage: 44, weight: 25),
    ],
  );

  // --- Weekly (M7) — base stats = campaign art counterparts; battle applies ×2 ---

  static const weeklyBoss01 = EnemyDef(
    id: 'weekly_boss_01',
    name: 'Dusk Warden',
    maxHp: 140,
    isBoss: true,
    blurb: 'Weekend extreme — dusk steel (Warchief counterpart).',
    skills: [
      EnemySkill(id: 'guard', name: 'Guard Cut', damage: 10, weight: 35),
      EnemySkill(id: 'sweep', name: 'Dusk Sweep', damage: 16, weight: 40),
      EnemySkill(id: 'sentence', name: 'Sentence', damage: 26, weight: 25),
    ],
  );

  static const weeklyBoss02 = EnemyDef(
    id: 'weekly_boss_02',
    name: 'Ash Herald',
    maxHp: 160,
    isBoss: true,
    blurb: 'Weekend extreme — ember proclamations (Mirelord counterpart).',
    skills: [
      EnemySkill(id: 'cinder', name: 'Cinder', damage: 11, weight: 40),
      EnemySkill(id: 'brand', name: 'Brand', damage: 17, weight: 40),
      EnemySkill(id: 'pyre', name: 'Pyre', damage: 28, weight: 20),
    ],
  );

  static const weeklyBoss03 = EnemyDef(
    id: 'weekly_boss_03',
    name: 'Tide Marauder',
    maxHp: 175,
    isBoss: true,
    blurb: 'Weekend extreme — crashing tide (Pack Alpha counterpart).',
    skills: [
      EnemySkill(id: 'spray', name: 'Spray', damage: 12, weight: 40),
      EnemySkill(id: 'riptide', name: 'Riptide', damage: 18, weight: 35),
      EnemySkill(id: 'drown', name: 'Drown', damage: 30, weight: 25),
    ],
  );

  static const weeklyBoss04 = EnemyDef(
    id: 'weekly_boss_04',
    name: 'Gilded Scourge',
    maxHp: 210,
    isBoss: true,
    blurb: 'Weekend extreme — coin and claw (Gilded Fence counterpart).',
    skills: [
      EnemySkill(id: 'toll', name: 'Toll', damage: 15, weight: 40),
      EnemySkill(id: 'gild', name: 'Gild Blade', damage: 22, weight: 35),
      EnemySkill(id: 'levy', name: 'Levy', damage: 36, weight: 25),
    ],
  );

  static const weeklyBoss05 = EnemyDef(
    id: 'weekly_boss_05',
    name: 'Eclipse Judge',
    maxHp: 260,
    isBoss: true,
    blurb: 'Weekend extreme — verdict of night (Mythspire counterpart).',
    skills: [
      EnemySkill(id: 'gavel', name: 'Gavel', damage: 18, weight: 35),
      EnemySkill(id: 'verdict', name: 'Verdict', damage: 26, weight: 40),
      EnemySkill(id: 'blacksun', name: 'Black Sun', damage: 44, weight: 25),
    ],
  );

  static const weeklyScout = EnemyDef(
    id: 'weekly_scout',
    name: 'Weekly Scout',
    maxHp: 50,
    blurb: 'Weekday objective sparring partner (Goblin counterpart).',
    skills: [
      EnemySkill(id: 'nick', name: 'Nick', damage: 4, weight: 45),
      EnemySkill(id: 'slash', name: 'Slash', damage: 8, weight: 40),
      EnemySkill(id: 'heavy', name: 'Heavy', damage: 14, weight: 15),
    ],
  );

  static const all = [
    goblin,
    wolf,
    shaman,
    mireSpawn,
    leechWisp,
    hexer,
    ridgeHawk,
    brute,
    cryptSkel,
    forgeImp,
    warchief,
    mirelord,
    packAlpha,
    quarryOverseer,
    boneSeer,
    lakeWraith,
    gildedFence,
    siegeCaptain,
    emberSmith,
    mythspireTyrant,
    weeklyScout,
    weeklyBoss01,
    weeklyBoss02,
    weeklyBoss03,
    weeklyBoss04,
    weeklyBoss05,
  ];

  static EnemyDef byId(String id) {
    final enemy = tryById(id);
    if (enemy == null) throw StateError('Unknown enemy id: $id');
    return enemy;
  }

  static EnemyDef? tryById(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }
}
