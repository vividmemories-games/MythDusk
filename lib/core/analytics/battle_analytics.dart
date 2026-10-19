/// Stable `mode` values for [GameplayAnalyticsEvents.battleStarted] /
/// [GameplayAnalyticsEvents.battleEnded].
String battleAnalyticsMode({
  required bool isDaily,
  required bool isWeekly,
  required bool isExpedition,
}) {
  if (isExpedition) return 'expedition';
  if (isDaily) return 'daily';
  if (isWeekly) return 'weekly';
  return 'campaign';
}
