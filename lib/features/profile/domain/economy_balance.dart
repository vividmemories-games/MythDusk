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

/// Optional defeat continue — [docs/01_Game_Design/Balancing_Bible.md] §3.6.
abstract final class DefeatContinueBalance {
  static const rewardedAdContinuesPerEncounter = 1;
  static const paidContinuesPerEncounter = 1;
  static const maxContinuesPerEncounter =
      rewardedAdContinuesPerEncounter + paidContinuesPerEncounter;
  static const paidContinueCoinCost = 500;

  /// Same revive strength as Second Wind.
  static const reviveHpFraction = 0.3;
}

/// Pure continue-cap math (testable without Flutter).
abstract final class DefeatContinueRules {
  static bool canUseAd({
    required int adUsed,
    required int paidUsed,
  }) {
    if (adUsed >= DefeatContinueBalance.rewardedAdContinuesPerEncounter) {
      return false;
    }
    return (adUsed + paidUsed) < DefeatContinueBalance.maxContinuesPerEncounter;
  }

  static bool canUsePaid({
    required int adUsed,
    required int paidUsed,
    required int coins,
    int cost = DefeatContinueBalance.paidContinueCoinCost,
  }) {
    if (paidUsed >= DefeatContinueBalance.paidContinuesPerEncounter) {
      return false;
    }
    if ((adUsed + paidUsed) >= DefeatContinueBalance.maxContinuesPerEncounter) {
      return false;
    }
    return coins >= cost;
  }
}

/// One-time starter pack — QA claim until IAP (Bible §3.6).
abstract final class StarterPackBalance {
  static const id = 'starter_pack_001';
  static const coins = 400;
  static const gems = 40;
  static const cosmeticId = 'overlay_dusk_sash';
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
