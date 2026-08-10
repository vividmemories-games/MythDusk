import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mythdusk/features/battle/domain/battle_objective.dart';
import 'package:mythdusk/features/daily/domain/daily_battle_medal.dart';
import 'package:mythdusk/features/daily/domain/daily_schedule.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';

void main() {
  group('DailySchedule', () {
    test('same dayKey yields stable template', () {
      final a = DailySchedule.forDate(DateTime(2026, 8, 10));
      final b = DailySchedule.forDate(DateTime(2026, 8, 10, 23, 59));
      expect(a.dayKey, '2026-08-10');
      expect(a.templateId, b.templateId);
      expect(a.enemyId, b.enemyId);
      expect(a.medals.length, 3);
    });

    test('different days can rotate templates', () {
      final ids = {
        for (var d = 1; d <= 14; d++)
          DailySchedule.forDate(DateTime(2026, 8, d)).templateId,
      };
      expect(ids.length, greaterThan(1));
    });
  });

  group('DailyMedalEval', () {
    test('evaluates color / skills / hp medals', () {
      const medal = DailyMedalDefinition(
        id: 'm1',
        title: 'Reds',
        type: DailyBattleMedalType.matchTilesColor,
        target: 10,
        colorId: 'red',
      );
      expect(
        DailyMedalEval.isMet(
          medal,
          progress: const BattleProgress(
            tilesClearedByColor: {'red': 10},
          ),
          heroHp: 50,
          heroMaxHp: 100,
        ),
        isTrue,
      );
      expect(
        DailyMedalEval.isMet(
          medal,
          progress: const BattleProgress(
            tilesClearedByColor: {'red': 9},
          ),
          heroHp: 50,
          heroMaxHp: 100,
        ),
        isFalse,
      );
    });
  });

  group('ProfileNotifier daily claim', () {
    test('idempotent daily victory coins', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ProfileNotifier(prefs);
      final contract = DailySchedule.forDate(DateTime(2026, 8, 10));
      final progress = BattleProgress(
        playerTurnNumber: 5,
        tilesClearedByColor: {
          'red': 40,
          'green': 40,
          'blue': 40,
          'yellow': 40,
          'purple': 40
        },
        resourcesGenerated: {
          'mana': 40,
          'attack': 40,
          'healing': 40,
          'shield': 40,
        },
        skillsCastCount: 5,
        skillsCastIds: ['a', 'b', 'c'],
        usedPrep: false,
      );

      final first = await notifier.applyDailyVictory(
        contract: contract,
        progress: progress,
        heroHp: 90,
        heroMaxHp: 100,
      );
      expect(first.coins, greaterThan(0));
      expect(notifier.state.dailyLastCompletedDay, contract.dayKey);

      final second = await notifier.applyDailyVictory(
        contract: contract,
        progress: progress,
        heroHp: 90,
        heroMaxHp: 100,
      );
      expect(second.coins, 0);
      expect(second.medalIds, isEmpty);
    });
  });
}
