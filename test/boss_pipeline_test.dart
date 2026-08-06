import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/domain/enemy_def.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';

void main() {
  SkillDef cheapHit() => HeroCatalog.mage.skills.firstWhere(
        (s) => s.damage > 0,
      );

  group('boss flee vs death', () {
    BattleController controller({int? bossForm, int enemyHp = 1}) {
      return BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.warchief,
          bossForm: bossForm,
        ).copyWith(
          enemyHp: enemyHp,
          ap: 10,
          resources: const {
            'attack': 99,
            'mana': 99,
            'healing': 99,
            'shield': 99,
            'ultimate': 99,
          },
        ),
      );
    }

    test('form 1–3 flee on lethal skill', () {
      for (final form in [1, 2, 3]) {
        final c = controller(bossForm: form);
        c.castSkill(cheapHit());
        expect(c.state.phase, BattlePhase.victory, reason: 'form $form');
        expect(c.state.bossFled, isTrue, reason: 'form $form');
        expect(c.state.enemyHp, 0);
        expect(c.state.log.last, contains('flees'));
      }
    });

    test('form 4 dies on lethal skill', () {
      final c = controller(bossForm: 4);
      c.castSkill(cheapHit());
      expect(c.state.phase, BattlePhase.victory);
      expect(c.state.bossFled, isFalse);
      expect(c.state.log.last, 'Victory!');
    });

    test('trash enemy dies without flee', () {
      final c = BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.goblin,
        ).copyWith(
          enemyHp: 1,
          ap: 10,
          resources: const {
            'attack': 99,
            'mana': 99,
            'healing': 99,
            'shield': 99,
            'ultimate': 99,
          },
        ),
      );
      c.castSkill(cheapHit());
      expect(c.state.phase, BattlePhase.victory);
      expect(c.state.bossFled, isFalse);
    });
  });

  group('boss enrage', () {
    test('enrages on player turn >= threshold', () {
      final c = BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.warchief,
          bossForm: 1,
          enrageAfterTurns: 2,
        ),
      );
      expect(c.state.enraged, isFalse);
      c.startPlayerTurn(applyInline: true); // turn 1
      expect(c.state.playerTurnNumber, 1);
      expect(c.state.enraged, isFalse);
      c.startPlayerTurn(applyInline: true); // turn 2
      expect(c.state.playerTurnNumber, 2);
      expect(c.state.enraged, isTrue);
      expect(c.state.log, contains(contains('enrages')));
    });

    test('enraged multiplies enemy damage', () {
      const skill = EnemySkill(
        id: 'slash',
        name: 'Slash',
        damage: 10,
        weight: 1,
      );
      final startHp = HeroCatalog.mage.maxHp;
      final calm = BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.warchief,
        ).copyWith(heroHp: startHp, shield: 0),
      );
      calm.applyEnemySkill(skill);

      final mad = BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.warchief,
        ).copyWith(heroHp: startHp, shield: 0, enraged: true),
      );
      mad.applyEnemySkill(skill);

      expect(startHp - calm.state.heroHp, 10);
      expect(
        startHp - mad.state.heroHp,
        (10 * BossCombatBalance.enrageDamageMultiplier).round(),
      );
      expect(mad.state.heroHp, lessThan(calm.state.heroHp));
    });
  });
}
