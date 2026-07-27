import 'dart:math';

import 'board_cell.dart';
import 'match_balance.dart';
import 'match_shapes.dart';
import 'overlay_def.dart';
import 'puzzle_board.dart';
import 'tile_color.dart';
import 'tile_id_gen.dart';
import 'tile_spawn_weights.dart';

/// Result of resolving matches / blasts on the board.
class MatchResult {
  const MatchResult({
    required this.matchedCells,
    required this.resourceGains,
    required this.apGained,
    this.rocketsCreated = 0,
    this.bombsCreated = 0,
    this.fireballsCreated = 0,
    this.seekersCreated = 0,
    this.mergeLabel,
  });

  final Set<(int, int)> matchedCells;
  final Map<String, int> resourceGains;
  final int apGained;
  final int rocketsCreated;
  final int bombsCreated;
  final int fireballsCreated;
  final int seekersCreated;
  final String? mergeLabel;

  static const empty = MatchResult(
    matchedCells: {},
    resourceGains: {},
    apGained: 0,
  );

  MatchResult merge(MatchResult other) {
    final gains = Map<String, int>.from(resourceGains);
    other.resourceGains.forEach((key, value) {
      gains[key] = (gains[key] ?? 0) + value;
    });
    return MatchResult(
      matchedCells: {...matchedCells, ...other.matchedCells},
      resourceGains: gains,
      apGained: apGained + other.apGained,
      rocketsCreated: rocketsCreated + other.rocketsCreated,
      bombsCreated: bombsCreated + other.bombsCreated,
      fireballsCreated: fireballsCreated + other.fireballsCreated,
      seekersCreated: seekersCreated + other.seekersCreated,
      mergeLabel: mergeLabel ?? other.mergeLabel,
    );
  }
}

/// Planned clear + special creation for one cascade wave.
class WavePlan {
  const WavePlan({
    required this.clearCells,
    required this.creations,
    required this.match,
  });

  final Set<(int, int)> clearCells;
  final Map<(int, int), TileSpecial> creations;
  final MatchResult match;

  bool get isEmpty => clearCells.isEmpty && creations.isEmpty;

  static const empty = WavePlan(
    clearCells: {},
    creations: {},
    match: MatchResult.empty,
  );
}

class CascadeStep {
  const CascadeStep({
    required this.match,
    required this.clearingCells,
    required this.boardAfterClear,
    required this.boardAfterDrop,
    required this.boardAfterFill,
  });

  final MatchResult match;
  final Set<(int, int)> clearingCells;
  final PuzzleBoard boardAfterClear;
  final PuzzleBoard boardAfterDrop;
  final PuzzleBoard boardAfterFill;
}

class CascadeResult {
  const CascadeResult({
    required this.steps,
    required this.finalBoard,
    required this.totals,
    this.boardAfterSwap,
  });

  final List<CascadeStep> steps;
  final PuzzleBoard finalBoard;
  final MatchResult totals;
  final PuzzleBoard? boardAfterSwap;

  bool get hadMatches => steps.isNotEmpty;
}

/// Pure helpers for match-3. No Flutter imports.
abstract final class PuzzleEngine {
  static Set<(int, int)> findMatches(PuzzleBoard board) =>
      MatchShapes.allMatchedCells(board);

  static Set<(int, int)> rocketVerticalBlast(
    PuzzleBoard board,
    (int, int) at,
  ) {
    final cells = <(int, int)>{};
    final col = at.$2;
    for (var r = 0; r < board.height; r++) {
      if (board.at(r, col).isPlayable) cells.add((r, col));
    }
    return cells;
  }

  static Set<(int, int)> rocketHorizontalBlast(
    PuzzleBoard board,
    (int, int) at,
  ) {
    final cells = <(int, int)>{};
    final row = at.$1;
    for (var c = 0; c < board.width; c++) {
      if (board.at(row, c).isPlayable) cells.add((row, c));
    }
    return cells;
  }

  static Set<(int, int)> bombBlast(PuzzleBoard board, (int, int) at) {
    final cells = <(int, int)>{};
    final (row, col) = at;
    for (var r = row - 1; r <= row + 1; r++) {
      for (var c = col - 1; c <= col + 1; c++) {
        if (!board.inBounds(r, c)) continue;
        if (board.at(r, c).isPlayable) cells.add((r, c));
      }
    }
    return cells;
  }

  static Set<(int, int)> blast4x4(PuzzleBoard board, (int, int) at) {
    final cells = <(int, int)>{};
    final (row, col) = at;
    for (var r = row - 1; r <= row + 2; r++) {
      for (var c = col - 1; c <= col + 2; c++) {
        if (!board.inBounds(r, c)) continue;
        if (board.at(r, c).isPlayable) cells.add((r, c));
      }
    }
    return cells;
  }

  static Set<(int, int)> seekerBlast(
    PuzzleBoard board,
    (int, int) at, {
    required Random random,
    int count = 8,
  }) {
    final playable = <(int, int)>[];
    for (var r = 0; r < board.height; r++) {
      for (var c = 0; c < board.width; c++) {
        if (board.at(r, c).isPlayable) playable.add((r, c));
      }
    }
    playable.shuffle(random);
    final cells = <(int, int)>{at};
    for (final p in playable) {
      if (cells.length >= count) break;
      cells.add(p);
    }
    return cells;
  }

  static Set<(int, int)> colorClear(PuzzleBoard board, TileColor color) {
    final cells = <(int, int)>{};
    for (var r = 0; r < board.height; r++) {
      for (var c = 0; c < board.width; c++) {
        final cell = board.at(r, c);
        // Includes tinted power-ups so fireball can chain into them.
        if (cell.isPlayable && cell.color == color) cells.add((r, c));
      }
    }
    return cells;
  }

  static TileColor? randomMatchableColor(PuzzleBoard board, Random random) {
    final colors = <TileColor>{};
    for (var r = 0; r < board.height; r++) {
      for (var c = 0; c < board.width; c++) {
        final cell = board.at(r, c);
        if (cell.isMatchable) colors.add(cell.color!);
      }
    }
    if (colors.isEmpty) return null;
    final list = colors.toList();
    return list[random.nextInt(list.length)];
  }

  /// Symmetric fat cross: 3 full rows + 3 full columns centered on [at].
  static Set<(int, int)> fatCrossBlast(PuzzleBoard board, (int, int) at) {
    final cells = <(int, int)>{};
    final (row, col) = at;
    for (final r in [row - 1, row, row + 1]) {
      if (r < 0 || r >= board.height) continue;
      cells.addAll(rocketHorizontalBlast(board, (r, col)));
    }
    for (final c in [col - 1, col, col + 1]) {
      if (c < 0 || c >= board.width) continue;
      cells.addAll(rocketVerticalBlast(board, (row, c)));
    }
    return cells;
  }

  static Set<(int, int)> specialBlast(
    PuzzleBoard board,
    (int, int) at,
    TileSpecial special, {
    required Random random,
    TileColor? fireballColor,
  }) {
    return switch (special) {
      TileSpecial.rocketVertical => rocketVerticalBlast(board, at),
      TileSpecial.rocketHorizontal => rocketHorizontalBlast(board, at),
      TileSpecial.bomb => bombBlast(board, at),
      TileSpecial.seeker => seekerBlast(board, at, random: random),
      TileSpecial.fireball => () {
          final color = fireballColor ??
              board.at(at.$1, at.$2).color ??
              randomMatchableColor(board, random);
          if (color == null) {
            return {(at)};
          }
          return {...colorClear(board, color), at};
        }(),
      TileSpecial.none => {if (board.at(at.$1, at.$2).isPlayable) at},
    };
  }

  /// Expands [seed] by chaining any power-ups inside the clear set.
  ///
  /// [skipActivation] marks specials that already fired (e.g. the tapped
  /// fireball) so they are not re-blasted via tint/random color.
  static Set<(int, int)> expandWithSpecials(
    PuzzleBoard board,
    Set<(int, int)> seed, {
    required Random random,
    Set<(int, int)> skipActivation = const {},
  }) {
    final clear = {...seed};
    final activated = {...skipActivation};
    var changed = true;
    while (changed) {
      changed = false;
      for (final pos in [...clear]) {
        if (!activated.add(pos)) continue;
        final cell = board.at(pos.$1, pos.$2);
        if (!cell.hasSpecial) continue;
        final blast = specialBlast(board, pos, cell.special, random: random);
        for (final b in blast) {
          if (clear.add(b)) changed = true;
        }
      }
    }
    return clear;
  }

  static Set<(int, int)> convertColorAndFire(
    PuzzleBoard board,
    TileColor color,
    TileSpecial asSpecial, {
    required Random random,
  }) {
    final clear = <(int, int)>{};
    for (var r = 0; r < board.height; r++) {
      for (var c = 0; c < board.width; c++) {
        final cell = board.at(r, c);
        if (!cell.isPlayable || cell.color != color) continue;
        clear.addAll(
          specialBlast(board, (r, c), asSpecial, random: random),
        );
      }
    }
    return clear;
  }

  static Set<(int, int)> mergeBlast({
    required PuzzleBoard board,
    required (int, int) dest,
    required TileSpecial a,
    required TileColor? colorA,
    required TileSpecial b,
    required TileColor? colorB,
    required Random random,
  }) {
    final pair = {a, b};

    if (a.isRocket && b.isRocket) {
      final row = dest.$1;
      final col = dest.$2;
      final row2 = (row + 1 < board.height) ? row + 1 : row - 1;
      final col2 = (col + 1 < board.width) ? col + 1 : col - 1;
      final cells = <(int, int)>{};
      cells.addAll(rocketHorizontalBlast(board, (row, col)));
      if (row2 >= 0) cells.addAll(rocketHorizontalBlast(board, (row2, col)));
      cells.addAll(rocketVerticalBlast(board, (row, col)));
      if (col2 >= 0) cells.addAll(rocketVerticalBlast(board, (row, col2)));
      return cells;
    }

    // Bomb + any rocket → same fat 3×3 cross (3 rows + 3 cols).
    if (pair.contains(TileSpecial.bomb) &&
        (pair.contains(TileSpecial.rocketVertical) ||
            pair.contains(TileSpecial.rocketHorizontal))) {
      return fatCrossBlast(board, dest);
    }

    if (a == TileSpecial.bomb && b == TileSpecial.bomb) {
      return blast4x4(board, dest);
    }

    if (a == TileSpecial.fireball && b == TileSpecial.fireball) {
      return {
        for (var r = 0; r < board.height; r++)
          for (var c = 0; c < board.width; c++)
            if (board.at(r, c).isPlayable) (r, c),
      };
    }

    if (pair.contains(TileSpecial.fireball) &&
        pair.contains(TileSpecial.rocketVertical)) {
      final color = a == TileSpecial.rocketVertical ? colorA : colorB;
      if (color == null) return {dest};
      return convertColorAndFire(
        board,
        color,
        TileSpecial.rocketVertical,
        random: random,
      );
    }

    if (pair.contains(TileSpecial.fireball) &&
        pair.contains(TileSpecial.rocketHorizontal)) {
      final color = a == TileSpecial.rocketHorizontal ? colorA : colorB;
      if (color == null) return {dest};
      return convertColorAndFire(
        board,
        color,
        TileSpecial.rocketHorizontal,
        random: random,
      );
    }

    if (pair.contains(TileSpecial.fireball) &&
        pair.contains(TileSpecial.bomb)) {
      final color = a == TileSpecial.bomb ? colorA : colorB;
      if (color == null) return {dest};
      return convertColorAndFire(
        board,
        color,
        TileSpecial.bomb,
        random: random,
      );
    }

    if (pair.contains(TileSpecial.fireball) &&
        pair.contains(TileSpecial.seeker)) {
      final color = a == TileSpecial.seeker ? colorA : colorB;
      if (color == null) return {dest};
      return convertColorAndFire(
        board,
        color,
        TileSpecial.seeker,
        random: random,
      );
    }

    if (a == TileSpecial.seeker && b == TileSpecial.seeker) {
      return seekerBlast(board, dest, random: random, count: 16);
    }

    if (pair.contains(TileSpecial.seeker) &&
        pair.contains(TileSpecial.rocketVertical)) {
      final cols = List.generate(board.width, (i) => i)..shuffle(random);
      final cells = <(int, int)>{};
      for (final c in cols.take(4)) {
        cells.addAll(rocketVerticalBlast(board, (dest.$1, c)));
      }
      return cells;
    }

    if (pair.contains(TileSpecial.seeker) &&
        pair.contains(TileSpecial.rocketHorizontal)) {
      final rows = List.generate(board.height, (i) => i)..shuffle(random);
      final cells = <(int, int)>{};
      for (final r in rows.take(4)) {
        cells.addAll(rocketHorizontalBlast(board, (r, dest.$2)));
      }
      return cells;
    }

    if (pair.contains(TileSpecial.seeker) && pair.contains(TileSpecial.bomb)) {
      final playable = <(int, int)>[];
      for (var r = 0; r < board.height; r++) {
        for (var c = 0; c < board.width; c++) {
          if (board.at(r, c).isPlayable) playable.add((r, c));
        }
      }
      playable.shuffle(random);
      final cells = <(int, int)>{};
      for (final p in playable.take(3)) {
        cells.addAll(bombBlast(board, p));
      }
      return cells;
    }

    // Fallback: fire both specials at dest / neighbors.
    return {
      ...specialBlast(board, dest, a, random: random),
      ...specialBlast(board, dest, b, random: random),
    };
  }

  static String mergeLabel(TileSpecial a, TileSpecial b) {
    final names = [a.name, b.name]..sort();
    return 'Merge ${names.join(' + ')}';
  }

  static WavePlan planWave(
    PuzzleBoard board, {
    (int, int)? swapDestination,
    (int, int)? swapOrigin,
    required Random random,
  }) {
    final shapes = MatchShapes.detectAll(board);
    if (shapes.isEmpty) return WavePlan.empty;

    final seed = <(int, int)>{};
    for (final s in shapes) {
      seed.addAll(s.cells);
    }

    var clear = expandWithSpecials(board, seed, random: random);

    final creations = <(int, int), TileSpecial>{};
    final picks = MatchShapes.pickCreations(
      shapes: shapes,
      swapDestination: swapDestination,
      swapOrigin: swapOrigin,
    );
    for (final pick in picks) {
      if (!seed.contains(pick.at)) continue;
      creations[pick.at] = pick.special;
      clear.remove(pick.at);
    }

    final match = resolveMatches(
      board,
      {...clear, ...creations.keys},
      rocketsCreated: creations.values.where((s) => s.isRocket).length,
      bombsCreated: creations.values.where((s) => s == TileSpecial.bomb).length,
      fireballsCreated:
          creations.values.where((s) => s == TileSpecial.fireball).length,
      seekersCreated:
          creations.values.where((s) => s == TileSpecial.seeker).length,
    );

    return WavePlan(clearCells: clear, creations: creations, match: match);
  }

  static MatchResult resolveMatches(
    PuzzleBoard board,
    Set<(int, int)> matched, {
    int rocketsCreated = 0,
    int bombsCreated = 0,
    int fireballsCreated = 0,
    int seekersCreated = 0,
    String? mergeLabel,
    MatchBalanceConfig balance = MatchBalanceConfig.defaults,
  }) {
    if (matched.isEmpty && mergeLabel == null) return MatchResult.empty;

    final gains = <String, int>{};
    for (final (row, col) in matched) {
      final cell = board.at(row, col);
      if (cell.suppressesResources) continue;
      final color = cell.color;
      if (color == null) continue;
      final key = color.resourceId;
      gains[key] = (gains[key] ?? 0) + balance.resourcePerTile;
    }

    var ap = matched.isEmpty
        ? 0
        : (matched.length ~/ balance.tilesPerAp)
            .clamp(balance.minApPerMatch, balance.maxApPerWave);
    ap += rocketsCreated * balance.apPerRocket;
    ap += bombsCreated * balance.apPerBomb;
    ap += fireballsCreated * balance.apPerFireball;
    ap += seekersCreated * balance.apPerSeeker;

    return MatchResult(
      matchedCells: matched,
      resourceGains: gains,
      apGained: ap.clamp(0, balance.maxApPerWave),
      rocketsCreated: rocketsCreated,
      bombsCreated: bombsCreated,
      fireballsCreated: fireballsCreated,
      seekersCreated: seekersCreated,
      mergeLabel: mergeLabel,
    );
  }

  static bool areAdjacent((int, int) a, (int, int) b) {
    final dr = (a.$1 - b.$1).abs();
    final dc = (a.$2 - b.$2).abs();
    return (dr + dc) == 1;
  }

  /// First adjacent **color** swap that creates a match (ignores power-ups).
  /// Scans top→bottom, left→right; tries right then down neighbor.
  static ((int, int) a, (int, int) b)? findFirstColorSwap(
    PuzzleBoard board, {
    Random? random,
  }) {
    final rng = random ?? Random(0);
    for (var row = 0; row < board.height; row++) {
      for (var col = 0; col < board.width; col++) {
        if (!board.at(row, col).isMatchable) continue;
        final a = (row, col);
        for (final b in [(row, col + 1), (row + 1, col)]) {
          if (!board.inBounds(b.$1, b.$2)) continue;
          if (!board.at(b.$1, b.$2).isMatchable) continue;
          final swapped = swap(board, a, b);
          final plan = planWave(
            swapped,
            swapDestination: b,
            swapOrigin: a,
            random: rng,
          );
          if (!plan.isEmpty) return (a, b);
        }
      }
    }
    return null;
  }

  static bool hasColorMove(PuzzleBoard board, {Random? random}) =>
      findFirstColorSwap(board, random: random) != null;

  /// Recolor normal gems in place; power-ups stay. Result has no matches and
  /// at least one valid color swap when possible.
  static PuzzleBoard reshuffleKeepingSpecials(
    PuzzleBoard board, {
    required Random random,
    required TileIdGen ids,
    int maxAttempts = 80,
  }) {
    PuzzleBoard? last;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final next = _fillMatchableNoMatches(board, random: random, ids: ids);
      last = next;
      if (findMatches(next).isEmpty && hasColorMove(next, random: random)) {
        return next;
      }
    }
    return last ?? board;
  }

  /// Like [PuzzleBoard.squareNoMatches] but only rewrites matchable cells.
  static PuzzleBoard _fillMatchableNoMatches(
    PuzzleBoard board, {
    required Random random,
    required TileIdGen ids,
  }) {
    const colors = TileColor.values;
    final next = List<BoardCell>.from(board.cells);

    BoardCell at(int r, int c) => next[r * board.width + c];

    for (var row = 0; row < board.height; row++) {
      for (var col = 0; col < board.width; col++) {
        final i = row * board.width + col;
        final existing = next[i];
        if (existing.masked ||
            existing.isSolidObstacle ||
            existing.hasSpecial) {
          continue;
        }
        if (!existing.isPlayable && existing.color == null) continue;

        final forbidden = <TileColor>{};
        if (col >= 2) {
          final a = at(row, col - 1).matchColor;
          final b = at(row, col - 2).matchColor;
          if (a != null && a == b) forbidden.add(a);
        }
        if (row >= 2) {
          final a = at(row - 1, col).matchColor;
          final b = at(row - 2, col).matchColor;
          if (a != null && a == b) forbidden.add(a);
        }
        if (row > 0 && col > 0) {
          final tl = at(row - 1, col - 1).matchColor;
          final tr = at(row - 1, col).matchColor;
          final bl = at(row, col - 1).matchColor;
          if (tl != null && tl == tr && tl == bl) forbidden.add(tl);
        }

        final options =
            colors.where((c) => !forbidden.contains(c)).toList(growable: false);
        final pick = options.isEmpty
            ? colors[random.nextInt(colors.length)]
            : options[random.nextInt(options.length)];
        next[i] = BoardCell.tile(
          id: existing.id ?? ids.next(),
          color: pick,
          obstacleLayers: existing.obstacleLayers,
          overlayId: existing.overlayId,
          overlayArchetype: existing.overlayArchetype,
          overlayBreakRule: existing.overlayBreakRule,
          overlayHazard: existing.overlayHazard,
        );
      }
    }
    return PuzzleBoard(width: board.width, height: board.height, cells: next);
  }

  static PuzzleBoard swap(PuzzleBoard board, (int, int) a, (int, int) b) {
    final cellA = board.at(a.$1, a.$2);
    final cellB = board.at(b.$1, b.$2);
    var next = board.copyWithCell(a.$1, a.$2, cellB);
    next = next.copyWithCell(b.$1, b.$2, cellA);
    return next;
  }

  /// Clears tiles in [cells], then applies overlay break damage.
  ///
  /// [overlayTouchCells] defaults to [cells]. Pass creation cells too so
  /// binders under power-up spawns still take match-under damage, and so
  /// adjacent blockers feel those touches.
  static PuzzleBoard clearCells(
    PuzzleBoard board,
    Set<(int, int)> cells, {
    Set<(int, int)>? overlayTouchCells,
  }) {
    final touch = overlayTouchCells ?? cells;
    final damage = overlayDamageFromClears(board, touch);

    var next = board;
    for (final (row, col) in cells) {
      final cell = next.at(row, col);
      if (cell.masked || cell.isSolidObstacle) continue;
      next = next.copyWithCell(row, col, cell.copyWith(clearTile: true));
    }

    for (final entry in damage.entries) {
      final (row, col) = entry.key;
      final cell = next.at(row, col);
      if (!cell.hasObstacle) continue;
      next = next.copyWithCell(row, col, cell.damageOverlay(entry.value));
    }
    return next;
  }

  /// Computes overlay layer damage for one clear wave.
  ///
  /// - **match_under** binders: 1 damage if the cell is in [touch]
  /// - **adjacent_match** blockers: 1 damage if any orthogonally adjacent
  ///   touch cell exists (unique per blocker per wave, not per neighbor)
  static Map<(int, int), int> overlayDamageFromClears(
    PuzzleBoard board,
    Set<(int, int)> touch,
  ) {
    final damage = <(int, int), int>{};

    void hit((int, int) pos) {
      damage[pos] = 1;
    }

    for (final (row, col) in touch) {
      if (!board.inBounds(row, col)) continue;
      final cell = board.at(row, col);

      // Match-under: binder on the cleared / touched cell.
      if (cell.hasObstacle &&
          cell.overlayBreakRule == OverlayBreakRule.matchUnder) {
        hit((row, col));
      }

      // Adjacent-match: blockers next to a touch cell.
      for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final nr = row + dr;
        final nc = col + dc;
        if (!board.inBounds(nr, nc)) continue;
        final neighbor = board.at(nr, nc);
        if (neighbor.hasObstacle &&
            neighbor.overlayBreakRule == OverlayBreakRule.adjacentMatch) {
          hit((nr, nc));
        }
      }
    }
    return damage;
  }

  static PuzzleBoard applyCreations(
    PuzzleBoard board,
    Map<(int, int), TileSpecial> creations,
  ) {
    var next = board;
    for (final entry in creations.entries) {
      final (row, col) = entry.key;
      final existing = board.at(row, col);
      if (existing.id == null) continue;
      next = next.copyWithCell(
        row,
        col,
        BoardCell.powerUp(
          id: existing.id!,
          special: entry.value,
          tint: existing.color,
          obstacleLayers: existing.obstacleLayers,
          overlayId: existing.overlayId,
          overlayArchetype: existing.overlayArchetype,
          overlayBreakRule: existing.overlayBreakRule,
          overlayHazard: existing.overlayHazard,
        ),
      );
    }
    return next;
  }

  static bool _isGravitySolid(BoardCell cell) =>
      cell.masked || cell.isSolidObstacle;

  static PuzzleBoard applyGravity(PuzzleBoard board) {
    final next = List<BoardCell>.from(board.cells);
    for (var col = 0; col < board.width; col++) {
      final stack = <BoardCell>[];
      for (var row = board.height - 1; row >= 0; row--) {
        final cell = board.at(row, col);
        if (_isGravitySolid(cell)) continue;
        if (cell.isPlayable) {
          // Binder overlays stay on the cell; only the tile falls.
          stack.add(
            cell.isBinderObstacle ? cell.copyWith(clearOverlay: true) : cell,
          );
        }
      }

      var writeRow = board.height - 1;
      for (final tile in stack) {
        while (writeRow >= 0 && _isGravitySolid(board.at(writeRow, col))) {
          writeRow--;
        }
        if (writeRow < 0) break;
        final dest = board.at(writeRow, col);
        if (dest.isBinderObstacle) {
          next[writeRow * board.width + col] = tile.copyWith(
            obstacleLayers: dest.obstacleLayers,
            overlayId: dest.overlayId,
            overlayArchetype: dest.overlayArchetype,
            overlayBreakRule: dest.overlayBreakRule,
            overlayHazard: dest.overlayHazard,
          );
        } else {
          next[writeRow * board.width + col] = tile;
        }
        writeRow--;
      }
      while (writeRow >= 0) {
        final dest = board.at(writeRow, col);
        if (!_isGravitySolid(dest)) {
          next[writeRow * board.width + col] = dest.isBinderObstacle
              ? dest.copyWith(clearTile: true)
              : BoardCell.empty();
        }
        writeRow--;
      }
    }
    return PuzzleBoard(width: board.width, height: board.height, cells: next);
  }

  static PuzzleBoard fillEmpty(
    PuzzleBoard board, {
    required Random random,
    required TileIdGen ids,
    TileSpawnWeights spawnWeights = TileSpawnWeights.uniform,
  }) {
    final next = List<BoardCell>.from(board.cells);
    for (var row = 0; row < board.height; row++) {
      for (var col = 0; col < board.width; col++) {
        final i = row * board.width + col;
        final cell = next[i];
        if (cell.masked || cell.isSolidObstacle || cell.isPlayable) continue;
        final color = spawnWeights.pick(random);
        if (cell.isBinderObstacle) {
          next[i] = BoardCell.tile(
            id: ids.next(),
            color: color,
            obstacleLayers: cell.obstacleLayers,
            overlayId: cell.overlayId,
            overlayArchetype: cell.overlayArchetype,
            overlayBreakRule: cell.overlayBreakRule,
            overlayHazard: cell.overlayHazard,
          );
        } else {
          next[i] = BoardCell.tile(id: ids.next(), color: color);
        }
      }
    }
    return PuzzleBoard(width: board.width, height: board.height, cells: next);
  }

  static ({
    PuzzleBoard afterClear,
    PuzzleBoard afterDrop,
    PuzzleBoard afterFill,
  }) collapse(
    PuzzleBoard board,
    WavePlan plan, {
    required Random random,
    required TileIdGen ids,
  }) {
    var afterClear = clearCells(
      board,
      plan.clearCells,
      overlayTouchCells: {...plan.clearCells, ...plan.creations.keys},
    );
    afterClear = applyCreations(afterClear, plan.creations);
    final afterDrop = applyGravity(afterClear);
    final afterFill = fillEmpty(afterDrop, random: random, ids: ids);
    return (
      afterClear: afterClear,
      afterDrop: afterDrop,
      afterFill: afterFill,
    );
  }

  static CascadeResult _cascadeFromPlan(
    PuzzleBoard swapped,
    WavePlan plan, {
    required Random random,
    required TileIdGen ids,
  }) {
    final collapsed = collapse(swapped, plan, random: random, ids: ids);
    final rest = resolveCascade(
      collapsed.afterFill,
      random: random,
      ids: ids,
    );
    return CascadeResult(
      steps: [
        CascadeStep(
          match: plan.match,
          clearingCells: plan.clearCells,
          boardAfterClear: collapsed.afterClear,
          boardAfterDrop: collapsed.afterDrop,
          boardAfterFill: collapsed.afterFill,
        ),
        ...rest.steps,
      ],
      finalBoard: rest.finalBoard,
      totals: plan.match.merge(rest.totals),
      boardAfterSwap: swapped,
    );
  }

  static CascadeResult resolveCascade(
    PuzzleBoard board, {
    required Random random,
    required TileIdGen ids,
    int maxWaves = 32,
  }) {
    final steps = <CascadeStep>[];
    var current = board;
    var totals = MatchResult.empty;

    for (var wave = 0; wave < maxWaves; wave++) {
      final plan = planWave(current, random: random);
      if (plan.isEmpty) break;

      totals = totals.merge(plan.match);
      final collapsed = collapse(current, plan, random: random, ids: ids);
      steps.add(
        CascadeStep(
          match: plan.match,
          clearingCells: plan.clearCells,
          boardAfterClear: collapsed.afterClear,
          boardAfterDrop: collapsed.afterDrop,
          boardAfterFill: collapsed.afterFill,
        ),
      );
      current = collapsed.afterFill;
    }

    return CascadeResult(
      steps: steps,
      finalBoard: current,
      totals: totals,
    );
  }

  /// Activate a power-up in place (tap) or after a swap.
  ///
  /// [swapColor] is set when activated by swapping with a normal tile (fireball
  /// uses it). When null and the special is a fireball, a random board color
  /// is chosen.
  static CascadeResult? activateSpecial(
    PuzzleBoard board,
    (int, int) pos, {
    TileColor? swapColor,
    required Random random,
    required TileIdGen ids,
  }) {
    if (!board.inBounds(pos.$1, pos.$2)) return null;
    final cell = board.at(pos.$1, pos.$2);
    if (!cell.hasSpecial) return null;

    late Set<(int, int)> clear;
    late String label;

    if (cell.special == TileSpecial.fireball) {
      final color = swapColor ?? randomMatchableColor(board, random);
      if (color == null) {
        clear = {pos};
        label = 'Fireball';
      } else {
        clear = colorClear(board, color)..add(pos);
        // Skip re-firing this fireball; chain other power-ups it clears.
        clear = expandWithSpecials(
          board,
          clear,
          random: random,
          skipActivation: {pos},
        );
        label = swapColor != null
            ? 'Fireball → ${color.name}'
            : 'Fireball (random ${color.name})';
      }
    } else {
      clear = specialBlast(board, pos, cell.special, random: random);
      clear = expandWithSpecials(
        board,
        clear,
        random: random,
        skipActivation: {pos},
      );
      label = 'Activate ${cell.special.name}';
    }

    final match = resolveMatches(board, clear, mergeLabel: label);
    final plan = WavePlan(clearCells: clear, creations: {}, match: match);
    return _cascadeFromPlan(board, plan, random: random, ids: ids);
  }

  /// Try a swap; handles special merges, special activation, and shape matches.
  /// [b] is the swap destination.
  static CascadeResult? trySwap(
    PuzzleBoard board,
    (int, int) a,
    (int, int) b, {
    required Random random,
    required TileIdGen ids,
  }) {
    if (!areAdjacent(a, b)) return null;
    if (!board.at(a.$1, a.$2).isPlayable) return null;
    if (!board.at(b.$1, b.$2).isPlayable) return null;

    final swapped = swap(board, a, b);
    final atA = swapped.at(a.$1, a.$2);
    final atB = swapped.at(b.$1, b.$2);

    // Special ↔ special merge at destination b.
    if (atA.hasSpecial && atB.hasSpecial) {
      var clear = mergeBlast(
        board: swapped,
        dest: b,
        a: atA.special,
        colorA: atA.color,
        b: atB.special,
        colorB: atB.color,
        random: random,
      );
      clear = expandWithSpecials(
        swapped,
        clear,
        random: random,
        skipActivation: {a, b},
      );
      final label = mergeLabel(atA.special, atB.special);
      final match = resolveMatches(swapped, clear, mergeLabel: label);
      final plan = WavePlan(clearCells: clear, creations: {}, match: match);
      return _cascadeFromPlan(swapped, plan, random: random, ids: ids);
    }

    // Special ↔ any normal tile: activate the special (not color-matched).
    if (atA.hasSpecial ^ atB.hasSpecial) {
      final specialPos = atA.hasSpecial ? a : b;
      final normalPos = atA.hasSpecial ? b : a;
      final normalColor = swapped.at(normalPos.$1, normalPos.$2).color;
      return activateSpecial(
        swapped,
        specialPos,
        swapColor: normalColor,
        random: random,
        ids: ids,
      );
    }

    final plan = planWave(
      swapped,
      swapDestination: b,
      swapOrigin: a,
      random: random,
    );
    if (plan.isEmpty) return null;

    return _cascadeFromPlan(swapped, plan, random: random, ids: ids);
  }
}
