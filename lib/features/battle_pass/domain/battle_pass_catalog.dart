import '../../cosmetics/domain/cosmetic_catalog.dart';

/// Battle pass stays off until Remote Config `battle_pass_enabled` is true.
/// Premium track is cosmetics + currency + materials only — no exclusive
/// combat power and no campaign hero unlocks.
class BattlePassReward {
  const BattlePassReward({
    required this.tier,
    required this.freeTrack,
    this.coins = 0,
    this.gems = 0,
    this.cosmeticId,
    this.materialId,
  });

  final int tier;
  final bool freeTrack;
  final int coins;
  final int gems;
  final String? cosmeticId;
  final String? materialId;

  bool get grantsCombatPower => false;
}

abstract final class BattlePassCatalog {
  static const seasonId = 'season_000_preview';
  static const premiumPriceMicros = 7990000;
  static const enabledByDefault = false;

  static const rewards = <BattlePassReward>[
    BattlePassReward(tier: 1, freeTrack: true, coins: 50),
    BattlePassReward(
      tier: 1,
      freeTrack: false,
      gems: 20,
      cosmeticId: 'overlay_dusk_sash',
    ),
    BattlePassReward(
      tier: 2,
      freeTrack: true,
      coins: 75,
    ),
    BattlePassReward(
      tier: 2,
      freeTrack: false,
      coins: 150,
      materialId: 'upgrade_dust_small',
    ),
    BattlePassReward(
      tier: 3,
      freeTrack: false,
      cosmeticId: 'overlay_dusk_sash',
    ),
  ];

  static bool get premiumHasExclusiveCombatPower =>
      rewards.any((r) => !r.freeTrack && r.grantsCombatPower);

  static bool cosmeticIsKnown(String id) =>
      CosmeticCatalog.byId(id) != null || id.startsWith('upgrade_dust');
}
