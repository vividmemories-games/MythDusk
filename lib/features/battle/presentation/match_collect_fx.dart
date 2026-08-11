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
