/// Thin gameplay analytics — no vendor SDK this phase.
abstract class GameplayAnalytics {
  void log(String name, [Map<String, Object?> payload = const {}]);
}

/// Default production sink (silent).
final class NoopGameplayAnalytics implements GameplayAnalytics {
  const NoopGameplayAnalytics();

  @override
  void log(String name, [Map<String, Object?> payload = const {}]) {}
}

/// Debug sink — prints events in debug/profile builds when wired.
final class DebugGameplayAnalytics implements GameplayAnalytics {
  DebugGameplayAnalytics({void Function(String message)? sink})
      : _sink = sink ?? print;

  final void Function(String message) _sink;

  @override
  void log(String name, [Map<String, Object?> payload = const {}]) {
    if (payload.isEmpty) {
      _sink('[GameplayAnalytics] $name');
      return;
    }
    _sink('[GameplayAnalytics] $name $payload');
  }
}

/// Stable event names (retention plan §G).
abstract final class GameplayAnalyticsEvents {
  static const sessionStart = 'session_start';
  static const battleStarted = 'battle_started';
  static const battleEnded = 'battle_ended';
  static const dailyOpened = 'daily_opened';
  static const dailyClaimed = 'daily_claimed';
  static const expeditionStarted = 'expedition_started';
  static const expeditionAbandoned = 'expedition_abandoned';
  static const expeditionCompleted = 'expedition_completed';
  static const relicChosen = 'relic_chosen';
  static const masteryProgress = 'mastery_progress';
  static const masteryClaimed = 'mastery_claimed';
  static const heroUnlockCelebrated = 'hero_unlock_celebrated';
  static const loadoutChanged = 'loadout_changed';
  static const lifeRefillOfferShown = 'life_refill_offer_shown';
  static const lifeRefillPurchased = 'life_refill_purchased';
  static const prepItemPurchased = 'prep_item_purchased';
  static const starterPackClaimed = 'starter_pack_claimed';
  static const iapStarted = 'iap_started';
  static const iapSucceeded = 'iap_succeeded';
  static const iapFailed = 'iap_failed';
  static const iapRestored = 'iap_restored';
  static const rewardedAdStarted = 'rewarded_ad_started';
  static const rewardedAdCompleted = 'rewarded_ad_completed';
  static const rewardedAdFailed = 'rewarded_ad_failed';
  static const defeatContinueOffered = 'defeat_continue_offered';
  static const defeatContinueUsed = 'defeat_continue_used';
  static const cosmeticEquipped = 'cosmetic_equipped';
}
