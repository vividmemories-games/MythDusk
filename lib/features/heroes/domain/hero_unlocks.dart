/// Campaign progression gates for hero select (Content Architecture ~50/100/150/200).
abstract final class HeroUnlocks {
  static const mageId = 'mage';

  /// Completed campaign nodes required to unlock each hero.
  static const thresholds = <String, int>{
    mageId: 0,
    'knight': 50,
    'ranger': 100,
    'priest': 150,
    'ninja': 200,
  };

  static int requiredClears(String heroId) => thresholds[heroId] ?? 999;

  static bool isUnlocked(String heroId, int completedNodeCount) {
    return completedNodeCount >= requiredClears(heroId);
  }

  static String lockBlurb(String heroId, int completedNodeCount) {
    final need = requiredClears(heroId);
    final left = (need - completedNodeCount).clamp(0, need);
    return 'Clear $need campaign nodes ($left left)';
  }
}
