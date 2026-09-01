/// Client vs Cloud Function field split for `users/{uid}` (schema 14).
///
/// Keep in sync with `firestore.rules` and `functions/index.js`.
abstract final class ProfileFieldPolicy {
  static const schemaVersion = 14;

  /// Owner may write these on `users/{uid}`.
  static const clientWritable = {
    'schemaVersion',
    'displayName',
    'selectedHeroId',
    'equippedSkillIdsByHero',
    'equippedOverlayByHero',
    'equippedTitleId',
    'equippedFrameId',
    'hintsEnabled',
    'soundEnabled',
    'hapticsEnabled',
    'tutorialBeatsSeen',
    'firstBattleTutorialDone',
    'seenUnlockCelebrationIds',
    'updatedAt',
  };

  /// Must only change via Cloud Functions.
  static const functionOnly = {
    'coins',
    'gems',
    'lives',
    'lastLifeRegenAt',
    'gemLifeRefillDay',
    'gemLifeRefillCount',
    'upgradeLevelsByHero',
    'completedNodeIds',
    'prepInventory',
    'secondWindUsedDay',
    'weeklyLastCompletedDay',
    'dailyLastCompletedDay',
    'claimedDailyMedalIds',
    'chapterMedalCounters',
    'claimedChapterMedalIds',
    'activeExpedition',
    'masteryProgressByHero',
    'claimedMasteryIds',
    'unlockedMasterySkillIds',
    'claimedCosmeticIds',
    'claimedStarterPackIds',
    'activeEncounterId',
    'activeEncounterNodeId',
    'encounterAdContinuesUsed',
    'encounterPaidContinuesUsed',
    'pendingContinueRevive',
    'createdAt',
  };

  static Map<String, dynamic> clientPatch(Map<String, dynamic> profileJson) {
    return {
      for (final key in clientWritable)
        if (profileJson.containsKey(key)) key: profileJson[key],
    };
  }

  static bool isClientWritable(String field) => clientWritable.contains(field);

  static bool isFunctionOnly(String field) => functionOnly.contains(field);
}
