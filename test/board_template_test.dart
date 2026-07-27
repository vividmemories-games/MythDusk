import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythora/features/puzzle/domain/board_builder.dart';
import 'package:mythora/features/puzzle/domain/board_template.dart';
import 'package:mythora/features/puzzle/domain/level_board_config.dart';
import 'package:mythora/features/puzzle/domain/overlay_def.dart';
import 'package:mythora/features/puzzle/domain/puzzle_engine.dart';
import 'package:mythora/features/puzzle/domain/tile_color.dart';
import 'package:mythora/features/puzzle/domain/tile_spawn_weights.dart';

void main() {
  late OverlayCatalog overlays;
  late BoardTemplateCatalog templates;

  setUpAll(() async {
    overlays = OverlayCatalog.fromJson(
      jsonDecode(await File('assets/boards/overlays.json').readAsString())
          as Map<String, dynamic>,
    );
    templates = BoardTemplateCatalog.fromJson(
      jsonDecode(await File('assets/boards/templates.json').readAsString())
          as Map<String, dynamic>,
      overlays: overlays,
    );
  });

  test('overlay catalog loads rock / vine / poison', () {
    expect(overlays['ovl_rock']?.isBlocker, isTrue);
    expect(overlays['ovl_vine']?.isBinder, isTrue);
    expect(overlays['ovl_poison']?.suppressesResources, isTrue);
  });

  test('open 6x6 template fills playable with no starting matches', () {
    final board = BoardBuilder.fromTemplate(
      template: templates.require('board_open_6x6'),
      overlays: overlays,
      random: Random(7),
    );
    expect(board.width, 6);
    expect(board.height, 6);
    expect(PuzzleEngine.findMatches(board), isEmpty);
    expect(board.cells.every((c) => c.isPlayable), isTrue);
  });

  test('bridge template applies masks and rock blockers', () {
    final board = BoardBuilder.fromTemplate(
      template: templates.require('board_bridge_narrow_01'),
      overlays: overlays,
      random: Random(11),
    );

    expect(board.at(0, 0).masked, isTrue);
    expect(board.at(0, 1).masked, isTrue);
    expect(board.at(0, 2).isPlayable, isTrue);

    final rock = board.at(3, 2);
    expect(rock.isSolidObstacle, isTrue);
    expect(rock.overlayId, 'ovl_rock');
    expect(rock.obstacleLayers, 2);
    expect(rock.isPlayable, isFalse);

    expect(PuzzleEngine.findMatches(board), isEmpty);
  });

  test('vine template places binders under tiles', () {
    final board = BoardBuilder.fromTemplate(
      template: templates.require('board_vine_corners_01'),
      overlays: overlays,
      random: Random(3),
    );
    final corner = board.at(0, 0);
    expect(corner.isBinderObstacle, isTrue);
    expect(corner.isPlayable, isTrue);
    expect(corner.overlayId, 'ovl_vine');
    expect(corner.color, isNotNull);
  });

  test('static blockers hold gravity like holes', () {
    final board = BoardBuilder.fromTemplate(
      template: templates.require('board_bridge_narrow_01'),
      overlays: overlays,
      random: Random(19),
    );
    final after = PuzzleEngine.applyGravity(board);
    expect(after.at(3, 2).isSolidObstacle, isTrue);
    expect(after.at(3, 2).overlayId, 'ovl_rock');
  });

  test('spawn weights bias picks toward heavy color', () {
    final weights = TileSpawnWeights.fromJson({
      'red': 100.0,
      'blue': 0.0,
      'green': 0.0,
      'yellow': 0.0,
      'purple': 0.0,
    });
    final rng = Random(1);
    var red = 0;
    for (var i = 0; i < 50; i++) {
      if (weights.pick(rng) == TileColor.red) red++;
    }
    expect(red, 50);
  });

  test('level board config merges node over chapter defaults', () {
    final defaults = LevelBoardConfig.fromJson({
      'templateId': 'board_open_6x6',
      'spawnWeights': {'purple': 2.0},
      'movers': [
        {
          'type': 'row_shove',
          'rows': [2],
          'direction': 'left'
        },
      ],
    });
    final node = LevelBoardConfig.fromJson({
      'templateId': 'board_bridge_narrow_01',
    });
    final merged = node.mergeOver(defaults);
    expect(merged.templateId, 'board_bridge_narrow_01');
    expect(merged.effectiveSpawnWeights.weightOf(TileColor.purple), 2.0);
    expect(merged.effectiveMovers, hasLength(1));
    expect(merged.effectiveMovers.first.type, 'row_shove');
  });

  test('unknown legend char throws', () {
    expect(
      () => BoardTemplate.fromJson({
        'id': 'bad',
        'width': 2,
        'height': 1,
        'legend': {},
        'grid': ['X.'],
      }),
      throwsFormatException,
    );
  });
}
