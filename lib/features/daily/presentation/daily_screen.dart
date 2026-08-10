import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/opaque_character_art.dart';
import '../../battle/domain/enemy_def.dart';
import '../../prep/presentation/prep_picker_sheet.dart';
import '../../profile/domain/economy_balance.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../domain/daily_schedule.dart';
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

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Daily'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Contract · ${contract.dayKey}',
                style: textTheme.bodyMedium?.copyWith(
                  color: MythDuskColors.softGold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                contract.title,
                style: textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(contract.blurb, style: textTheme.bodyMedium),
              const SizedBox(height: 16),
              SizedBox(
                height: 130,
                child: OpaqueCharacterArt(
                  assetPath: GameAssets.enemy(contract.enemyId),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.sports_mma,
                    size: 72,
                    color: MythDuskColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                enemy.name,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MythDuskColors.deepTeal.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MythDuskColors.mist),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed
                          ? 'Completed today — new contract at midnight'
                          : 'Primary: ${contract.objective.progressLabel}',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      completed
                          ? 'Reward already claimed for ${contract.dayKey}.'
                          : 'Reward: +${contract.coinReward} coins'
                              ' · medals +${DailyBalance.medalCoinBonus} each',
                      style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Text('Medals', style: textTheme.titleMedium),
                    const SizedBox(height: 6),
                    for (final medal in contract.medals)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${medal.title}',
                          style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                      ),
                    if (override != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'QA override: ${DailySchedule.dayKey(override)}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: MythDuskColors.amber,
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
                    : () => _play(context, ref, contract),
                child: Text(
                  profile.lives <= 0
                      ? 'No lives'
                      : completed
                          ? 'Completed'
                          : 'Play contract',
                ),
              ),
              const SizedBox(height: 10),
              if (AppFlavor.showQaTools) ...[
                OutlinedButton(
                  onPressed: () => _showQaOverride(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MythDuskColors.parchment,
                    side: const BorderSide(color: MythDuskColors.mist),
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
                          offset == 0 ? null : now.add(Duration(days: offset));
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
