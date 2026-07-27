import 'dart:math';

import 'board_cell.dart';
import 'puzzle_engine.dart';
import 'tile_color.dart';
import 'tile_id_gen.dart';

/// Immutable rectangular puzzle board.
///
/// Phase 1 uses a filled 6×6 grid. Later levels may use masks / irregular shapes
/// by setting cells to masked.
class PuzzleBoard {
  PuzzleBoard({
    required this.width,
    required this.height,
    required List<BoardCell> cells,
  }) : cells = List.unmodifiable(cells) {
    assert(cells.length == width * height);
  }

  final int width;
  final int height;
  final List<BoardCell> cells;

  static const defaultSize = 6;

  /// Fills a square board with no starting matches.
  factory PuzzleBoard.squareNoMatches({
    int size = defaultSize,
    Random? random,
    TileIdGen? ids,
  }) {
    final rng = random ?? Random();
    final idGen = ids ?? TileIdGen();
    const colors = TileColor.values;
    final cells = List<BoardCell>.filled(size * size, BoardCell.empty());

    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final forbidden = <TileColor>{};

        if (col >= 2) {
          final a = cells[row * size + col - 1].color;
          final b = cells[row * size + col - 2].color;
          if (a != null && a == b) forbidden.add(a);
        }
        if (row >= 2) {
          final a = cells[(row - 1) * size + col].color;
          final b = cells[(row - 2) * size + col].color;
          if (a != null && a == b) forbidden.add(a);
        }
        // Avoid completing a 2×2 square (bottom-right cell of the square).
        if (row > 0 && col > 0) {
          final tl = cells[(row - 1) * size + col - 1].color;
          final tr = cells[(row - 1) * size + col].color;
          final bl = cells[row * size + col - 1].color;
          if (tl != null && tl == tr && tl == bl) forbidden.add(tl);
        }

        final options =
            colors.where((c) => !forbidden.contains(c)).toList(growable: false);
        final pick = options.isEmpty
            ? colors[rng.nextInt(colors.length)]
            : options[rng.nextInt(options.length)];
        cells[row * size + col] = BoardCell.tile(id: idGen.next(), color: pick);
      }
    }

    final board = PuzzleBoard(width: size, height: size, cells: cells);
    assert(
      PuzzleEngine.findMatches(board).isEmpty,
      'squareNoMatches produced a board with matches',
    );
    return board;
  }

  /// No starting matches and at least one valid color swap.
  factory PuzzleBoard.squarePlayable({
    int size = defaultSize,
    Random? random,
    TileIdGen? ids,
    int maxAttempts = 40,
  }) {
    final rng = random ?? Random();
    final idGen = ids ?? TileIdGen();
    PuzzleBoard? last;
    for (var i = 0; i < maxAttempts; i++) {
      final board = PuzzleBoard.squareNoMatches(
        size: size,
        random: rng,
        ids: idGen,
      );
      last = board;
      if (PuzzleEngine.hasColorMove(board, random: rng)) return board;
    }
    return last ??
        PuzzleBoard.squareNoMatches(size: size, random: rng, ids: idGen);
  }

  /// Legacy random fill (may contain matches). Prefer [squareNoMatches].
  factory PuzzleBoard.squareRandom({
    int size = defaultSize,
    Random? random,
    TileIdGen? ids,
  }) {
    final rng = random ?? Random();
    final idGen = ids ?? TileIdGen();
    const colors = TileColor.values;
    final cells = List<BoardCell>.generate(
      size * size,
      (_) => BoardCell.tile(
        id: idGen.next(),
        color: colors[rng.nextInt(colors.length)],
      ),
    );
    return PuzzleBoard(width: size, height: size, cells: cells);
  }

  BoardCell at(int row, int col) => cells[row * width + col];

  bool inBounds(int row, int col) =>
      row >= 0 && row < height && col >= 0 && col < width;

  PuzzleBoard copyWithCell(int row, int col, BoardCell cell) {
    final next = List<BoardCell>.from(cells);
    next[row * width + col] = cell;
    return PuzzleBoard(width: width, height: height, cells: next);
  }

  PuzzleBoard copyWithCells(List<BoardCell> next) {
    return PuzzleBoard(width: width, height: height, cells: next);
  }

  /// Map of tile id → (row, col) for playable tiles.
  Map<int, (int, int)> tilePositions() {
    final map = <int, (int, int)>{};
    for (var row = 0; row < height; row++) {
      for (var col = 0; col < width; col++) {
        final cell = at(row, col);
        final id = cell.id;
        if (id != null && cell.isPlayable) {
          map[id] = (row, col);
        }
      }
    }
    return map;
  }
}
