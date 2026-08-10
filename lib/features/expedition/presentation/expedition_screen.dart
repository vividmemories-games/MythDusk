import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_providers.dart';
import '../../../core/analytics/gameplay_analytics.dart';
import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/opaque_character_art.dart';
import '../../heroes/domain/hero_def.dart';
import '../../heroes/domain/hero_unlocks.dart';
import '../../prep/presentation/prep_picker_sheet.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../domain/expedition_models.dart';

class ExpeditionScreen extends ConsumerWidget {
  const ExpeditionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(profileProvider.notifier).tickLifeRegen();
    final profile = ref.watch(profileProvider);
    final unlocked =
        profile.completedNodeIds.length >= ExpeditionBalance.minCampaignClears;
    final run = profile.activeExpedition;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Expedition'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: !unlocked
              ? _LockedBody(
                  clears: profile.completedNodeIds.length,
                  textTheme: textTheme,
                )
              : run == null ||
                      run.phase == ExpeditionPhase.settled ||
                      run.phase == ExpeditionPhase.failed
                  ? _HubStart(
                      profile: profile,
                      settled: run,
                      textTheme: textTheme,
                    )
                  : run.phase == ExpeditionPhase.relicPick
                      ? _RelicPick(run: run, textTheme: textTheme)
                      : _ActiveRun(
                          run: run, profile: profile, textTheme: textTheme),
        ),
      ),
    );
  }
}

class _LockedBody extends StatelessWidget {
  const _LockedBody({required this.clears, required this.textTheme});

  final int clears;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Relic Expedition',
            style: textTheme.displayLarge?.copyWith(fontSize: 28)),
        const SizedBox(height: 12),
        Text(
          'Clear ${ExpeditionBalance.minCampaignClears} campaign nodes to open '
          'the relic path. Progress: $clears / ${ExpeditionBalance.minCampaignClears}.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _HubStart extends ConsumerWidget {
  const _HubStart({
    required this.profile,
    required this.settled,
    required this.textTheme,
  });

  final PlayerProfile profile;
  final ExpeditionRunState? settled;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clears = profile.completedNodeIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Relic Expedition',
            style: textTheme.displayLarge?.copyWith(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          'Three scavenger fights, then a boss. Pick a relic after each win. '
          'One retry per run.',
          style: textTheme.bodyMedium,
        ),
        if (settled != null) ...[
          const SizedBox(height: 12),
          Text(
            settled!.phase == ExpeditionPhase.settled
                ? 'Last run cleared · +${ExpeditionBalance.clearCoinReward} coins'
                : 'Last run failed · +${ExpeditionBalance.failCoinReward} coins',
            style:
                textTheme.bodyMedium?.copyWith(color: MythDuskColors.softGold),
          ),
        ],
        const SizedBox(height: 16),
        Text('Fight as', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final hero in HeroCatalog.all)
              if (HeroUnlocks.isUnlocked(hero.id, clears))
                ChoiceChip(
                  label: Text(hero.name),
                  selected: profile.selectedHeroId == hero.id,
                  onSelected: (_) =>
                      ref.read(profileProvider.notifier).selectHero(hero.id),
                ),
          ],
        ),
        const Spacer(),
        FilledButton(
          onPressed: () {
            final ok = ref.read(profileProvider.notifier).startExpedition();
            if (!ok) return;
            ref.read(gameplayAnalyticsProvider).log(
              GameplayAnalyticsEvents.expeditionStarted,
              {'heroId': profile.selectedHeroId},
            );
          },
          child: const Text('Begin expedition'),
        ),
        if (settled != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                ref.read(profileProvider.notifier).clearSettledExpedition(),
            child: const Text('Dismiss last run'),
          ),
        ],
      ],
    );
  }
}

class _ActiveRun extends ConsumerWidget {
  const _ActiveRun({
    required this.run,
    required this.profile,
    required this.textTheme,
  });

  final ExpeditionRunState run;
  final PlayerProfile profile;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encounter = run.encounter;
    final enemy = ExpeditionBalance.enemyFor(encounter);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Room ${run.battleIndex + 1} / ${ExpeditionRunState.battleCount}',
          style: textTheme.bodyMedium?.copyWith(color: MythDuskColors.softGold),
        ),
        const SizedBox(height: 6),
        Text(encounter.label,
            style: textTheme.displayLarge?.copyWith(fontSize: 26)),
        const SizedBox(height: 8),
        Text(
          run.retryUsed ? 'Retry already used' : 'One retry remaining',
          style: textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: OpaqueCharacterArt(
            assetPath: GameAssets.enemy(enemy.id),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.sports_mma,
              size: 72,
              color: MythDuskColors.muted,
            ),
          ),
        ),
        Text(enemy.name,
            textAlign: TextAlign.center, style: textTheme.headlineMedium),
        const SizedBox(height: 12),
        if (run.relicIds.isNotEmpty) ...[
          Text('Relics', style: textTheme.titleMedium),
          for (final id in run.relicIds)
            Text(
              '• ${RelicCatalog.byId(id)?.name ?? id}',
              style: textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          const SizedBox(height: 12),
        ],
        const Spacer(),
        FilledButton(
          onPressed: () => _launch(context, ref),
          child: Text(encounter.isBoss ? 'Fight boss' : 'Enter fight'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            ref.read(gameplayAnalyticsProvider).log(
                  GameplayAnalyticsEvents.expeditionAbandoned,
                );
            ref.read(profileProvider.notifier).abandonExpedition();
          },
          child: const Text('Abandon run'),
        ),
      ],
    );
  }

  Future<void> _launch(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);
    if (profile.lives <= 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No lives remaining')),
      );
      return;
    }
    final ok = await showPrepPickerSheet(
      context,
      encounterName: run.encounter.label,
    );
    if (!ok || !context.mounted) return;
    ref.read(profileProvider.notifier).beginExpeditionBattle();
    ref.read(gameplayAnalyticsProvider).log(
      GameplayAnalyticsEvents.battleStarted,
      {'mode': 'expedition', 'room': run.battleIndex},
    );
    if (!context.mounted) return;
    context.push('/battle/${ExpeditionBalance.battleNodeId}');
  }
}

class _RelicPick extends ConsumerWidget {
  const _RelicPick({required this.run, required this.textTheme});

  final ExpeditionRunState run;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = [
      for (final id in run.pendingRelicOffers) RelicCatalog.byId(id),
    ].whereType<RelicDefinition>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Choose a relic',
            style: textTheme.displayLarge?.copyWith(fontSize: 26)),
        const SizedBox(height: 8),
        Text(
          'Expedition-only. Relics never deal match damage.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        for (final relic in offers) ...[
          OutlinedButton(
            onPressed: () {
              ref
                  .read(profileProvider.notifier)
                  .chooseExpeditionRelic(relic.id);
              ref.read(gameplayAnalyticsProvider).log(
                GameplayAnalyticsEvents.relicChosen,
                {'relicId': relic.id},
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: MythDuskColors.parchment,
              side: const BorderSide(color: MythDuskColors.mist),
              padding: const EdgeInsets.all(14),
              alignment: Alignment.centerLeft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(relic.name, style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(relic.blurb,
                    style: textTheme.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
