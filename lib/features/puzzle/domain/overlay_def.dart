/// How an overlay breaks when matched against.
enum OverlayBreakRule {
  /// Clear when a match happens in an adjacent playable cell.
  adjacentMatch,

  /// Clear when the tile under this overlay is matched.
  matchUnder,
}

/// Blocker occupies the cell; binder traps a tile underneath.
enum OverlayArchetype {
  blocker,
  binder,
}

/// Hazard effect while the overlay remains on the board.
enum OverlayHazard {
  none,
  suppressResources,
}

/// Catalog entry for a board overlay type (rock, vine, poison, …).
class OverlayDef {
  const OverlayDef({
    required this.id,
    required this.archetype,
    required this.breakRule,
    this.maxLayers = 1,
    this.hazard = OverlayHazard.none,
    this.schemaVersion = 1,
    this.contentVersion = 1,
    this.isEnabled = true,
  });

  final String id;
  final OverlayArchetype archetype;
  final OverlayBreakRule breakRule;
  final int maxLayers;
  final OverlayHazard hazard;
  final int schemaVersion;
  final int contentVersion;
  final bool isEnabled;

  bool get isBlocker => archetype == OverlayArchetype.blocker;
  bool get isBinder => archetype == OverlayArchetype.binder;
  bool get suppressesResources => hazard == OverlayHazard.suppressResources;

  factory OverlayDef.fromJson(Map<String, dynamic> json) {
    return OverlayDef(
      id: json['id'] as String,
      archetype: _archetype(json['archetype'] as String?),
      breakRule: _breakRule(json['breakRule'] as String?),
      maxLayers: json['maxLayers'] as int? ?? 1,
      hazard: _hazard(json['hazard'] as String?),
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      contentVersion: json['contentVersion'] as int? ?? 1,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  static OverlayArchetype _archetype(String? raw) => switch (raw) {
        'binder' => OverlayArchetype.binder,
        _ => OverlayArchetype.blocker,
      };

  static OverlayBreakRule _breakRule(String? raw) => switch (raw) {
        'match_under' => OverlayBreakRule.matchUnder,
        _ => OverlayBreakRule.adjacentMatch,
      };

  static OverlayHazard _hazard(String? raw) => switch (raw) {
        'suppress_resources' => OverlayHazard.suppressResources,
        _ => OverlayHazard.none,
      };
}

/// Loaded overlay catalog keyed by id.
class OverlayCatalog {
  OverlayCatalog(List<OverlayDef> overlays)
      : _byId = {for (final o in overlays) o.id: o};

  final Map<String, OverlayDef> _byId;

  OverlayDef? operator [](String id) => _byId[id];

  OverlayDef require(String id) {
    final def = _byId[id];
    if (def == null) {
      throw StateError('Unknown overlay id: $id');
    }
    return def;
  }

  Iterable<OverlayDef> get all => _byId.values;

  factory OverlayCatalog.fromJson(Map<String, dynamic> json) {
    final raw = json['overlays'] as List<dynamic>? ?? const [];
    return OverlayCatalog([
      for (final e in raw) OverlayDef.fromJson(e as Map<String, dynamic>),
    ]);
  }
}
