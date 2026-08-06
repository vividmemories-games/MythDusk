import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/puzzle/domain/board_cell.dart';
import 'package:mythdusk/features/puzzle/domain/overlay_def.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_board.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_engine.dart';
import 'package:mythdusk/features/puzzle/domain/tile_color.dart';
import 'package:mythdusk/features/puzzle/domain/tile_id_gen.dart';

PuzzleBoard _board(List<List<BoardCell>> rows) {
  final height = rows.length;
  final width = rows.first.length;
  return PuzzleBoard(
    width: width,
    height: height,
    cells: [for (final row in rows) ...row],
  );
}

BoardCell _gem(int id, TileColor color) => BoardCell.tile(id: id, color: color);

BoardCell _vine(int id, TileColor color) => BoardCell.tile(
      id: id,
      color: color,
      obstacleLayers: 1,
      overlayId: 'ovl_vine',
      overlayArchetype: OverlayArchetype.binder,
      overlayBreakRule: OverlayBreakRule.matchUnder,
    );

BoardCell _poison(int id, TileColor color) => BoardCell.tile(
      id: id,
      color: color,
      obstacleLayers: 1,
      overlayId: 'ovl_poison',
      overlayArchetype: OverlayArchetype.binder,
      overlayBreakRule: OverlayBreakRule.matchUnder,
      overlayHazard: OverlayHazard.suppressResources,
    );

BoardCell _rock({int layers = 1}) => BoardCell.blocker(
      overlayId: 'ovl_rock',
      layers: layers,
      breakRule: OverlayBreakRule.adjacentMatch,
    );

void main() {
  test('match_under binder breaks when its tile is cleared', () {
    final board = _board([
      [_vine(1, TileColor.red), _gem(2, TileColor.red), _gem(3, TileColor.red)],
      [
        _gem(4, TileColor.blue),
        _gem(5, TileColor.green),
        _gem(6, TileColor.yellow)
      ],
    ]);
    final after = PuzzleEngine.clearCells(board, {(0, 0), (0, 1), (0, 2)});
    expect(after.at(0, 0).hasObstacle, isFalse);
    expect(after.at(0, 0).isEmpty, isTrue);
  });

  test('adjacent_match rock takes one damage per wave when touched', () {
    final board = _board([
      [_gem(1, TileColor.red), _rock(layers: 2), _gem(2, TileColor.blue)],
      [
        _gem(3, TileColor.red),
        _gem(4, TileColor.green),
        _gem(5, TileColor.yellow)
      ],
      [
        _gem(6, TileColor.red),
        _gem(7, TileColor.blue),
        _gem(8, TileColor.green)
      ],
    ]);
    // Clear left column (touches rock once via (0,0) and (1,0) — still 1 dmg).
    final after = PuzzleEngine.clearCells(board, {(0, 0), (1, 0), (2, 0)});
    expect(after.at(0, 1).isSolidObstacle, isTrue);
    expect(after.at(0, 1).obstacleLayers, 1);

    final after2 = PuzzleEngine.clearCells(after, {(0, 2)});
    expect(after2.at(0, 1).hasObstacle, isFalse);
  });

  test('rock not adjacent to clears is untouched', () {
    final board = _board([
      [_gem(1, TileColor.red), _gem(2, TileColor.blue), _rock()],
      [
        _gem(3, TileColor.red),
        _gem(4, TileColor.green),
        _gem(5, TileColor.yellow)
      ],
      [
        _gem(6, TileColor.red),
        _gem(7, TileColor.blue),
        _gem(8, TileColor.green)
      ],
    ]);
    final after = PuzzleEngine.clearCells(board, {(0, 0), (1, 0), (2, 0)});
    expect(after.at(0, 2).obstacleLayers, 1);
  });

  test('poison binder suppresses resource gains but still grants AP', () {
    final board = _board([
      [
        _poison(1, TileColor.red),
        _gem(2, TileColor.red),
        _gem(3, TileColor.red),
      ],
    ]);
    final match = PuzzleEngine.resolveMatches(board, {(0, 0), (0, 1), (0, 2)});
    // Two normal reds + one suppressed poison → 2 attack.
    expect(match.resourceGains['attack'], 2);
    expect(match.apGained, greaterThan(0));
  });

  test('creation cell still applies match_under damage', () {
    final board = _board([
      [_vine(1, TileColor.red), _gem(2, TileColor.red), _gem(3, TileColor.red)],
    ]);
    // Simulate power-up spawn at (0,0): not in clearCells, but in touch set.
    final after = PuzzleEngine.clearCells(
      board,
      {(0, 1), (0, 2)},
      overlayTouchCells: {(0, 0), (0, 1), (0, 2)},
    );
    expect(after.at(0, 0).hasObstacle, isFalse);
    expect(after.at(0, 0).color, TileColor.red); // tile kept for creation
  });

  test('binder shell remains on cell when tile falls away', () {
    final ids = TileIdGen();
    final board = _board([
      [_vine(ids.next(), TileColor.red)],
      [BoardCell.empty()],
    ]);
    final dropped = PuzzleEngine.applyGravity(board);
    expect(dropped.at(0, 0).isBinderObstacle, isTrue);
    expect(dropped.at(0, 0).color, isNull);
    expect(dropped.at(1, 0).isPlayable, isTrue);
    expect(dropped.at(1, 0).hasObstacle, isFalse);
  });
}
