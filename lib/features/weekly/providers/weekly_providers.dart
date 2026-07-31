import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/weekly_schedule.dart';

/// QA override: set to a fixed local [DateTime] to test weekday vs weekend.
/// Null = device local clock. Not persisted (Firebase will own day checks later).
final weeklyDayOverrideProvider = StateProvider<DateTime?>((ref) => null);

final weeklyEffectiveNowProvider = Provider<DateTime>((ref) {
  return ref.watch(weeklyDayOverrideProvider) ?? DateTime.now();
});

final weeklyChallengeProvider = Provider<WeeklyChallenge>((ref) {
  return WeeklySchedule.forDate(ref.watch(weeklyEffectiveNowProvider));
});
