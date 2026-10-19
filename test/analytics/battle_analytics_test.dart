import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/analytics/battle_analytics.dart';

void main() {
  group('battleAnalyticsMode', () {
    test('prefers expedition over other flags', () {
      expect(
        battleAnalyticsMode(
          isDaily: true,
          isWeekly: true,
          isExpedition: true,
        ),
        'expedition',
      );
    });

    test('daily before weekly', () {
      expect(
        battleAnalyticsMode(
          isDaily: true,
          isWeekly: true,
          isExpedition: false,
        ),
        'daily',
      );
    });

    test('weekly campaign default', () {
      expect(
        battleAnalyticsMode(
          isDaily: false,
          isWeekly: true,
          isExpedition: false,
        ),
        'weekly',
      );
      expect(
        battleAnalyticsMode(
          isDaily: false,
          isWeekly: false,
          isExpedition: false,
        ),
        'campaign',
      );
    });
  });
}
