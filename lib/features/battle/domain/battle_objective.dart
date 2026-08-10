import 'enemy_effect.dart';

/// Shared battle objective kinds (Weekly, Daily, and future modes).
enum BattleObjectiveType {
  surviveTurns,
  clearTiles,
}

/// Typed alias kept for Weekly call sites during migration.
typedef WeeklyObjectiveType = BattleObjectiveType;

/// Battle-side primary objective (null for normal campaign HP fights).
class BattleObjective {
  const BattleObjective({
    required this.type,
    required this.target,
  });

  final BattleObjectiveType type;
  final int target;

  String get progressLabel => switch (type) {
        BattleObjectiveType.surviveTurns => 'Survive $target turns',
        BattleObjectiveType.clearTiles => 'Clear $target tiles',
      };

  String progressText({
    required int playerTurnNumber,
    required int tilesCleared,
  }) {
    return switch (type) {
      BattleObjectiveType.surviveTurns =>
        'Turn ${playerTurnNumber.clamp(0, target)}/$target',
      BattleObjectiveType.clearTiles =>
        'Tiles ${tilesCleared.clamp(0, target)}/$target',
    };
  }

  bool isMet({required int playerTurnNumber, required int tilesCleared}) {
    return switch (type) {
      BattleObjectiveType.surviveTurns => playerTurnNumber >= target,
      BattleObjectiveType.clearTiles => tilesCleared >= target,
    };
  }
}

/// Cumulative battle counters for objectives, medals, and mastery folds.
///
/// Updated only from [BattleController] — never from widgets.
class BattleProgress {
  const BattleProgress({
    this.playerTurnNumber = 0,
    this.tilesCleared = 0,
    this.tilesClearedByColor = const {},
    this.resourcesGenerated = const {},
    this.overlaysBroken = 0,
    this.overlaysBrokenById = const {},
    this.skillsCastCount = 0,
    this.skillsCastIds = const [],
    this.usedPrep = false,
  });

  final int playerTurnNumber;
  final int tilesCleared;
  final Map<String, int> tilesClearedByColor;
  final Map<String, int> resourcesGenerated;
  final int overlaysBroken;
  final Map<String, int> overlaysBrokenById;
  final int skillsCastCount;
  final List<String> skillsCastIds;
  final bool usedPrep;

  Set<String> get distinctSkillsCast => skillsCastIds.toSet();

  BattleProgress copyWith({
    int? playerTurnNumber,
    int? tilesCleared,
    Map<String, int>? tilesClearedByColor,
    Map<String, int>? resourcesGenerated,
    int? overlaysBroken,
    Map<String, int>? overlaysBrokenById,
    int? skillsCastCount,
    List<String>? skillsCastIds,
    bool? usedPrep,
  }) {
    return BattleProgress(
      playerTurnNumber: playerTurnNumber ?? this.playerTurnNumber,
      tilesCleared: tilesCleared ?? this.tilesCleared,
      tilesClearedByColor: tilesClearedByColor ?? this.tilesClearedByColor,
      resourcesGenerated: resourcesGenerated ?? this.resourcesGenerated,
      overlaysBroken: overlaysBroken ?? this.overlaysBroken,
      overlaysBrokenById: overlaysBrokenById ?? this.overlaysBrokenById,
      skillsCastCount: skillsCastCount ?? this.skillsCastCount,
      skillsCastIds: skillsCastIds ?? this.skillsCastIds,
      usedPrep: usedPrep ?? this.usedPrep,
    );
  }

  int resourceGenerated(BattleResource resource) =>
      resourcesGenerated[resource.id] ?? 0;

  int tilesOfColor(String colorId) => tilesClearedByColor[colorId] ?? 0;
}
