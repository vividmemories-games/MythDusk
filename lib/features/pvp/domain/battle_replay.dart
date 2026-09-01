import 'dart:math';

import '../../battle/domain/battle_state.dart';
import '../../puzzle/domain/puzzle_engine.dart';
import '../../puzzle/domain/tile_id_gen.dart';
import 'battle_action.dart';

/// Applies an action log through [BattleController] with a seeded RNG.
/// Two callers with the same initial state, seed, and log must agree.
abstract final class BattleReplay {
  static BattleState apply({
    required BattleState initial,
    required List<BattleAction> log,
    required int seed,
    int tileIdStart = 1000,
    void Function(BattleController controller, BattleAction action)?
        beforeEnemy,
  }) {
    final controller = BattleController(
      initial,
      random: Random(seed),
      ids: TileIdGen(tileIdStart),
    );
    controller.startPlayerTurn(applyInline: true);
    for (final action in log) {
      _applyOne(controller, action);
      beforeEnemy?.call(controller, action);
      if (controller.state.phase == BattlePhase.enemyTurn) {
        controller.applyEnemySkill(controller.enemyAction);
        controller.clearCombatFx();
        if (controller.state.phase == BattlePhase.playerTurn) {
          controller.startPlayerTurn(applyInline: true);
          controller.reshuffleIfDead();
        }
      }
    }
    return controller.state;
  }

  static void applyCascadeInline(
    BattleController controller,
    CascadeResult cascade, {
    int movesSpent = 1,
  }) {
    var boardWithMatches = cascade.boardAfterSwap ?? controller.state.board;
    for (final step in cascade.steps) {
      final overlaysBroken = PuzzleEngine.countOverlaysFullyBroken(
        boardWithMatches,
        step.boardAfterClear,
      );
      controller.applyMatchRewards(
        step.match,
        overlaysBrokenDelta: overlaysBroken,
      );
      boardWithMatches = step.boardAfterFill;
    }
    controller.state = controller.state.copyWith(
      board: cascade.finalBoard,
      clearingCells: const {},
      spawningIds: const {},
    );
    if (controller.tryObjectiveVictory()) return;
    controller.finishPlayerAction(movesSpent: movesSpent);
    if (controller.tryObjectiveVictory()) return;
    if (controller.state.phase == BattlePhase.playerTurn) {
      controller.reshuffleIfDead();
    }
  }

  static void _applyOne(BattleController controller, BattleAction action) {
    switch (action.type) {
      case BattleActionType.swap:
        final cascade = controller.peekSwap(action.cellA, action.cellB);
        if (cascade == null) return;
        applyCascadeInline(controller, cascade);
      case BattleActionType.activate:
        final cascade = controller.beginActivate(action.cellA);
        if (cascade == null) return;
        applyCascadeInline(controller, cascade);
      case BattleActionType.castSkill:
        final skillId = action.skillId;
        if (skillId == null) return;
        for (final skill in controller.state.hero.skills) {
          if (skill.id == skillId) {
            controller.castSkill(skill);
            controller.clearCombatFx();
            return;
          }
        }
      case BattleActionType.endTurn:
        controller.endPlayerTurn();
      case BattleActionType.forfeit:
        controller.state = controller.state.copyWith(
          phase: BattlePhase.defeat,
          heroHp: 0,
        );
    }
  }
}
