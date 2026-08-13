import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/assets/game_assets.dart';
import '../../puzzle/domain/tile_color.dart';

/// Global keys for resource HUD chips (match-collect flight targets).
class ResourceFlyTargets {
  ResourceFlyTargets();

  final GlobalKey boardKey = GlobalKey(debugLabel: 'battle_board');
  final Map<String, GlobalKey> resourceKeys = {
    for (final id in const [
      'attack',
      'mana',
      'healing',
      'shield',
      'ultimate',
    ])
      id: GlobalKey(debugLabel: 'res_$id'),
  };

  Offset? globalCenterOf(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }
}

final resourceFlyTargetsProvider = Provider<ResourceFlyTargets>((ref) {
  return ResourceFlyTargets();
});

class MatchCollectParticle {
  const MatchCollectParticle({
    required this.id,
    required this.resourceId,
    required this.startGlobal,
  });

  final int id;
  final String resourceId;
  final Offset startGlobal;
}

/// Ephemeral flight list; UI consumes and clears.
final matchCollectFlightsProvider =
    StateProvider<List<MatchCollectParticle>>((ref) => const []);

/// Invalid-swap wobble pulse for the two bounced cells.
class BoardBouncePulse {
  const BoardBouncePulse({
    required this.cells,
    required this.token,
  });

  final Set<(int, int)> cells;
  final int token;
}

final boardBouncePulseProvider =
    StateProvider<BoardBouncePulse?>((ref) => null);

/// Per-resource bump tokens; chips pulse when the token changes.
final hudResourceBumpProvider =
    StateProvider<Map<String, int>>((ref) => const {});

/// Caps match-collect shards so large clears stay readable.
const kMaxMatchCollectParticles = 12;

List<MatchCollectParticle> capMatchCollectParticles(
  List<MatchCollectParticle> particles, {
  int max = kMaxMatchCollectParticles,
}) {
  if (particles.length <= max) return particles;
  if (max <= 0) return const [];
  final step = particles.length / max;
  return [
    for (var i = 0; i < max; i++) particles[(i * step).floor()],
  ];
}

String? resourceIdForTileColor(TileColor? color) => switch (color) {
      TileColor.red => 'attack',
      TileColor.blue => 'mana',
      TileColor.green => 'healing',
      TileColor.yellow => 'shield',
      TileColor.purple => 'ultimate',
      null => null,
    };

String gemAssetForResource(String resourceId) =>
    GameAssets.resourceIcon(resourceId);

/// Accent color for clear / bounce FX by tile resource.
Color juiceColorForTile(TileColor? color) => switch (color) {
      TileColor.red => const Color(0xFFE85D4C),
      TileColor.blue => const Color(0xFF4C9BE8),
      TileColor.green => const Color(0xFF4CB87A),
      TileColor.yellow => const Color(0xFFE8C84C),
      TileColor.purple => const Color(0xFFB06CE8),
      null => const Color(0xFFF2E6C8),
    };
