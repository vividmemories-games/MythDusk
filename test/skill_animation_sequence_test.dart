import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/providers/battle_provider.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';

class _ReadyBattle extends BattleNotifier {
  _ReadyBattle({required super.hero});

  void prepareCast(SkillDef skill, {int? enemyHp, int? heroHp}) {
    state = state.copyWith(
      enemyHp: enemyHp,
      heroHp: heroHp,
      ap: skill.apCost,
      resources: skill.resourceCosts,
    );
  }

  BattleState get snapshot => state;
}

void main() {
  test('every hero skill has a unique animation profile', () {
    final skillIds =
        HeroCatalog.all.expand((hero) => hero.skills).map((skill) => skill.id);
    expect(SkillAnimation.values.map((animation) => animation.skillId),
        unorderedEquals(skillIds));
  });

  final cases = [
    (HeroCatalog.mage, 'fireball', SkillAnimation.fireball, false),
    (HeroCatalog.mage, 'fireball', SkillAnimation.fireball, true),
    (HeroCatalog.mage, 'arcane_bolt', SkillAnimation.arcaneBolt, false),
    (HeroCatalog.knight, 'basic_slash', SkillAnimation.basicSlash, false),
    (HeroCatalog.priest, 'smite', SkillAnimation.smite, false),
  ];
  for (final (hero, skillId, animation, reduceMotion) in cases) {
    test(
      '$skillId shows a lethal impact before victory (reduced motion: '
      '$reduceMotion)',
      () async {
        final skill = hero.skills.firstWhere((skill) => skill.id == skillId);
        final battle = _ReadyBattle(hero: hero)
          ..prepareCast(skill, enemyHp: skill.damage - 1);
        addTearDown(battle.dispose);
        final startingHp = battle.snapshot.enemyHp;
        final frames = <BattleState>[];
        final unsubscribe = battle.addListener(
          frames.add,
          fireImmediately: false,
        );
        addTearDown(unsubscribe);

        final cast = battle.castSkill(skill, reduceMotion: reduceMotion);
        expect(battle.snapshot.inputLocked, isTrue);
        await battle.castSkill(skill);
        await cast;

        expect(frames.map((frame) => frame.combatFx), [
          if (!reduceMotion) CombatFx.skillCast,
          CombatFx.skillImpact,
          CombatFx.none,
        ]);
        if (!reduceMotion) {
          expect(frames.first.enemyHp, startingHp);
          expect(frames.first.skillAnimation, animation);
        }

        final impact = frames[frames.length - 2];
        expect(impact.enemyHp, 0);
        expect(impact.skillDamage, startingHp);
        expect(impact.skillAnimation, animation);
        expect(impact.phase, BattlePhase.resolving);
        expect(battle.snapshot.phase, BattlePhase.victory);
        expect(battle.snapshot.ap, 0);
        expect(battle.snapshot.skillsCastIds, [skillId]);
      },
    );
  }

  for (final (hero, animation, missingHp, expected) in [
    (HeroCatalog.priest, SkillAnimation.mend, 5, 5),
    (HeroCatalog.priest, SkillAnimation.mend, 0, 0),
    (HeroCatalog.knight, SkillAnimation.shieldWall, 0, 20),
    (HeroCatalog.priest, SkillAnimation.sanctuary, 7, 21),
  ]) {
    test(
        '${animation.label} applies its actual gain at impact (missing HP: '
        '$missingHp)', () async {
      final skill =
          hero.skills.firstWhere((skill) => skill.id == animation.skillId);
      final battle = _ReadyBattle(hero: hero)
        ..prepareCast(skill, heroHp: hero.maxHp - missingHp);
      addTearDown(battle.dispose);
      final starting = battle.snapshot;
      final frames = <BattleState>[];
      addTearDown(battle.addListener(frames.add, fireImmediately: false));

      await battle.castSkill(skill);

      expect(frames.map((frame) => frame.combatFx), [
        CombatFx.skillCast,
        CombatFx.skillImpact,
        CombatFx.none,
      ]);
      expect(frames.first.heroHp, starting.heroHp);
      expect(frames.first.shield, starting.shield);
      final impact = frames[1];
      expect(impact.enemyHp, starting.enemyHp);
      expect(impact.heroHp, hero.maxHp);
      expect(impact.shield, starting.shield + skill.shield);
      expect(
        impact.skillSupportAmount + impact.skillShieldGain,
        expected,
      );
      expect(battle.snapshot.ap, 0);
      expect(battle.snapshot.phase, BattlePhase.playerTurn);
    });
  }
}
