import 'package:flutter_test/flutter_test.dart';
import 'package:mythora/features/battle/domain/battle_state.dart';
import 'package:mythora/features/battle/domain/enemy_def.dart';
import 'package:mythora/features/heroes/domain/hero_def.dart';

void main() {
  group('endPlayerTurn', () {
    test('discards remaining moves and starts enemy phase', () {
      final c = BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.goblin,
        ),
      );
      c.startPlayerTurn(applyInline: true);
      expect(c.state.movesLeft, greaterThan(0));
      expect(c.state.phase, BattlePhase.playerTurn);

      c.endPlayerTurn();
      expect(c.state.movesLeft, 0);
      expect(c.state.phase, BattlePhase.enemyTurn);
      expect(c.state.log.last, 'Turn ended.');
    });
  });

  group('soft-lock handoff', () {
    test('enemy skill leaves 0 moves until startPlayerTurn refills', () {
      final c = BattleController(
        BattleState.initial(
          hero: HeroCatalog.mage,
          enemy: EnemyCatalog.goblin,
        ),
      );
      c.startPlayerTurn(applyInline: true);
      final budget = c.state.movesPerTurn;

      // Simulate last move spent → enemy turn → enemy hits.
      c.finishPlayerAction(movesSpent: c.state.movesLeft);
      expect(c.state.phase, BattlePhase.enemyTurn);
      expect(c.state.movesLeft, 0);

      c.applyEnemySkill(
        const EnemySkill(id: 'nick', name: 'Nick', damage: 1, weight: 1),
      );
      expect(c.state.phase, BattlePhase.playerTurn);
      expect(
          c.state.movesLeft, 0); // soft-lock if UI never calls startPlayerTurn

      c.startPlayerTurn(applyInline: true);
      expect(c.state.movesLeft, budget);
      expect(c.state.phase, BattlePhase.playerTurn);
    });
  });
}
