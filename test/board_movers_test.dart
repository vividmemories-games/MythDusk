import 'package:flutter_test/flutter_test.dart';
import 'package:mythora/features/puzzle/domain/board_cell.dart';
import 'package:mythora/features/puzzle/domain/board_movers.dart';
import 'package:mythora/features/puzzle/domain/level_board_config.dart';
import 'package:mythora/features/puzzle/domain/overlay_def.dart';
import 'package:mythora/features/puzzle/domain/puzzle_board.dart';
import 'package:mythora/features/puzzle/domain/tile_color.dart';

PuzzleBoard _rowBoard(List<BoardCell> row) {
  return PuzzleBoard(width: row.length, height: 1, cells: row);
}

BoardCell _g(int id, TileColor c) => BoardCell.tile(id: id, color: c);

void main() {
  test('row_shove left wraps the full open row', () {
    final board = _rowBoard([
      _g(1, TileColor.red),
      _g(2, TileColor.blue),
      _g(3, TileColor.green),
    ]);
    final after = BoardMovers.applyOne(
      board,
      const BoardMoverConfig(
        type: 'row_shove',
        rows: [0],
        direction: 'left',
      ),
    );
    expect(after.at(0, 0).id, 2);
    expect(after.at(0, 1).id, 3);
    expect(after.at(0, 2).id, 1);
  });

  test('row_shove right wraps the opposite way', () {
    final board = _rowBoard([
      _g(1, TileColor.red),
      _g(2, TileColor.blue),
      _g(3, TileColor.green),
    ]);
    final after = BoardMovers.applyOne(
      board,
      const BoardMoverConfig(
        type: 'row_shove',
        rows: [0],
        direction: 'right',
      ),
    );
    expect(after.at(0, 0).id, 3);
    expect(after.at(0, 1).id, 1);
    expect(after.at(0, 2).id, 2);
  });

  test('solid blockers split wrap segments', () {
    final board = _rowBoard([
      _g(1, TileColor.red),
      _g(2, TileColor.blue),
      BoardCell.blocker(overlayId: 'ovl_rock', layers: 1),
      _g(3, TileColor.green),
      _g(4, TileColor.yellow),
    ]);
    final after = BoardMovers.applyOne(
      board,
      const BoardMoverConfig(
        type: 'row_shove',
        rows: [0],
        direction: 'left',
      ),
    );
    expect(after.at(0, 0).id, 2);
    expect(after.at(0, 1).id, 1);
    expect(after.at(0, 2).isSolidObstacle, isTrue);
    expect(after.at(0, 3).id, 4);
    expect(after.at(0, 4).id, 3);
  });

  test('binder overlay stays on cell while tile wraps away', () {
    final board = _rowBoard([
      BoardCell.tile(
        id: 1,
        color: TileColor.red,
        obstacleLayers: 1,
        overlayId: 'ovl_vine',
        overlayArchetype: OverlayArchetype.binder,
        overlayBreakRule: OverlayBreakRule.matchUnder,
      ),
      _g(2, TileColor.blue),
    ]);
    final after = BoardMovers.applyOne(
      board,
      const BoardMoverConfig(
        type: 'row_shove',
        rows: [0],
        direction: 'left',
      ),
    );
    // Tile 2 moved onto cell 0 — vine stays on cell 0.
    expect(after.at(0, 0).id, 2);
    expect(after.at(0, 0).isBinderObstacle, isTrue);
    expect(after.at(0, 0).overlayId, 'ovl_vine');
    // Tile 1 moved to cell 1 without vine.
    expect(after.at(0, 1).id, 1);
    expect(after.at(0, 1).hasObstacle, isFalse);
  });

  test('everyNTurns gates application', () {
    final board = _rowBoard([
      _g(1, TileColor.red),
      _g(2, TileColor.blue),
    ]);
    final movers = [
      const BoardMoverConfig(
        type: 'row_shove',
        rows: [0],
        direction: 'left',
        everyNTurns: 2,
      ),
    ];
    final turn1 = BoardMovers.applyForTurn(
      board,
      movers,
      playerTurnNumber: 1,
    );
    expect(turn1.at(0, 0).id, 2); // due on turn 1
    final turn2 = BoardMovers.applyForTurn(
      turn1,
      movers,
      playerTurnNumber: 2,
    );
    expect(turn2.at(0, 0).id, 2); // not due
    final turn3 = BoardMovers.applyForTurn(
      turn2,
      movers,
      playerTurnNumber: 3,
    );
    expect(turn3.at(0, 0).id, 1); // due again
  });

  test('col_shove up wraps a column', () {
    final board = PuzzleBoard(
      width: 1,
      height: 3,
      cells: [
        _g(1, TileColor.red),
        _g(2, TileColor.blue),
        _g(3, TileColor.green),
      ],
    );
    final after = BoardMovers.applyOne(
      board,
      const BoardMoverConfig(
        type: 'col_shove',
        cols: [0],
        direction: 'up',
      ),
    );
    expect(after.at(0, 0).id, 2);
    expect(after.at(1, 0).id, 3);
    expect(after.at(2, 0).id, 1);
  });
}
