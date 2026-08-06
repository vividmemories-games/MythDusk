import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/battle/domain/enemy_def.dart';
import 'package:mythdusk/features/campaign/data/campaign_repository.dart';
import 'package:mythdusk/features/campaign/domain/campaign_models.dart';

void main() {
  test('campaign_index lists 10 chapters in order', () async {
    final raw = await File('assets/levels/campaign_index.json').readAsString();
    final index =
        CampaignIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(index.chapters, hasLength(10));
    expect(index.chapters.first.id, 'twilight_road');
    expect(index.chapters.last.id, 'ch_mythspire');
    expect(
      index.chapters.map((c) => c.order).toList(),
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    );
    expect(index.chapters.first.isUnlocked({}), isTrue);
    expect(index.chapters[1].isUnlocked({}), isFalse);
    expect(index.chapters[1].isUnlocked({'node_20'}), isTrue);
  });

  test('every indexed chapter loads 4×5 with boss finales', () async {
    final raw = await File('assets/levels/campaign_index.json').readAsString();
    final index =
        CampaignIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    for (final entry in index.chapters) {
      final chapter = CampaignChapter.fromJson(
        jsonDecode(await File(entry.asset).readAsString())
            as Map<String, dynamic>,
      );
      expect(chapter.id, entry.id, reason: entry.asset);
      expect(chapter.acts, hasLength(4), reason: entry.id);
      expect(chapter.nodes, hasLength(20), reason: entry.id);
      expect(chapter.boardDefaults.hasTemplate, isTrue, reason: entry.id);
      for (final act in chapter.acts) {
        expect(act.nodes, hasLength(5), reason: '${entry.id}/${act.id}');
        expect(act.finale.isBoss, isTrue, reason: act.finale.id);
        expect(act.finale.bossForm, isNotNull);
        // Boss enemy must resolve in catalog (not fall back silently wrong).
        final enemy = EnemyCatalog.byId(act.finale.enemyId);
        expect(enemy.id, act.finale.enemyId, reason: act.finale.enemyId);
        expect(enemy.isBoss, isTrue, reason: enemy.id);
      }
      expect(
        chapter.acts.map((a) => a.finale.bossForm).toList(),
        [1, 2, 3, 4],
        reason: entry.id,
      );
    }
  });

  test('total campaign spine is 200 nodes', () async {
    final raw = await File('assets/levels/campaign_index.json').readAsString();
    final index =
        CampaignIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    var total = 0;
    final ids = <String>{};
    for (final entry in index.chapters) {
      final chapter = CampaignChapter.fromJson(
        jsonDecode(await File(entry.asset).readAsString())
            as Map<String, dynamic>,
      );
      total += chapter.nodes.length;
      for (final node in chapter.nodes) {
        ids.add(node.id);
      }
    }
    expect(total, 200);
    expect(ids, hasLength(200));
    // Seeding all ids unlocks every chapter gate in the index.
    for (final entry in index.chapters) {
      expect(entry.isUnlocked(ids), isTrue, reason: entry.id);
    }
  });
}
