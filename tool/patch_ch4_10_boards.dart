/// Patches Ch4–10 campaign JSON with per-node board variety.
/// Run: dart run tool/patch_ch4_10_boards.dart
import 'dart:convert';
import 'dart:io';

const chapters = <String>[
  'assets/levels/ashen_quarries.json',
  'assets/levels/skybridge_siege.json',
  'assets/levels/candlecrypt.json',
  'assets/levels/mirror_lake.json',
  'assets/levels/thornmarket.json',
  'assets/levels/eclipse_forge.json',
  'assets/levels/mythspire_gate.json',
];

/// Rotating fingerprints so each chapter gets ≥3 distinct resolved boards.
List<Map<String, dynamic>> _patternsFor(String chapterId) {
  final base = switch (chapterId) {
    'ch_ashen' => [
        {'templateId': 'board_open_6x6'},
        {'templateId': 'board_bridge_narrow_01'},
        {
          'templateId': 'board_bridge_narrow_01',
          'spawnWeights': {'red': 1.2, 'yellow': 0.8},
        },
        {
          'templateId': 'board_vine_corners_01',
          'movers': [
            {
              'type': 'row_shove',
              'rows': [3],
              'direction': 'right',
              'everyNTurns': 2,
            }
          ],
        },
        {
          'templateId': 'board_bridge_narrow_01',
          'hazardSpawn': {
            'overlayId': 'ovl_poison',
            'chancePerTurn': 0.2,
            'maxOnBoard': 2,
          },
        },
      ],
    'ch_skybridge' => [
        {'templateId': 'board_bridge_narrow_01'},
        {'templateId': 'board_open_6x6'},
        {
          'templateId': 'board_bridge_narrow_01',
          'movers': [
            {
              'type': 'row_shove',
              'rows': [1, 4],
              'direction': 'left',
              'everyNTurns': 2,
            }
          ],
        },
        {
          'templateId': 'board_open_6x6',
          'spawnWeights': {'blue': 1.25, 'purple': 0.75},
        },
        {
          'templateId': 'board_vine_corners_01',
          'movers': [
            {
              'type': 'row_shove',
              'rows': [2],
              'direction': 'right',
              'everyNTurns': 1,
            }
          ],
        },
      ],
    'ch_candlecrypt' => [
        {'templateId': 'board_vine_corners_01'},
        {'templateId': 'board_mistfen_sticky_01'},
        {'templateId': 'board_open_6x6'},
        {
          'templateId': 'board_mistfen_sticky_01',
          'hazardSpawn': {
            'overlayId': 'ovl_poison',
            'chancePerTurn': 0.25,
            'maxOnBoard': 3,
          },
        },
        {
          'templateId': 'board_vine_corners_01',
          'spawnWeights': {'green': 1.3, 'red': 0.7},
        },
      ],
    'ch_mirror' => [
        {'templateId': 'board_open_6x6'},
        {
          'templateId': 'board_open_6x6',
          'spawnWeights': {'blue': 1.4, 'yellow': 1.2, 'red': 0.6},
        },
        {'templateId': 'board_bridge_narrow_01'},
        {
          'templateId': 'board_vine_corners_01',
          'spawnWeights': {'purple': 1.3, 'blue': 1.2},
        },
        {
          'templateId': 'board_open_6x6',
          'movers': [
            {
              'type': 'row_shove',
              'rows': [2],
              'direction': 'left',
              'everyNTurns': 3,
            }
          ],
        },
      ],
    'ch_thornmarket' => [
        {'templateId': 'board_vine_corners_01'},
        {'templateId': 'board_mistfen_sticky_01'},
        {
          'templateId': 'board_vine_corners_01',
          'hazardSpawn': {
            'overlayId': 'ovl_poison',
            'chancePerTurn': 0.22,
            'maxOnBoard': 2,
          },
        },
        {
          'templateId': 'board_mistfen_sticky_01',
          'spawnWeights': {'green': 1.35, 'yellow': 0.8},
        },
        {
          'templateId': 'board_bridge_narrow_01',
          'movers': [
            {
              'type': 'row_shove',
              'rows': [3],
              'direction': 'right',
              'everyNTurns': 2,
            }
          ],
        },
      ],
    'ch_eclipse' => [
        {'templateId': 'board_bridge_narrow_01'},
        {
          'templateId': 'board_open_6x6',
          'spawnWeights': {'purple': 1.4, 'red': 1.15},
        },
        {'templateId': 'board_mistfen_sticky_01'},
        {
          'templateId': 'board_bridge_narrow_01',
          'hazardSpawn': {
            'overlayId': 'ovl_poison',
            'chancePerTurn': 0.18,
            'maxOnBoard': 2,
          },
        },
        {
          'templateId': 'board_vine_corners_01',
          'movers': [
            {
              'type': 'row_shove',
              'rows': [1],
              'direction': 'left',
              'everyNTurns': 2,
            }
          ],
        },
      ],
    _ => [
        // mythspire_gate and fallback
        {'templateId': 'board_open_6x6'},
        {'templateId': 'board_bridge_narrow_01'},
        {'templateId': 'board_vine_corners_01'},
        {
          'templateId': 'board_mistfen_sticky_01',
          'spawnWeights': {'purple': 1.25, 'blue': 1.1},
        },
        {
          'templateId': 'board_bridge_narrow_01',
          'movers': [
            {
              'type': 'row_shove',
              'rows': [2, 3],
              'direction': 'right',
              'everyNTurns': 2,
            }
          ],
          'hazardSpawn': {
            'overlayId': 'ovl_poison',
            'chancePerTurn': 0.2,
            'maxOnBoard': 3,
          },
        },
      ],
  };
  return [for (final p in base) Map<String, dynamic>.from(p)];
}

void main() {
  for (final path in chapters) {
    final file = File(path);
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final chapterId = json['id'] as String;
    final patterns = _patternsFor(chapterId);
    var order = 0;
    final acts = json['acts'] as List<dynamic>;
    for (final act in acts) {
      final nodes = (act as Map<String, dynamic>)['nodes'] as List<dynamic>;
      for (final raw in nodes) {
        final node = raw as Map<String, dynamic>;
        final pattern = patterns[order % patterns.length];
        // Keep explicit early-node teaching: n01 often open/simple via pattern 0.
        node['board'] = jsonDecode(jsonEncode(pattern));
        order++;
      }
    }
    const encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync('${encoder.convert(json)}\n');
    stdout.writeln('Patched $path ($order nodes)');
  }
}
