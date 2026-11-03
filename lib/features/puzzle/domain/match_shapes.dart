import 'board_cell.dart';
import 'puzzle_board.dart';
import 'tile_color.dart';

/// A detected same-color formation from the shape catalog.
class DetectedShape {
  const DetectedShape({
    required this.cells,
    required this.color,
    this.creates = TileSpecial.none,
  });

  final Set<(int, int)> cells;
  final TileColor color;
  final TileSpecial creates;

  bool get createsSpecial => creates != TileSpecial.none;
}

/// Spreadsheet shape catalog: lines, 2×2, mix-of-five L / T / plus.
abstract final class MatchShapes {
  static List<DetectedShape> detectAll(PuzzleBoard board) {
    return [
      ..._detectLines(board),
      ..._detectSquares(board),
      ..._detectTemplates(board, _lPentominoes, TileSpecial.seeker),
      ..._detectTemplates(board, _tPentominoes, TileSpecial.bomb),
      ..._detectTemplates(board, _plusShapes, TileSpecial.bomb),
    ];
  }

  static Set<(int, int)> allMatchedCells(PuzzleBoard board) {
    final cells = <(int, int)>{};
    for (final s in detectAll(board)) {
      cells.addAll(s.cells);
    }
    return cells;
  }

  /// Chooses power-up creations for one wave.
  ///
  /// Every disjoint creating shape spawns its own power-up; overlapping
  /// creating shapes (e.g. an L and the 4-line embedded in its arm)
  /// collapse to the highest-ranked one.
  ///
  /// Placement: the power-up appears on the swapped tile that completed
  /// the shape — destination first, then origin. Shapes formed without a
  /// swap (cascade waves) fall back to the shape centroid.
  static List<({(int, int) at, TileSpecial special, Set<(int, int)> sources})>
      pickCreations({
    required List<DetectedShape> shapes,
    (int, int)? swapDestination,
    (int, int)? swapOrigin,
  }) {
    int swapPreference(DetectedShape s) {
      if (swapDestination != null && s.cells.contains(swapDestination)) {
        return 2;
      }
      if (swapOrigin != null && s.cells.contains(swapOrigin)) return 1;
      return 0;
    }

    final creating = shapes.where((s) => s.createsSpecial).toList()
      ..sort((a, b) {
        final rank = b.creates.creationRank.compareTo(a.creates.creationRank);
        if (rank != 0) return rank;
        return swapPreference(b).compareTo(swapPreference(a));
      });
    if (creating.isEmpty) return const [];

    final picks =
        <({(int, int) at, TileSpecial special, Set<(int, int)> sources})>[];
    final claimed = <(int, int)>{};
    for (final shape in creating) {
      if (shape.cells.any(claimed.contains)) continue;
      claimed.addAll(shape.cells);

      final (int, int) at;
      if (swapDestination != null && shape.cells.contains(swapDestination)) {
        at = swapDestination;
      } else if (swapOrigin != null && shape.cells.contains(swapOrigin)) {
        at = swapOrigin;
      } else {
        at = _centroid(shape.cells);
      }
      picks.add((
        at: at,
        special: shape.creates,
        sources: Set.unmodifiable(shape.cells)
      ));
    }
    return picks;
  }

  static (int, int) _centroid(Set<(int, int)> cells) {
    final list = cells.toList()
      ..sort((a, b) {
        final dr = a.$1.compareTo(b.$1);
        return dr != 0 ? dr : a.$2.compareTo(b.$2);
      });
    return list[list.length ~/ 2];
  }

  static List<DetectedShape> _detectLines(PuzzleBoard board) {
    final shapes = <DetectedShape>[];

    for (var row = 0; row < board.height; row++) {
      var runStart = 0;
      TileColor? runColor = board.at(row, 0).matchColor;
      for (var col = 1; col <= board.width; col++) {
        final color = col < board.width ? board.at(row, col).matchColor : null;
        if (color == null || color != runColor) {
          final len = col - runStart;
          if (runColor != null && len >= 3) {
            final cells = <(int, int)>{
              for (var c = runStart; c < col; c++) (row, c),
            };
            shapes.add(
              DetectedShape(
                cells: cells,
                color: runColor,
                creates: len >= 5
                    ? TileSpecial.fireball
                    : len == 4
                        ? TileSpecial.rocketVertical
                        : TileSpecial.none,
              ),
            );
          }
          runColor = color;
          runStart = col;
        }
      }
    }

    for (var col = 0; col < board.width; col++) {
      var runStart = 0;
      TileColor? runColor = board.at(0, col).matchColor;
      for (var row = 1; row <= board.height; row++) {
        final color = row < board.height ? board.at(row, col).matchColor : null;
        if (color == null || color != runColor) {
          final len = row - runStart;
          if (runColor != null && len >= 3) {
            final cells = <(int, int)>{
              for (var r = runStart; r < row; r++) (r, col),
            };
            shapes.add(
              DetectedShape(
                cells: cells,
                color: runColor,
                creates: len >= 5
                    ? TileSpecial.fireball
                    : len == 4
                        ? TileSpecial.rocketHorizontal
                        : TileSpecial.none,
              ),
            );
          }
          runColor = color;
          runStart = row;
        }
      }
    }

    return shapes;
  }

  static List<DetectedShape> _detectSquares(PuzzleBoard board) {
    final shapes = <DetectedShape>[];
    for (var row = 0; row < board.height - 1; row++) {
      for (var col = 0; col < board.width - 1; col++) {
        final c00 = board.at(row, col);
        final c01 = board.at(row, col + 1);
        final c10 = board.at(row + 1, col);
        final c11 = board.at(row + 1, col + 1);
        if (!c00.isMatchable ||
            !c01.isMatchable ||
            !c10.isMatchable ||
            !c11.isMatchable) {
          continue;
        }
        final color = c00.matchColor!;
        if (c01.matchColor == color &&
            c10.matchColor == color &&
            c11.matchColor == color) {
          shapes.add(
            DetectedShape(
              cells: {
                (row, col),
                (row, col + 1),
                (row + 1, col),
                (row + 1, col + 1),
              },
              color: color,
              creates: TileSpecial.bomb,
            ),
          );
        }
      }
    }
    return shapes;
  }

  static List<DetectedShape> _detectTemplates(
    PuzzleBoard board,
    List<List<(int, int)>> templates,
    TileSpecial creates,
  ) {
    final shapes = <DetectedShape>[];
    final seen = <String>{};

    for (var row = 0; row < board.height; row++) {
      for (var col = 0; col < board.width; col++) {
        final origin = board.at(row, col);
        if (!origin.isMatchable) continue;
        final color = origin.matchColor!;

        for (final template in templates) {
          final cells = <(int, int)>{};
          var ok = true;
          for (final offset in template) {
            final r = row + offset.$1;
            final c = col + offset.$2;
            if (!board.inBounds(r, c) ||
                !board.at(r, c).isMatchable ||
                board.at(r, c).matchColor != color) {
              ok = false;
              break;
            }
            cells.add((r, c));
          }
          if (!ok || cells.length != template.length) continue;

          final sorted = cells.toList()
            ..sort((a, b) {
              final dr = a.$1.compareTo(b.$1);
              return dr != 0 ? dr : a.$2.compareTo(b.$2);
            });
          final key = '$creates:${sorted.join('|')}';
          if (!seen.add(key)) continue;

          shapes.add(
            DetectedShape(cells: cells, color: color, creates: creates),
          );
        }
      }
    }
    return shapes;
  }

  static final List<List<(int, int)>> _lPentominoes = _uniqueTemplates([
    for (final base in [
      [(0, 0), (1, 0), (2, 0), (3, 0), (3, 1)],
      [(0, 0), (0, 1), (0, 2), (0, 3), (1, 0)],
    ])
      ..._dihedral(base),
  ]);

  static final List<List<(int, int)>> _tPentominoes = _uniqueTemplates([
    for (final base in [
      [(0, 0), (0, 1), (0, 2), (1, 1), (2, 1)],
    ])
      ..._dihedral(base),
  ]);

  static final List<List<(int, int)>> _plusShapes = [
    [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)],
  ];

  static List<List<(int, int)>> _dihedral(List<(int, int)> cells) {
    final variants = <List<(int, int)>>[];
    var current = List<(int, int)>.from(cells);
    for (var i = 0; i < 4; i++) {
      variants.add(_normalize(current));
      variants.add(
        _normalize([
          for (final c in current) (c.$1, -c.$2),
        ]),
      );
      current = [
        for (final c in current) (c.$2, -c.$1),
      ];
    }
    return variants;
  }

  static List<(int, int)> _normalize(List<(int, int)> cells) {
    final minR = cells.map((c) => c.$1).reduce((a, b) => a < b ? a : b);
    final minC = cells.map((c) => c.$2).reduce((a, b) => a < b ? a : b);
    return [
      for (final c in cells) (c.$1 - minR, c.$2 - minC),
    ];
  }

  static List<List<(int, int)>> _uniqueTemplates(
    List<List<(int, int)>> templates,
  ) {
    final seen = <String>{};
    final out = <List<(int, int)>>[];
    for (final t in templates) {
      final norm = _normalize(t)
        ..sort((a, b) {
          final dr = a.$1.compareTo(b.$1);
          return dr != 0 ? dr : a.$2.compareTo(b.$2);
        });
      final key = norm.join('|');
      if (seen.add(key)) out.add(norm);
    }
    return out;
  }
}
