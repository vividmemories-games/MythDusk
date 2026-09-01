import 'dart:math';

import '../../battle/domain/battle_state.dart';
import '../../heroes/domain/hero_def.dart';
import '../../puzzle/domain/puzzle_board.dart';
import '../../puzzle/domain/tile_id_gen.dart';
import 'battle_action.dart';
import 'battle_replay.dart';
import 'hero_as_enemy.dart';
import 'pvp_models.dart';

/// Live 1v1: shared board, frozen loadouts, no AI enemy turn.
/// Each action is replayed from the seed so both clients agree.
abstract final class PvpDuelEngine {
  static BattleState replay({
    required PvpMatch match,
    required String viewerUid,
  }) {
    final ids = TileIdGen(1000);
    final board = PuzzleBoard.squarePlayable(
      random: Random(match.seed),
      ids: ids,
    );
    var currentUid = match.uidA;
    var a = _Side.fromHero(match.loadoutA.hero);
    var b = _Side.fromHero(match.loadoutB.hero);
    var liveBoard = board;
    var tileNext = ids.peek;
    final rng = Random(match.seed ^ 0x9e3779b9);

    BattleState buildState(String actorUid, PuzzleBoard currentBoard) {
      final actor = actorUid == match.uidA ? a : b;
      final other = actorUid == match.uidA ? b : a;
      final hero = match.loadoutFor(actorUid).hero;
      final foe = match.opponentLoadout(actorUid).hero;
      return BattleState.initial(
        hero: hero,
        enemy: HeroAsEnemy.fromHero(foe),
        board: currentBoard,
        ids: TileIdGen(tileNext),
        random: rng,
      ).copyWith(
        heroHp: actor.hp,
        enemyHp: other.hp,
        ap: actor.ap,
        resources: actor.resources,
        shield: actor.shield,
        movesLeft: actor.movesLeft,
        movesPerTurn: hero.movesPerTurn,
      );
    }

    var controller = BattleController(
      buildState(currentUid, liveBoard),
      random: rng,
      ids: TileIdGen(tileNext),
    );
    controller.startPlayerTurn(applyInline: true);
    _store(currentUid == match.uidA ? a : b, controller.state);
    liveBoard = controller.state.board;
    tileNext = controller.ids.peek;

    for (final action in match.actionLog) {
      if (controller.state.phase == BattlePhase.victory ||
          controller.state.phase == BattlePhase.defeat) {
        break;
      }
      if (action.actorUid != currentUid &&
          action.type != BattleActionType.forfeit) {
        continue;
      }
      if (action.type == BattleActionType.forfeit) {
        final loserIsViewer = action.actorUid == viewerUid;
        return controller.state.copyWith(
          phase: loserIsViewer ? BattlePhase.defeat : BattlePhase.victory,
        );
      }
      _apply(controller, action);
      liveBoard = controller.state.board;
      tileNext = controller.ids.peek;
      if (currentUid == match.uidA) {
        _store(a, controller.state);
        b.hp = controller.state.enemyHp;
      } else {
        _store(b, controller.state);
        a.hp = controller.state.enemyHp;
      }
      final passTurn = action.type == BattleActionType.endTurn ||
          controller.state.phase == BattlePhase.enemyTurn;
      if (passTurn &&
          controller.state.phase != BattlePhase.victory &&
          controller.state.phase != BattlePhase.defeat) {
        currentUid = currentUid == match.uidA ? match.uidB : match.uidA;
        controller = BattleController(
          buildState(currentUid, liveBoard),
          random: rng,
          ids: TileIdGen(tileNext),
        );
        controller.startPlayerTurn(applyInline: true);
        liveBoard = controller.state.board;
        tileNext = controller.ids.peek;
      }
    }

    if (viewerUid == currentUid) {
      return controller.state;
    }
    return buildState(viewerUid, liveBoard).copyWith(
      phase: BattlePhase.enemyTurn,
      movesLeft: 0,
    );
  }

  static void _apply(BattleController controller, BattleAction action) {
    switch (action.type) {
      case BattleActionType.swap:
        final cascade = controller.peekSwap(action.cellA, action.cellB);
        if (cascade == null) return;
        BattleReplay.applyCascadeInline(controller, cascade);
      case BattleActionType.activate:
        final cascade = controller.beginActivate(action.cellA);
        if (cascade == null) return;
        BattleReplay.applyCascadeInline(controller, cascade);
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
        break;
    }
  }

  static void _store(_Side side, BattleState state) {
    side
      ..hp = state.heroHp
      ..ap = state.ap
      ..shield = state.shield
      ..movesLeft = state.movesLeft
      ..resources = Map<String, int>.from(state.resources);
  }
}

class _Side {
  _Side({
    required this.hp,
    required this.ap,
    required this.shield,
    required this.movesLeft,
    required this.resources,
  });

  factory _Side.fromHero(HeroDef hero) {
    return _Side(
      hp: hero.maxHp,
      ap: 0,
      shield: 0,
      movesLeft: hero.movesPerTurn,
      resources: const {
        'attack': 0,
        'mana': 0,
        'healing': 0,
        'shield': 0,
        'ultimate': 0,
      },
    );
  }

  int hp;
  int ap;
  int shield;
  int movesLeft;
  Map<String, int> resources;
}
