import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/challenge_art.dart';
import '../../battle/domain/enemy_def.dart';
import '../../prep/presentation/prep_picker_sheet.dart';
import '../../profile/domain/economy_balance.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../domain/daily_schedule.dart';
import '../domain/daily_battle_medal.dart';
import '../providers/daily_providers.dart';

class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(profileProvider.notifier).tickLifeRegen();
    final contract = ref.watch(dailyContractProvider);
    final profile = ref.watch(profileProvider);
    final override = ref.watch(dailyDayOverrideProvider);
    final completed = profile.dailyLastCompletedDay == contract.dayKey;
    final textTheme = Theme.of(context).textTheme;
    final enemy = EnemyCatalog.byId(contract.enemyId);
    final claimedToday = contract.medals
        .where((m) => profile.claimedDailyMedalIds.contains(m.id))
        .length;

    final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      body: Stack(
        children: [
          Positioned.fill(
              child: Image.asset(ChallengeArtwork.stage, fit: BoxFit.cover)),
          Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: .65))),
          SafeArea(
            child: Column(children: [
              Expanded(
                  child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(alignment: Alignment.center, children: [
                          Padding(
                              padding: const EdgeInsets.all(8),
                              child:
                                  Text('Daily', style: challengeTextStyle(20))),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: BackButton(onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/');
                                }
                              })),
                        ]),
                        const ChallengeDivider(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CONTRACT · ${contract.dayKey}',
                                    style: challengeTextStyle(12,
                                            color: MythDuskColors.softGold)
                                        .copyWith(letterSpacing: 1.3)),
                                const SizedBox(height: 4),
                                Text(contract.title,
                                    style: challengeTextStyle(
                                        largeText ? 28 : 34,
                                        bold: true)),
                                const SizedBox(height: 4),
                                Text(contract.blurb,
                                    style: challengeTextStyle(14,
                                            color: MythDuskColors.muted)
                                        .copyWith(height: 1.35)),
                              ]),
                        ),
                        ChallengeStage(
                            enemyId: contract.enemyId, name: enemy.name),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ChallengePanel(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      ChallengeArtIcon('objective',
                                          size: largeText ? 42 : 48),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(
                                                completed
                                                    ? 'CONTRACT COMPLETE'
                                                    : 'PRIMARY OBJECTIVE',
                                                style: challengeTextStyle(11,
                                                        color: MythDuskColors
                                                            .softGold)
                                                    .copyWith(
                                                        letterSpacing: 1)),
                                            const SizedBox(height: 5),
                                            Text(
                                                contract
                                                    .objective.progressLabel,
                                                style: challengeTextStyle(23,
                                                    bold: true)),
                                          ])),
                                      if (!largeText)
                                        ChallengeCoinReward(
                                            amount: contract.coinReward,
                                            claimed: completed),
                                    ]),
                                if (largeText)
                                  Align(
                                      alignment: Alignment.centerRight,
                                      child: ChallengeCoinReward(
                                          amount: contract.coinReward,
                                          claimed: completed)),
                                const SizedBox(height: 9),
                                Text(
                                    completed
                                        ? 'Reward claimed. Next contract at local midnight.'
                                        : 'Win once today for +${contract.coinReward} coins · medals +${contract.medals.first.coinReward} each',
                                    style: challengeTextStyle(13,
                                        color: MythDuskColors.muted)),
                                const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 5),
                                    child: ChallengeDivider()),
                                Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 14,
                                    children: [
                                      Text('Medals',
                                          style: challengeTextStyle(27,
                                              bold: true)),
                                      Text(
                                          '$claimedToday / ${contract.medals.length} claimed',
                                          style: challengeTextStyle(16,
                                              color: MythDuskColors.muted)),
                                    ]),
                                const SizedBox(height: 8),
                                for (final medal in contract.medals)
                                  Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: _MedalCard(
                                          medal: medal,
                                          claimed: profile.claimedDailyMedalIds
                                              .contains(medal.id))),
                                if (override != null)
                                  Text(
                                      'QA override: ${DailySchedule.dayKey(override)}',
                                      style: textTheme.bodySmall?.copyWith(
                                          color: MythDuskColors.amber)),
                              ])),
                        ),
                        if (AppFlavor.showQaTools) ...[
                          const SizedBox(height: 8),
                          const ChallengeDivider(),
                          TextButton(
                              onPressed: () => _showQaOverride(context, ref),
                              child: Text('QA: set day',
                                  style: challengeTextStyle(12,
                                      color: MythDuskColors.muted))),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              )),
              ChallengeActions(
                lives: profile.lives,
                maxLives: EconomyBalance.maxLives,
                enabled: !completed && profile.lives > 0,
                label: profile.lives <= 0
                    ? 'No lives'
                    : completed
                        ? 'Completed — come back tomorrow'
                        : 'Play contract',
                onPressed: () => _play(context, ref, contract),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _play(
    BuildContext context,
    WidgetRef ref,
    DailyContract contract,
  ) async {
    ref.read(profileProvider.notifier).tickLifeRegen();
    if (ref.read(profileProvider).lives <= 0) return;
    final ok = await showPrepPickerSheet(
      context,
      encounterName: contract.enemyName,
    );
    if (!ok || !context.mounted) return;
    context.push('/battle/${DailyBalance.battleNodeId}');
  }

  void _showQaOverride(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MythDuskColors.deepTeal,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'QA day override',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (final offset in const [0, 1, -1, 2, 3])
                  ListTile(
                    title: Text(
                      offset == 0
                          ? 'Today (clear override)'
                          : 'Local day ${offset > 0 ? '+' : ''}$offset',
                    ),
                    onTap: () {
                      ref.read(dailyDayOverrideProvider.notifier).state =
                          offset == 0
                              ? null
                              : DateTime(now.year, now.month, now.day + offset);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MedalCard extends StatelessWidget {
  const _MedalCard({required this.medal, required this.claimed});
  final DailyMedalDefinition medal;
  final bool claimed;
  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;
    final art = switch (medal.type) {
      DailyBattleMedalType.underPlayerTurns => 'hourglass',
      DailyBattleMedalType.castSkills ||
      DailyBattleMedalType.castDistinctSkills =>
        'lightning',
      DailyBattleMedalType.finishAboveHpPct => 'heart',
      DailyBattleMedalType.matchTilesColor =>
        medal.colorId == 'purple' ? 'spiral' : 'objective',
      DailyBattleMedalType.breakOverlays ||
      DailyBattleMedalType.generateResource =>
        'objective',
      DailyBattleMedalType.finishWithoutPrep => 'coin',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: const Color(0xCC03232B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MythDuskColors.mist, width: 1.3)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          ChallengeArtIcon(art, size: 40),
          const SizedBox(width: 10),
          Expanded(
              child: Text(medal.title,
                  style: challengeTextStyle(16,
                      bold: true,
                      color: claimed
                          ? MythDuskColors.softGold
                          : MythDuskColors.parchment))),
          if (!largeText)
            ChallengeCoinReward(amount: medal.coinReward, claimed: claimed),
        ]),
        if (largeText)
          Align(
              alignment: Alignment.centerRight,
              child: ChallengeCoinReward(
                  amount: medal.coinReward, claimed: claimed)),
      ]),
    );
  }
}
