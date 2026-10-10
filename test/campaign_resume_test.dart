import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:mythdusk/features/home/presentation/home_progress.dart';
import 'package:mythdusk/features/campaign/data/campaign_repository.dart';
import 'package:mythdusk/features/campaign/domain/campaign_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CampaignChapter chapter;
  setUpAll(() async {
    chapter = CampaignChapter.fromJson(jsonDecode(
            await rootBundle.loadString('assets/levels/twilight_road.json'))
        as Map<String, dynamic>);
  });
  test('fresh player resumes at first node', () {
    expect(chapter.nextPlayableNode({})?.id, chapter.nodes.first.id);
  });
  test('completion advances into the next act', () {
    final completed = chapter.acts.first.nodes.map((n) => n.id).toSet();
    expect(chapter.nextPlayableNode(completed)?.id,
        chapter.acts[1].nodes.first.id);
  });
  test('fully cleared chapter has no automatic replay target', () {
    expect(chapter.nextPlayableNode(chapter.nodes.map((n) => n.id).toSet()),
        isNull);
  });
  test('a gap resumes at the earliest playable unfinished node', () {
    final completed = chapter.nodes.take(8).map((n) => n.id).toSet()
      ..remove(chapter.nodes[2].id);
    expect(chapter.nextPlayableNode(completed)?.id, chapter.nodes[2].id);
  });
  Future<HomeCampaignProgress> progressFor(Set<String> completed) async {
    final profile = PlayerProfile(completedNodeIds: completed);
    SharedPreferences.setMockInitialValues(
        {'mythdusk_profile_v2': jsonEncode(profile.toJson())});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
    addTearDown(container.dispose);
    return container.read(homeCampaignProgressProvider.future);
  }

  test('chapter finale advances Home to the next unlocked realm', () async {
    final progress = await progressFor(chapter.nodes.map((n) => n.id).toSet());
    expect(progress.chapterId, 'ch_mistfen');
    expect(progress.nextNodeId, 'ch_mistfen_n01');
  });
  test('all campaign content completed falls back to exploration', () async {
    final progress = await progressFor(await loadAllCampaignNodeIds());
    expect(progress.nextNodeId, isNull);
    expect(progress.chapterId, 'ch_mythspire');
  });
}
