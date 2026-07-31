import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../battle/domain/enemy_def.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final enemy = EnemyCatalog.byId(challenge.enemyId);

    return Scaffold(
      backgroundColor: MythoraColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Weekly'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                challenge.isWeekend
                    ? 'Weekend'
                    : _weekdayLabel(challenge.dayKey),
                style: textTheme.bodyMedium?.copyWith(
                  color: MythoraColors.softGold,
                ),
              ),
              const SizedBox(height: 6),
              Text(challenge.title,
                  style: textTheme.displayLarge?.copyWith(fontSize: 28)),
              const SizedBox(height: 8),
              Text(challenge.blurb, style: textTheme.bodyMedium),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  height: 140,
                  child: Image.asset(
                    GameAssets.enemy(
                      challenge.enemyId,
                      bossForm: challenge.isBoss ? 4 : null,
                    ),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.sports_mma,
                      size: 72,
                      color: MythoraColors.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                enemy.name,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MythoraColors.deepTeal.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MythoraColors.mist),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed
                          ? 'Completed today — come back tomorrow'
                          : 'Reward: +${challenge.coinReward} coins',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fail spends 1 life · Day uses device local time '
                      '(server will own this with Firebase).',
                      style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                    if (override != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'QA override: ${WeeklySchedule.dayKey(override)}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: MythoraColors.amber,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: completed || profile.lives <= 0
                    ? null
                    : () => _play(context, ref, challenge),
                child: Text(
                  profile.lives <= 0
                      ? 'No lives'
                      : completed
                          ? 'Completed'
                          : 'Play',
                ),
              ),
              const SizedBox(height: 10),
              if (AppFlavor.showQaTools) ...[
                OutlinedButton(
                  onPressed: () => _showQaOverride(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MythoraColors.parchment,
                    side: const BorderSide(color: MythoraColors.mist),
                  ),
                  child: const Text('QA: set day'),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Lives ${profile.lives}/${EconomyBalance.maxLives}',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
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
      backgroundColor: MythoraColors.deepTeal,
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
