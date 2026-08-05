import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../campaign/data/campaign_repository.dart';
import '../../campaign/domain/campaign_models.dart';
import '../../profile/providers/mock_profile_provider.dart';

/// Snapshot of campaign progress for the Home hub strip.
class HomeCampaignProgress {
  const HomeCampaignProgress({
    required this.chapterTitle,
    required this.actTitle,
    required this.completedInChapter,
    required this.totalInChapter,
    required this.chapterId,
  });

  final String chapterTitle;
  final String actTitle;
  final int completedInChapter;
  final int totalInChapter;
  final String chapterId;
}

/// Furthest unlocked chapter + act progress for the hub.
final homeCampaignProgressProvider =
    FutureProvider<HomeCampaignProgress>((ref) async {
  final completed = ref.watch(
    profileProvider.select((p) => p.completedNodeIds),
  );
  final index = await ref.watch(campaignIndexProvider.future);

  var entry = index.first;
  for (final c in index.chapters) {
    if (c.isUnlocked(completed)) entry = c;
  }

  final raw = await rootBundle.loadString(entry.asset);
  final chapter = CampaignChapter.fromJson(
    jsonDecode(raw) as Map<String, dynamic>,
  );
  final act = chapter.currentAct(completed);
  final done = chapter.nodes.where((n) => completed.contains(n.id)).length;

  return HomeCampaignProgress(
    chapterTitle: entry.title,
    actTitle: act.title,
    completedInChapter: done,
    totalInChapter: chapter.nodes.length,
    chapterId: entry.id,
  );
});
