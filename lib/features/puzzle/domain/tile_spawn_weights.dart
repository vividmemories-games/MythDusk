import 'dart:math';

import 'tile_color.dart';

/// Relative spawn weights per [TileColor]. Missing colors default to 1.0.
class TileSpawnWeights {
  const TileSpawnWeights([this._weights = const {}]);

  final Map<TileColor, double> _weights;

  static const uniform = TileSpawnWeights();

  double weightOf(TileColor color) => _weights[color] ?? 1.0;

  factory TileSpawnWeights.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return uniform;
    final map = <TileColor, double>{};
    for (final color in TileColor.values) {
      final raw = json[color.name];
      if (raw is num) map[color] = raw.toDouble();
    }
    return TileSpawnWeights(map);
  }

  Map<String, dynamic> toJson() => {
        for (final c in TileColor.values) c.name: weightOf(c),
      };

  /// Weighted random pick. Falls back to uniform if all weights are ≤ 0.
  TileColor pick(Random random) {
    var total = 0.0;
    for (final c in TileColor.values) {
      final w = weightOf(c);
      if (w > 0) total += w;
    }
    if (total <= 0) {
      return TileColor.values[random.nextInt(TileColor.values.length)];
    }
    var roll = random.nextDouble() * total;
    for (final c in TileColor.values) {
      final w = weightOf(c);
      if (w <= 0) continue;
      roll -= w;
      if (roll <= 0) return c;
    }
    return TileColor.values.last;
  }

  /// Restrict pick to [options]; falls back to [pick] if options empty.
  TileColor pickFrom(List<TileColor> options, Random random) {
    if (options.isEmpty) return pick(random);
    var total = 0.0;
    for (final c in options) {
      final w = weightOf(c);
      if (w > 0) total += w;
    }
    if (total <= 0) {
      return options[random.nextInt(options.length)];
    }
    var roll = random.nextDouble() * total;
    for (final c in options) {
      final w = weightOf(c);
      if (w <= 0) continue;
      roll -= w;
      if (roll <= 0) return c;
    }
    return options.last;
  }
}
