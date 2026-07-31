import 'dart:math';

import '../../../core/assets/game_assets.dart';
import '../../profile/domain/economy_balance.dart';

/// Meta prep items carried into battles (Content Architecture §3 / Bible §3).
enum PrepItemId {
  vanguardTonic,
  aegisFlask,
  secondWind,
}

extension PrepItemIdX on PrepItemId {
  String get storageKey => switch (this) {
        PrepItemId.vanguardTonic => 'vanguard_tonic',
        PrepItemId.aegisFlask => 'aegis_flask',
        PrepItemId.secondWind => 'second_wind',
      };

  String get displayName => switch (this) {
        PrepItemId.vanguardTonic => 'Vanguard Tonic',
        PrepItemId.aegisFlask => 'Aegis Flask',
        PrepItemId.secondWind => 'Second Wind',
      };

  String get blurb => switch (this) {
        PrepItemId.vanguardTonic => '+1 Move this battle',
        PrepItemId.aegisFlask => 'Start with a small shield',
        PrepItemId.secondWind => 'Once/day: revive to ~30% HP',
      };

  String get assetPath => switch (this) {
        PrepItemId.vanguardTonic => GameAssets.prepVanguard,
        PrepItemId.aegisFlask => GameAssets.prepAegis,
        PrepItemId.secondWind => GameAssets.prepSecondWind,
      };

  static PrepItemId? tryParse(String key) {
    for (final id in PrepItemId.values) {
      if (id.storageKey == key) return id;
    }
    return null;
  }

  /// Parses level JSON `prepDrops` entries (`prep_vanguard_tonic` or `vanguard_tonic`).
  static PrepItemId? tryParseDrop(String raw) {
    final key = raw.startsWith('prep_') ? raw.substring(5) : raw;
    return tryParse(key);
  }
}

/// Prep combat hooks — numbers owned by docs/01_Game_Design/Balancing_Bible.md.
abstract final class PrepBalance {
  static const maxEquipped = 3;
  static const aegisShield = 15;
  static const vanguardBonusMoves = 1;
  static const secondWindHpFraction = 0.3;
  static const defaultMinMoves = 2;

  /// Back-compat aliases → [EconomyBalance].
  static const startingLives = EconomyBalance.startingLives;
  static const maxLives = EconomyBalance.maxLives;

  /// Coin prices for prep shop stubs (Balancing Bible §5.2).
  static const shopCoinCost = {
    PrepItemId.vanguardTonic: 40,
    PrepItemId.aegisFlask: 60,
    PrepItemId.secondWind: 150,
  };

  /// Effective moves for a battle turn budget.
  static int movesThisTurn({
    required int heroMoves,
    required int prepBonus,
    int levelModifier = 0,
    int bossDebuff = 0,
    int minMoves = defaultMinMoves,
  }) {
    final raw = heroMoves + prepBonus + levelModifier - bossDebuff;
    return raw < minMoves ? minMoves : raw;
  }
}

/// Non-boss clear drop table (Balancing Bible §3.1).
abstract final class PrepDrops {
  static const nonBossGrant = {
    PrepItemId.vanguardTonic: 1,
  };

  /// Act index is 0-based within the chapter (0 = Act I).
  static const aegisAct2PlusChance = 0.25;
  static const secondWindAct3PlusChance = 0.08;

  /// When [nodePrepDrops] is non-empty, those ids are authoritative (+1 each).
  /// Otherwise uses the act-based random table.
  static Map<PrepItemId, int> forVictory({
    required bool isBoss,
    int actIndex = 0,
    List<String> nodePrepDrops = const [],
    Random? random,
  }) {
    if (isBoss) return const {};
    if (nodePrepDrops.isNotEmpty) {
      return fromNodePrepDrops(nodePrepDrops);
    }
    return forNonBossClear(actIndex: actIndex, random: random);
  }

  static Map<PrepItemId, int> fromNodePrepDrops(List<String> prepDrops) {
    final drops = <PrepItemId, int>{};
    for (final raw in prepDrops) {
      final id = PrepItemIdX.tryParseDrop(raw);
      if (id == null) continue;
      drops[id] = (drops[id] ?? 0) + 1;
    }
    return drops;
  }

  static Map<PrepItemId, int> forNonBossClear({
    int actIndex = 0,
    Random? random,
  }) {
    final rng = random ?? Random();
    final drops = Map<PrepItemId, int>.of(nonBossGrant);
    if (actIndex >= 1 && rng.nextDouble() < aegisAct2PlusChance) {
      drops[PrepItemId.aegisFlask] = (drops[PrepItemId.aegisFlask] ?? 0) + 1;
    }
    if (actIndex >= 2 && rng.nextDouble() < secondWindAct3PlusChance) {
      drops[PrepItemId.secondWind] = (drops[PrepItemId.secondWind] ?? 0) + 1;
    }
    return drops;
  }
}
