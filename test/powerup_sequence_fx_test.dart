import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/presentation/animated_puzzle_board.dart';
import 'package:mythdusk/features/battle/presentation/board_powerup_fx.dart';
import 'package:mythdusk/features/battle/presentation/powerup_sequence_fx.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/puzzle/domain/board_cell.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_board.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_engine.dart';
import 'package:mythdusk/features/puzzle/domain/tile_color.dart';
import 'package:mythdusk/features/puzzle/domain/tile_id_gen.dart';

PuzzleBoard patternedBoard() => PuzzleBoard(width: 6, height: 6, cells: [
      for (var r = 0; r < 6; r++)
        for (var c = 0; c < 6; c++)
          BoardCell.tile(
              id: r * 6 + c + 1, color: TileColor.values[(r + c * 2) % 5]),
    ]);

CascadeResult creationCascade() {
  var board = patternedBoard();
  for (var c = 0; c < 4; c++) {
    board = board.copyWithCell(
        0, c, BoardCell.tile(id: c + 1, color: TileColor.red));
  }
  return PuzzleEngine.resolveCascade(board,
      random: Random(2), ids: TileIdGen(100));
}

PuzzleBoard creationBoard() {
  var board = patternedBoard();
  for (var c = 0; c < 4; c++) {
    board = board.copyWithCell(
        0, c, BoardCell.tile(id: c + 1, color: TileColor.red));
  }
  return board;
}

CascadeResult combinationCascade(TileSpecial first, TileSpecial second) {
  final board = patternedBoard()
      .copyWithCell(
          2, 2, BoardCell.powerUp(id: 15, special: first, tint: TileColor.red))
      .copyWithCell(2, 3,
          BoardCell.powerUp(id: 16, special: second, tint: TileColor.blue));
  return PuzzleEngine.trySwap(board, (2, 2), (2, 3),
      random: Random(4), ids: TileIdGen(100))!;
}

BattleState initial(PuzzleBoard board) =>
    BattleState.initial(hero: HeroCatalog.mage, board: board);

Widget frame(BattleState battle, {bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Center(
            child: SizedBox(
                width: 240,
                height: 360,
                child: AnimatedPuzzleBoard(battle: battle, onTap: (_, __) {}))),
      ),
    );

void main() {
  test(
      'creation metadata retains the winning shape and surviving tile identity',
      () {
    final step = creationCascade().steps.first;
    expect(step.creationEvents, hasLength(1));
    final creation = step.creationEvents.single;
    expect(creation.special, TileSpecial.rocketVertical);
    expect(creation.sources, {(0, 0), (0, 1), (0, 2), (0, 3)});
    expect(step.clearingCells, isNot(contains(creation.at)));
    final after = step.boardAfterClear.at(creation.at.$1, creation.at.$2);
    expect(after.special, creation.special);
    expect(after.id, creationBoard().at(creation.at.$1, creation.at.$2).id);
  });

  test('disjoint creating shapes retain separate source groups', () {
    var board = creationBoard();
    for (var c = 2; c < 6; c++) {
      board = board.copyWithCell(
          5, c, BoardCell.tile(id: 31 + c, color: TileColor.blue));
    }
    final step = PuzzleEngine.resolveCascade(board,
            random: Random(8), ids: TileIdGen(100))
        .steps
        .first;
    expect(step.creationEvents, hasLength(2));
    expect(
        step.creationEvents.first.sources
            .intersection(step.creationEvents.last.sources),
        isEmpty);
  });

  test('clear metadata survives updates and resets before gravity', () {
    final step = creationCascade().steps.first;
    final controller = BattleController(initial(creationBoard()));
    controller.showClearing(creationBoard(), step.clearingCells, step: step);
    expect(controller.state.activeCascadeStep, same(step));
    expect(controller.state.copyWith(ap: 4).activeCascadeStep, same(step));
    expect(controller.state.boardClearDuration,
        BattleController.powerupClearDuration);
    controller.showHoles(step.boardAfterClear);
    expect(controller.state.activeCascadeStep, isNull);
    expect(controller.state.boardClearDuration, BattleController.clearDuration);
    controller.showClearing(creationBoard(), step.clearingCells, step: step);
    controller.showClearing(creationBoard(), {(0, 0)});
    expect(controller.state.activeCascadeStep, isNull);
  });

  for (final reduceMotion in [false, true]) {
    testWidgets('creation reveal and cleanup, reduced motion=$reduceMotion',
        (tester) async {
      final step = creationCascade().steps.first;
      final battle = initial(creationBoard());
      await tester.pumpWidget(frame(battle, reduceMotion: reduceMotion));
      final clearing = battle.copyWith(
          clearingCells: step.clearingCells,
          activeCascadeStep: step,
          phase: BattlePhase.resolving);
      await tester.pumpWidget(frame(clearing, reduceMotion: reduceMotion));
      expect(find.byType(PowerupCreationFx),
          reduceMotion ? findsNothing : findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      final controller = BattleController(clearing)
        ..showHoles(step.boardAfterClear);
      await tester
          .pumpWidget(frame(controller.state, reduceMotion: reduceMotion));
      expect(find.byType(PowerupCreationFx), findsNothing);
      final cell = step.creationEvents.single.at;
      expect(controller.state.board.at(cell.$1, cell.$2).hasSpecial, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }

  final specials =
      TileSpecial.values.where((s) => s != TileSpecial.none).toList();
  for (var a = 0; a < specials.length; a++) {
    for (var b = a; b < specials.length; b++) {
      final first = specials[a];
      final second = specials[b];
      testWidgets('${first.name} + ${second.name} uses one combo sequence',
          (tester) async {
        final cascade = combinationCascade(first, second);
        final step = cascade.steps.first;
        final combo = step.combination!;
        expect(combo.at, (2, 3));
        expect(combo.partner, (2, 2));
        expect(combo.first, second);
        expect(combo.second, first);
        expect(
            cascade.steps.skip(1).every((s) => s.combination == null), isTrue);
        final battle = initial(cascade.boardAfterSwap!);
        final clearing = battle.copyWith(
            clearingCells: step.clearingCells,
            activeCascadeStep: step,
            phase: BattlePhase.resolving);
        await tester.pumpWidget(frame(battle));
        await tester.pumpWidget(frame(clearing));
        expect(find.byType(PowerupCombinationFx), findsOneWidget);
        // The pair is rendered by the sequence instead of firing twice.
        expect(find.byType(BoardPowerupFx), findsNothing);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.takeException(), isNull);
        final controller = BattleController(clearing)
          ..showHoles(step.boardAfterClear);
        await tester.pumpWidget(frame(controller.state));
        expect(find.byType(PowerupCombinationFx), findsNothing);
        await tester.pumpWidget(frame(clearing, reduceMotion: true));
        expect(find.byType(PowerupCombinationFx), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('leaving during combo charge cancels animation cleanly',
      (tester) async {
    final cascade = combinationCascade(TileSpecial.fireball, TileSpecial.bomb);
    final step = cascade.steps.first;
    await tester.pumpWidget(frame(initial(cascade.boardAfterSwap!)
        .copyWith(clearingCells: step.clearingCells, activeCascadeStep: step)));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
