/// Soft-progression knobs — numbers owned by docs/01_Game_Design/Balancing_Bible.md.
abstract final class EconomyBalance {
  static const maxLives = 5;
  static const startingLives = 5;

  /// Passive regen while below [maxLives].
  static const lifeRegenMinutes = 20;

  static const gemLifeRefillCost = 75;
  static const gemLifeRefillAmount = 3;
  static const gemLifeRefillsPerDay = 3;

  /// Upgrade: +5% per tier, max 6 tiers = +30% per stat line.
  static const upgradePctPerTier = 0.05;
  static const upgradeMaxTiers = 6;

  static const upgradeStatHp = 'hp';
  static const upgradeStatDamage = 'damage';
  static const upgradeStatShield = 'shield';

  static const upgradeStatKeys = [
    upgradeStatHp,
    upgradeStatDamage,
    upgradeStatShield,
  ];

  /// Zeroed hp/damage/shield map for a hero with no personality training yet.
  static Map<String, int> emptyUpgradeLevels() => {
        for (final k in upgradeStatKeys) k: 0,
      };

  /// Clamps unknown keys out and bounds tiers to 0–[upgradeMaxTiers].
  static Map<String, int> sanitizeUpgradeLevels(Map<String, dynamic>? raw) {
    final out = emptyUpgradeLevels();
    if (raw == null) return out;
    for (final e in raw.entries) {
      if (!upgradeStatKeys.contains(e.key)) continue;
      out[e.key] = (e.value as num).toInt().clamp(0, upgradeMaxTiers);
    }
    return out;
  }

  /// Coin cost to purchase the next tier (1-indexed tier → cost).
  static const upgradeTierCoinCost = {
    1: 100,
    2: 150,
    3: 225,
    4: 325,
    5: 450,
    6: 600,
  };

  /// Multiplier for a given upgrade level (0 → 1.0, 6 → 1.30).
  static double multiplierFor(int level) {
    final clamped = level.clamp(0, upgradeMaxTiers);
    return 1.0 + upgradePctPerTier * clamped;
  }

  static int coinCostForNextTier(int currentLevel) {
    final next = currentLevel + 1;
    if (next > upgradeMaxTiers) return -1;
    return upgradeTierCoinCost[next] ?? -1;
  }
}

/// Pure life-regen math (testable without Flutter).
abstract final class LifeRegenMath {
  /// Returns updated lives and timer anchor. Null [lastLifeRegenAt] means
  /// full lives (timer frozen) or "start counting from now" after a spend.
  static ({int lives, DateTime? lastLifeRegenAt}) apply({
    required int lives,
    required DateTime? lastLifeRegenAt,
    required DateTime now,
    int maxLives = EconomyBalance.maxLives,
    int intervalMinutes = EconomyBalance.lifeRegenMinutes,
  }) {
    if (lives >= maxLives) {
      return (lives: maxLives, lastLifeRegenAt: null);
    }
    final start = lastLifeRegenAt ?? now;
    final gained = now.difference(start).inMinutes ~/ intervalMinutes;
    if (gained <= 0) {
      return (lives: lives, lastLifeRegenAt: lastLifeRegenAt);
    }
    final newLives = (lives + gained).clamp(0, maxLives);
    if (newLives >= maxLives) {
      return (lives: maxLives, lastLifeRegenAt: null);
    }
    final advanced = start.add(Duration(minutes: gained * intervalMinutes));
    return (lives: newLives, lastLifeRegenAt: advanced);
  }

  static Duration? timeUntilNextLife({
    required int lives,
    required DateTime? lastLifeRegenAt,
    required DateTime now,
    int maxLives = EconomyBalance.maxLives,
    int intervalMinutes = EconomyBalance.lifeRegenMinutes,
  }) {
    if (lives >= maxLives) return null;
    final start = lastLifeRegenAt ?? now;
    final next = start.add(Duration(minutes: intervalMinutes));
    final delta = next.difference(now);
    return delta.isNegative ? Duration.zero : delta;
  }
}
