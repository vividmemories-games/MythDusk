import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythora/features/campaign/domain/campaign_models.dart';

void main() {
  final chapter = CampaignChapter.fromJson({
    'id': 'twilight_road',
    'title': 'Twilight Road',
    'subtitle': 'Test',
    'acts': [
      {
        'id': 'act1',
        'title': 'Act I',
        'mapAsset': 'assets/images/maps/map_ch_twilight_road_a1.png',
        'nodes': [
          {
            'id': 'node_01',
            'name': 'A',
            'enemyId': 'goblin',
            'coinReward': 35,
            'order': 0,
          },
          {
            'id': 'node_02',
            'name': 'B',
            'enemyId': 'wolf',
            'coinReward': 50,
            'order': 1,
          },
        ],
      },
      {
        'id': 'act2',
        'title': 'Act II',
        'mapAsset': 'assets/images/maps/map_ch_twilight_road_a2.png',
        'nodes': [
          {
            'id': 'node_03',
            'name': 'C',
            'enemyId': 'shaman',
            'coinReward': 70,
            'order': 2,
          },
        ],
      },
    ],
  });

  test('first node always unlocked', () {
    expect(chapter.isUnlocked('node_01', {}), isTrue);
  });

  test('second node locked until first completed', () {
    expect(chapter.isUnlocked('node_02', {}), isFalse);
    expect(chapter.isUnlocked('node_02', {'node_01'}), isTrue);
  });

  test('nodes flatten across acts in order', () {
    expect(chapter.nodes.map((n) => n.id).toList(), [
      'node_01',
      'node_02',
      'node_03',
    ]);
  });

  test('act II unlocks after act I finale', () {
    expect(chapter.isActUnlocked(chapter.acts[1], {}), isFalse);
    expect(chapter.isActUnlocked(chapter.acts[1], {'node_02'}), isTrue);
  });

  test('currentAct advances with progress', () {
    expect(chapter.currentAct({}).id, 'act1');
    expect(chapter.currentAct({'node_02'}).id, 'act2');
  });

  test('fog of war: only current and N+1 are clear/peek', () {
    // On node_01 — peek node_02, shroud node_03.
    expect(chapter.fogTier(chapter.nodeById('node_01'), {}), MapFogTier.clear);
    expect(chapter.fogTier(chapter.nodeById('node_02'), {}), MapFogTier.peek);
    expect(
        chapter.fogTier(chapter.nodeById('node_03'), {}), MapFogTier.shrouded);

    // Cleared node_01 — now on node_02, peek node_03.
    expect(
      chapter.fogTier(chapter.nodeById('node_01'), {'node_01'}),
      MapFogTier.clear,
    );
    expect(
      chapter.fogTier(chapter.nodeById('node_02'), {'node_01'}),
      MapFogTier.clear,
    );
    expect(
      chapter.fogTier(chapter.nodeById('node_03'), {'node_01'}),
      MapFogTier.peek,
    );
  });

  test('map coordinates parse when valid and normalized', () {
    final node = CampaignNode.fromJson({
      'id': 'node_01',
      'name': 'A',
      'enemyId': 'goblin',
      'coinReward': 35,
      'order': 0,
      'mapX': 0.46,
      'mapY': 0.9,
    });
    expect(node.mapX, 0.46);
    expect(node.mapY, 0.9);
  });

  test('missing or out-of-range map coordinates fall back to null', () {
    final missing = CampaignNode.fromJson({
      'id': 'node_01',
      'name': 'A',
      'enemyId': 'goblin',
      'coinReward': 35,
      'order': 0,
    });
    expect(missing.mapX, isNull);
    expect(missing.mapY, isNull);

    final invalid = CampaignNode.fromJson({
      'id': 'node_02',
      'name': 'B',
      'enemyId': 'wolf',
      'coinReward': 50,
      'order': 1,
      'mapX': 1.4,
      'mapY': -0.2,
    });
    expect(invalid.mapX, isNull);
    expect(invalid.mapY, isNull);
  });

  test('boss_sighting and warchief mark isBoss', () {
    final boss = CampaignNode.fromJson({
      'id': 'node_05',
      'name': 'Warchief',
      'enemyId': 'warchief',
      'coinReward': 120,
      'order': 4,
      'kind': 'boss_sighting',
      'bossForm': 1,
    });
    expect(boss.isBoss, isTrue);
    expect(boss.bossForm, 1);
    final trash = CampaignNode.fromJson({
      'id': 'node_01',
      'name': 'A',
      'enemyId': 'goblin',
      'coinReward': 35,
      'order': 0,
    });
    expect(trash.isBoss, isFalse);
    expect(trash.bossForm, isNull);
  });

  test('bossForm out of range is ignored', () {
    final node = CampaignNode.fromJson({
      'id': 'node_05',
      'name': 'Warchief',
      'enemyId': 'warchief',
      'coinReward': 120,
      'order': 4,
      'kind': 'boss_sighting',
      'bossForm': 9,
    });
    expect(node.bossForm, isNull);
  });

  test('boardDefaults and node board config parse', () {
    final chapter = CampaignChapter.fromJson({
      'id': 'twilight_road',
      'title': 'Twilight Road',
      'boardDefaults': {
        'templateId': 'board_open_6x6',
        'spawnWeights': {'red': 1.2},
      },
      'acts': [
        {
          'id': 'act1',
          'title': 'Act I',
          'mapAsset': 'assets/images/maps/map_ch_twilight_road_a1.png',
          'nodes': [
            {
              'id': 'node_01',
              'name': 'A',
              'enemyId': 'goblin',
              'coinReward': 35,
              'order': 0,
              'board': {'templateId': 'board_bridge_narrow_01'},
              'minMoves': 2,
              'enrageAfterTurns': 8,
              'prepDrops': ['prep_vanguard_tonic'],
            },
          ],
        },
      ],
    });
    final node = chapter.nodes.first;
    expect(chapter.boardDefaults.templateId, 'board_open_6x6');
    expect(chapter.boardFor(node).templateId, 'board_bridge_narrow_01');
    expect(node.minMoves, 2);
    expect(node.enrageAfterTurns, 8);
    expect(node.prepDrops, ['prep_vanguard_tonic']);
  });

  test('twilight_road asset has 4 acts × 5 nodes and boss finales', () async {
    final raw = await File('assets/levels/twilight_road.json').readAsString();
    final chapter =
        CampaignChapter.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(chapter.acts, hasLength(4));
    expect(chapter.nodes, hasLength(20));
    for (final act in chapter.acts) {
      expect(act.nodes, hasLength(5));
      expect(act.finale.isBoss, isTrue);
      expect(File(act.mapAsset).existsSync(), isTrue, reason: act.mapAsset);
    }
    expect(
      chapter.acts.map((a) => a.finale.bossForm).toList(),
      [1, 2, 3, 4],
    );
    expect(
      chapter.acts.map((a) => a.finale.order + 1).toList(),
      [5, 10, 15, 20],
    );
    expect(chapter.boardDefaults.templateId, 'board_open_6x6');
  });
}
