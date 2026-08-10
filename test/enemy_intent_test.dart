import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/domain/enemy_def.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';

void main() {
  BattleController makeController({int seed = 7}) {
    return BattleController(
      BattleState.initial(
        hero: HeroCatalog.mage,
        enemy: EnemyCatalog.goblin,
      ),
      random: Random(seed),
    );
  }

  group('Enemy intent telegraph', () {
    test('rollEnemyIntent sets an intent from the enemy skill list', () {
      final controller = makeController();
      expect(controller.state.enemyIntent, isNull);
      controller.rollEnemyIntent();
      final intent = controller.state.enemyIntent;
      expect(intent, isNotNull);
      expect(EnemyCatalog.goblin.skills, contains(intent));
    });

    test('enemyAction returns the telegraphed intent', () {
      final controller = makeController();
      controller.rollEnemyIntent();
      final intent = controller.state.enemyIntent;
      expect(controller.enemyAction, same(intent));
    });

    test('applyEnemySkill executes exactly the telegraphed damage', () {
      final controller = makeController();
      controller.rollEnemyIntent();
      final intent = controller.state.enemyIntent!;
      final hpBefore = controller.state.heroHp;

      controller.applyEnemySkill(controller.enemyAction);

      expect(controller.state.heroHp, hpBefore - intent.damage);
      expect(controller.state.lastEnemySkillName, intent.name);
    });

    test('startPlayerTurn re-rolls intent after enemy skill', () {
      final controller = makeController();
      controller.rollEnemyIntent();

      controller.applyEnemySkill(controller.enemyAction);
      controller.startPlayerTurn(applyInline: true);

      expect(controller.state.phase, BattlePhase.playerTurn);
      expect(controller.state.enemyIntent, isNotNull);
      expect(
          EnemyCatalog.goblin.skills, contains(controller.state.enemyIntent));
      expect(controller.state.playerTurnNumber, 1);
    });

    test('second wind revive then startPlayerTurn keeps a fresh intent', () {
      final controller = BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.goblin,
          secondWindArmed: true,
        ).copyWith(heroHp: 1, shield: 0),
        random: Random(3),
      );
      controller.rollEnemyIntent();

      const lethal = EnemySkill(
        id: 'heavy',
        name: 'Heavy',
        damage: 99,
        weight: 1,
      );
      controller.applyEnemySkill(lethal);
      controller.startPlayerTurn(applyInline: true);

      expect(controller.state.phase, BattlePhase.playerTurn);
      expect(controller.state.secondWindArmed, isFalse);
      expect(controller.state.enemyIntent, isNotNull);
    });

    test('weighted roll is deterministic with a seeded random', () {
      final a = makeController(seed: 42)..rollEnemyIntent();
      final b = makeController(seed: 42)..rollEnemyIntent();
      expect(a.state.enemyIntent!.id, b.state.enemyIntent!.id);
    });
  });

  group('Leech / Hexer intent labels', () {
    test('leech skill intent includes drain and heal', () {
      final leech =
          EnemyCatalog.leechWisp.skills.firstWhere((s) => s.id == 'leech');
      expect(leech.intentLabel, contains('6 dmg'));
      expect(leech.intentLabel, contains('drain 4 healing'));
      expect(leech.intentLabel, contains('heal self 8'));
    });

    test('hexer warp intent includes spawn warp details', () {
      final warp = EnemyCatalog.hexer.skills.firstWhere((s) => s.id == 'warp');
      expect(warp.intentLabel, contains('5 dmg'));
      expect(warp.intentLabel, contains('warp spawns'));
      expect(warp.intentLabel, contains('purple×3'));
      expect(warp.intentLabel, contains('green×0.25'));
    });
  });
}
