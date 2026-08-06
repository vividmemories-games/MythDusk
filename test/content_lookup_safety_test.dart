import 'package:flutter_test/flutter_test.dart';
import 'package:mythora/features/battle/domain/enemy_def.dart';
import 'package:mythora/features/campaign/data/campaign_repository.dart';
import 'package:mythora/features/campaign/domain/campaign_models.dart';
import 'package:mythora/features/heroes/domain/hero_def.dart';
import 'package:mythora/features/profile/providers/mock_profile_provider.dart';

void main() {
  final chapter = CampaignChapter.fromJson({
    'id': 'chapter_one',
    'title': 'Chapter One',
    'acts': [
      {
        'id': 'act_one',
        'mapAsset': 'assets/images/maps/test.webp',
        'nodes': [
          {
            'id': 'node_one',
            'name': 'Node One',
            'enemyId': 'goblin',
            'coinReward': 10,
            'order': 0,
          },
        ],
      },
    ],
  });

  test('catalog lookups reject unknown ids instead of returning defaults', () {
    expect(HeroCatalog.tryById('missing'), isNull);
    expect(EnemyCatalog.tryById('missing'), isNull);
    expect(() => HeroCatalog.byId('missing'), throwsStateError);
    expect(() => EnemyCatalog.byId('missing'), throwsStateError);
  });

  test('campaign lookups distinguish missing content from the first item', () {
    const index = CampaignIndex(
      chapters: [
        CampaignIndexEntry(
          id: 'chapter_one',
          title: 'Chapter One',
          asset: 'chapter_one.json',
          order: 1,
        ),
      ],
    );

    expect(index.tryById('missing'), isNull);
    expect(chapter.tryNodeById('missing'), isNull);
    expect(chapter.tryActById('missing'), isNull);
    expect(() => index.byId('missing'), throwsStateError);
    expect(() => chapter.nodeById('missing'), throwsStateError);
    expect(() => chapter.actById('missing'), throwsStateError);
    expect(() => const CampaignIndex(chapters: []).first, throwsStateError);
  });

  test('persisted unknown hero id is recovered only at profile migration', () {
    final profile = PlayerProfile.fromJson({
      'selectedHeroId': 'retired_hero',
    });

    expect(profile.selectedHeroId, HeroCatalog.mage.id);
    expect(profile.selectedHero, HeroCatalog.mage);
  });
}
