import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../data/campaign_repository.dart';
import '../data/chapter_medal_catalog.dart';
import '../domain/chapter_medal.dart';

/// Pick a campaign chapter, then open its act map.
class ChapterSelectScreen extends ConsumerWidget {
  const ChapterSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexAsync = ref.watch(campaignIndexProvider);
    final selectedId = ref.watch(selectedCampaignChapterIdProvider);
    final profile = ref.watch(profileProvider);
    final completed = profile.completedNodeIds;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
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
              final medals = ChapterMedalCatalog.forChapter(entry.id);
              final claimedCount = medals
                  .where((m) => profile.isChapterMedalClaimed(m.id))
                  .length;

              return Material(
                color: selected
                    ? MythDuskColors.deepTeal
                    : MythDuskColors.deepTeal.withValues(alpha: 0.55),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: unlocked
                                  ? MythDuskColors.amber.withValues(alpha: 0.25)
                                  : MythDuskColors.mist.withValues(alpha: 0.2),
                              child: Text(
                                '${entry.order}',
                                style: textTheme.titleMedium?.copyWith(
                                  color: unlocked
                                      ? MythDuskColors.amber
                                      : MythDuskColors.muted,
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
                                          ? MythDuskColors.parchment
                                          : MythDuskColors.muted,
                                    ),
                                  ),
                                  if (entry.subtitle.isNotEmpty)
                                    Text(
                                      entry.subtitle,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontSize: 12,
                                        color:
                                            MythDuskColors.softGold.withValues(
                                          alpha: unlocked ? 1 : 0.5,
                                        ),
                                      ),
                                    ),
                                  if (!unlocked)
                                    Text(
                                      'Clear the previous chapter finale',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontSize: 11,
                                        color: MythDuskColors.muted,
                                      ),
                                    )
                                  else if (medals.isNotEmpty)
                                    Text(
                                      'Medals $claimedCount/${medals.length}',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontSize: 11,
                                        color: MythDuskColors.softGold,
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
                                  ? MythDuskColors.amber
                                  : MythDuskColors.muted,
                            ),
                          ],
                        ),
                        if (unlocked && selected && medals.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _SelectedChapterMedals(
                            chapterId: entry.id,
                            medals: medals,
                          ),
                        ],
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

class _SelectedChapterMedals extends ConsumerWidget {
  const _SelectedChapterMedals({
    required this.chapterId,
    required this.medals,
  });

  final String chapterId;
  final List<ChapterMedalDefinition> medals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final counters = profile.medalCountersFor(chapterId);
    final chapterAsync = ref.watch(campaignChapterProvider);

    return chapterAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (chapter) {
        if (chapter.id != chapterId) return const SizedBox.shrink();
        final nodeIds = chapter.nodes.map((n) => n.id).toSet();
        final chapterComplete =
            nodeIds.every(profile.completedNodeIds.contains);

        return Column(
          children: [
            for (final medal in medals)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _MedalRow(
                  medal: medal,
                  label: medal.progressLabel(counters.valueFor(medal)),
                  claimed: profile.isChapterMedalClaimed(medal.id),
                  met: counters.isMet(
                    medal,
                    chapterComplete: chapterComplete,
                  ),
                  onClaim: () {
                    final granted =
                        ref.read(profileProvider.notifier).claimChapterMedal(
                              medal.id,
                              chapterNodeIds: nodeIds,
                            );
                    if (granted > 0 && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${medal.title} claimed · +$granted coins',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MedalRow extends StatelessWidget {
  const _MedalRow({
    required this.medal,
    required this.label,
    required this.claimed,
    required this.met,
    required this.onClaim,
  });

  final ChapterMedalDefinition medal;
  final String label;
  final bool claimed;
  final bool met;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          claimed ? Icons.military_tech : Icons.military_tech_outlined,
          size: 16,
          color: claimed ? MythDuskColors.amber : MythDuskColors.muted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MythDuskColors.parchment.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
          ),
        ),
        if (claimed)
          Text(
            'Claimed',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: MythDuskColors.softGold,
                ),
          )
        else if (met)
          TextButton(
            onPressed: onClaim,
            style: TextButton.styleFrom(
              foregroundColor: MythDuskColors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('+${medal.coinReward}'),
          ),
      ],
    );
  }
}
