import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/challenge_art.dart';
import '../../../shared/widgets/relic_frame.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../data/campaign_repository.dart';
import '../data/chapter_medal_catalog.dart';
import '../domain/chapter_medal.dart';

/// Illustrated realm browser; quick continuation lives on Home.
class ChapterSelectScreen extends ConsumerWidget {
  const ChapterSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexAsync = ref.watch(campaignIndexProvider);
    final selectedId = ref.watch(selectedCampaignChapterIdProvider);
    final profile = ref.watch(profileProvider);
    final chapterAsync = ref.watch(campaignChapterProvider);
    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      body: Stack(children: [
        Positioned.fill(
            child: Image.asset(GameAssets.homeBackground, fit: BoxFit.cover)),
        const Positioned.fill(child: ColoredBox(color: Color(0xCC07151C))),
        SafeArea(
            child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(children: [
                IconButton(
                    tooltip: 'Back to home',
                    icon: const Icon(Icons.chevron_left,
                        color: MythDuskColors.softGold),
                    onPressed: () {
                      final router = GoRouter.of(context);
                      if (router.canPop()) {
                        router.pop();
                      } else {
                        router.go('/');
                      }
                    }),
                Expanded(
                    child: Text('Realms of MythDusk',
                        textAlign: TextAlign.center,
                        style: challengeTextStyle(21, bold: true))),
              ])),
          const ChallengeDivider(),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Choose a path through the dusk',
                  style: challengeTextStyle(12))),
          Expanded(
              child: indexAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
                child: Text('Could not load realms. Please try again.')),
            data: (index) {
              final selected = index.tryById(selectedId);
              final current = selected != null &&
                      selected.isUnlocked(profile.completedNodeIds)
                  ? selected
                  : index.first;
              final medals = ChapterMedalCatalog.forChapter(current.id);
              final claimed = medals
                  .where((m) => profile.isChapterMedalClaimed(m.id))
                  .length;
              final chapter = chapterAsync.asData?.value;
              final matches = chapter?.id == current.id;
              final done = matches
                  ? chapter!.nodes
                      .where((n) => profile.completedNodeIds.contains(n.id))
                      .length
                  : 0;
              final total = matches ? chapter!.nodes.length : 0;
              void explore(CampaignIndexEntry entry) {
                ref.read(selectedCampaignChapterIdProvider.notifier).state =
                    entry.id;
                context.push('/campaign');
              }

              return ListView(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                  children: [
                    _RealmCard(
                        entry: current,
                        featured: true,
                        unlocked: true,
                        detail: matches
                            ? '${chapter!.currentAct(profile.completedNodeIds).title} · $done / $total cleared'
                            : current.subtitle,
                        progress: total == 0 ? null : done / total,
                        onTap: () => explore(current)),
                    if (medals.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ChallengePanel(
                              child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: EdgeInsets.zero,
                                  iconColor: MythDuskColors.softGold,
                                  collapsedIconColor: MythDuskColors.softGold,
                                  title: Text('Chapter Medals',
                                      style:
                                          challengeTextStyle(16, bold: true)),
                                  subtitle: Text(
                                      '$claimed / ${medals.length} claimed',
                                      style: challengeTextStyle(12)),
                                  children: [
                                _SelectedChapterMedals(
                                    chapterId: current.id, medals: medals)
                              ]))),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('Beyond the Twilight',
                            style: challengeTextStyle(17, bold: true))),
                    for (var i = 0; i < index.chapters.length; i++)
                      if (index.chapters[i].id != current.id)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RealmCard(
                                entry: index.chapters[i],
                                featured: false,
                                unlocked: index.chapters[i]
                                    .isUnlocked(profile.completedNodeIds),
                                detail: index.chapters[i]
                                        .isUnlocked(profile.completedNodeIds)
                                    ? index.chapters[i].subtitle
                                    : 'Clear ${i > 0 ? index.chapters[i - 1].title : 'the previous realm'} to unlock',
                                onTap: () => explore(index.chapters[i]))),
                  ]);
            },
          )),
        ])),
      ]),
    );
  }
}

class _RealmCard extends StatelessWidget {
  const _RealmCard(
      {required this.entry,
      required this.featured,
      required this.unlocked,
      required this.detail,
      required this.onTap,
      this.progress});
  final CampaignIndexEntry entry;
  final bool featured, unlocked;
  final String detail;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      enabled: unlocked,
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: unlocked ? onTap : null,
              child: Stack(children: [
                Positioned.fill(
                    child: Image.asset(
                        GameAssets.battleBackground(entry.asset
                            .split('/')
                            .last
                            .replaceAll('.json', '')),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: MythDuskColors.deepTeal))),
                Positioned.fill(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                  Color(unlocked ? 0xE607151C : 0xEE07151C),
                  const Color(0x6607151C)
                ])))),
                Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (featured) ...[
                            Text('CURRENT REALM',
                                style: challengeTextStyle(10,
                                    color: MythDuskColors.softGold)),
                            const SizedBox(height: 8)
                          ],
                          Text(entry.title,
                              style: challengeTextStyle(featured ? 25 : 19,
                                  bold: true,
                                  color: unlocked
                                      ? MythDuskColors.parchment
                                      : MythDuskColors.muted)),
                          const SizedBox(height: 8),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!unlocked) ...[
                                  const Icon(Icons.lock_outline,
                                      size: 16, color: MythDuskColors.muted),
                                  const SizedBox(width: 6)
                                ],
                                Expanded(
                                    child: Text(detail,
                                        style: challengeTextStyle(12,
                                            color: unlocked
                                                ? MythDuskColors.parchment
                                                : MythDuskColors.muted))),
                              ]),
                          if (featured) ...[
                            const SizedBox(height: 10),
                            if (progress != null)
                              Row(children: [
                                Expanded(
                                    child: LinearProgressIndicator(
                                        value: progress!.clamp(0, 1),
                                        color: const Color(0xFF3ECFCB),
                                        backgroundColor:
                                            MythDuskColors.deepTeal)),
                                const SizedBox(width: 10),
                                Text('${(progress! * 100).round()}%',
                                    style: challengeTextStyle(12))
                              ]),
                            const SizedBox(height: 32),
                            ChallengePlayButton(
                                enabled: unlocked,
                                onPressed: onTap,
                                label: 'Explore Realm'),
                          ] else
                            const SizedBox(height: 18),
                        ])),
                const Positioned.fill(child: RelicFrame()),
              ]))));
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
