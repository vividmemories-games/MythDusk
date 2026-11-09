import 'board_cell.dart';

/// Resolved creation details, retained for presentation without re-detecting matches.
class PowerupCreation {
  const PowerupCreation({
    required this.at,
    required this.special,
    required this.sources,
  });

  final (int, int) at;
  final TileSpecial special;
  final Set<(int, int)> sources;
}

/// The actual swapped pair; labels are for display, never event detection.
class PowerupCombination {
  const PowerupCombination({
    required this.at,
    required this.partner,
    required this.first,
    required this.second,
  });

  final (int, int) at;
  final (int, int) partner;
  final TileSpecial first;
  final TileSpecial second;
}
