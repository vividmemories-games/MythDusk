import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/domain/skill_affordability.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';

void main() {
  test('reports missing resources before AP when both short', () {
    final state = BattleState.initial(hero: HeroCatalog.mage);
    final skill = HeroCatalog.mage.skills.first; // Fireball 2 AP / mana+healing
    final afford = SkillAffordability.evaluate(skill, state);
    expect(afford.canCast, isFalse);
    expect(afford.blockingReason, isNotNull);
    expect(afford.apHave, 0);
    expect(afford.apNeed, 2);
  });

  test('ready when dual resources and AP meet cost', () {
    final base = BattleState.initial(hero: HeroCatalog.mage);
    final skill = HeroCatalog.mage.skills.first;
    final state = base.copyWith(
      ap: 2,
      resources: {
        ...base.resources,
        for (final e in skill.resourceCosts.entries) e.key: e.value,
      },
    );
    final afford = SkillAffordability.evaluate(skill, state);
    expect(afford.canCast, isTrue);
    expect(afford.blockingReason, isNull);
    expect(afford.apOk, isTrue);
  });

  test('every catalog skill costs at least two resources', () {
    for (final hero in HeroCatalog.all) {
      for (final skill in hero.skills) {
        expect(
          skill.resourceCosts.length,
          greaterThanOrEqualTo(2),
          reason: '${hero.id}.${skill.id}',
        );
      }
    }
  });
}
