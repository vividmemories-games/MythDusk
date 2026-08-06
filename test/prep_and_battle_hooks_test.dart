import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/domain/enemy_def.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/prep/domain/prep_item.dart';

void main() {
  group('PrepBalance.movesThisTurn', () {
    test('adds prep bonus and clamps to min 2', () {
      expect(
        PrepBalance.movesThisTurn(heroMoves: 5, prepBonus: 1),
        6,
      );
      expect(
        PrepBalance.movesThisTurn(heroMoves: 1, prepBonus: 0),
        2,
      );
      expect(
        PrepBalance.movesThisTurn(
          heroMoves: 4,
          prepBonus: 0,
          bossDebuff: 3,
        ),
        2,
      );
    });
  });

  group('BattleState prep hooks', () {
    test('vanguard and aegis apply at start', () {
      final state = BattleState.initial(
        hero: HeroCatalog.mage,
        enemy: EnemyCatalog.warchief,
        bonusMoves: 1,
        bonusShield: PrepBalance.aegisShield,
        secondWindArmed: true,
        prepLogNotes: const ['prep'],
      );
      expect(state.movesPerTurn, HeroCatalog.mage.movesPerTurn + 1);
      expect(state.movesLeft, state.movesPerTurn);
      expect(state.shield, PrepBalance.aegisShield);
      expect(state.secondWindArmed, isTrue);
      expect(state.log, contains('prep'));
    });

    test('second wind revives instead of defeat', () {
      final controller = BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.goblin,
          secondWindArmed: true,
        ).copyWith(heroHp: 1, shield: 0),
      );
      const lethal = EnemySkill(
        id: 'heavy',
        name: 'Heavy',
        damage: 99,
        weight: 1,
      );
      controller.applyEnemySkill(lethal);
      expect(controller.state.phase, BattlePhase.playerTurn);
      expect(controller.state.heroHp, greaterThan(0));
      expect(controller.state.secondWindArmed, isFalse);
      expect(
        controller.state.heroHp,
        (HeroCatalog.mage.maxHp * PrepBalance.secondWindHpFraction).round(),
      );
    });

    test('without second wind, lethal hit defeats', () {
      final controller = BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.goblin,
        ).copyWith(heroHp: 1, shield: 0),
      );
      controller.applyEnemySkill(
        const EnemySkill(id: 'heavy', name: 'Heavy', damage: 99, weight: 1),
      );
      expect(controller.state.phase, BattlePhase.defeat);
      expect(controller.state.heroHp, 0);
    });
  });

  test('prep item ids are stable', () {
    expect(PrepItemId.vanguardTonic.storageKey, 'vanguard_tonic');
    expect(PrepItemId.aegisFlask.displayName, 'Aegis Flask');
    expect(PrepItemIdX.tryParse('second_wind'), PrepItemId.secondWind);
  });

  test('showHint and clearHint update hintCells', () {
    final controller = BattleController(
      BattleState.initial(
        hero: HeroCatalog.mage,
        enemy: EnemyCatalog.goblin,
      ),
    );
    controller.showHint({(0, 0), (0, 1)});
    expect(controller.state.hintCells, {(0, 0), (0, 1)});
    controller.clearHint();
    expect(controller.state.hintCells, isEmpty);
  });
}
