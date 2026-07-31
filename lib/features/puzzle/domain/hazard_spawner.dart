import 'dart:math';

import 'board_cell.dart';
import 'level_board_config.dart';
import 'overlay_def.dart';
import 'puzzle_board.dart';

/// Result of a hazard spawn attempt.
class HazardSpawnOutcome {
  const HazardSpawnOutcome({
    required this.board,
    this.spawnedCells = const {},
  });

  final PuzzleBoard board;
  final Set<(int, int)> spawnedCells;

  bool get didSpawn => spawnedCells.isNotEmpty;
}

/// Spawns hazard binders onto random playable tiles (Mistfen poison, etc.).
abstract final class HazardSpawner {
  /// Returns a new board when a hazard was placed; otherwise [board].
  static PuzzleBoard maybeSpawn({
    required PuzzleBoard board,
    required HazardSpawnConfig config,
    required OverlayDef def,
    required Random random,
  }) =>
      maybeSpawnTracked(
        board: board,
        config: config,
        def: def,
        random: random,
      ).board;

  /// Like [maybeSpawn], but also reports which cells received the hazard.
  static HazardSpawnOutcome maybeSpawnTracked({
    required PuzzleBoard board,
    required HazardSpawnConfig config,
    required OverlayDef def,
    required Random random,
  }) {
    if (config.chancePerTurn <= 0 || config.maxOnBoard <= 0) {
      return HazardSpawnOutcome(board: board);
    }

    var onBoard = 0;
    final candidates = <(int, int)>[];
    for (var r = 0; r < board.height; r++) {
      for (var c = 0; c < board.width; c++) {
        final cell = board.at(r, c);
        if (cell.overlayId == config.overlayId) onBoard++;
        if (cell.isPlayable &&
            cell.id != null &&
            !cell.hasObstacle &&
            !cell.hasSpecial) {
          candidates.add((r, c));
        }
      }
    }
    if (onBoard >= config.maxOnBoard || candidates.isEmpty) {
      return HazardSpawnOutcome(board: board);
    }
    if (random.nextDouble() >= config.chancePerTurn) {
      return HazardSpawnOutcome(board: board);
    }

    final pick = candidates[random.nextInt(candidates.length)];
    final cell = board.at(pick.$1, pick.$2);
    final next = BoardCell.withOverlay(
      def: def,
      layers: 1,
      id: cell.id,
      color: cell.color,
      special: cell.special,
    );
    return HazardSpawnOutcome(
      board: board.copyWithCell(pick.$1, pick.$2, next),
      spawnedCells: {pick},
    );
  }
}
