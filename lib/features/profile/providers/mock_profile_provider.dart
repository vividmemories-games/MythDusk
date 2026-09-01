import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../battle/domain/battle_objective.dart';
import '../../battle/domain/battle_tutorial.dart';
import '../../campaign/data/chapter_medal_catalog.dart';
import '../../campaign/domain/chapter_medal.dart';
import '../../daily/domain/daily_schedule.dart';
import '../../expedition/domain/expedition_models.dart';
import '../../heroes/domain/hero_def.dart';
import '../../heroes/domain/hero_loadout.dart';
import '../../heroes/domain/hero_unlocks.dart';
import '../../mastery/domain/mastery_catalog.dart';
import '../../prep/domain/prep_item.dart';
import '../../cosmetics/domain/cosmetic_catalog.dart';
import '../../shop/domain/iap_catalog.dart';
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
    this.dailyLastCompletedDay = '',
    this.claimedDailyMedalIds = const {},
    this.hintsEnabled = true,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.tutorialBeatsSeen = const {},
    this.firstBattleTutorialDone = false,
    this.seenUnlockCelebrationIds = const {},
    this.chapterMedalCounters = const {},
    this.claimedChapterMedalIds = const {},
    this.activeExpedition,
    this.masteryProgressByHero = const {},
    this.claimedMasteryIds = const {},
    this.unlockedMasterySkillIds = const {},
    this.claimedCosmeticIds = const {},
    this.equippedOverlayByHero = const {},
    this.equippedTitleId,
    this.equippedFrameId,
    this.claimedStarterPackIds = const {},
    this.activeEncounterId,
    this.activeEncounterNodeId,
    this.encounterAdContinuesUsed = 0,
    this.encounterPaidContinuesUsed = 0,
    this.pendingContinueRevive = false,
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

  /// `yyyy-MM-dd` of last Daily Contract completion (empty = never).
  final String dailyLastCompletedDay;

  /// Claimed Daily medal ids (include dayKey prefix; idempotent).
  final Set<String> claimedDailyMedalIds;

  final bool hintsEnabled;
  final bool soundEnabled;
  final bool hapticsEnabled;

  /// First-battle coachmark beats already dismissed.
  final Set<String> tutorialBeatsSeen;

  /// True after the first-battle tutorial is finished or skipped.
  final bool firstBattleTutorialDone;

  /// Hero IDs whose unlock celebration has already been shown.
  final Set<String> seenUnlockCelebrationIds;

  /// chapterId → cumulative medal counters.
  final Map<String, ChapterMedalCounters> chapterMedalCounters;

  /// Claimed chapter medal definition ids.
  final Set<String> claimedChapterMedalIds;

  /// Active Relic Expedition run (null when idle).
  final ExpeditionRunState? activeExpedition;

  /// heroId → mastery counters.
  final Map<String, HeroMasteryCounters> masteryProgressByHero;

  /// Claimed mastery definition ids.
  final Set<String> claimedMasteryIds;

  /// Skill ids unlocked via mastery (skill 4).
  final Set<String> unlockedMasterySkillIds;

  /// Cosmetic stub ids (titles / frames / overlays).
  final Set<String> claimedCosmeticIds;

  /// heroId → equipped overlay cosmetic id.
  final Map<String, String> equippedOverlayByHero;

  final String? equippedTitleId;
  final String? equippedFrameId;

  /// One-time pack entitlements (starter pack, later IAP).
  final Set<String> claimedStarterPackIds;

  /// Current battle-attempt token for defeat-continue caps.
  final String? activeEncounterId;
  final String? activeEncounterNodeId;
  final int encounterAdContinuesUsed;
  final int encounterPaidContinuesUsed;
  final bool pendingContinueRevive;

  HeroDef get selectedHero => HeroCatalog.byId(selectedHeroId);

  String? equippedOverlayIdFor(String heroId) => equippedOverlayByHero[heroId];

  bool hasClaimedStarterPack([String id = StarterPackBalance.id]) =>
      claimedStarterPackIds.contains(id);

  ChapterMedalCounters medalCountersFor(String chapterId) =>
      chapterMedalCounters[chapterId] ?? const ChapterMedalCounters();

  bool isChapterMedalClaimed(String medalId) =>
      claimedChapterMedalIds.contains(medalId);

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
      unlockedExtraSkillIds: unlockedMasterySkillIds,
    );
  }

  /// Catalog skills the player may equip for [heroId].
  List<SkillDef> availableSkillsFor(String heroId) {
    return HeroLoadout.availableSkills(
      HeroCatalog.byId(heroId),
      unlockedMasterySkillIds,
    );
  }

  HeroMasteryCounters masteryFor(String heroId) =>
      masteryProgressByHero[heroId] ?? const HeroMasteryCounters();

  bool isMasteryClaimed(String masteryId) =>
      claimedMasteryIds.contains(masteryId);

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

  /// Catalog hero with that hero's personality upgrades (available skills).
  HeroDef scaledHero([String? heroId]) {
    final id = heroId ?? selectedHeroId;
    final base = HeroCatalog.byId(id);
    final available = availableSkillsFor(id);
    return base.withSkills(available).withCombatMultipliers(
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
    String? dailyLastCompletedDay,
    Set<String>? claimedDailyMedalIds,
    bool? hintsEnabled,
    bool? soundEnabled,
    bool? hapticsEnabled,
    Set<String>? tutorialBeatsSeen,
    bool? firstBattleTutorialDone,
    Set<String>? seenUnlockCelebrationIds,
    Map<String, ChapterMedalCounters>? chapterMedalCounters,
    Set<String>? claimedChapterMedalIds,
    ExpeditionRunState? activeExpedition,
    bool clearActiveExpedition = false,
    Map<String, HeroMasteryCounters>? masteryProgressByHero,
    Set<String>? claimedMasteryIds,
    Set<String>? unlockedMasterySkillIds,
    Set<String>? claimedCosmeticIds,
    Map<String, String>? equippedOverlayByHero,
    String? equippedTitleId,
    bool clearEquippedTitle = false,
    String? equippedFrameId,
    bool clearEquippedFrame = false,
    Set<String>? claimedStarterPackIds,
    String? activeEncounterId,
    bool clearActiveEncounter = false,
    String? activeEncounterNodeId,
    int? encounterAdContinuesUsed,
    int? encounterPaidContinuesUsed,
    bool? pendingContinueRevive,
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
      dailyLastCompletedDay:
          dailyLastCompletedDay ?? this.dailyLastCompletedDay,
      claimedDailyMedalIds: claimedDailyMedalIds ?? this.claimedDailyMedalIds,
      hintsEnabled: hintsEnabled ?? this.hintsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      tutorialBeatsSeen: tutorialBeatsSeen ?? this.tutorialBeatsSeen,
      firstBattleTutorialDone:
          firstBattleTutorialDone ?? this.firstBattleTutorialDone,
      seenUnlockCelebrationIds:
          seenUnlockCelebrationIds ?? this.seenUnlockCelebrationIds,
      chapterMedalCounters: chapterMedalCounters ?? this.chapterMedalCounters,
      claimedChapterMedalIds:
          claimedChapterMedalIds ?? this.claimedChapterMedalIds,
      activeExpedition: clearActiveExpedition
          ? null
          : (activeExpedition ?? this.activeExpedition),
      masteryProgressByHero:
          masteryProgressByHero ?? this.masteryProgressByHero,
      claimedMasteryIds: claimedMasteryIds ?? this.claimedMasteryIds,
      unlockedMasterySkillIds:
          unlockedMasterySkillIds ?? this.unlockedMasterySkillIds,
      claimedCosmeticIds: claimedCosmeticIds ?? this.claimedCosmeticIds,
      equippedOverlayByHero:
          equippedOverlayByHero ?? this.equippedOverlayByHero,
      equippedTitleId:
          clearEquippedTitle ? null : (equippedTitleId ?? this.equippedTitleId),
      equippedFrameId:
          clearEquippedFrame ? null : (equippedFrameId ?? this.equippedFrameId),
      claimedStarterPackIds:
          claimedStarterPackIds ?? this.claimedStarterPackIds,
      activeEncounterId: clearActiveEncounter
          ? null
          : (activeEncounterId ?? this.activeEncounterId),
      activeEncounterNodeId: clearActiveEncounter
          ? null
          : (activeEncounterNodeId ?? this.activeEncounterNodeId),
      encounterAdContinuesUsed: clearActiveEncounter
          ? 0
          : (encounterAdContinuesUsed ?? this.encounterAdContinuesUsed),
      encounterPaidContinuesUsed: clearActiveEncounter
          ? 0
          : (encounterPaidContinuesUsed ?? this.encounterPaidContinuesUsed),
      pendingContinueRevive: clearActiveEncounter
          ? false
          : (pendingContinueRevive ?? this.pendingContinueRevive),
    );
  }

  /// Bump when the persisted shape changes; readers stay tolerant of older
  /// payloads. Mirrors the planned Firestore `users` doc (see
  /// docs/04_Technical/Firestore_Schema.md).
  static const schemaVersion = 14;

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
        'dailyLastCompletedDay': dailyLastCompletedDay,
        'claimedDailyMedalIds': claimedDailyMedalIds.toList(),
        'hintsEnabled': hintsEnabled,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'tutorialBeatsSeen': tutorialBeatsSeen.toList(),
        'firstBattleTutorialDone': firstBattleTutorialDone,
        'seenUnlockCelebrationIds': seenUnlockCelebrationIds.toList(),
        'chapterMedalCounters': {
          for (final e in chapterMedalCounters.entries) e.key: e.value.toJson(),
        },
        'claimedChapterMedalIds': claimedChapterMedalIds.toList(),
        'activeExpedition': activeExpedition?.toJson(),
        'masteryProgressByHero': {
          for (final e in masteryProgressByHero.entries)
            e.key: e.value.toJson(),
        },
        'claimedMasteryIds': claimedMasteryIds.toList(),
        'unlockedMasterySkillIds': unlockedMasterySkillIds.toList(),
        'claimedCosmeticIds': claimedCosmeticIds.toList(),
        'equippedOverlayByHero': equippedOverlayByHero,
        'equippedTitleId': equippedTitleId,
        'equippedFrameId': equippedFrameId,
        'claimedStarterPackIds': claimedStarterPackIds.toList(),
        'activeEncounterId': activeEncounterId,
        'activeEncounterNodeId': activeEncounterNodeId,
        'encounterAdContinuesUsed': encounterAdContinuesUsed,
        'encounterPaidContinuesUsed': encounterPaidContinuesUsed,
        'pendingContinueRevive': pendingContinueRevive,
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

    final unlockedMasterySkillIds =
        (json['unlockedMasterySkillIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toSet() ??
            {};

    final rawLoadouts = json['equippedSkillIdsByHero'] as Map<String, dynamic>?;
    final loadouts = <String, List<String>>{};
    if (rawLoadouts != null) {
      for (final e in rawLoadouts.entries) {
        final hero = HeroCatalog.tryById(e.key);
        if (hero == null) continue;
        final rawIds =
            (e.value as List<dynamic>?)?.map((id) => id as String).toList() ??
                const <String>[];
        loadouts[hero.id] = HeroLoadout.sanitize(
          hero: hero,
          raw: rawIds,
          unlockedExtraSkillIds: unlockedMasterySkillIds,
        );
      }
    }

    ExpeditionRunState? expedition;
    final rawExp = json['activeExpedition'];
    if (rawExp is Map<String, dynamic>) {
      expedition = ExpeditionRunState.fromJson(rawExp);
    } else if (rawExp is Map) {
      expedition =
          ExpeditionRunState.fromJson(Map<String, dynamic>.from(rawExp));
    }

    final masteryProgress = <String, HeroMasteryCounters>{};
    final rawMastery = json['masteryProgressByHero'] as Map<String, dynamic>?;
    if (rawMastery != null) {
      for (final e in rawMastery.entries) {
        if (HeroCatalog.tryById(e.key) == null) continue;
        masteryProgress[e.key] = HeroMasteryCounters.fromJson(
          e.value is Map<String, dynamic>
              ? e.value as Map<String, dynamic>
              : Map<String, dynamic>.from(e.value as Map),
        );
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
      dailyLastCompletedDay: json['dailyLastCompletedDay'] as String? ?? '',
      claimedDailyMedalIds: (json['claimedDailyMedalIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
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
      chapterMedalCounters: _parseChapterMedalCounters(
        json['chapterMedalCounters'] as Map<String, dynamic>?,
      ),
      claimedChapterMedalIds: (json['claimedChapterMedalIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      activeExpedition: expedition,
      masteryProgressByHero: masteryProgress,
      claimedMasteryIds: (json['claimedMasteryIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      unlockedMasterySkillIds: unlockedMasterySkillIds,
      claimedCosmeticIds: (json['claimedCosmeticIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      equippedOverlayByHero: _parseStringMap(json['equippedOverlayByHero']),
      equippedTitleId: json['equippedTitleId'] as String?,
      equippedFrameId: json['equippedFrameId'] as String?,
      claimedStarterPackIds: (json['claimedStarterPackIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      activeEncounterId: json['activeEncounterId'] as String?,
      activeEncounterNodeId: json['activeEncounterNodeId'] as String?,
      encounterAdContinuesUsed:
          (json['encounterAdContinuesUsed'] as num?)?.toInt() ?? 0,
      encounterPaidContinuesUsed:
          (json['encounterPaidContinuesUsed'] as num?)?.toInt() ?? 0,
      pendingContinueRevive: json['pendingContinueRevive'] as bool? ?? false,
    );
  }

  static Map<String, String> _parseStringMap(dynamic raw) {
    if (raw is! Map) return {};
    return {
      for (final e in raw.entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
    };
  }

  static Map<String, ChapterMedalCounters> _parseChapterMedalCounters(
    Map<String, dynamic>? raw,
  ) {
    if (raw == null) return {};
    return {
      for (final e in raw.entries)
        e.key: ChapterMedalCounters.fromJson(
          e.value is Map<String, dynamic>
              ? e.value as Map<String, dynamic>
              : Map<String, dynamic>.from(e.value as Map),
        ),
    };
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
    final sanitized = HeroLoadout.sanitize(
      hero: hero,
      raw: skillIds,
      unlockedExtraSkillIds: state.unlockedMasterySkillIds,
    );
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
      unlockedExtraSkillIds: state.unlockedMasterySkillIds,
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
    String? chapterId,
    BattleProgress? progress,
    int heroHp = 0,
    int heroMaxHp = 1,
    int? bossForm,
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

    var counters = Map<String, ChapterMedalCounters>.from(
      state.chapterMedalCounters,
    );
    if (chapterId != null && progress != null) {
      counters[chapterId] = ChapterMedalFold.applyVictory(
        current: counters[chapterId] ?? const ChapterMedalCounters(),
        progress: progress,
        heroHp: heroHp,
        heroMaxHp: heroMaxHp,
        usedPrep: progress.usedPrep,
        bossForm: bossForm,
      );
    }

    state = state.copyWith(
      coins: state.coins + coinReward,
      completedNodeIds: completed,
      prepInventory: inv,
      chapterMedalCounters: counters,
      clearActiveEncounter: true,
    );
    if (progress != null) {
      _recordMasteryProgress(
        heroId: state.selectedHeroId,
        progress: progress,
      );
    }
    await _persist();
  }

  /// Claim a met chapter medal once. Returns coins granted (0 if denied).
  int claimChapterMedal(
    String medalId, {
    required Set<String> chapterNodeIds,
  }) {
    final def = ChapterMedalCatalog.byId(medalId);
    if (def == null) return 0;
    if (state.claimedChapterMedalIds.contains(medalId)) return 0;
    final chapterComplete =
        chapterNodeIds.every(state.completedNodeIds.contains);
    final counters = state.medalCountersFor(def.chapterId);
    if (!counters.isMet(def, chapterComplete: chapterComplete)) return 0;
    state = state.copyWith(
      coins: state.coins + def.coinReward,
      claimedChapterMedalIds: {...state.claimedChapterMedalIds, medalId},
    );
    _persist();
    return def.coinReward;
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
      clearActiveEncounter: true,
    );
    await _persist();
    return coinReward;
  }

  /// Daily Contract win: base coins + newly earned medals (idempotent per day).
  Future<({int coins, List<String> medalIds})> applyDailyVictory({
    required DailyContract contract,
    required BattleProgress progress,
    required int heroHp,
    required int heroMaxHp,
  }) async {
    if (state.dailyLastCompletedDay == contract.dayKey) {
      await _persist();
      return (coins: 0, medalIds: const <String>[]);
    }

    final earned = <String>[];
    var bonus = 0;
    for (final medal in contract.medals) {
      if (state.claimedDailyMedalIds.contains(medal.id)) continue;
      if (!DailyMedalEval.isMet(
        medal,
        progress: progress,
        heroHp: heroHp,
        heroMaxHp: heroMaxHp,
      )) {
        continue;
      }
      earned.add(medal.id);
      bonus += medal.coinReward;
    }

    final total = contract.coinReward + bonus;
    state = state.copyWith(
      coins: state.coins + total,
      dailyLastCompletedDay: contract.dayKey,
      claimedDailyMedalIds: {...state.claimedDailyMedalIds, ...earned},
      clearActiveEncounter: true,
    );
    _recordMasteryProgress(
      heroId: state.selectedHeroId,
      progress: progress,
    );
    await _persist();
    return (coins: total, medalIds: earned);
  }

  bool get expeditionUnlocked =>
      state.completedNodeIds.length >= ExpeditionBalance.minCampaignClears;

  /// Starts a new expedition if gated and no active run.
  bool startExpedition({String? heroId, int? seed}) {
    if (!expeditionUnlocked) return false;
    final run = state.activeExpedition;
    if (run != null &&
        run.phase != ExpeditionPhase.settled &&
        run.phase != ExpeditionPhase.failed) {
      return false;
    }
    final id = heroId ?? state.selectedHeroId;
    if (HeroCatalog.tryById(id) == null) return false;
    if (!HeroUnlocks.isUnlocked(id, state.completedNodeIds.length)) {
      return false;
    }
    final s = seed ?? DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      selectedHeroId: id,
      activeExpedition: ExpeditionRunState.start(heroId: id, seed: s),
      clearActiveExpedition: false,
    );
    _persist();
    return true;
  }

  void abandonExpedition() {
    final run = state.activeExpedition;
    if (run == null) return;
    state = state.copyWith(clearActiveExpedition: true);
    _persist();
  }

  /// Marks the current expedition fight as battle phase before launch.
  bool beginExpeditionBattle() {
    final run = state.activeExpedition;
    if (run == null) return false;
    if (run.phase != ExpeditionPhase.hub &&
        run.phase != ExpeditionPhase.battle) {
      return false;
    }
    state = state.copyWith(
      activeExpedition: run.copyWith(phase: ExpeditionPhase.battle),
    );
    _persist();
    return true;
  }

  /// Settles an expedition battle. Returns coins granted (0 until final settle).
  Future<int> applyExpeditionBattleResult({
    required bool won,
    required BattleProgress progress,
  }) async {
    final run = state.activeExpedition;
    if (run == null) return 0;

    if (!won) {
      if (!run.retryUsed) {
        state = state.copyWith(
          activeExpedition: run.copyWith(
            phase: ExpeditionPhase.hub,
            retryUsed: true,
          ),
        );
        await _persist();
        return 0;
      }
      state = state.copyWith(
        coins: state.coins + ExpeditionBalance.failCoinReward,
        activeExpedition: run.copyWith(phase: ExpeditionPhase.failed),
      );
      _recordMasteryProgress(
        heroId: run.heroId,
        progress: progress,
        won: false,
      );
      await _persist();
      return ExpeditionBalance.failCoinReward;
    }

    _recordMasteryProgress(heroId: run.heroId, progress: progress);

    if (run.isBossFight) {
      state = state.copyWith(
        coins: state.coins + ExpeditionBalance.clearCoinReward,
        activeExpedition: run.copyWith(phase: ExpeditionPhase.settled),
        masteryProgressByHero: _bumpExpeditionClear(run.heroId),
      );
      await _persist();
      return ExpeditionBalance.clearCoinReward;
    }

    final offers = RelicCatalog.offerThree(
      seed: run.seed + run.battleIndex * 97,
      ownedIds: run.relicIds.toSet(),
    );
    state = state.copyWith(
      activeExpedition: run.copyWith(
        phase: ExpeditionPhase.relicPick,
        pendingRelicOffers: [for (final o in offers) o.id],
      ),
    );
    await _persist();
    return 0;
  }

  /// Picks one offered relic and advances to the next fight hub.
  bool chooseExpeditionRelic(String relicId) {
    final run = state.activeExpedition;
    if (run == null || run.phase != ExpeditionPhase.relicPick) return false;
    if (!run.pendingRelicOffers.contains(relicId)) return false;
    state = state.copyWith(
      activeExpedition: run.copyWith(
        phase: ExpeditionPhase.hub,
        battleIndex: run.battleIndex + 1,
        relicIds: [...run.relicIds, relicId],
        pendingRelicOffers: const [],
      ),
    );
    _persist();
    return true;
  }

  void clearSettledExpedition() {
    final run = state.activeExpedition;
    if (run == null) return;
    if (run.phase != ExpeditionPhase.settled &&
        run.phase != ExpeditionPhase.failed) {
      return;
    }
    state = state.copyWith(clearActiveExpedition: true);
    _persist();
  }

  Map<String, HeroMasteryCounters> _bumpExpeditionClear(String heroId) {
    final next = Map<String, HeroMasteryCounters>.from(
      state.masteryProgressByHero,
    );
    final cur = next[heroId] ?? const HeroMasteryCounters();
    next[heroId] = cur.copyWith(expeditionClears: cur.expeditionClears + 1);
    return next;
  }

  void _recordMasteryProgress({
    required String heroId,
    required BattleProgress progress,
    bool won = true,
  }) {
    if (HeroCatalog.tryById(heroId) == null) return;
    final next = Map<String, HeroMasteryCounters>.from(
      state.masteryProgressByHero,
    );
    final cur = next[heroId] ?? const HeroMasteryCounters();
    next[heroId] = cur.copyWith(
      wins: won ? cur.wins + 1 : cur.wins,
      skillsCast: cur.skillsCast + progress.skillsCastCount,
    );
    state = state.copyWith(masteryProgressByHero: next);
  }

  /// Claim a met mastery tier. Returns true if granted.
  bool claimMastery(String masteryId) {
    final def = MasteryCatalog.byId(masteryId);
    if (def == null) return false;
    if (state.claimedMasteryIds.contains(masteryId)) return false;
    final counters = state.masteryFor(def.heroId);
    if (counters.valueFor(def.condition) < def.target) return false;

    var skills = Set<String>.from(state.unlockedMasterySkillIds);
    var cosmetics = Set<String>.from(state.claimedCosmeticIds);
    switch (def.rewardType) {
      case MasteryRewardType.unlockSkill:
        if (def.rewardSkillId != null) skills.add(def.rewardSkillId!);
      case MasteryRewardType.cosmeticTitle:
      case MasteryRewardType.cosmeticFrame:
        if (def.rewardCosmeticId != null) {
          cosmetics.add(def.rewardCosmeticId!);
        }
    }
    state = state.copyWith(
      claimedMasteryIds: {...state.claimedMasteryIds, masteryId},
      unlockedMasterySkillIds: skills,
      claimedCosmeticIds: cosmetics,
    );
    _persist();
    return true;
  }

  String ensureActiveEncounterId({required String nodeId}) {
    if (state.activeEncounterId != null &&
        state.activeEncounterNodeId == nodeId) {
      return state.activeEncounterId!;
    }
    final id = '${nodeId}_${DateTime.now().microsecondsSinceEpoch}';
    state = state.copyWith(
      activeEncounterId: id,
      activeEncounterNodeId: nodeId,
      encounterAdContinuesUsed: 0,
      encounterPaidContinuesUsed: 0,
      pendingContinueRevive: false,
    );
    _persist();
    return id;
  }

  Future<void> clearActiveEncounter() async {
    if (state.activeEncounterId == null && !state.pendingContinueRevive) {
      return;
    }
    state = state.copyWith(clearActiveEncounter: true);
    await _persist();
  }

  bool canUseAdContinue() {
    return DefeatContinueRules.canUseAd(
      adUsed: state.encounterAdContinuesUsed,
      paidUsed: state.encounterPaidContinuesUsed,
    );
  }

  bool canUsePaidContinue() {
    return DefeatContinueRules.canUsePaid(
      adUsed: state.encounterAdContinuesUsed,
      paidUsed: state.encounterPaidContinuesUsed,
      coins: state.coins,
    );
  }

  bool consumeAdContinueAndArmRevive() {
    if (!canUseAdContinue()) return false;
    state = state.copyWith(
      encounterAdContinuesUsed: state.encounterAdContinuesUsed + 1,
      pendingContinueRevive: true,
    );
    _persist();
    return true;
  }

  bool consumePaidContinueAndArmRevive() {
    if (!canUsePaidContinue()) return false;
    state = state.copyWith(
      coins: state.coins - DefeatContinueBalance.paidContinueCoinCost,
      encounterPaidContinuesUsed: state.encounterPaidContinuesUsed + 1,
      pendingContinueRevive: true,
    );
    _persist();
    return true;
  }

  /// Returns true once, then clears the pending flag.
  bool consumePendingContinueRevive(String encounterId) {
    if (!state.pendingContinueRevive) return false;
    if (state.activeEncounterId != encounterId) return false;
    state = state.copyWith(pendingContinueRevive: false);
    _persist();
    return true;
  }

  bool claimStarterPack() {
    if (state.hasClaimedStarterPack()) return false;
    final cosmetics = Set<String>.from(state.claimedCosmeticIds)
      ..add(StarterPackBalance.cosmeticId);
    state = state.copyWith(
      coins: state.coins + StarterPackBalance.coins,
      gems: state.gems + StarterPackBalance.gems,
      claimedStarterPackIds: {
        ...state.claimedStarterPackIds,
        StarterPackBalance.id,
      },
      claimedCosmeticIds: cosmetics,
    );
    _persist();
    return true;
  }

  bool claimValuePack30Day() {
    const id = 'value_pack_30d';
    if (state.hasClaimedStarterPack(id)) return false;
    state = state.copyWith(
      gems: state.gems + IapGrantTable.value30DayUpfrontGems,
      claimedStarterPackIds: {
        ...state.claimedStarterPackIds,
        id,
      },
    );
    _persist();
    return true;
  }

  bool equipCosmetic(String cosmeticId, {String? heroId}) {
    final def = CosmeticCatalog.byId(cosmeticId);
    if (def == null) return false;
    if (!state.claimedCosmeticIds.contains(cosmeticId)) return false;
    final targetHero = heroId ?? state.selectedHeroId;
    if (!def.availableFor(targetHero)) return false;

    switch (def.slot) {
      case CosmeticSlot.overlay:
        final next = Map<String, String>.from(state.equippedOverlayByHero);
        next[targetHero] = cosmeticId;
        state = state.copyWith(equippedOverlayByHero: next);
      case CosmeticSlot.title:
        state = state.copyWith(equippedTitleId: cosmeticId);
      case CosmeticSlot.frame:
        state = state.copyWith(equippedFrameId: cosmeticId);
    }
    _persist();
    return true;
  }

  bool unequipCosmetic(String cosmeticId, {String? heroId}) {
    final def = CosmeticCatalog.byId(cosmeticId);
    if (def == null) return false;
    final targetHero = heroId ?? state.selectedHeroId;
    switch (def.slot) {
      case CosmeticSlot.overlay:
        if (state.equippedOverlayByHero[targetHero] != cosmeticId) return false;
        final next = Map<String, String>.from(state.equippedOverlayByHero)
          ..remove(targetHero);
        state = state.copyWith(equippedOverlayByHero: next);
      case CosmeticSlot.title:
        if (state.equippedTitleId != cosmeticId) return false;
        state = state.copyWith(clearEquippedTitle: true);
      case CosmeticSlot.frame:
        if (state.equippedFrameId != cosmeticId) return false;
        state = state.copyWith(clearEquippedFrame: true);
    }
    _persist();
    return true;
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
