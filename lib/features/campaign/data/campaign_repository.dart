import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/campaign_models.dart';

class CampaignIndexEntry {
  const CampaignIndexEntry({
    required this.id,
    required this.title,
    required this.asset,
    required this.order,
    this.subtitle = '',
    this.requiresNodeId,
  });

  final String id;
  final String title;
  final String asset;
  final int order;
  final String subtitle;

  /// Prior chapter finale node that must be completed to unlock.
  final String? requiresNodeId;

  bool isUnlocked(Set<String> completedNodeIds) {
    final req = requiresNodeId;
    if (req == null || req.isEmpty) return true;
    return completedNodeIds.contains(req);
  }

  factory CampaignIndexEntry.fromJson(Map<String, dynamic> json) {
    return CampaignIndexEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      asset: json['asset'] as String,
      order: json['order'] as int? ?? 0,
      subtitle: json['subtitle'] as String? ?? '',
      requiresNodeId: json['requiresNodeId'] as String?,
    );
  }
}

class CampaignIndex {
  const CampaignIndex({required this.chapters});

  final List<CampaignIndexEntry> chapters;

  CampaignIndexEntry get first {
    if (chapters.isEmpty) {
      throw StateError('Campaign index contains no chapters');
    }
    return chapters.first;
  }

  CampaignIndexEntry byId(String id) {
    final chapter = tryById(id);
    if (chapter == null) throw StateError('Unknown campaign chapter id: $id');
    return chapter;
  }

  CampaignIndexEntry? tryById(String id) {
    for (final chapter in chapters) {
      if (chapter.id == id) return chapter;
    }
    return null;
  }

  factory CampaignIndex.fromJson(Map<String, dynamic> json) {
    final raw = json['chapters'] as List<dynamic>? ?? const [];
    final chapters = [
      for (final e in raw)
        CampaignIndexEntry.fromJson(e as Map<String, dynamic>),
    ]..sort((a, b) => a.order.compareTo(b.order));
    return CampaignIndex(chapters: chapters);
  }
}

final campaignIndexProvider = FutureProvider<CampaignIndex>((ref) async {
  final raw = await rootBundle.loadString('assets/levels/campaign_index.json');
  return CampaignIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// Currently selected chapter (Home → Campaign). Defaults to Twilight Road.
final selectedCampaignChapterIdProvider =
    StateProvider<String>((ref) => 'twilight_road');

final campaignChapterProvider = FutureProvider<CampaignChapter>((ref) async {
  final index = await ref.watch(campaignIndexProvider.future);
  final id = ref.watch(selectedCampaignChapterIdProvider);
  final entry = index.byId(id);
  final raw = await rootBundle.loadString(entry.asset);
  return CampaignChapter.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// Every node id across the campaign spine (for QA unlock-all).
Future<Set<String>> loadAllCampaignNodeIds() async {
  final raw = await rootBundle.loadString('assets/levels/campaign_index.json');
  final index = CampaignIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  final ids = <String>{};
  for (final entry in index.chapters) {
    final chapterRaw = await rootBundle.loadString(entry.asset);
    final chapter = CampaignChapter.fromJson(
      jsonDecode(chapterRaw) as Map<String, dynamic>,
    );
    for (final node in chapter.nodes) {
      ids.add(node.id);
    }
  }
  return ids;
}
