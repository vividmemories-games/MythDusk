import 'overlay_def.dart';
import 'tile_color.dart';

/// Special tiles from shape matches / merges.
enum TileSpecial {
  none,

  /// Clears its column when activated. Created by horizontal line of 4.
  rocketVertical,

  /// Clears its row when activated. Created by vertical line of 4.
  rocketHorizontal,

  /// Clears a 3×3 area when activated.
  bomb,

  /// Clears all tiles of a color (tap = random, swap = that tile's color).
  fireball,

  /// Clears 8 random playable tiles (including self).
  seeker,
}

extension TileSpecialPriority on TileSpecial {
  /// Higher wins when multiple shapes claim the same creation cell.
  int get creationRank => switch (this) {
        TileSpecial.fireball => 40,
        TileSpecial.bomb => 30,
        TileSpecial.seeker => 20,
        TileSpecial.rocketVertical || TileSpecial.rocketHorizontal => 10,
        TileSpecial.none => 0,
      };

  bool get isRocket =>
      this == TileSpecial.rocketVertical ||
      this == TileSpecial.rocketHorizontal;
}

/// A single cell on the puzzle board.
class BoardCell {
  const BoardCell({
    this.id,
    this.color,
    this.special = TileSpecial.none,
    this.masked = false,
    this.obstacleLayers = 0,
    this.overlayId,
    this.overlayArchetype,
    this.overlayBreakRule,
    this.overlayHazard = OverlayHazard.none,
  });

  final int? id;

  /// Tint / clear identity. Power-ups may keep a tint for fireball chaining
  /// but never participate in color matching ([matchColor] is null when special).
  final TileColor? color;
  final TileSpecial special;
  final bool masked;
  final int obstacleLayers;

  /// Catalog overlay id when [obstacleLayers] > 0.
  final String? overlayId;
  final OverlayArchetype? overlayArchetype;
  final OverlayBreakRule? overlayBreakRule;
  final OverlayHazard overlayHazard;

  bool get hasSpecial => special != TileSpecial.none;
  bool get isEmpty => !masked && color == null && !hasSpecial && !hasObstacle;
  bool get isPlayable =>
      !masked && !isSolidObstacle && (hasSpecial || color != null);
  bool get isMatchable =>
      !masked && !isSolidObstacle && !hasSpecial && color != null;
  bool get hasObstacle => obstacleLayers > 0;

  /// Static blocker — occupies the cell; gravity treats like a hole.
  bool get isSolidObstacle =>
      hasObstacle && overlayArchetype == OverlayArchetype.blocker;

  /// Binder overlay on (or waiting for) a tile.
  bool get isBinderObstacle =>
      hasObstacle && overlayArchetype == OverlayArchetype.binder;

  bool get suppressesResources =>
      hasObstacle && overlayHazard == OverlayHazard.suppressResources;

  /// Color used for shape matching — always null for power-ups.
  TileColor? get matchColor => hasSpecial ? null : color;

  static BoardCell empty() => const BoardCell();

  static BoardCell maskedHole() => const BoardCell(masked: true);

  static BoardCell blocker({
    required String overlayId,
    required int layers,
    OverlayBreakRule breakRule = OverlayBreakRule.adjacentMatch,
    OverlayHazard hazard = OverlayHazard.none,
  }) {
    assert(layers > 0);
    return BoardCell(
      obstacleLayers: layers,
      overlayId: overlayId,
      overlayArchetype: OverlayArchetype.blocker,
      overlayBreakRule: breakRule,
      overlayHazard: hazard,
    );
  }

  /// Places an overlay from catalog metadata onto an empty or tiled cell.
  static BoardCell withOverlay({
    required OverlayDef def,
    required int layers,
    int? id,
    TileColor? color,
    TileSpecial special = TileSpecial.none,
  }) {
    final clamped = layers.clamp(1, def.maxLayers);
    if (def.isBlocker) {
      return BoardCell.blocker(
        overlayId: def.id,
        layers: clamped,
        breakRule: def.breakRule,
        hazard: def.hazard,
      );
    }
    if (special != TileSpecial.none && id != null) {
      return BoardCell.powerUp(
        id: id,
        special: special,
        tint: color,
        obstacleLayers: clamped,
        overlayId: def.id,
        overlayArchetype: OverlayArchetype.binder,
        overlayBreakRule: def.breakRule,
        overlayHazard: def.hazard,
      );
    }
    if (id != null && color != null) {
      return BoardCell.tile(
        id: id,
        color: color,
        obstacleLayers: clamped,
        overlayId: def.id,
        overlayArchetype: OverlayArchetype.binder,
        overlayBreakRule: def.breakRule,
        overlayHazard: def.hazard,
      );
    }
    return BoardCell(
      obstacleLayers: clamped,
      overlayId: def.id,
      overlayArchetype: OverlayArchetype.binder,
      overlayBreakRule: def.breakRule,
      overlayHazard: def.hazard,
    );
  }

  static BoardCell tile({
    required int id,
    required TileColor color,
    TileSpecial special = TileSpecial.none,
    int obstacleLayers = 0,
    String? overlayId,
    OverlayArchetype? overlayArchetype,
    OverlayBreakRule? overlayBreakRule,
    OverlayHazard overlayHazard = OverlayHazard.none,
  }) {
    if (special != TileSpecial.none) {
      return BoardCell.powerUp(
        id: id,
        special: special,
        tint: color,
        obstacleLayers: obstacleLayers,
        overlayId: overlayId,
        overlayArchetype: overlayArchetype,
        overlayBreakRule: overlayBreakRule,
        overlayHazard: overlayHazard,
      );
    }
    return BoardCell(
      id: id,
      color: color,
      obstacleLayers: obstacleLayers,
      overlayId: overlayId,
      overlayArchetype: overlayArchetype,
      overlayBreakRule: overlayBreakRule,
      overlayHazard: overlayHazard,
    );
  }

  static BoardCell powerUp({
    required int id,
    required TileSpecial special,
    TileColor? tint,
    int obstacleLayers = 0,
    String? overlayId,
    OverlayArchetype? overlayArchetype,
    OverlayBreakRule? overlayBreakRule,
    OverlayHazard overlayHazard = OverlayHazard.none,
  }) {
    assert(special != TileSpecial.none);
    return BoardCell(
      id: id,
      color: tint,
      special: special,
      obstacleLayers: obstacleLayers,
      overlayId: overlayId,
      overlayArchetype: overlayArchetype,
      overlayBreakRule: overlayBreakRule,
      overlayHazard: overlayHazard,
    );
  }

  BoardCell copyWith({
    int? id,
    TileColor? color,
    TileSpecial? special,
    bool? masked,
    int? obstacleLayers,
    String? overlayId,
    OverlayArchetype? overlayArchetype,
    OverlayBreakRule? overlayBreakRule,
    OverlayHazard? overlayHazard,
    bool clearTile = false,
    bool clearColor = false,
    bool clearOverlay = false,
  }) {
    if (clearTile) {
      return BoardCell(
        masked: masked ?? this.masked,
        obstacleLayers:
            clearOverlay ? 0 : (obstacleLayers ?? this.obstacleLayers),
        overlayId: clearOverlay ? null : (overlayId ?? this.overlayId),
        overlayArchetype:
            clearOverlay ? null : (overlayArchetype ?? this.overlayArchetype),
        overlayBreakRule:
            clearOverlay ? null : (overlayBreakRule ?? this.overlayBreakRule),
        overlayHazard: clearOverlay
            ? OverlayHazard.none
            : (overlayHazard ?? this.overlayHazard),
      );
    }
    return BoardCell(
      id: id ?? this.id,
      color: clearColor ? null : (color ?? this.color),
      special: special ?? this.special,
      masked: masked ?? this.masked,
      obstacleLayers:
          clearOverlay ? 0 : (obstacleLayers ?? this.obstacleLayers),
      overlayId: clearOverlay ? null : (overlayId ?? this.overlayId),
      overlayArchetype:
          clearOverlay ? null : (overlayArchetype ?? this.overlayArchetype),
      overlayBreakRule:
          clearOverlay ? null : (overlayBreakRule ?? this.overlayBreakRule),
      overlayHazard: clearOverlay
          ? OverlayHazard.none
          : (overlayHazard ?? this.overlayHazard),
    );
  }

  /// Returns this cell with [layers] removed from the overlay (clears at 0).
  BoardCell damageOverlay([int layers = 1]) {
    if (!hasObstacle || layers <= 0) return this;
    final next = obstacleLayers - layers;
    if (next <= 0) return copyWith(clearOverlay: true);
    return copyWith(obstacleLayers: next);
  }
}
