import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/puzzle/domain/board_cell.dart';
import 'package:mythdusk/features/puzzle/domain/match_balance.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_board.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_engine.dart';
import 'package:mythdusk/features/puzzle/domain/tile_color.dart';
import 'package:mythdusk/features/puzzle/domain/tile_id_gen.dart';

void main() {
  PuzzleBoard board3x3AllRed() {
    final ids = TileIdGen();
    return PuzzleBoard(
      width: 3,
      height: 3,
      cells: List.generate(
        9,
        (_) => BoardCell.tile(id: ids.next(), color: TileColor.red),
      ),
    );
  }

  group('MatchBalanceConfig', () {
    test('defaults reproduce the documented formula', () {
      final board = board3x3AllRed();
      final result = PuzzleEngine.resolveMatches(
        board,
        {(0, 0), (0, 1), (0, 2)},
      );
      expect(result.resourceGains['attack'], 3);
      expect(result.apGained, 1); // 3 tiles ~/ 3
    });

    test('custom tilesPerAp and resourcePerTile are honored', () {
      final board = board3x3AllRed();
      final result = PuzzleEngine.resolveMatches(
        board,
        {(0, 0), (0, 1), (0, 2)},
        balance: const MatchBalanceConfig(tilesPerAp: 1, resourcePerTile: 2),
      );
      expect(result.resourceGains['attack'], 6);
      expect(result.apGained, 3);
    });

    test('power-up creation AP bonuses come from config', () {
      final board = board3x3AllRed();
      final result = PuzzleEngine.resolveMatches(
        board,
        {(0, 0), (0, 1), (0, 2)},
        bombsCreated: 1,
        balance: const MatchBalanceConfig(apPerBomb: 5),
      );
      expect(result.apGained, 1 + 5);
    });

    test('maxApPerWave caps huge blasts', () {
      final board = board3x3AllRed();
      final result = PuzzleEngine.resolveMatches(
        board,
        {
          for (var r = 0; r < 3; r++)
            for (var c = 0; c < 3; c++) (r, c),
        },
        balance: const MatchBalanceConfig(tilesPerAp: 1, maxApPerWave: 4),
      );
      expect(result.apGained, 4);
    });

    test('json round-trip preserves values', () {
      const config = MatchBalanceConfig(tilesPerAp: 2, apPerFireball: 9);
      final decoded = MatchBalanceConfig.fromJson(config.toJson());
      expect(decoded.tilesPerAp, 2);
      expect(decoded.apPerFireball, 9);
      expect(decoded.schemaVersion, config.schemaVersion);
    });
  });
}
