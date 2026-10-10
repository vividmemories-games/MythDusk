import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/challenge_art.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../prep/presentation/prep_picker_sheet.dart';
import '../../profile/domain/economy_balance.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../domain/weekly_schedule.dart';
import '../providers/weekly_providers.dart';

class WeeklyScreen extends ConsumerWidget {
  const WeeklyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(profileProvider.notifier).tickLifeRegen();
    final challenge = ref.watch(weeklyChallengeProvider);
    final profile = ref.watch(profileProvider);
    final override = ref.watch(weeklyDayOverrideProvider);
    final completed = profile.weeklyLastCompletedDay == challenge.dayKey;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 19;

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      body: Stack(children: [
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
                        child: Text('Weekly', style: challengeTextStyle(20))),
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
                            Text(
                                '${challenge.isWeekend ? 'WEEKEND' : _weekdayLabel(challenge.dayKey).toUpperCase()} · ${challenge.dayKey}',
                                style: challengeTextStyle(12,
                                        color: MythDuskColors.softGold)
                                    .copyWith(letterSpacing: 1.3)),
                            const SizedBox(height: 4),
                            Text(challenge.title,
                                style: challengeTextStyle(largeText ? 28 : 34,
                                    bold: true)),
                            const SizedBox(height: 4),
                            Text(challenge.blurb,
                                style: challengeTextStyle(14,
                                        color: MythDuskColors.muted)
                                    .copyWith(height: 1.35)),
                          ])),
                  ChallengeStage(
                      enemyId: challenge.enemyId,
                      name: challenge.enemyName,
                      bossForm: challenge.isBoss ? 4 : null,
                      heightFactor: .62),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ChallengePanel(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            Row(children: [
                              ChallengeArtIcon(
                                  challenge.isBoss ? 'coin' : 'objective',
                                  size: 48),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        completed
                                            ? 'CHALLENGE COMPLETE'
                                            : challenge.isBoss
                                                ? 'BOSS CHALLENGE'
                                                : 'PRIMARY OBJECTIVE',
                                        style: challengeTextStyle(11,
                                                color: MythDuskColors.softGold)
                                            .copyWith(letterSpacing: 1)),
                                    const SizedBox(height: 5),
                                    Text(
                                        challenge.objective?.progressLabel ??
                                            'Defeat the boss',
                                        style:
                                            challengeTextStyle(23, bold: true)),
                                  ])),
                              if (!largeText)
                                ChallengeCoinReward(
                                    amount: challenge.coinReward,
                                    claimed: completed),
                            ]),
                            if (largeText)
                              Align(
                                  alignment: Alignment.centerRight,
                                  child: ChallengeCoinReward(
                                      amount: challenge.coinReward,
                                      claimed: completed)),
                            const SizedBox(height: 9),
                            Text(
                                completed
                                    ? 'Reward claimed. Come back tomorrow.'
                                    : 'First win today: +${challenge.coinReward} coins',
                                style: challengeTextStyle(13,
                                    color: MythDuskColors.muted)),
                            if (challenge.enrageAfterTurns != null) ...[
                              const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 7),
                                  child: ChallengeDivider()),
                              Text(
                                  'Boss enrages after ${challenge.enrageAfterTurns} turns',
                                  style: challengeTextStyle(14,
                                      color: MythDuskColors.softGold)),
                            ],
                            const SizedBox(height: 6),
                            Text(
                                'Fail spends 1 life · Resets at local midnight.',
                                style: challengeTextStyle(12,
                                    color: MythDuskColors.muted)),
                            if (override != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                  'QA override: ${WeeklySchedule.dayKey(override)}',
                                  style: challengeTextStyle(12,
                                      color: MythDuskColors.amber)),
                            ],
                          ]))),
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
                ]),
          )))),
          ChallengeActions(
              lives: profile.lives,
              maxLives: EconomyBalance.maxLives,
              enabled: !completed && profile.lives > 0,
              label: profile.lives <= 0
                  ? 'No lives'
                  : completed
                      ? 'Completed'
                      : 'Play',
              onPressed: () => _play(context, ref, challenge)),
        ])),
      ]),
    );
  }

  String _weekdayLabel(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return dayKey;
    final dt = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[dt.weekday];
  }

  Future<void> _play(
    BuildContext context,
    WidgetRef ref,
    WeeklyChallenge challenge,
  ) async {
    ref.read(profileProvider.notifier).tickLifeRegen();
    if (ref.read(profileProvider).lives <= 0) return;
    final ok = await showPrepPickerSheet(
      context,
      encounterName: challenge.enemyName,
    );
    if (!ok || !context.mounted) return;
    if (!context.mounted) return;
    context.push('/battle/${WeeklyBalance.battleNodeId}');
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
                Text('QA day override',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Use device time'),
                  onTap: () {
                    ref.read(weeklyDayOverrideProvider.notifier).state = null;
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Force weekday (Wed)'),
                  onTap: () {
                    final d = now.subtract(
                        Duration(days: now.weekday - DateTime.wednesday));
                    ref.read(weeklyDayOverrideProvider.notifier).state = d;
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Force weekend (Sat)'),
                  onTap: () {
                    final d = now
                        .add(Duration(days: DateTime.saturday - now.weekday));
                    ref.read(weeklyDayOverrideProvider.notifier).state = d;
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
