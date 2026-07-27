import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../data/campaign_repository.dart';

/// Pick a campaign chapter, then open its act map.
class ChapterSelectScreen extends ConsumerWidget {
  const ChapterSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexAsync = ref.watch(campaignIndexProvider);
    final selectedId = ref.watch(selectedCampaignChapterIdProvider);
    final completed = ref.watch(profileProvider).completedNodeIds;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: MythoraColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Campaign'),
      ),
      body: indexAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load chapters: $e')),
        data: (index) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: index.chapters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final entry = index.chapters[i];
              final unlocked = entry.isUnlocked(completed);
              final selected = entry.id == selectedId;
              return Material(
                color: selected
                    ? MythoraColors.deepTeal
                    : MythoraColors.deepTeal.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: unlocked
                      ? () {
                          ref
                              .read(selectedCampaignChapterIdProvider.notifier)
                              .state = entry.id;
                          context.push('/campaign');
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: unlocked
                              ? MythoraColors.amber.withValues(alpha: 0.25)
                              : MythoraColors.mist.withValues(alpha: 0.2),
                          child: Text(
                            '${entry.order}',
                            style: textTheme.titleMedium?.copyWith(
                              color: unlocked
                                  ? MythoraColors.amber
                                  : MythoraColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: textTheme.titleMedium?.copyWith(
                                  color: unlocked
                                      ? MythoraColors.parchment
                                      : MythoraColors.muted,
                                ),
                              ),
                              if (entry.subtitle.isNotEmpty)
                                Text(
                                  entry.subtitle,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: MythoraColors.softGold
                                        .withValues(alpha: unlocked ? 1 : 0.5),
                                  ),
                                ),
                              if (!unlocked)
                                Text(
                                  'Clear the previous chapter finale',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 11,
                                    color: MythoraColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          unlocked
                              ? (selected
                                  ? Icons.play_arrow_rounded
                                  : Icons.chevron_right)
                              : Icons.lock_outline,
                          color: unlocked
                              ? MythoraColors.amber
                              : MythoraColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
