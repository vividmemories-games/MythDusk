/// Per-battle Daily medal kinds (full Daily mode UI is M5).
///
/// These share [BattleProgress] settlement with Weekly/Campaign; Daily
/// schedules and claim UI land in the Daily milestone.
enum DailyBattleMedalType {
  matchTilesColor('match_tiles_color'),
  breakOverlays('break_overlays'),
  finishAboveHpPct('finish_above_hp_pct'),
  finishWithoutPrep('finish_without_prep'),
  underPlayerTurns('under_player_turns'),
  generateResource('generate_resource'),
  castSkills('cast_skills'),
  castDistinctSkills('cast_distinct_skills');

  const DailyBattleMedalType(this.wireName);
  final String wireName;

  static DailyBattleMedalType parse(Object? raw) {
    for (final t in values) {
      if (t.wireName == raw || t.name == raw) return t;
    }
    throw FormatException('Unknown daily battle medal type: $raw');
  }
}
