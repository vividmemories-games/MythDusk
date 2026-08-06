import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/domain/enemy_def.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:mythdusk/features/weekly/domain/weekly_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WeeklySchedule', () {
    test('weekday date seed picks survive or clear stably', () {
      final wed = DateTime(2026, 7, 29); // Wednesday
      final a = WeeklySchedule.forDate(wed);
      final b = WeeklySchedule.forDate(wed);
      expect(a.isWeekend, isFalse);
      expect(a.objective, isNotNull);
      expect(a.dayKey, b.dayKey);
      expect(a.objective!.type, b.objective!.type);
      expect(a.enemyId, 'weekly_scout');
    });

    test('weekend picks a weekly_boss id from the roster', () {
      final sat = DateTime(2026, 8, 1); // Saturday
      final challenge = WeeklySchedule.forDate(sat);
      expect(challenge.isWeekend, isTrue);
      expect(challenge.objective, isNull);
      expect(WeeklyBalance.bossIds.contains(challenge.enemyId), isTrue);
      expect(challenge.enrageAfterTurns, WeeklyBalance.weekendEnrageAfterTurns);
    });

    test('same ISO week keeps the same weekend boss', () {
      final sat = DateTime(2026, 8, 1);
      final sun = DateTime(2026, 8, 2);
      expect(
        WeeklySchedule.forDate(sat).enemyId,
        WeeklySchedule.forDate(sun).enemyId,
      );
    });

    test('weekday targets match Balancing Bible v1.1', () {
      expect(WeeklyBalance.surviveTurnsTarget, 7);
      expect(WeeklyBalance.clearTilesTarget, 60);
      expect(WeeklyBalance.enemyStatMultiplier, 2.0);
    });
  });

  group('Weekly enemy toughness', () {
    test('scaled weekly bosses are 2× campaign counterparts', () {
      const mult = WeeklyBalance.enemyStatMultiplier;
      final dusk = EnemyCatalog.weeklyBoss01.scaled(
        hpMult: mult,
        damageMult: mult,
      );
      expect(dusk.maxHp, EnemyCatalog.warchief.maxHp * 2);
      expect(dusk.skills.first.damage,
          EnemyCatalog.warchief.skills.first.damage * 2);

      final scout = EnemyCatalog.weeklyScout.scaled(
        hpMult: mult,
        damageMult: mult,
      );
      expect(scout.maxHp, EnemyCatalog.goblin.maxHp * 2);
      expect(
          scout.skills.last.damage, EnemyCatalog.goblin.skills.last.damage * 2);

      final judge = EnemyCatalog.weeklyBoss05.scaled(
        hpMult: mult,
        damageMult: mult,
      );
      expect(judge.maxHp, EnemyCatalog.mythspireTyrant.maxHp * 2);
    });
  });

  group('BattleObjective', () {
    test('survive turns wins when playerTurnNumber reaches target', () {
      final controller = BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.weeklyScout,
          isWeekly: true,
          objective: const BattleObjective(
            type: WeeklyObjectiveType.surviveTurns,
            target: 2,
          ),
        ),
      );
      controller.startPlayerTurn(applyInline: true); // turn 1
      expect(controller.state.phase, isNot(BattlePhase.victory));
      // Simulate enemy handoff without damage.
      controller.state =
          controller.state.copyWith(phase: BattlePhase.playerTurn);
      controller.startPlayerTurn(applyInline: true); // turn 2 → win
      expect(controller.state.phase, BattlePhase.victory);
      expect(controller.state.playerTurnNumber, 2);
    });

    test('clear tiles wins when enough tiles are matched', () {
      final controller = BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.weeklyScout,
          isWeekly: true,
          objective: const BattleObjective(
            type: WeeklyObjectiveType.clearTiles,
            target: 3,
          ),
        ),
      );
      controller.state = controller.state.copyWith(tilesCleared: 3);
      expect(controller.tryObjectiveVictory(), isTrue);
      expect(controller.state.phase, BattlePhase.victory);
    });
  });

  group('ProfileNotifier weekly', () {
    test('applyWeeklyVictory grants once per dayKey', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ProfileNotifier(prefs);
      final first = await notifier.applyWeeklyVictory(
        dayKey: '2026-07-28',
        coinReward: 40,
      );
      expect(first, 40);
      expect(notifier.state.weeklyLastCompletedDay, '2026-07-28');
      final second = await notifier.applyWeeklyVictory(
        dayKey: '2026-07-28',
        coinReward: 40,
      );
      expect(second, 0);
    });
  });
}
