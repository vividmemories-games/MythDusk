import 'dart:math';

import 'board_cell.dart';
import 'board_template.dart';
import 'overlay_def.dart';
import 'puzzle_board.dart';
import 'puzzle_engine.dart';
import 'tile_color.dart';
import 'tile_id_gen.dart';
import 'tile_spawn_weights.dart';

/// Builds a playable [PuzzleBoard] from a [BoardTemplate] + overlay catalog.
abstract final class BoardBuilder {
  /// Structure cells from the template (masks / blockers / binder stubs), then
  /// fill open cells with a no-match weighted spawn. Retries until playable.
  static PuzzleBoard fromTemplate({
    required BoardTemplate template,
    required OverlayCatalog overlays,
    TileSpawnWeights spawnWeights = TileSpawnWeights.uniform,
    Random? random,
    TileIdGen? ids,
    int maxAttempts = 40,
  }) {
    final rng = random ?? Random();
    final idGen = ids ?? TileIdGen();
    final structure = _structureBoard(template, overlays);

    PuzzleBoard? last;
    for (var i = 0; i < maxAttempts; i++) {
      final filled = _fillStructure(
        structure,
        spawnWeights: spawnWeights,
        random: rng,
        ids: idGen,
      );
      last = filled;
      if (PuzzleEngine.findMatches(filled).isEmpty &&
          PuzzleEngine.hasColorMove(filled, random: rng)) {
        return filled;
      }
    }
    return last ?? structure;
  }

  static PuzzleBoard _structureBoard(
    BoardTemplate template,
    OverlayCatalog overlays,
  ) {
    final cells = <BoardCell>[];
    for (var row = 0; row < template.height; row++) {
      for (var col = 0; col < template.width; col++) {
        final spec = template.at(row, col);
        if (spec.masked) {
          cells.add(BoardCell.maskedHole());
          continue;
        }
        if (spec.overlayId != null) {
          final def = overlays.require(spec.overlayId!);
          cells.add(
            BoardCell.withOverlay(def: def, layers: spec.layers),
          );
          continue;
        }
        cells.add(BoardCell.empty());
      }
    }
    return PuzzleBoard(
      width: template.width,
      height: template.height,
      cells: cells,
    );
  }

  static PuzzleBoard _fillStructure(
    PuzzleBoard structure, {
    required TileSpawnWeights spawnWeights,
    required Random random,
    required TileIdGen ids,
  }) {
    final next = List<BoardCell>.from(structure.cells);
    const colors = TileColor.values;

    BoardCell at(int r, int c) => next[r * structure.width + c];

    for (var row = 0; row < structure.height; row++) {
      for (var col = 0; col < structure.width; col++) {
        final i = row * structure.width + col;
        final existing = next[i];
        if (existing.masked || existing.isSolidObstacle) continue;

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
        final pick = spawnWeights.pickFrom(options, random);

        if (existing.isBinderObstacle) {
          next[i] = BoardCell.tile(
            id: ids.next(),
            color: pick,
            obstacleLayers: existing.obstacleLayers,
            overlayId: existing.overlayId,
            overlayArchetype: existing.overlayArchetype,
            overlayBreakRule: existing.overlayBreakRule,
            overlayHazard: existing.overlayHazard,
          );
        } else {
          next[i] = BoardCell.tile(id: ids.next(), color: pick);
        }
      }
    }

    return PuzzleBoard(
      width: structure.width,
      height: structure.height,
      cells: next,
    );
  }
}
