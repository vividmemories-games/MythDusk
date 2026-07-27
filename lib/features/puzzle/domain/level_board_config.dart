import 'tile_spawn_weights.dart';

/// Deterministic board transform applied on a schedule.
///
/// Execution is deferred; this model is the JSON contract.
class BoardMoverConfig {
  const BoardMoverConfig({
    required this.type,
    this.rows = const [],
    this.cols = const [],
    this.direction = 'left',
    this.everyNTurns = 1,
  });

  /// e.g. `row_shove`, `col_shove`
  final String type;
  final List<int> rows;
  final List<int> cols;

  /// `left` | `right` | `up` | `down`
  final String direction;
  final int everyNTurns;

  factory BoardMoverConfig.fromJson(Map<String, dynamic> json) {
    return BoardMoverConfig(
      type: json['type'] as String,
      rows: _intList(json['rows']),
      cols: _intList(json['cols']),
      direction: json['direction'] as String? ?? 'left',
      everyNTurns: json['everyNTurns'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (rows.isNotEmpty) 'rows': rows,
        if (cols.isNotEmpty) 'cols': cols,
        'direction': direction,
        'everyNTurns': everyNTurns,
      };

  static List<int> _intList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is num) e.toInt(),
    ];
  }
}

/// Optional per-turn hazard spawn knobs (execution deferred to Ch2+).
class HazardSpawnConfig {
  const HazardSpawnConfig({
    required this.overlayId,
    this.chancePerTurn = 0.0,
    this.maxOnBoard = 0,
  });

  final String overlayId;
  final double chancePerTurn;
  final int maxOnBoard;

  factory HazardSpawnConfig.fromJson(Map<String, dynamic> json) {
    return HazardSpawnConfig(
      overlayId: json['overlayId'] as String,
      chancePerTurn: (json['chancePerTurn'] as num?)?.toDouble() ?? 0.0,
      maxOnBoard: json['maxOnBoard'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'overlayId': overlayId,
        'chancePerTurn': chancePerTurn,
        'maxOnBoard': maxOnBoard,
      };
}

/// Per-level (or chapter-default) board modifiers referencing a template.
class LevelBoardConfig {
  const LevelBoardConfig({
    this.templateId,
    this.spawnWeights,
    this.movers,
    this.hazardSpawn,
  });

  final String? templateId;
  final TileSpawnWeights? spawnWeights;
  final List<BoardMoverConfig>? movers;
  final HazardSpawnConfig? hazardSpawn;

  bool get hasTemplate => templateId != null && templateId!.isNotEmpty;

  TileSpawnWeights get effectiveSpawnWeights =>
      spawnWeights ?? TileSpawnWeights.uniform;

  List<BoardMoverConfig> get effectiveMovers => movers ?? const [];

  factory LevelBoardConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LevelBoardConfig();
    final moversRaw = json['movers'] as List<dynamic>?;
    final weightsRaw = json['spawnWeights'] as Map<String, dynamic>?;
    final hazardRaw = json['hazardSpawn'] as Map<String, dynamic>?;
    return LevelBoardConfig(
      templateId: json['templateId'] as String?,
      spawnWeights:
          weightsRaw == null ? null : TileSpawnWeights.fromJson(weightsRaw),
      movers: moversRaw == null
          ? null
          : [
              for (final e in moversRaw)
                BoardMoverConfig.fromJson(e as Map<String, dynamic>),
            ],
      hazardSpawn:
          hazardRaw == null ? null : HazardSpawnConfig.fromJson(hazardRaw),
    );
  }

  /// Node fields override chapter defaults; lists replace rather than append.
  LevelBoardConfig mergeOver(LevelBoardConfig defaults) {
    return LevelBoardConfig(
      templateId: templateId ?? defaults.templateId,
      spawnWeights: spawnWeights ?? defaults.spawnWeights,
      movers: movers ?? defaults.movers,
      hazardSpawn: hazardSpawn ?? defaults.hazardSpawn,
    );
  }
}
