import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythora/features/heroes/domain/hero_unlocks.dart';
import 'package:mythora/features/puzzle/domain/board_cell.dart';
import 'package:mythora/features/puzzle/domain/hazard_spawner.dart';
import 'package:mythora/features/puzzle/domain/level_board_config.dart';
import 'package:mythora/features/puzzle/domain/overlay_def.dart';
import 'package:mythora/features/puzzle/domain/puzzle_board.dart';
import 'package:mythora/features/puzzle/domain/tile_color.dart';
import 'package:mythora/features/puzzle/domain/tile_id_gen.dart';

void main() {
  group('HazardSpawner', () {
    const poison = OverlayDef(
      id: 'ovl_poison',
      archetype: OverlayArchetype.binder,
      breakRule: OverlayBreakRule.matchUnder,
      hazard: OverlayHazard.suppressResources,
    );

    PuzzleBoard openBoard() {
      final ids = TileIdGen();
      return PuzzleBoard(
        width: 3,
        height: 3,
        cells: [
          for (var i = 0; i < 9; i++)
            BoardCell.tile(id: ids.next(), color: TileColor.red),
        ],
      );
    }

    test('spawns poison when chance is 1.0 under max cap', () {
      final board = openBoard();
      final next = HazardSpawner.maybeSpawn(
        board: board,
        config: const HazardSpawnConfig(
          overlayId: 'ovl_poison',
          chancePerTurn: 1.0,
          maxOnBoard: 2,
        ),
        def: poison,
        random: Random(1),
      );
      final count = next.cells.where((c) => c.overlayId == 'ovl_poison').length;
      expect(count, 1);
      expect(next.cells.any((c) => c.suppressesResources), isTrue);
    });

    test('respects maxOnBoard', () {
      var board = openBoard();
      board = board.copyWithCell(
        0,
        0,
        BoardCell.withOverlay(
          def: poison,
          layers: 1,
          id: board.at(0, 0).id,
          color: TileColor.red,
        ),
      );
      board = board.copyWithCell(
        0,
        1,
        BoardCell.withOverlay(
          def: poison,
          layers: 1,
          id: board.at(0, 1).id,
          color: TileColor.red,
        ),
      );
      final next = HazardSpawner.maybeSpawn(
        board: board,
        config: const HazardSpawnConfig(
          overlayId: 'ovl_poison',
          chancePerTurn: 1.0,
          maxOnBoard: 2,
        ),
        def: poison,
        random: Random(2),
      );
      expect(
        next.cells.where((c) => c.overlayId == 'ovl_poison').length,
        2,
      );
    });

    test('maybeSpawnTracked reports spawned cell', () {
      final board = openBoard();
      final outcome = HazardSpawner.maybeSpawnTracked(
        board: board,
        config: const HazardSpawnConfig(
          overlayId: 'ovl_poison',
          chancePerTurn: 1.0,
          maxOnBoard: 2,
        ),
        def: poison,
        random: Random(1),
      );
      expect(outcome.didSpawn, isTrue);
      expect(outcome.spawnedCells, hasLength(1));
      final (r, c) = outcome.spawnedCells.single;
      expect(outcome.board.at(r, c).overlayId, 'ovl_poison');
    });
  });

  group('HeroUnlocks', () {
    test('mage free; others gated at 50/100/150/200', () {
      expect(HeroUnlocks.isUnlocked('mage', 0), isTrue);
      expect(HeroUnlocks.isUnlocked('knight', 49), isFalse);
      expect(HeroUnlocks.isUnlocked('knight', 50), isTrue);
      expect(HeroUnlocks.isUnlocked('ranger', 100), isTrue);
      expect(HeroUnlocks.isUnlocked('priest', 149), isFalse);
      expect(HeroUnlocks.isUnlocked('ninja', 200), isTrue);
    });
  });
}
