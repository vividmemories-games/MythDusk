/// Campaign progression gates for hero select.
///
/// Clear thresholds (retention phase M1): Mage 0 / Knight 5 / Ranger 15 /
/// Priest 30 / Ninja 50. Unlock celebrations are separate — see
/// [pendingUnlockCelebrations].
abstract final class HeroUnlocks {
  static const mageId = 'mage';

  /// Completed campaign nodes required to unlock each hero.
  static const thresholds = <String, int>{
    mageId: 0,
    'knight': 5,
    'ranger': 15,
    'priest': 30,
    'ninja': 50,
  };

  /// Unlockable heroes in threshold order (excludes starter Mage).
  static List<String> get unlockableHeroIds => thresholds.entries
      .where((e) => e.key != mageId && e.value > 0)
      .map((e) => e.key)
      .toList()
    ..sort((a, b) => requiredClears(a).compareTo(requiredClears(b)));

  static int requiredClears(String heroId) => thresholds[heroId] ?? 999;

  static bool isUnlocked(String heroId, int completedNodeCount) {
    return completedNodeCount >= requiredClears(heroId);
  }

  static String lockBlurb(String heroId, int completedNodeCount) {
    final need = requiredClears(heroId);
    final left = (need - completedNodeCount).clamp(0, need);
    return 'Clear $need campaign nodes ($left left)';
  }

  /// Heroes that are unlocked by clear count but whose celebration has not
  /// been shown yet. Mage is never celebrated (starter). Order is ascending
  /// by threshold so earlier unlocks play first.
  static List<String> pendingUnlockCelebrations({
    required int completedNodeCount,
    required Set<String> seenCelebrationIds,
  }) {
    final pending = <String>[];
    for (final heroId in unlockableHeroIds) {
      if (!isUnlocked(heroId, completedNodeCount)) continue;
      if (seenCelebrationIds.contains(heroId)) continue;
      pending.add(heroId);
    }
    return pending;
  }
}
