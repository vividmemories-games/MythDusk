import '../domain/chapter_medal.dart';

/// Four medals × ten chapters = 40 definitions (retention M3).
abstract final class ChapterMedalCatalog {
  static List<ChapterMedalDefinition> forChapter(String chapterId) {
    return all.where((m) => m.chapterId == chapterId).toList(growable: false);
  }

  static ChapterMedalDefinition? byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }

  static final all = <ChapterMedalDefinition>[
    // Twilight Road
    const ChapterMedalDefinition(
      id: 'medal_twilight_red_80',
      chapterId: 'twilight_road',
      title: 'Ember Path',
      type: ChapterMedalType.matchTilesColor,
      target: 80,
      colorId: 'red',
    ),
    const ChapterMedalDefinition(
      id: 'medal_twilight_hp_8',
      chapterId: 'twilight_road',
      title: 'Steady Steps',
      type: ChapterMedalType.winsAboveHpPct,
      target: 8,
      minHpPct: 50,
    ),
    const ChapterMedalDefinition(
      id: 'medal_twilight_boss4_8',
      chapterId: 'twilight_road',
      title: 'Swift Finale',
      type: ChapterMedalType.bossFormUnderTurns,
      target: 8,
      bossForm: 4,
    ),
    const ChapterMedalDefinition(
      id: 'medal_twilight_turns_100',
      chapterId: 'twilight_road',
      title: 'Quick Road',
      type: ChapterMedalType.chapterTotalPlayerTurns,
      target: 100,
    ),

    // Mistfen
    const ChapterMedalDefinition(
      id: 'medal_mistfen_green_100',
      chapterId: 'ch_mistfen',
      title: 'Marsh Greens',
      type: ChapterMedalType.matchTilesColor,
      target: 100,
      colorId: 'green',
    ),
    const ChapterMedalDefinition(
      id: 'medal_mistfen_overlays_25',
      chapterId: 'ch_mistfen',
      title: 'Clear the Mire',
      type: ChapterMedalType.breakOverlays,
      target: 25,
    ),
    const ChapterMedalDefinition(
      id: 'medal_mistfen_noprep_10',
      chapterId: 'ch_mistfen',
      title: 'Bare Boots',
      type: ChapterMedalType.winsWithoutPrep,
      target: 10,
    ),
    const ChapterMedalDefinition(
      id: 'medal_mistfen_cast_40',
      chapterId: 'ch_mistfen',
      title: 'Reed Casting',
      type: ChapterMedalType.castSkills,
      target: 40,
    ),

    // Howling
    const ChapterMedalDefinition(
      id: 'medal_howling_blue_90',
      chapterId: 'ch_howling',
      title: 'Wind Blues',
      type: ChapterMedalType.matchTilesColor,
      target: 90,
      colorId: 'blue',
    ),
    const ChapterMedalDefinition(
      id: 'medal_howling_mana_120',
      chapterId: 'ch_howling',
      title: 'Sky Mana',
      type: ChapterMedalType.generateResource,
      target: 120,
      resourceId: 'mana',
    ),
    const ChapterMedalDefinition(
      id: 'medal_howling_hp_10',
      chapterId: 'ch_howling',
      title: 'Ridge Guard',
      type: ChapterMedalType.winsAboveHpPct,
      target: 10,
    ),
    const ChapterMedalDefinition(
      id: 'medal_howling_boss4_9',
      chapterId: 'ch_howling',
      title: 'Pack Breaker',
      type: ChapterMedalType.bossFormUnderTurns,
      target: 9,
      bossForm: 4,
    ),

    // Ashen–Mythspire: reuse the 4-slot pattern with scaled targets
    ..._scaledChapter('ch_ashen', 'Ashen', 'yellow', 110, 30, 12, 110),
    ..._scaledChapter(
        'ch_candlecrypt', 'Candlecrypt', 'purple', 100, 20, 12, 120),
    ..._scaledChapter('ch_mirror', 'Mirror', 'blue', 120, 15, 12, 115),
    ..._scaledChapter('ch_thornmarket', 'Thornmarket', 'red', 130, 20, 14, 125),
    ..._scaledChapter('ch_skybridge', 'Skybridge', 'yellow', 120, 25, 12, 130),
    ..._scaledChapter('ch_eclipse', 'Eclipse', 'red', 140, 35, 14, 140),
    ..._scaledChapter('ch_mythspire', 'Mythspire', 'purple', 150, 40, 15, 150),
  ];

  static List<ChapterMedalDefinition> _scaledChapter(
    String chapterId,
    String label,
    String color,
    int colorTarget,
    int overlayTarget,
    int hpWins,
    int turnCap,
  ) {
    return [
      ChapterMedalDefinition(
        id: 'medal_${chapterId}_color',
        chapterId: chapterId,
        title: '$label Shards',
        type: ChapterMedalType.matchTilesColor,
        target: colorTarget,
        colorId: color,
      ),
      ChapterMedalDefinition(
        id: 'medal_${chapterId}_overlays',
        chapterId: chapterId,
        title: '$label Breaker',
        type: ChapterMedalType.breakOverlays,
        target: overlayTarget,
      ),
      ChapterMedalDefinition(
        id: 'medal_${chapterId}_hp',
        chapterId: chapterId,
        title: '$label Vitality',
        type: ChapterMedalType.winsAboveHpPct,
        target: hpWins,
      ),
      ChapterMedalDefinition(
        id: 'medal_${chapterId}_turns',
        chapterId: chapterId,
        title: '$label Pace',
        type: ChapterMedalType.chapterTotalPlayerTurns,
        target: turnCap,
      ),
    ];
  }
}
