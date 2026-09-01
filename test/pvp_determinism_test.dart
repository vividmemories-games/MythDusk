import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/pvp/domain/battle_action.dart';
import 'package:mythdusk/features/pvp/domain/battle_replay.dart';
import 'package:mythdusk/features/pvp/domain/pvp_duel.dart';
import 'package:mythdusk/features/pvp/domain/pvp_models.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_board.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_engine.dart';
import 'package:mythdusk/features/puzzle/domain/tile_id_gen.dart';

void main() {
  test('two clients with the same seed and log reach the same BattleState', () {
    final ids = TileIdGen(1000);
    final board = PuzzleBoard.squarePlayable(random: Random(7), ids: ids);
    final swap = PuzzleEngine.findFirstColorSwap(board, random: Random(3));
    expect(swap, isNotNull);

    final initial = BattleState.initial(
      hero: HeroCatalog.mage,
      board: board,
      ids: TileIdGen(ids.peek),
      random: Random(0),
    );
    final log = [
      BattleAction.swap(actorUid: 'a', a: swap!.$1, b: swap.$2),
    ];

    BattleState play() => BattleReplay.apply(
          initial: initial,
          log: log,
          seed: 11,
          tileIdStart: ids.peek,
        );

    final a = play();
    final b = play();
    expect(a.heroHp, b.heroHp);
    expect(a.enemyHp, b.enemyHp);
    expect(a.ap, b.ap);
    expect(a.movesLeft, b.movesLeft);
    expect(a.phase, b.phase);
    expect(
      [for (final cell in a.board.cells) cell.color],
      [for (final cell in b.board.cells) cell.color],
    );
  });

  test('live 1v1 replay agrees on HP from opposite seats', () {
    const match = PvpMatch(
      id: 'm1',
      uidA: 'a',
      uidB: 'b',
      seed: 42,
      loadoutA: const PvpLoadout(heroId: 'mage', skillIds: ['fireball']),
      loadoutB: const PvpLoadout(heroId: 'knight', skillIds: []),
      currentUid: 'a',
    );
    final fromA = PvpDuelEngine.replay(match: match, viewerUid: 'a');
    final fromB = PvpDuelEngine.replay(match: match, viewerUid: 'b');
    expect(fromA.heroHp, fromB.enemyHp);
    expect(fromA.enemyHp, fromB.heroHp);
    expect(fromA.hero.id, 'mage');
    expect(fromB.hero.id, 'knight');
  });
}
