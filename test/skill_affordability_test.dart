import 'package:flutter_test/flutter_test.dart';
import 'package:mythora/features/battle/domain/battle_state.dart';
import 'package:mythora/features/battle/domain/skill_affordability.dart';
import 'package:mythora/features/heroes/domain/hero_def.dart';

void main() {
  test('reports missing mana before AP when both short', () {
    final state = BattleState.initial(hero: HeroCatalog.mage);
    final skill = HeroCatalog.mage.skills.first; // Fireball 2 AP / 8 mana
    final afford = SkillAffordability.evaluate(skill, state);
    expect(afford.canCast, isFalse);
    expect(afford.blockingReason, contains('mana'));
    expect(afford.resourceLines.first.label, '0/8');
    expect(afford.apHave, 0);
    expect(afford.apNeed, 2);
  });

  test('ready when resources and AP meet cost', () {
    final base = BattleState.initial(hero: HeroCatalog.mage);
    final state = base.copyWith(
      ap: 2,
      resources: {
        ...base.resources,
        'mana': 8,
      },
    );
    final skill = HeroCatalog.mage.skills.first;
    final afford = SkillAffordability.evaluate(skill, state);
    expect(afford.canCast, isTrue);
    expect(afford.blockingReason, isNull);
    expect(afford.apOk, isTrue);
  });
}
