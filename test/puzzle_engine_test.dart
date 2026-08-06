import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/puzzle/domain/board_cell.dart';
import 'package:mythdusk/features/puzzle/domain/match_shapes.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_board.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_engine.dart';
import 'package:mythdusk/features/puzzle/domain/tile_color.dart';
import 'package:mythdusk/features/puzzle/domain/tile_id_gen.dart';

PuzzleBoard _board(int w, int h, List<TileColor?> colors, {TileIdGen? ids}) {
  final idGen = ids ?? TileIdGen();
  assert(colors.length == w * h);
  final cells = <BoardCell>[];
  for (final color in colors) {
    if (color == null) {
      cells.add(BoardCell.empty());
    } else {
      cells.add(BoardCell.tile(id: idGen.next(), color: color));
    }
  }
  return PuzzleBoard(width: w, height: h, cells: cells);
}

void main() {
  test('finds horizontal match of three', () {
    final ids = TileIdGen();
    final cells = List<BoardCell>.generate(
      36,
      (_) => BoardCell.tile(id: ids.next(), color: TileColor.blue),
    );
    // Break blue lines — paint a safe pattern then red run
    for (var i = 0; i < 36; i++) {
      cells[i] = BoardCell.tile(
        id: ids.next(),
        color: TileColor.values[i % 5],
      );
    }
    cells[0] = BoardCell.tile(id: ids.next(), color: TileColor.red);
    cells[1] = BoardCell.tile(id: ids.next(), color: TileColor.red);
    cells[2] = BoardCell.tile(id: ids.next(), color: TileColor.red);

    final board = PuzzleBoard(width: 6, height: 6, cells: cells);
    final matches = PuzzleEngine.findMatches(board);
    expect(matches.contains((0, 0)), isTrue);
    expect(matches.contains((0, 1)), isTrue);
    expect(matches.contains((0, 2)), isTrue);
  });

  test('squareNoMatches starts with zero catalog matches', () {
    for (var seed = 0; seed < 40; seed++) {
      final board = PuzzleBoard.squareNoMatches(random: Random(seed));
      expect(
        MatchShapes.detectAll(board),
        isEmpty,
        reason: 'seed $seed produced shapes',
      );
    }
  });

  test('applyGravity drops tiles and leaves empties on top', () {
    final ids = TileIdGen();
    final cells = [
      BoardCell.empty(),
      BoardCell.tile(id: ids.next(), color: TileColor.green),
      BoardCell.tile(id: ids.next(), color: TileColor.yellow),
      BoardCell.tile(id: ids.next(), color: TileColor.red),
      BoardCell.tile(id: ids.next(), color: TileColor.green),
      BoardCell.tile(id: ids.next(), color: TileColor.yellow),
      BoardCell.tile(id: ids.next(), color: TileColor.blue),
      BoardCell.tile(id: ids.next(), color: TileColor.green),
      BoardCell.tile(id: ids.next(), color: TileColor.yellow),
    ];
    final board = PuzzleBoard(width: 3, height: 3, cells: cells);
    final dropped = PuzzleEngine.applyGravity(board);
    expect(dropped.at(0, 0).isEmpty, isTrue);
    expect(dropped.at(1, 0).color, TileColor.red);
    expect(dropped.at(2, 0).color, TileColor.blue);
  });

  test('H4 creates vertical rocket at swap destination', () {
    final ids = TileIdGen();
    // After swapping (1,3)→(0,3): row0 becomes R R R R G
    final board = _board(
        5,
        3,
        [
          TileColor.red,
          TileColor.red,
          TileColor.red,
          TileColor.blue,
          TileColor.green,
          TileColor.yellow,
          TileColor.purple,
          TileColor.blue,
          TileColor.red,
          TileColor.yellow,
          TileColor.purple,
          TileColor.blue,
          TileColor.green,
          TileColor.yellow,
          TileColor.purple,
        ],
        ids: ids);

    final cascade = PuzzleEngine.trySwap(
      board,
      (1, 3),
      (0, 3),
      random: Random(1),
      ids: ids,
    );
    expect(cascade, isNotNull);
    expect(cascade!.totals.rocketsCreated, greaterThanOrEqualTo(1));
    final after = cascade.steps.first.boardAfterClear;
    expect(after.at(0, 3).special, TileSpecial.rocketVertical);
  });

  test('2x2 square creates bomb', () {
    final ids = TileIdGen();
    final board = _board(
        3,
        3,
        [
          TileColor.red,
          TileColor.red,
          TileColor.blue,
          TileColor.red,
          TileColor.red,
          TileColor.green,
          TileColor.yellow,
          TileColor.purple,
          TileColor.blue,
        ],
        ids: ids);
    final plan = PuzzleEngine.planWave(board, random: Random(0));
    expect(plan.creations.values, contains(TileSpecial.bomb));
    expect(plan.match.bombsCreated, 1);
  });

  test('H5 creates fireball', () {
    final ids = TileIdGen();
    final board = _board(
        5,
        3,
        [
          TileColor.red,
          TileColor.red,
          TileColor.red,
          TileColor.red,
          TileColor.red,
          TileColor.blue,
          TileColor.green,
          TileColor.yellow,
          TileColor.purple,
          TileColor.blue,
          TileColor.green,
          TileColor.yellow,
          TileColor.purple,
          TileColor.blue,
          TileColor.green,
        ],
        ids: ids);
    final plan = PuzzleEngine.planWave(
      board,
      swapDestination: (0, 2),
      random: Random(0),
    );
    expect(plan.creations[(0, 2)], TileSpecial.fireball);
  });

  test('L pentomino creates seeker', () {
    final ids = TileIdGen();
    // L: column of 4 red + one to the right at bottom
    final board = _board(
        4,
        4,
        [
          TileColor.red,
          TileColor.blue,
          TileColor.green,
          TileColor.yellow,
          TileColor.red,
          TileColor.yellow,
          TileColor.purple,
          TileColor.blue,
          TileColor.red,
          TileColor.green,
          TileColor.blue,
          TileColor.purple,
          TileColor.red,
          TileColor.red,
          TileColor.yellow,
          TileColor.green,
        ],
        ids: ids);
    final shapes = MatchShapes.detectAll(board);
    expect(
      shapes.any((s) => s.creates == TileSpecial.seeker),
      isTrue,
      reason: 'expected L → seeker, got ${shapes.map((s) => s.creates)}',
    );
  });

  test('plus shape creates bomb', () {
    final ids = TileIdGen();
    final board = _board(
        3,
        3,
        [
          TileColor.blue,
          TileColor.red,
          TileColor.green,
          TileColor.red,
          TileColor.red,
          TileColor.red,
          TileColor.yellow,
          TileColor.red,
          TileColor.purple,
        ],
        ids: ids);
    final shapes = MatchShapes.detectAll(board);
    expect(shapes.any((s) => s.creates == TileSpecial.bomb), isTrue);
  });

  test('fireball swap clears that color', () {
    final ids = TileIdGen();
    final cells = List<BoardCell>.generate(
      16,
      (i) => BoardCell.tile(
        id: ids.next(),
        color: TileColor.values[i % 5],
      ),
    );
    cells[0] = BoardCell.powerUp(
      id: ids.next(),
      special: TileSpecial.fireball,
      tint: TileColor.red,
    );
    cells[1] = BoardCell.tile(id: ids.next(), color: TileColor.blue);
    cells[5] = BoardCell.tile(id: ids.next(), color: TileColor.blue);
    cells[10] = BoardCell.tile(id: ids.next(), color: TileColor.blue);
    final board = PuzzleBoard(width: 4, height: 4, cells: cells);

    final cascade = PuzzleEngine.trySwap(
      board,
      (0, 0),
      (0, 1),
      random: Random(3),
      ids: ids,
    );
    expect(cascade, isNotNull);
    expect(cascade!.steps.first.match.mergeLabel, 'Fireball → blue');
    final cleared = cascade.steps.first.clearingCells;
    expect(cleared.contains((0, 1)), isTrue);
    expect(cleared.contains((1, 1)), isTrue); // blue at (1,1) = index 5
    expect(cleared.contains((2, 2)), isTrue); // blue at (2,2) = index 10
  });

  test('fireball tap clears a random color', () {
    final ids = TileIdGen();
    final cells = List<BoardCell>.generate(
      16,
      (i) => BoardCell.tile(id: ids.next(), color: TileColor.green),
    );
    cells[0] = BoardCell.powerUp(
      id: ids.next(),
      special: TileSpecial.fireball,
    );
    cells[1] = BoardCell.tile(id: ids.next(), color: TileColor.red);
    cells[2] = BoardCell.tile(id: ids.next(), color: TileColor.red);
    cells[5] = BoardCell.tile(id: ids.next(), color: TileColor.blue);
    final board = PuzzleBoard(width: 4, height: 4, cells: cells);

    final cascade = PuzzleEngine.activateSpecial(
      board,
      (0, 0),
      random: Random(7),
      ids: ids,
    );
    expect(cascade, isNotNull);
    expect(
      cascade!.steps.first.match.mergeLabel,
      startsWith('Fireball (random '),
    );
    expect(cascade.steps.first.clearingCells.contains((0, 0)), isTrue);
  });

  test('fireball chains power-ups of the cleared color', () {
    final ids = TileIdGen();
    final cells = List<BoardCell>.generate(
      16,
      (i) => BoardCell.tile(id: ids.next(), color: TileColor.yellow),
    );
    cells[0] = BoardCell.powerUp(
      id: ids.next(),
      special: TileSpecial.fireball,
    );
    // Vertical rocket tinted blue — fireball swap onto blue should chain it.
    cells[1] = BoardCell.tile(id: ids.next(), color: TileColor.blue);
    cells[5] = BoardCell.powerUp(
      id: ids.next(),
      special: TileSpecial.rocketVertical,
      tint: TileColor.blue,
    );
    final board = PuzzleBoard(width: 4, height: 4, cells: cells);

    final cascade = PuzzleEngine.trySwap(
      board,
      (0, 0),
      (0, 1),
      random: Random(1),
      ids: ids,
    );
    expect(cascade, isNotNull);
    final cleared = cascade!.steps.first.clearingCells;
    // Rocket at (1,1) fires → entire column 1.
    expect(cleared.contains((1, 1)), isTrue);
    expect(cleared.contains((2, 1)), isTrue);
    expect(cleared.contains((3, 1)), isTrue);
  });

  test('power-up activates when swapped with any adjacent color', () {
    final ids = TileIdGen();
    final cells = List<BoardCell>.generate(
      9,
      (i) => BoardCell.tile(id: ids.next(), color: TileColor.values[i % 5]),
    );
    cells[0] = BoardCell.powerUp(
      id: ids.next(),
      special: TileSpecial.rocketHorizontal,
      tint: TileColor.red,
    );
    cells[1] = BoardCell.tile(id: ids.next(), color: TileColor.green);
    final board = PuzzleBoard(width: 3, height: 3, cells: cells);

    final cascade = PuzzleEngine.trySwap(
      board,
      (0, 0),
      (0, 1),
      random: Random(0),
      ids: ids,
    );
    expect(cascade, isNotNull);
    // Horizontal rocket clears its row.
    expect(cascade!.steps.first.clearingCells.contains((0, 0)), isTrue);
    expect(cascade.steps.first.clearingCells.contains((0, 1)), isTrue);
    expect(cascade.steps.first.clearingCells.contains((0, 2)), isTrue);
  });

  test('power-ups do not form color matches', () {
    final ids = TileIdGen();
    final cells = [
      BoardCell.powerUp(
        id: ids.next(),
        special: TileSpecial.bomb,
        tint: TileColor.red,
      ),
      BoardCell.tile(id: ids.next(), color: TileColor.red),
      BoardCell.tile(id: ids.next(), color: TileColor.red),
      BoardCell.tile(id: ids.next(), color: TileColor.blue),
      BoardCell.tile(id: ids.next(), color: TileColor.green),
      BoardCell.tile(id: ids.next(), color: TileColor.yellow),
      BoardCell.tile(id: ids.next(), color: TileColor.purple),
      BoardCell.tile(id: ids.next(), color: TileColor.blue),
      BoardCell.tile(id: ids.next(), color: TileColor.green),
    ];
    final board = PuzzleBoard(width: 3, height: 3, cells: cells);
    expect(MatchShapes.detectAll(board), isEmpty);
  });

  test('V-rocket + bomb and H-rocket + bomb both use fat 3x3 cross', () {
    final ids = TileIdGen();
    final cells = List<BoardCell>.generate(
      36,
      (i) => BoardCell.tile(id: ids.next(), color: TileColor.values[i % 5]),
    );
    final board = PuzzleBoard(width: 6, height: 6, cells: cells);
    const dest = (2, 2);
    final withV = PuzzleEngine.mergeBlast(
      board: board,
      dest: dest,
      a: TileSpecial.rocketVertical,
      colorA: TileColor.red,
      b: TileSpecial.bomb,
      colorB: TileColor.blue,
      random: Random(0),
    );
    final withH = PuzzleEngine.mergeBlast(
      board: board,
      dest: dest,
      a: TileSpecial.rocketHorizontal,
      colorA: TileColor.red,
      b: TileSpecial.bomb,
      colorB: TileColor.blue,
      random: Random(0),
    );
    expect(withV, withH);
    expect(withV, PuzzleEngine.fatCrossBlast(board, dest));
    // 3 full rows + 3 full cols on 6×6 = 3*6 + 3*6 - 9 overlap = 27
    expect(withV.length, 27);
  });

  test('rocket + rocket merge clears two rows and two cols', () {
    final ids = TileIdGen();
    final cells = List<BoardCell>.generate(
      16,
      (i) => BoardCell.tile(id: ids.next(), color: TileColor.values[i % 5]),
    );
    cells[5] = BoardCell.tile(
      id: ids.next(),
      color: TileColor.red,
      special: TileSpecial.rocketVertical,
    );
    cells[6] = BoardCell.tile(
      id: ids.next(),
      color: TileColor.blue,
      special: TileSpecial.rocketHorizontal,
    );
    final board = PuzzleBoard(width: 4, height: 4, cells: cells);
    final cascade = PuzzleEngine.trySwap(
      board,
      (1, 1),
      (1, 2),
      random: Random(4),
      ids: ids,
    );
    expect(cascade, isNotNull);
    expect(cascade!.steps.first.clearingCells.length, greaterThan(4));
  });

  test('bomb + bomb merge uses 4x4 blast', () {
    final ids = TileIdGen();
    final cells = List<BoardCell>.generate(
      16,
      (i) => BoardCell.tile(id: ids.next(), color: TileColor.values[i % 5]),
    );
    cells[5] = BoardCell.tile(
      id: ids.next(),
      color: TileColor.red,
      special: TileSpecial.bomb,
    );
    cells[6] = BoardCell.tile(
      id: ids.next(),
      color: TileColor.blue,
      special: TileSpecial.bomb,
    );
    final board = PuzzleBoard(width: 4, height: 4, cells: cells);
    final clear = PuzzleEngine.mergeBlast(
      board: board,
      dest: (1, 2),
      a: TileSpecial.bomb,
      colorA: TileColor.red,
      b: TileSpecial.bomb,
      colorB: TileColor.blue,
      random: Random(0),
    );
    expect(clear.length, greaterThanOrEqualTo(9));
  });

  test('seeker blast clears eight cells including self', () {
    final board = PuzzleBoard.squareNoMatches(random: Random(9));
    final clear = PuzzleEngine.seekerBlast(
      board,
      (2, 2),
      random: Random(1),
      count: 8,
    );
    expect(clear.contains((2, 2)), isTrue);
    expect(clear.length, 8);
  });

  test('power-up spawns at swap origin when that tile completed the shape', () {
    final ids = TileIdGen();
    // Selecting (0,1) and tapping (1,1) pulls the red up into row 0,
    // completing an H4 through the origin cell (0,1).
    final board = _board(
        4,
        3,
        [
          TileColor.red, TileColor.blue, TileColor.red, TileColor.red, //
          TileColor.green, TileColor.red, TileColor.yellow, TileColor.purple,
          TileColor.yellow, TileColor.purple, TileColor.green, TileColor.blue,
        ],
        ids: ids);
    expect(MatchShapes.detectAll(board), isEmpty);

    final cascade = PuzzleEngine.trySwap(
      board,
      (0, 1),
      (1, 1),
      random: Random(0),
      ids: ids,
    );
    expect(cascade, isNotNull);
    expect(cascade!.totals.rocketsCreated, 1);
    final after = cascade.steps.first.boardAfterClear;
    expect(after.at(0, 1).special, TileSpecial.rocketVertical);
  });

  test('one swap completing two shapes creates both power-ups', () {
    final ids = TileIdGen();
    // Swapping (2,1)<->(2,2) completes a V4 of blue in col 1 (through the
    // origin) and a V4 of red in col 2 (through the destination).
    final board = _board(
        4,
        4,
        [
          TileColor.green, TileColor.blue, TileColor.red, TileColor.yellow, //
          TileColor.purple, TileColor.blue, TileColor.red, TileColor.green,
          TileColor.yellow, TileColor.red, TileColor.blue, TileColor.purple,
          TileColor.green, TileColor.blue, TileColor.red, TileColor.yellow,
        ],
        ids: ids);
    expect(MatchShapes.detectAll(board), isEmpty);

    final cascade = PuzzleEngine.trySwap(
      board,
      (2, 1),
      (2, 2),
      random: Random(0),
      ids: ids,
    );
    expect(cascade, isNotNull);
    expect(cascade!.totals.rocketsCreated, 2);
    final after = cascade.steps.first.boardAfterClear;
    expect(after.at(2, 1).special, TileSpecial.rocketHorizontal);
    expect(after.at(2, 2).special, TileSpecial.rocketHorizontal);
  });

  test('L shape and its embedded 4-line collapse to a single seeker', () {
    final ids = TileIdGen();
    // Formed L: col 0 rows 0-3 + (3,1). The vertical arm alone would be a
    // rocket shape; only the higher-ranked seeker must be created.
    final board = _board(
        4,
        4,
        [
          TileColor.red, TileColor.blue, TileColor.green, TileColor.yellow, //
          TileColor.red, TileColor.yellow, TileColor.purple, TileColor.blue,
          TileColor.red, TileColor.green, TileColor.blue, TileColor.purple,
          TileColor.red, TileColor.red, TileColor.yellow, TileColor.green,
        ],
        ids: ids);
    final plan = PuzzleEngine.planWave(board, random: Random(0));
    expect(plan.creations.length, 1);
    expect(plan.creations.values.single, TileSpecial.seeker);
  });

  test('trySwap rejects non-matching adjacent swap', () {
    final ids = TileIdGen();
    final cells = [
      BoardCell.tile(id: ids.next(), color: TileColor.red),
      BoardCell.tile(id: ids.next(), color: TileColor.green),
      BoardCell.tile(id: ids.next(), color: TileColor.blue),
      BoardCell.tile(id: ids.next(), color: TileColor.green),
      BoardCell.tile(id: ids.next(), color: TileColor.yellow),
      BoardCell.tile(id: ids.next(), color: TileColor.red),
      BoardCell.tile(id: ids.next(), color: TileColor.blue),
      BoardCell.tile(id: ids.next(), color: TileColor.red),
      BoardCell.tile(id: ids.next(), color: TileColor.yellow),
    ];
    final board = PuzzleBoard(width: 3, height: 3, cells: cells);
    expect(PuzzleEngine.findMatches(board), isEmpty);
    final cascade = PuzzleEngine.trySwap(
      board,
      (0, 1),
      (1, 1),
      random: Random(0),
      ids: ids,
    );
    expect(cascade, isNull);
  });

  test('findFirstColorSwap returns first valid color move', () {
    // Swap (0,1)↔(1,1) forms a horizontal red match on row 0.
    final board = _board(3, 3, [
      TileColor.red, TileColor.green, TileColor.red, //
      TileColor.green, TileColor.red, TileColor.blue,
      TileColor.blue, TileColor.yellow, TileColor.green,
    ]);
    expect(PuzzleEngine.findMatches(board), isEmpty);
    final swap = PuzzleEngine.findFirstColorSwap(board);
    expect(swap, isNotNull);
    expect(swap!.$1, (0, 1));
    expect(swap.$2, (1, 1));
    expect(PuzzleEngine.hasColorMove(board), isTrue);
  });

  test('findFirstColorSwap ignores power-up cells', () {
    final ids = TileIdGen();
    // Same geometry, but (1,1) is a bomb so the color move is unavailable.
    final cells = [
      BoardCell.tile(id: ids.next(), color: TileColor.red),
      BoardCell.tile(id: ids.next(), color: TileColor.green),
      BoardCell.tile(id: ids.next(), color: TileColor.red),
      BoardCell.tile(id: ids.next(), color: TileColor.green),
      BoardCell.powerUp(
        id: ids.next(),
        special: TileSpecial.bomb,
        tint: TileColor.red,
      ),
      BoardCell.tile(id: ids.next(), color: TileColor.blue),
      BoardCell.tile(id: ids.next(), color: TileColor.blue),
      BoardCell.tile(id: ids.next(), color: TileColor.yellow),
      BoardCell.tile(id: ids.next(), color: TileColor.green),
    ];
    final board = PuzzleBoard(width: 3, height: 3, cells: cells);
    final swap = PuzzleEngine.findFirstColorSwap(board);
    if (swap != null) {
      expect(board.at(swap.$1.$1, swap.$1.$2).isMatchable, isTrue);
      expect(board.at(swap.$2.$1, swap.$2.$2).isMatchable, isTrue);
      expect(
        {swap.$1, swap.$2}.contains((1, 1)),
        isFalse,
        reason: 'hint must not involve a power-up cell',
      );
    }
  });

  test('reshuffleKeepingSpecials preserves power-ups and creates a move', () {
    final ids = TileIdGen();
    final random = Random(42);
    var board = PuzzleBoard.squarePlayable(random: random, ids: ids);
    // Plant two power-ups at fixed cells.
    final cells = List<BoardCell>.from(board.cells);
    cells[0] = BoardCell.powerUp(
      id: 9001,
      special: TileSpecial.bomb,
      tint: TileColor.red,
    );
    cells[board.width + 2] = BoardCell.powerUp(
      id: 9002,
      special: TileSpecial.rocketVertical,
      tint: TileColor.blue,
    );
    board = PuzzleBoard(
      width: board.width,
      height: board.height,
      cells: cells,
    );

    final next = PuzzleEngine.reshuffleKeepingSpecials(
      board,
      random: Random(7),
      ids: ids,
    );

    expect(next.at(0, 0).special, TileSpecial.bomb);
    expect(next.at(0, 0).id, 9001);
    expect(next.at(1, 2).special, TileSpecial.rocketVertical);
    expect(next.at(1, 2).id, 9002);
    expect(PuzzleEngine.findMatches(next), isEmpty);
    expect(PuzzleEngine.hasColorMove(next, random: Random(7)), isTrue);
  });
}
