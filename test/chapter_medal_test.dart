import 'package:flutter_test/flutter_test.dart';

import 'package:mythdusk/features/battle/domain/battle_objective.dart';
import 'package:mythdusk/features/campaign/data/chapter_medal_catalog.dart';
import 'package:mythdusk/features/campaign/domain/chapter_medal.dart';
import 'package:mythdusk/features/daily/domain/daily_battle_medal.dart';

void main() {
  group('ChapterMedalCatalog', () {
    test('defines 40 medals across 10 chapters (4 each)', () {
      expect(ChapterMedalCatalog.all.length, 40);
      final byChapter = <String, int>{};
      for (final m in ChapterMedalCatalog.all) {
        byChapter[m.chapterId] = (byChapter[m.chapterId] ?? 0) + 1;
      }
      expect(byChapter.length, 10);
      expect(byChapter.values.every((n) => n == 4), isTrue);
    });
  });

  group('ChapterMedalFold', () {
    test('accumulates color clears, skills, and hp wins', () {
      final next = ChapterMedalFold.applyVictory(
        current: const ChapterMedalCounters(),
        progress: const BattleProgress(
          playerTurnNumber: 5,
          tilesClearedByColor: {'red': 12, 'blue': 3},
          resourcesGenerated: {'mana': 8},
          overlaysBroken: 2,
          skillsCastCount: 3,
          skillsCastIds: ['a', 'b', 'c'],
          usedPrep: false,
        ),
        heroHp: 80,
        heroMaxHp: 100,
        usedPrep: false,
        bossForm: 4,
      );

      expect(next.tilesByColor['red'], 12);
      expect(next.overlaysBroken, 2);
      expect(next.winsAboveHpPct, 1);
      expect(next.winsWithoutPrep, 1);
      expect(next.skillsCast, 3);
      expect(next.bossFormTurns['4'], 5);
      expect(next.totalPlayerTurns, 5);
      expect(next.resourcesGenerated['mana'], 8);
    });

    test('keeps best (lowest) boss form turn count', () {
      final first = ChapterMedalFold.applyVictory(
        current: const ChapterMedalCounters(),
        progress: const BattleProgress(playerTurnNumber: 9),
        heroHp: 10,
        heroMaxHp: 100,
        usedPrep: true,
        bossForm: 4,
      );
      final second = ChapterMedalFold.applyVictory(
        current: first,
        progress: const BattleProgress(playerTurnNumber: 6),
        heroHp: 10,
        heroMaxHp: 100,
        usedPrep: true,
        bossForm: 4,
      );
      expect(second.bossFormTurns['4'], 6);
    });
  });

  group('ChapterMedalCounters.isMet', () {
    test('match tiles requires target count', () {
      const def = ChapterMedalDefinition(
        id: 't',
        chapterId: 'twilight_road',
        title: 'T',
        type: ChapterMedalType.matchTilesColor,
        target: 10,
        colorId: 'red',
      );
      expect(
        const ChapterMedalCounters(tilesByColor: {'red': 9}).isMet(def),
        isFalse,
      );
      expect(
        const ChapterMedalCounters(tilesByColor: {'red': 10}).isMet(def),
        isTrue,
      );
    });

    test('pace medal requires chapter complete', () {
      const def = ChapterMedalDefinition(
        id: 'pace',
        chapterId: 'twilight_road',
        title: 'Pace',
        type: ChapterMedalType.chapterTotalPlayerTurns,
        target: 100,
      );
      const counters = ChapterMedalCounters(totalPlayerTurns: 40);
      expect(counters.isMet(def), isFalse);
      expect(counters.isMet(def, chapterComplete: true), isTrue);
    });
  });

  group('DailyBattleMedalType', () {
    test('parses wire names', () {
      expect(
        DailyBattleMedalType.parse('break_overlays'),
        DailyBattleMedalType.breakOverlays,
      );
      expect(DailyBattleMedalType.values.length, 8);
    });
  });

  group('BattleProgress', () {
    test('exposes distinct skill casts', () {
      const p = BattleProgress(
        skillsCastIds: ['a', 'b', 'a'],
        skillsCastCount: 3,
      );
      expect(p.distinctSkillsCast, {'a', 'b'});
    });
  });
}
