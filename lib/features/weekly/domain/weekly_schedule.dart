/// Weekly objective types (Mon–Fri puzzle modes).
enum WeeklyObjectiveType {
  surviveTurns,
  clearTiles,
}

/// Battle-side objective progress (null for normal campaign HP fights).
class BattleObjective {
  const BattleObjective({
    required this.type,
    required this.target,
  });

  final WeeklyObjectiveType type;
  final int target;

  String get progressLabel => switch (type) {
        WeeklyObjectiveType.surviveTurns => 'Survive $target turns',
        WeeklyObjectiveType.clearTiles => 'Clear $target tiles',
      };

  String progressText(
      {required int playerTurnNumber, required int tilesCleared}) {
    return switch (type) {
      WeeklyObjectiveType.surviveTurns =>
        'Turn ${playerTurnNumber.clamp(0, target)}/$target',
      WeeklyObjectiveType.clearTiles =>
        'Tiles ${tilesCleared.clamp(0, target)}/$target',
    };
  }

  bool isMet({required int playerTurnNumber, required int tilesCleared}) {
    return switch (type) {
      WeeklyObjectiveType.surviveTurns => playerTurnNumber >= target,
      WeeklyObjectiveType.clearTiles => tilesCleared >= target,
    };
  }
}

/// One day's weekly challenge (objective or weekend boss).
class WeeklyChallenge {
  const WeeklyChallenge({
    required this.dayKey,
    required this.isWeekend,
    required this.title,
    required this.blurb,
    required this.enemyId,
    required this.coinReward,
    required this.enemyName,
    this.objective,
    this.enrageAfterTurns,
  });

  final String dayKey;
  final bool isWeekend;
  final String title;
  final String blurb;
  final String enemyId;
  final String enemyName;
  final int coinReward;
  final BattleObjective? objective;
  final int? enrageAfterTurns;

  bool get isBoss => isWeekend;
}

/// Weekly balance knobs — owned by docs/01_Game_Design/Balancing_Bible.md §3.4.
abstract final class WeeklyBalance {
  static const surviveTurnsTarget = 7;
  static const clearTilesTarget = 60;
  static const weekdayCoinReward = 40;
  static const weekendCoinReward = 80;
  static const weekendEnrageAfterTurns = 8;

  /// HP and skill damage vs campaign art counterparts.
  static const enemyStatMultiplier = 2.0;

  /// Stable battle route id (not a campaign node).
  static const battleNodeId = 'weekly';

  static const bossIds = [
    'weekly_boss_01',
    'weekly_boss_02',
    'weekly_boss_03',
    'weekly_boss_04',
    'weekly_boss_05',
  ];
}

/// Builds today's challenge from local calendar time.
///
/// Firebase must own day/week validation when progress is server-backed;
/// this client schedule is a solo-dev / mock stub only.
abstract final class WeeklySchedule {
  static String dayKey(DateTime local) {
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  }

  static int _hash(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  /// ISO-8601 week year + week number for weekend boss rotation.
  static (int year, int week) isoWeek(DateTime local) {
    // Thursday of this week determines ISO week-year.
    final thursday =
        local.add(Duration(days: DateTime.thursday - local.weekday));
    final weekYear = thursday.year;
    final jan4 = DateTime(weekYear, 1, 4);
    final week1Thursday =
        jan4.add(Duration(days: DateTime.thursday - jan4.weekday));
    final week = 1 + thursday.difference(week1Thursday).inDays ~/ 7;
    return (weekYear, week);
  }

  static WeeklyChallenge forDate(DateTime local) {
    final key = dayKey(local);
    final weekend =
        local.weekday == DateTime.saturday || local.weekday == DateTime.sunday;

    if (weekend) {
      final (y, w) = isoWeek(local);
      final idx = _hash('$y-W$w') % WeeklyBalance.bossIds.length;
      final enemyId = WeeklyBalance.bossIds[idx];
      final name = _bossName(enemyId);
      return WeeklyChallenge(
        dayKey: key,
        isWeekend: true,
        title: 'Weekend Boss',
        blurb: 'Extreme bout — defeat $name.',
        enemyId: enemyId,
        enemyName: name,
        coinReward: WeeklyBalance.weekendCoinReward,
        enrageAfterTurns: WeeklyBalance.weekendEnrageAfterTurns,
      );
    }

    final survive = _hash(key) % 2 == 0;
    final objective = BattleObjective(
      type: survive
          ? WeeklyObjectiveType.surviveTurns
          : WeeklyObjectiveType.clearTiles,
      target: survive
          ? WeeklyBalance.surviveTurnsTarget
          : WeeklyBalance.clearTilesTarget,
    );
    return WeeklyChallenge(
      dayKey: key,
      isWeekend: false,
      title: survive ? 'Survive the Onslaught' : 'Clear the Board',
      blurb: objective.progressLabel,
      enemyId: 'weekly_scout',
      enemyName: 'Weekly Scout',
      coinReward: WeeklyBalance.weekdayCoinReward,
      objective: objective,
    );
  }

  static String _bossName(String id) => switch (id) {
        'weekly_boss_01' => 'Dusk Warden',
        'weekly_boss_02' => 'Ash Herald',
        'weekly_boss_03' => 'Tide Marauder',
        'weekly_boss_04' => 'Gilded Scourge',
        'weekly_boss_05' => 'Eclipse Judge',
        _ => 'Weekly Boss',
      };
}
