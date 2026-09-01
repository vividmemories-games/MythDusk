import '../../features/profile/domain/economy_balance.dart';
import '../../features/shop/domain/iap_catalog.dart';

/// Firebase Remote Config key names plus client defaults.
abstract final class RemoteConfigKeys {
  static const starterPackEnabled = 'starter_pack_enabled';
  static const defeatContinueEnabled = 'defeat_continue_enabled';
  static const battlePassEnabled = 'battle_pass_enabled';
  static const gemLifeRefillCost = 'gem_life_refill_cost';
  static const gemLifeRefillsPerDay = 'gem_life_refills_per_day';
  static const defeatContinueCoinCost = 'defeat_continue_coin_cost';
  static const rewardedAdDailyCap = 'rewarded_ad_daily_cap';
  static const starterPackCoins = 'starter_pack_coins';
  static const starterPackGems = 'starter_pack_gems';
  static const gemsSmallGrant = 'gems_small_grant';
  static const gemsMediumGrant = 'gems_medium_grant';
  static const value30DayPriceMicros = 'value_30d_price_micros';
  static const starterPackPriceMicros = 'starter_pack_price_micros';

  static const defaults = <String, dynamic>{
    starterPackEnabled: true,
    defeatContinueEnabled: true,
    battlePassEnabled: false,
    gemLifeRefillCost: EconomyBalance.gemLifeRefillCost,
    gemLifeRefillsPerDay: EconomyBalance.gemLifeRefillsPerDay,
    defeatContinueCoinCost: DefeatContinueBalance.paidContinueCoinCost,
    rewardedAdDailyCap: 5,
    starterPackCoins: StarterPackBalance.coins,
    starterPackGems: StarterPackBalance.gems,
    gemsSmallGrant: IapGrantTable.gemsSmall,
    gemsMediumGrant: IapGrantTable.gemsMedium,
    value30DayPriceMicros: 4990000,
    starterPackPriceMicros: 1990000,
  };
}
