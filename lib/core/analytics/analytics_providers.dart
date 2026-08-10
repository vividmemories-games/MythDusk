import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gameplay_analytics.dart';

final gameplayAnalyticsProvider = Provider<GameplayAnalytics>((ref) {
  if (kDebugMode) return DebugGameplayAnalytics();
  return const NoopGameplayAnalytics();
});
