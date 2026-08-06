import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/enemy_def.dart';
import 'package:mythdusk/features/battle/providers/battle_provider.dart';

void main() {
  test('QA hook forces a real enemy skill through the normal turn pipeline',
      () async {
    final notifier = BattleNotifier(enemy: EnemyCatalog.packAlpha);
    addTearDown(notifier.dispose);
    final movesPerTurn = notifier.state.movesPerTurn;
    final howl =
        EnemyCatalog.packAlpha.skills.firstWhere((skill) => skill.id == 'howl');

    final applied = await notifier.forceEnemySkillForQa(howl);

    expect(applied, isTrue);
    expect(notifier.state.lastEnemySkillName, howl.name);
    expect(notifier.state.movesLeft, movesPerTurn - 1);
    expect(notifier.state.pendingMovePenalty, 0);
  });

  test('QA hook rejects a skill that does not belong to the current enemy',
      () async {
    final notifier = BattleNotifier(enemy: EnemyCatalog.goblin);
    addTearDown(notifier.dispose);
    final howl =
        EnemyCatalog.packAlpha.skills.firstWhere((skill) => skill.id == 'howl');

    expect(await notifier.forceEnemySkillForQa(howl), isFalse);
  });
}
