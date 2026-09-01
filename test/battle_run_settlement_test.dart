import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_run_settlement.dart';

void main() {
  test('victory grants clamped coins and completes the node once', () {
    final first = BattleRunSettlement.apply(
      alreadyProcessed: false,
      won: true,
      coinReward: 120,
      completedNodeIds: const [],
      nodeId: 'node_01',
      lives: 5,
    );
    expect(first.grantCoins, 120);
    expect(first.completedNodeIds, ['node_01']);
    expect(first.lives, 5);

    final again = BattleRunSettlement.apply(
      alreadyProcessed: true,
      won: true,
      coinReward: 120,
      completedNodeIds: first.completedNodeIds,
      nodeId: 'node_01',
      lives: 5,
    );
    expect(again.alreadyProcessed, isTrue);
    expect(again.grantCoins, 0);
    expect(again.completedNodeIds, ['node_01']);
  });

  test('defeat spends a life and grants nothing', () {
    final result = BattleRunSettlement.apply(
      alreadyProcessed: false,
      won: false,
      coinReward: 120,
      completedNodeIds: const [],
      nodeId: 'node_01',
      lives: 5,
    );
    expect(result.grantCoins, 0);
    expect(result.lives, 4);
    expect(result.completedNodeIds, isEmpty);
  });

  test('pvp defeat does not spend a life', () {
    final result = BattleRunSettlement.apply(
      alreadyProcessed: false,
      won: false,
      coinReward: 0,
      completedNodeIds: const [],
      nodeId: 'pvp',
      lives: 5,
      isPvp: true,
    );
    expect(result.lives, 5);
  });

  test('coin reward is clamped', () {
    expect(BattleRunSettlement.clampCoinReward(-4), 0);
    expect(BattleRunSettlement.clampCoinReward(9000), 5000);
  });
}
