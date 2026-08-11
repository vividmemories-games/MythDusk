import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/domain/enemy_def.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_board.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_engine.dart';
import 'package:mythdusk/features/puzzle/domain/tile_id_gen.dart';

void main() {
  test('invalid swap peeks null and previewSwap restores seats', () {
    final board = PuzzleBoard.squareNoMatches(ids: TileIdGen(1));
    final controller = BattleController(
      BattleState.initial(
        hero: HeroCatalog.mage,
        enemy: EnemyCatalog.goblin,
        board: board,
      ),
    );

    // Find an adjacent pair that does not match.
    (int, int)? a;
    (int, int)? b;
    for (var r = 0; r < 6 && a == null; r++) {
      for (var c = 0; c < 5; c++) {
        final from = (r, c);
        final to = (r, c + 1);
        if (controller.peekSwap(from, to) == null) {
          a = from;
          b = to;
          break;
        }
      }
    }
    expect(a, isNotNull);
    expect(b, isNotNull);

    final original = controller.state.board;
    final preview = controller.previewSwapBoard(a!, b!);
    expect(preview.at(a.$1, a.$2).id, original.at(b.$1, b.$2).id);
    expect(preview.at(b.$1, b.$2).id, original.at(a.$1, a.$2).id);
    expect(controller.peekSwap(a, b), isNull);
  });

  test('PuzzleEngine.swap is reversible', () {
    final board = PuzzleBoard.squareNoMatches(ids: TileIdGen(2));
    const a = (0, 0);
    const b = (0, 1);
    final once = PuzzleEngine.swap(board, a, b);
    final back = PuzzleEngine.swap(once, a, b);
    expect(back.at(0, 0).id, board.at(0, 0).id);
    expect(back.at(0, 1).id, board.at(0, 1).id);
  });
}
