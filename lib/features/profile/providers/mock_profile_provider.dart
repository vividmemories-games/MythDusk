import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../heroes/domain/hero_def.dart';
import '../../heroes/domain/hero_loadout.dart';
import '../../heroes/domain/hero_unlocks.dart';
import '../../prep/domain/prep_item.dart';
import '../../battle/domain/battle_tutorial.dart';
import '../domain/economy_balance.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in main()');
});

/// Local profile until Firebase is wired (see docs/PHASES.md).
class PlayerProfile {
  const PlayerProfile({
    this.displayName = 'Wanderer',
    this.coins = 500,
    this.gems = 50,
    this.lives = EconomyBalance.startingLives,
    this.lastLifeRegenAt,
    this.gemLifeRefillDay = '',
    this.gemLifeRefillCount = 0,
    this.upgradeLevelsByHero = const {},
    this.selectedHeroId = 'mage',
    this.equippedSkillIdsByHero = const {},
    this.completedNodeIds = const {},
    this.prepInventory = const {
      PrepItemId.vanguardTonic: 2,
      PrepItemId.aegisFlask: 1,
      PrepItemId.secondWind: 1,
    },
    this.secondWindUsedDay = '',
    this.weeklyLastCompletedDay = '',
    this.hintsEnabled = true,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.tutorialBeatsSeen = const {},
    this.firstBattleTutorialDone = false,
    this.seenUnlockCelebrationIds = const {},
  });

  final String displayName;
  final int coins;
  final int gems;
  final int lives;

  /// When the current regen interval started. Null when at max lives.
  final DateTime? lastLifeRegenAt;

  /// `yyyy-MM-dd` for gem life refill counter.
  final String gemLifeRefillDay;
  final int gemLifeRefillCount;

  /// heroId → {hp,damage,shield} tiers 0–[EconomyBalance.upgradeMaxTiers].
  final Map<String, Map<String, int>> upgradeLevelsByHero;

  final String selectedHeroId;

  /// heroId → equipped skill ids (exactly two after sanitize).
  final Map<String, List<String>> equippedSkillIdsByHero;

  final Set<String> completedNodeIds;
  final Map<PrepItemId, int> prepInventory;

  /// `yyyy-MM-dd` of last Second Wind revive (empty = never).
  final String secondWindUsedDay;

  /// `yyyy-MM-dd` of last weekly reward claim (empty = never).
  final String weeklyLastCompletedDay;

  final bool hintsEnabled;
  final bool soundEnabled;
  final bool hapticsEnabled;

  /// First-battle coachmark beats already dismissed.
  final Set<String> tutorialBeatsSeen;

  /// True after the first-battle tutorial is finished or skipped.
  final bool firstBattleTutorialDone;

  /// Hero IDs whose unlock celebration has already been shown.
  final Set<String> seenUnlockCelebrationIds;

  HeroDef get selectedHero => HeroCatalog.byId(selectedHeroId);

  int prepCount(PrepItemId id) => prepInventory[id] ?? 0;

  /// Personality upgrade tier for [stat] on [heroId] (defaults to selected).
  int upgradeLevel(String stat, [String? heroId]) {
    return upgradeLevelsFor(heroId ?? selectedHeroId)[stat] ?? 0;
  }

  /// Sanitized upgrade map for a hero (zeros if never trained).
  Map<String, int> upgradeLevelsFor(String heroId) {
    return EconomyBalance.sanitizeUpgradeLevels(
      upgradeLevelsByHero[heroId] == null
          ? null
          : Map<String, dynamic>.from(upgradeLevelsByHero[heroId]!),
    );
  }

  /// Sanitized equipped skill ids for [heroId] (defaults to first two).
  List<String> equippedSkillIdsFor(String heroId) {
    final hero = HeroCatalog.byId(heroId);
    return HeroLoadout.sanitize(
      hero: hero,
      raw: equippedSkillIdsByHero[heroId],
    );
  }

  /// Unlocked heroes whose celebration has not been shown yet.
  List<String> get pendingUnlockCelebrations =>
      HeroUnlocks.pendingUnlockCelebrations(
        completedNodeCount: completedNodeIds.length,
        seenCelebrationIds: seenUnlockCelebrationIds,
      );

  bool get secondWindAvailableToday {
    final today = _todayKey();
    return secondWindUsedDay != today && prepCount(PrepItemId.secondWind) > 0;
  }

  int get gemLifeRefillsRemainingToday {
    final today = _todayKey();
    if (gemLifeRefillDay != today) return EconomyBalance.gemLifeRefillsPerDay;
    return (EconomyBalance.gemLifeRefillsPerDay - gemLifeRefillCount)
        .clamp(0, EconomyBalance.gemLifeRefillsPerDay);
  }

  Duration? timeUntilNextLife([DateTime? now]) {
    return LifeRegenMath.timeUntilNextLife(
      lives: lives,
      lastLifeRegenAt: lastLifeRegenAt,
      now: now ?? DateTime.now(),
    );
  }

  /// Catalog hero with that hero's personality upgrades (all skills).
  HeroDef scaledHero([String? heroId]) {
    final id = heroId ?? selectedHeroId;
    final base = HeroCatalog.byId(id);
    return base.withCombatMultipliers(
      hpMult: EconomyBalance.multiplierFor(
        upgradeLevel(EconomyBalance.upgradeStatHp, id),
      ),
      damageMult: EconomyBalance.multiplierFor(
        upgradeLevel(EconomyBalance.upgradeStatDamage, id),
      ),
      shieldMult: EconomyBalance.multiplierFor(
        upgradeLevel(EconomyBalance.upgradeStatShield, id),
      ),
    );
  }

  /// Hero with coin-upgrade multipliers and equipped skill loadout (battle).
  HeroDef combatHero([String? heroId]) {
    final id = heroId ?? selectedHeroId;
    return scaledHero(id).withEquippedSkillIds(equippedSkillIdsFor(id));
  }

  PlayerProfile copyWith({
    String? displayName,
    int? coins,
    int? gems,
    int? lives,
    DateTime? lastLifeRegenAt,
    bool clearLastLifeRegenAt = false,
    String? gemLifeRefillDay,
    int? gemLifeRefillCount,
    Map<String, Map<String, int>>? upgradeLevelsByHero,
    String? selectedHeroId,
    Map<String, List<String>>? equippedSkillIdsByHero,
    Set<String>? completedNodeIds,
    Map<PrepItemId, int>? prepInventory,
    String? secondWindUsedDay,
    String? weeklyLastCompletedDay,
    bool? hintsEnabled,
    bool? soundEnabled,
    bool? hapticsEnabled,
    Set<String>? tutorialBeatsSeen,
    bool? firstBattleTutorialDone,
    Set<String>? seenUnlockCelebrationIds,
  }) {
    return PlayerProfile(
      displayName: displayName ?? this.displayName,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      lives: lives ?? this.lives,
      lastLifeRegenAt: clearLastLifeRegenAt
          ? null
          : (lastLifeRegenAt ?? this.lastLifeRegenAt),
      gemLifeRefillDay: gemLifeRefillDay ?? this.gemLifeRefillDay,
      gemLifeRefillCount: gemLifeRefillCount ?? this.gemLifeRefillCount,
      upgradeLevelsByHero: upgradeLevelsByHero ?? this.upgradeLevelsByHero,
      selectedHeroId: selectedHeroId ?? this.selectedHeroId,
      equippedSkillIdsByHero:
          equippedSkillIdsByHero ?? this.equippedSkillIdsByHero,
      completedNodeIds: completedNodeIds ?? this.completedNodeIds,
      prepInventory: prepInventory ?? this.prepInventory,
      secondWindUsedDay: secondWindUsedDay ?? this.secondWindUsedDay,
      weeklyLastCompletedDay:
          weeklyLastCompletedDay ?? this.weeklyLastCompletedDay,
      hintsEnabled: hintsEnabled ?? this.hintsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      tutorialBeatsSeen: tutorialBeatsSeen ?? this.tutorialBeatsSeen,
      firstBattleTutorialDone:
          firstBattleTutorialDone ?? this.firstBattleTutorialDone,
      seenUnlockCelebrationIds:
          seenUnlockCelebrationIds ?? this.seenUnlockCelebrationIds,
    );
  }

  /// Bump when the persisted shape changes; readers stay tolerant of older
  /// payloads. Mirrors the planned Firestore `users` doc (see
  /// docs/04_Technical/Firestore_Schema.md).
  static const schemaVersion = 10;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'displayName': displayName,
        'coins': coins,
        'gems': gems,
        'lives': lives,
        'lastLifeRegenAt': lastLifeRegenAt?.toIso8601String(),
        'gemLifeRefillDay': gemLifeRefillDay,
        'gemLifeRefillCount': gemLifeRefillCount,
        'upgradeLevelsByHero': {
          for (final e in upgradeLevelsByHero.entries)
            e.key: Map<String, int>.from(e.value),
        },
        'selectedHeroId': selectedHeroId,
        'equippedSkillIdsByHero': {
          for (final e in equippedSkillIdsByHero.entries) e.key: e.value,
        },
        'completedNodeIds': completedNodeIds.toList(),
        'prepInventory': {
          for (final e in prepInventory.entries) e.key.storageKey: e.value,
        },
        'secondWindUsedDay': secondWindUsedDay,
        'weeklyLastCompletedDay': weeklyLastCompletedDay,
        'hintsEnabled': hintsEnabled,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'tutorialBeatsSeen': tutorialBeatsSeen.toList(),
        'firstBattleTutorialDone': firstBattleTutorialDone,
        'seenUnlockCelebrationIds': seenUnlockCelebrationIds.toList(),
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final ids = (json['completedNodeIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toSet() ??
        {};
    final rawPrep = json['prepInventory'] as Map<String, dynamic>?;
    final prep = <PrepItemId, int>{
      for (final id in PrepItemId.values) id: 0,
    };
    if (rawPrep != null) {
      for (final e in rawPrep.entries) {
        final id = PrepItemIdX.tryParse(e.key);
        if (id != null) prep[id] = (e.value as num).toInt();
      }
    } else {
      // Fresh / migrated profiles get a small starter stash.
      prep[PrepItemId.vanguardTonic] = 2;
      prep[PrepItemId.aegisFlask] = 1;
      prep[PrepItemId.secondWind] = 1;
    }

    final rawUpgradesByHero =
        json['upgradeLevelsByHero'] as Map<String, dynamic>?;
    final legacyUpgrades = json['upgradeLevels'] as Map<String, dynamic>?;
    final upgradesByHero = <String, Map<String, int>>{};

    if (rawUpgradesByHero != null) {
      for (final e in rawUpgradesByHero.entries) {
        final hero = HeroCatalog.tryById(e.key);
        if (hero == null) continue;
        final raw = e.value is Map<String, dynamic>
            ? e.value as Map<String, dynamic>
            : Map<String, dynamic>.from(e.value as Map);
        upgradesByHero[hero.id] = EconomyBalance.sanitizeUpgradeLevels(raw);
      }
    } else if (legacyUpgrades != null) {
      // M2a migration: copy account-global tiers onto every currently unlocked
      // hero. Heroes unlocked later start at 0/0/0.
      final legacy = EconomyBalance.sanitizeUpgradeLevels(legacyUpgrades);
      final clears = ids.length;
      for (final hero in HeroCatalog.all) {
        if (!HeroUnlocks.isUnlocked(hero.id, clears)) continue;
        upgradesByHero[hero.id] = Map<String, int>.from(legacy);
      }
    }

    DateTime? regenAt;
    final rawRegen = json['lastLifeRegenAt'] as String?;
    if (rawRegen != null && rawRegen.isNotEmpty) {
      regenAt = DateTime.tryParse(rawRegen);
    }

    final storedHeroId = json['selectedHeroId'] as String? ?? 'mage';
    // Persisted profiles may outlive renamed or removed content. Recover at
    // this explicit migration boundary; runtime catalog lookups stay strict.
    final selectedHeroId = HeroCatalog.tryById(storedHeroId)?.id ?? 'mage';

    final rawLoadouts = json['equippedSkillIdsByHero'] as Map<String, dynamic>?;
    final loadouts = <String, List<String>>{};
    if (rawLoadouts != null) {
      for (final e in rawLoadouts.entries) {
        final hero = HeroCatalog.tryById(e.key);
        if (hero == null) continue;
        final rawIds =
            (e.value as List<dynamic>?)?.map((id) => id as String).toList() ??
                const <String>[];
        loadouts[hero.id] = HeroLoadout.sanitize(hero: hero, raw: rawIds);
      }
    }

    return PlayerProfile(
      displayName: json['displayName'] as String? ?? 'Wanderer',
      coins: json['coins'] as int? ?? 500,
      gems: json['gems'] as int? ?? 50,
      lives: json['lives'] as int? ?? EconomyBalance.startingLives,
      lastLifeRegenAt: regenAt,
      gemLifeRefillDay: json['gemLifeRefillDay'] as String? ?? '',
      gemLifeRefillCount: json['gemLifeRefillCount'] as int? ?? 0,
      upgradeLevelsByHero: upgradesByHero,
      selectedHeroId: selectedHeroId,
      equippedSkillIdsByHero: loadouts,
      completedNodeIds: ids,
      prepInventory: prep,
      secondWindUsedDay: json['secondWindUsedDay'] as String? ?? '',
      weeklyLastCompletedDay: json['weeklyLastCompletedDay'] as String? ?? '',
      hintsEnabled: json['hintsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      tutorialBeatsSeen: (json['tutorialBeatsSeen'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      firstBattleTutorialDone:
          json['firstBattleTutorialDone'] as bool? ?? false,
      seenUnlockCelebrationIds:
          (json['seenUnlockCelebrationIds'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toSet() ??
              {},
    );
  }

  static String _todayKey([DateTime? now]) {
    final n = now ?? DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }
}

class ProfileNotifier extends StateNotifier<PlayerProfile> {
  ProfileNotifier(this._prefs) : super(_load(_prefs)) {
    tickLifeRegen();
  }

  final SharedPreferences _prefs;

  static const _key = 'mythdusk_profile_v2';

  static PlayerProfile _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key) ?? prefs.getString('mythdusk_profile_v1');
    if (raw == null) return const PlayerProfile();
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return PlayerProfile.fromJson(decoded);
    } catch (_) {
      return const PlayerProfile();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  /// Apply offline life regen. Safe to call on resume / home build.
  void tickLifeRegen([DateTime? now]) {
    final t = now ?? DateTime.now();
    final next = LifeRegenMath.apply(
      lives: state.lives,
      lastLifeRegenAt: state.lastLifeRegenAt,
      now: t,
    );
    if (next.lives == state.lives &&
        next.lastLifeRegenAt == state.lastLifeRegenAt) {
      return;
    }
    state = state.copyWith(
      lives: next.lives,
      lastLifeRegenAt: next.lastLifeRegenAt,
      clearLastLifeRegenAt: next.lastLifeRegenAt == null,
    );
    _persist();
  }

  void selectHero(String heroId) {
    if (HeroCatalog.tryById(heroId) == null) return;
    final clears = state.completedNodeIds.length;
    if (!HeroUnlocks.isUnlocked(heroId, clears)) return;
    state = state.copyWith(selectedHeroId: heroId);
    _persist();
  }

  /// Sets a validated two-skill loadout for [heroId].
  void setEquippedSkills(String heroId, List<String> skillIds) {
    final hero = HeroCatalog.tryById(heroId);
    if (hero == null) return;
    final sanitized = HeroLoadout.sanitize(hero: hero, raw: skillIds);
    final next = Map<String, List<String>>.from(state.equippedSkillIdsByHero);
    next[heroId] = sanitized;
    state = state.copyWith(equippedSkillIdsByHero: next);
    _persist();
  }

  /// Tap-to-equip helper for Heroes UI (keeps exactly two equipped).
  void toggleEquippedSkill(String heroId, String skillId) {
    final hero = HeroCatalog.tryById(heroId);
    if (hero == null) return;
    final nextIds = HeroLoadout.toggleEquip(
      hero: hero,
      current: state.equippedSkillIdsFor(heroId),
      skillId: skillId,
    );
    setEquippedSkills(heroId, nextIds);
  }

  void setHintsEnabled(bool value) {
    state = state.copyWith(hintsEnabled: value);
    _persist();
  }

  void setSoundEnabled(bool value) {
    state = state.copyWith(soundEnabled: value);
    _persist();
  }

  void setHapticsEnabled(bool value) {
    state = state.copyWith(hapticsEnabled: value);
    _persist();
  }

  void markTutorialBeat(String beatId) {
    if (state.firstBattleTutorialDone) return;
    if (state.tutorialBeatsSeen.contains(beatId)) return;
    final next = {...state.tutorialBeatsSeen, beatId};
    final done = BattleTutorial.nextBeat(next) == null;
    state = state.copyWith(
      tutorialBeatsSeen: next,
      firstBattleTutorialDone: done,
    );
    _persist();
  }

  void skipFirstBattleTutorial() {
    state = state.copyWith(
      firstBattleTutorialDone: true,
      tutorialBeatsSeen: BattleTutorial.orderedBeats.toSet(),
    );
    _persist();
  }

  /// Marks a hero unlock celebration as shown (idempotent).
  void markUnlockCelebrationSeen(String heroId) {
    if (state.seenUnlockCelebrationIds.contains(heroId)) return;
    state = state.copyWith(
      seenUnlockCelebrationIds: {...state.seenUnlockCelebrationIds, heroId},
    );
    _persist();
  }

  /// Consume equipped prep before a battle. Returns false if inventory short.
  bool consumePrep(List<PrepItemId> equipped) {
    final inv = Map<PrepItemId, int>.from(state.prepInventory);
    for (final id in equipped) {
      final n = inv[id] ?? 0;
      if (n <= 0) return false;
      inv[id] = n - 1;
    }
    state = state.copyWith(prepInventory: inv);
    _persist();
    return true;
  }

  void markSecondWindUsed() {
    state = state.copyWith(secondWindUsedDay: PlayerProfile._todayKey());
    _persist();
  }

  /// Purchase next upgrade tier for [stat] on [heroId] (defaults to selected).
  bool purchaseUpgrade(String stat, {String? heroId}) {
    if (!EconomyBalance.upgradeStatKeys.contains(stat)) return false;
    final id = heroId ?? state.selectedHeroId;
    if (HeroCatalog.tryById(id) == null) return false;
    final current = state.upgradeLevel(stat, id);
    final cost = EconomyBalance.coinCostForNextTier(current);
    if (cost < 0 || state.coins < cost) return false;
    final heroLevels = Map<String, int>.from(state.upgradeLevelsFor(id));
    heroLevels[stat] = current + 1;
    final byHero =
        Map<String, Map<String, int>>.from(state.upgradeLevelsByHero);
    byHero[id] = heroLevels;
    state = state.copyWith(
      coins: state.coins - cost,
      upgradeLevelsByHero: byHero,
    );
    _persist();
    return true;
  }

  /// Buy a prep item with coins. Returns false if broke.
  bool purchasePrepItem(PrepItemId id) {
    final cost = PrepBalance.shopCoinCost[id];
    if (cost == null || state.coins < cost) return false;
    final inv = Map<PrepItemId, int>.from(state.prepInventory);
    inv[id] = (inv[id] ?? 0) + 1;
    state = state.copyWith(
      coins: state.coins - cost,
      prepInventory: inv,
    );
    _persist();
    return true;
  }

  /// Gem partial life refill (Balancing Bible §4).
  bool purchaseGemLifeRefill([DateTime? now]) {
    final t = now ?? DateTime.now();
    tickLifeRegen(t);
    if (state.lives >= EconomyBalance.maxLives) return false;
    if (state.gems < EconomyBalance.gemLifeRefillCost) return false;

    final today = PlayerProfile._todayKey(t);
    var count = state.gemLifeRefillCount;
    if (state.gemLifeRefillDay != today) count = 0;
    if (count >= EconomyBalance.gemLifeRefillsPerDay) return false;

    final newLives = (state.lives + EconomyBalance.gemLifeRefillAmount)
        .clamp(0, EconomyBalance.maxLives);
    state = state.copyWith(
      gems: state.gems - EconomyBalance.gemLifeRefillCost,
      lives: newLives,
      gemLifeRefillDay: today,
      gemLifeRefillCount: count + 1,
      clearLastLifeRegenAt: newLives >= EconomyBalance.maxLives,
      lastLifeRegenAt: newLives >= EconomyBalance.maxLives
          ? null
          : (state.lastLifeRegenAt ?? t),
    );
    _persist();
    return true;
  }

  Future<void> applyVictory({
    required String nodeId,
    required int coinReward,
    bool isBoss = false,
    int actIndex = 0,
    List<String> nodePrepDrops = const [],
  }) async {
    final completed = {...state.completedNodeIds, nodeId};
    var inv = Map<PrepItemId, int>.from(state.prepInventory);
    final drops = PrepDrops.forVictory(
      isBoss: isBoss,
      actIndex: actIndex,
      nodePrepDrops: nodePrepDrops,
    );
    for (final e in drops.entries) {
      inv[e.key] = (inv[e.key] ?? 0) + e.value;
    }
    state = state.copyWith(
      coins: state.coins + coinReward,
      completedNodeIds: completed,
      prepInventory: inv,
    );
    await _persist();
  }

  /// Weekly win: coins once per [dayKey]; does not touch campaign nodes.
  Future<int> applyWeeklyVictory({
    required String dayKey,
    required int coinReward,
  }) async {
    if (state.weeklyLastCompletedDay == dayKey) {
      await _persist();
      return 0;
    }
    state = state.copyWith(
      coins: state.coins + coinReward,
      weeklyLastCompletedDay: dayKey,
    );
    await _persist();
    return coinReward;
  }

  /// Campaign defeat spends one life (Balancing Bible §4).
  Future<void> applyDefeat([DateTime? now]) async {
    final t = now ?? DateTime.now();
    tickLifeRegen(t);
    final newLives = (state.lives - 1).clamp(0, EconomyBalance.maxLives);
    state = state.copyWith(
      lives: newLives,
      lastLifeRegenAt: newLives >= EconomyBalance.maxLives
          ? null
          : (state.lastLifeRegenAt ?? t),
      clearLastLifeRegenAt: newLives >= EconomyBalance.maxLives,
    );
    await _persist();
  }

  Future<void> resetProgress() async {
    state = const PlayerProfile();
    await _persist();
  }

  /// Marks the given nodes complete so every chapter / act / pin unlocks.
  /// Used for art & content QA without playing the full spine.
  Future<void> unlockAllNodes(Set<String> nodeIds) async {
    state = state.copyWith(completedNodeIds: {...nodeIds});
    await _persist();
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, PlayerProfile>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileNotifier(prefs);
});

/// Back-compat alias.
final mockProfileProvider = profileProvider;

/// Prep selected for the next boss launch (cleared after battle starts).
final pendingBossPrepProvider =
    StateProvider<List<PrepItemId>>((ref) => const []);
