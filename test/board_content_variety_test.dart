import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythora/features/campaign/domain/campaign_models.dart';
import 'package:mythora/features/puzzle/domain/level_board_config.dart';

String _boardFingerprint(LevelBoardConfig cfg) {
  final movers = [
    for (final m in cfg.effectiveMovers)
      '${m.type}:${m.rows.join(',')}:${m.cols.join(',')}:${m.direction}:${m.everyNTurns}',
  ].join('|');
  final hazard = cfg.hazardSpawn == null
      ? '-'
      : '${cfg.hazardSpawn!.overlayId}:${cfg.hazardSpawn!.chancePerTurn}:${cfg.hazardSpawn!.maxOnBoard}';
  final weights = cfg.spawnWeights?.toJson().entries
          .where((e) => (e.value as num) != 1.0)
          .map((e) => '${e.key}=${e.value}')
          .join(',') ??
      '';
  return '${cfg.templateId ?? ''}#$movers#$hazard#$weights';
}

CampaignChapter _loadChapter(String path) {
  final raw = File(path).readAsStringSync();
  return CampaignChapter.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Set<String> _templateIdsFromCatalog() {
  final raw = File('assets/boards/templates.json').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final templates = json['templates'] as List<dynamic>;
  return {
    for (final t in templates) (t as Map<String, dynamic>)['id'] as String,
  };
}

void main() {
  final catalogIds = _templateIdsFromCatalog();

  test('every chapter templateId exists in templates.json', () {
    final indexRaw =
        File('assets/levels/campaign_index.json').readAsStringSync();
    final chapters =
        (jsonDecode(indexRaw) as Map<String, dynamic>)['chapters'] as List;
    for (final entry in chapters) {
      final asset = (entry as Map<String, dynamic>)['asset'] as String;
      final chapter = _loadChapter(asset);
      final ids = <String>{
        if (chapter.boardDefaults.templateId != null)
          chapter.boardDefaults.templateId!,
        for (final node in chapter.nodes)
          if (chapter.boardFor(node).templateId != null)
            chapter.boardFor(node).templateId!,
      };
      for (final id in ids) {
        expect(catalogIds.contains(id), isTrue,
            reason: '${chapter.id} references missing template $id');
      }
    }
  });

  test('Ch1–3 resolved boards are not all identical', () {
    const paths = {
      'twilight_road': 'assets/levels/twilight_road.json',
      'ch_mistfen': 'assets/levels/mistfen_marshes.json',
      'ch_howling': 'assets/levels/howling_ridge.json',
    };
    for (final entry in paths.entries) {
      final chapter = _loadChapter(entry.value);
      final fingerprints = {
        for (final node in chapter.nodes)
          _boardFingerprint(chapter.boardFor(node)),
      };
      expect(
        fingerprints.length,
        greaterThanOrEqualTo(3),
        reason: '${entry.key} should have ≥3 distinct board configs, '
            'got ${fingerprints.length}',
      );
    }
  });

  test('Mistfen early nodes lack hazard; late nodes spawn poison', () {
    final chapter = _loadChapter('assets/levels/mistfen_marshes.json');
    expect(chapter.boardDefaults.hazardSpawn, isNull);

    final early = chapter.nodeById('ch_mistfen_n01');
    expect(chapter.boardFor(early).hazardSpawn, isNull);
    expect(chapter.boardFor(early).templateId, 'board_open_6x6');

    final midQuiet = chapter.nodeById('ch_mistfen_n03');
    expect(chapter.boardFor(midQuiet).hazardSpawn, isNull);

    final lateBoss = chapter.nodeById('ch_mistfen_n20');
    final hazard = chapter.boardFor(lateBoss).hazardSpawn;
    expect(hazard, isNotNull);
    expect(hazard!.overlayId, 'ovl_poison');
    expect(hazard.chancePerTurn, greaterThan(0));
  });

  test('Howling ramps from calm intro to dual shove finales', () {
    final chapter = _loadChapter('assets/levels/howling_ridge.json');
    expect(chapter.boardDefaults.effectiveMovers, hasLength(1));
    expect(chapter.boardDefaults.effectiveMovers.first.everyNTurns, 2);

    final calm = chapter.nodeById('ch_howling_n01');
    expect(chapter.boardFor(calm).effectiveMovers, isEmpty);

    final gentle = chapter.nodeById('ch_howling_n03');
    expect(chapter.boardFor(gentle).effectiveMovers, hasLength(1));

    final dual = chapter.nodeById('ch_howling_n05');
    expect(chapter.boardFor(dual).effectiveMovers, hasLength(2));

    final finale = chapter.nodeById('ch_howling_n20');
    expect(chapter.boardFor(finale).effectiveMovers, hasLength(2));
    expect(chapter.boardFor(finale).templateId, 'board_bridge_narrow_01');
  });

  test('Twilight introduces vines then bridge boards', () {
    final chapter = _loadChapter('assets/levels/twilight_road.json');
    expect(chapter.boardFor(chapter.nodeById('node_01')).templateId,
        'board_open_6x6');
    expect(chapter.boardFor(chapter.nodeById('node_03')).templateId,
        'board_vine_corners_01');
    expect(chapter.boardFor(chapter.nodeById('node_04')).templateId,
        'board_bridge_narrow_01');
    expect(chapter.boardFor(chapter.nodeById('node_20')).templateId,
        'board_bridge_narrow_01');
  });
}
