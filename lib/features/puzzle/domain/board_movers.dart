import 'board_cell.dart';
import 'level_board_config.dart';
import 'puzzle_board.dart';
import 'tile_color.dart';

/// Applies scheduled board movers (wind / shove) with wrap-around.
///
/// Solid blockers and masked cells are anchors — tiles wrap in segments
/// between them. Binder overlays stay on their cells; only tile payloads move.
abstract final class BoardMovers {
  /// Applies every mover due on [playerTurnNumber] (1-based).
  static PuzzleBoard applyForTurn(
    PuzzleBoard board,
    List<BoardMoverConfig> movers, {
    required int playerTurnNumber,
  }) {
    if (movers.isEmpty || playerTurnNumber < 1) return board;
    var next = board;
    for (final mover in movers) {
      if (!_isDue(mover, playerTurnNumber)) continue;
      next = applyOne(next, mover);
    }
    return next;
  }

  static bool _isDue(BoardMoverConfig mover, int playerTurnNumber) {
    final every = mover.everyNTurns < 1 ? 1 : mover.everyNTurns;
    return (playerTurnNumber - 1) % every == 0;
  }

  static PuzzleBoard applyOne(PuzzleBoard board, BoardMoverConfig mover) {
    return switch (mover.type) {
      'row_shove' => _shoveRows(board, mover.rows, mover.direction),
      'col_shove' => _shoveCols(board, mover.cols, mover.direction),
      _ => board,
    };
  }

  static PuzzleBoard _shoveRows(
    PuzzleBoard board,
    List<int> rows,
    String direction,
  ) {
    var next = board;
    final towardStart = direction == 'left' || direction == 'up';
    for (final row in rows) {
      if (row < 0 || row >= board.height) continue;
      next = _rotateLine(
        next,
        positions: [
          for (var col = 0; col < board.width; col++) (row, col),
        ],
        towardStart: towardStart,
      );
    }
    return next;
  }

  static PuzzleBoard _shoveCols(
    PuzzleBoard board,
    List<int> cols,
    String direction,
  ) {
    var next = board;
    final towardStart = direction == 'up' || direction == 'left';
    for (final col in cols) {
      if (col < 0 || col >= board.width) continue;
      next = _rotateLine(
        next,
        positions: [
          for (var row = 0; row < board.height; row++) (row, col),
        ],
        towardStart: towardStart,
      );
    }
    return next;
  }

  /// Rotates tile payloads along [positions], wrapping within segments split
  /// by masked / solid-blocker anchors.
  static PuzzleBoard _rotateLine(
    PuzzleBoard board, {
    required List<(int, int)> positions,
    required bool towardStart,
  }) {
    final cells = List<BoardCell>.from(board.cells);
    var segment = <(int, int)>[];

    void flush() {
      if (segment.length < 2) {
        segment = [];
        return;
      }
      final payloads = [
        for (final p in segment) _TilePayload.from(board.at(p.$1, p.$2)),
      ];
      final rotated = towardStart
          ? [...payloads.skip(1), payloads.first]
          : [payloads.last, ...payloads.take(payloads.length - 1)];
      for (var i = 0; i < segment.length; i++) {
        final (r, c) = segment[i];
        final idx = r * board.width + c;
        cells[idx] = rotated[i].applyOnto(cells[idx]);
      }
      segment = [];
    }

    for (final pos in positions) {
      final cell = board.at(pos.$1, pos.$2);
      if (cell.masked || cell.isSolidObstacle) {
        flush();
        continue;
      }
      segment.add(pos);
    }
    flush();

    return PuzzleBoard(width: board.width, height: board.height, cells: cells);
  }
}

/// Tile identity that moves; overlays stay on the geometric cell.
class _TilePayload {
  const _TilePayload({
    this.id,
    this.color,
    this.special = TileSpecial.none,
  });

  final int? id;
  final TileColor? color;
  final TileSpecial special;

  factory _TilePayload.from(BoardCell cell) => _TilePayload(
        id: cell.id,
        color: cell.color,
        special: cell.special,
      );

  BoardCell applyOnto(BoardCell cell) {
    final overlayLayers = cell.obstacleLayers;
    final overlayId = cell.overlayId;
    final archetype = cell.overlayArchetype;
    final breakRule = cell.overlayBreakRule;
    final hazard = cell.overlayHazard;
    final masked = cell.masked;

    if (special != TileSpecial.none && id != null) {
      return BoardCell(
        id: id,
        color: color,
        special: special,
        masked: masked,
        obstacleLayers: overlayLayers,
        overlayId: overlayId,
        overlayArchetype: archetype,
        overlayBreakRule: breakRule,
        overlayHazard: hazard,
      );
    }
    if (id != null && color != null) {
      return BoardCell(
        id: id,
        color: color,
        masked: masked,
        obstacleLayers: overlayLayers,
        overlayId: overlayId,
        overlayArchetype: archetype,
        overlayBreakRule: breakRule,
        overlayHazard: hazard,
      );
    }
    return BoardCell(
      masked: masked,
      obstacleLayers: overlayLayers,
      overlayId: overlayId,
      overlayArchetype: archetype,
      overlayBreakRule: breakRule,
      overlayHazard: hazard,
    );
  }
}
