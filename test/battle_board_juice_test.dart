import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/presentation/animated_puzzle_board.dart';
import 'package:mythdusk/features/battle/presentation/board_powerup_fx.dart';
import 'package:mythdusk/features/battle/presentation/match_collect_fx.dart';
import 'package:mythdusk/features/battle/presentation/match_collect_overlay.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_board.dart';
import 'package:mythdusk/features/puzzle/domain/board_cell.dart';
import 'package:mythdusk/features/puzzle/domain/tile_color.dart';
import 'package:mythdusk/features/puzzle/domain/tile_id_gen.dart';

void main() {
  group('capMatchCollectParticles', () {
    MatchCollectParticle p(int id) => MatchCollectParticle(
          id: id,
          resourceId: 'mana',
          startGlobal: Offset.zero,
        );

    test('returns all when under cap', () {
      final input = [p(0), p(1), p(2)];
      expect(capMatchCollectParticles(input), input);
    });

    test('samples evenly when over cap', () {
      final input = [for (var i = 0; i < 24; i++) p(i)];
      final capped = capMatchCollectParticles(input, max: 12);
      expect(capped, hasLength(12));
      expect(capped.first.id, 0);
      expect(capped.last.id, lessThan(24));
      expect(capped.map((e) => e.id).toSet(), hasLength(12));
    });
  });

  testWidgets('resource shards wait for their individual pop times',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final targets = container.read(resourceFlyTargetsProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Stack(
          fit: StackFit.expand,
          children: [
            Center(
                child: SizedBox(
                    key: targets.resourceKeys['mana'], width: 20, height: 20)),
            const MatchCollectOverlay(),
          ],
        ),
      ),
    ));

    container.read(matchCollectFlightsProvider.notifier).state = const [
      MatchCollectParticle(
        id: 1,
        resourceId: 'mana',
        startGlobal: Offset(100, 200),
        launchDelay: Duration(milliseconds: 100),
      ),
      MatchCollectParticle(
        id: 2,
        resourceId: 'mana',
        startGlobal: Offset(200, 200),
        launchDelay: Duration(milliseconds: 300),
      ),
    ];

    await tester.pump(const Duration(milliseconds: 99));
    expect(find.byType(Image), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(Image), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(Image), findsNWidgets(2));
    await tester.pumpAndSettle();
  });

  group('BattleController juice timings', () {
    test('cascade steps are snappier than swap', () {
      expect(
        BattleController.clearDuration.inMilliseconds,
        lessThan(280),
      );
      expect(
        BattleController.fallDuration.inMilliseconds,
        lessThan(300),
      );
      expect(
        BattleController.swapDuration.inMilliseconds,
        lessThanOrEqualTo(180),
      );
    });
  });

  group('matchCollectFlightGlobal', () {
    test('starts and ends on the lerp endpoints', () {
      const start = Offset(10, 20);
      const end = Offset(110, 220);
      expect(
        matchCollectFlightGlobal(
          startGlobal: start,
          endGlobal: end,
          t: 0,
          arcLift: 40,
        ),
        start,
      );
      expect(
        matchCollectFlightGlobal(
          startGlobal: start,
          endGlobal: end,
          t: 1,
          arcLift: 40,
        ),
        end,
      );
    });

    test('midpoint arcs upward', () {
      const start = Offset(0, 100);
      const end = Offset(100, 100);
      final mid = matchCollectFlightGlobal(
        startGlobal: start,
        endGlobal: end,
        t: 0.5,
        arcLift: 40,
      );
      expect(mid.dx, 50);
      expect(mid.dy, lessThan(100));
    });
  });

  for (final reduceMotion in [false, true]) {
    testWidgets(
        'multi-row gravity ${reduceMotion ? "snaps with reduced motion" : "animates and settles"}',
        (tester) async {
      PuzzleBoard boardAt(int row) => PuzzleBoard(
            width: 1,
            height: 4,
            cells: [
              for (var r = 0; r < 4; r++)
                if (r == row)
                  BoardCell.tile(id: 1, color: TileColor.red)
                else
                  BoardCell.empty()
            ],
          );
      final initial = BattleState.initial(
        hero: HeroCatalog.mage,
        board: boardAt(0),
      );
      Widget frame(BattleState battle) => MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: Center(
                  child: SizedBox(
                      width: 320,
                      height: 320,
                      child: AnimatedPuzzleBoard(
                          battle: battle, onTap: (_, __) {}))),
            ),
          );
      final gem = find.byKey(const ValueKey('tile-1'));
      await tester.pumpWidget(frame(initial));
      await tester.pumpAndSettle();
      final start = tester.getTopLeft(gem).dy;
      await tester.pumpWidget(frame(initial.copyWith(board: boardAt(3))));
      await tester.pump(const Duration(milliseconds: 100));
      final during = tester.getTopLeft(gem).dy;
      await tester.pumpAndSettle();
      final end = tester.getTopLeft(gem).dy;
      expect(end, greaterThan(start));
      if (reduceMotion) {
        expect(during, end);
      } else {
        expect(during, greaterThan(start));
        expect(during, lessThan(end));
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final special
      in TileSpecial.values.where((s) => s != TileSpecial.none)) {
    testWidgets('${special.name} paints during clear and is removed afterward',
        (tester) async {
      final board = PuzzleBoard(width: 3, height: 3, cells: [
        for (var i = 0; i < 9; i++)
          BoardCell.tile(
              id: i + 1,
              color: TileColor.red,
              special: i == 4 ? special : TileSpecial.none),
      ]);
      final initial = BattleState.initial(hero: HeroCatalog.mage, board: board);
      Widget frame(BattleState battle, {bool reduceMotion = false}) =>
          MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduceMotion),
                child: Center(
                    child: SizedBox(
                        width: 320,
                        height: 320,
                        child: AnimatedPuzzleBoard(
                            battle: battle, onTap: (_, __) {})))),
          );
      final clearing = initial.copyWith(clearingCells: {
        for (var r = 0; r < 3; r++)
          for (var c = 0; c < 3; c++) (r, c),
      });
      await tester.pumpWidget(frame(initial));
      await tester.pumpWidget(frame(clearing));
      expect(find.byType(BoardPowerupFx), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(frame(initial));
      expect(find.byType(BoardPowerupFx), findsNothing);
      await tester.pumpWidget(frame(clearing, reduceMotion: true));
      expect(find.byType(BoardPowerupFx), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('refill tiles and existing gems descend in the same beat',
      (tester) async {
    final existing = BoardCell.tile(id: 1, color: TileColor.red);
    final newGem = BoardCell.tile(id: 2, color: TileColor.blue);
    PuzzleBoard column(List<BoardCell> cells) =>
        PuzzleBoard(width: 1, height: 4, cells: cells);
    final empty = BoardCell.empty();
    final initial = BattleState.initial(
      hero: HeroCatalog.mage,
      board: column([existing, empty, empty, empty]),
    );
    Widget frame(BattleState battle) => MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: AnimatedPuzzleBoard(battle: battle, onTap: (_, __) {}),
            ),
          ),
        );

    final falling = find.byKey(const ValueKey('tile-1'));
    final spawning = find.byKey(const ValueKey('tile-2'));
    await tester.pumpWidget(frame(initial));
    final oldStart = tester.getTopLeft(falling).dy;
    await tester.pumpWidget(frame(initial.copyWith(
      board: column([newGem, empty, empty, existing]),
      spawningIds: {2},
    )));
    final spawnStart = tester.getTopLeft(spawning).dy;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    final oldMid = tester.getTopLeft(falling).dy;
    final spawnMid = tester.getTopLeft(spawning).dy;
    await tester.pumpAndSettle();
    expect(oldMid, greaterThan(oldStart));
    expect(oldMid, lessThan(tester.getTopLeft(falling).dy));
    expect(spawnMid, greaterThan(spawnStart));
    expect(spawnMid, lessThan(tester.getTopLeft(spawning).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('match clear expands before collapsing', (tester) async {
    final board = PuzzleBoard(width: 1, height: 1, cells: [
      BoardCell.tile(id: 1, color: TileColor.red),
    ]);
    final initial = BattleState.initial(hero: HeroCatalog.mage, board: board);
    Widget frame(BattleState battle) => MaterialApp(
          home: SizedBox(
              width: 320,
              height: 320,
              child: AnimatedPuzzleBoard(battle: battle, onTap: (_, __) {})),
        );
    double scale() => tester
        .widget<Transform>(find
            .descendant(
              of: find.byType(AnimatedScale),
              matching: find.byType(Transform),
            )
            .first)
        .transform
        .storage[0];
    await tester.pumpWidget(frame(initial));
    await tester.pumpAndSettle();
    await tester.pumpWidget(frame(initial.copyWith(clearingCells: {(0, 0)})));
    await tester.pump(const Duration(milliseconds: 50));
    expect(scale(), greaterThan(1));
    await tester.pump(const Duration(milliseconds: 130));
    expect(scale(), lessThan(1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving a board without hints does not throw on dispose',
      (tester) async {
    final battle = BattleState.initial(
      hero: HeroCatalog.mage,
      board: PuzzleBoard.squarePlayable(random: Random(1), ids: TileIdGen(1)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 400,
          child: AnimatedPuzzleBoard(
            battle: battle,
            onTap: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
