import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/daily_schedule.dart';

/// QA override for Daily day key (mirrors Weekly).
final dailyDayOverrideProvider = StateProvider<DateTime?>((ref) => null);

final dailyEffectiveNowProvider = Provider<DateTime>((ref) {
  return ref.watch(dailyDayOverrideProvider) ?? DateTime.now();
});

final dailyContractProvider = Provider<DailyContract>((ref) {
  return DailySchedule.forDate(ref.watch(dailyEffectiveNowProvider));
});
