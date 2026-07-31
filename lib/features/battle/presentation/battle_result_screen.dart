import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/assets/game_assets.dart';
import '../../campaign/data/campaign_repository.dart';
import '../../profile/providers/mock_profile_provider.dart';

class BattleResultArgs {
  const BattleResultArgs({
    required this.won,
    required this.nodeId,
    required this.nodeName,
    required this.enemyName,
    required this.coinReward,
    this.bossFled = false,
    this.isWeekly = false,
    this.weeklyDayKey,
  });

  final bool won;
  final bool bossFled;
  final bool isWeekly;
  final String? weeklyDayKey;
  final String nodeId;
  final String nodeName;
  final String enemyName;
  final int coinReward;
}

class BattleResultScreen extends ConsumerStatefulWidget {
  const BattleResultScreen({super.key, required this.args});

  final BattleResultArgs args;

  @override
  ConsumerState<BattleResultScreen> createState() => _BattleResultScreenState();
}

class _BattleResultScreenState extends ConsumerState<BattleResultScreen> {
  var _applied = false;
  var _grantedCoins = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyReward());
  }

  Future<void> _applyReward() async {
    if (_applied) return;
    _applied = true;
    if (!widget.args.won) {
      await ref.read(profileProvider.notifier).applyDefeat();
      return;
    }
    if (widget.args.isWeekly) {
      final dayKey = widget.args.weeklyDayKey ?? '';
      final granted =
          await ref.read(profileProvider.notifier).applyWeeklyVictory(
                dayKey: dayKey,
                coinReward: widget.args.coinReward,
              );
      if (mounted) setState(() => _grantedCoins = granted);
      return;
    }
    final chapter = ref.read(campaignChapterProvider).valueOrNull;
    final node = chapter?.nodeById(widget.args.nodeId);
    final actIndex = chapter?.actForNode(widget.args.nodeId)?.index ?? 0;
    await ref.read(profileProvider.notifier).applyVictory(
          nodeId: widget.args.nodeId,
          coinReward: widget.args.coinReward,
          isBoss: node?.isBoss ?? false,
          actIndex: actIndex,
          nodePrepDrops: node?.prepDrops ?? const [],
        );
    if (mounted) setState(() => _grantedCoins = widget.args.coinReward);
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final textTheme = Theme.of(context).textTheme;
    final chapter = ref.watch(campaignChapterProvider).valueOrNull;
    final profile = ref.watch(profileProvider);

    String? nextNodeId;
    if (args.won && !args.isWeekly && chapter != null) {
      final current = chapter.nodeById(args.nodeId);
      final next = chapter.nodes.where((n) => n.order == current.order + 1);
      if (next.isNotEmpty) nextNodeId = next.first.id;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              if (args.won && args.bossFled) ...[
                Center(
                  child: Image.asset(
                    GameAssets.fxBossFlee,
                    width: 96,
                    height: 96,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                !args.won
                    ? 'Defeat'
                    : args.bossFled
                        ? 'Boss fled'
                        : 'Victory',
                textAlign: TextAlign.center,
                style: textTheme.displayLarge?.copyWith(
                  fontSize: 40,
                  color: args.won ? MythoraColors.amber : MythoraColors.ember,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                !args.won
                    ? '${args.enemyName} bested you. Try a different match plan.'
                    : args.bossFled
                        ? '${args.enemyName} escapes from ${args.nodeName} — stronger next time.'
                        : 'You defeated ${args.enemyName} at ${args.nodeName}.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              if (args.won) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MythoraColors.deepTeal,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: MythoraColors.mist),
                  ),
                  child: Column(
                    children: [
                      Text('Rewards', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        !args.won
                            ? '+0 coins'
                            : (!_applied
                                ? '+${args.coinReward} coins'
                                : (args.isWeekly && _grantedCoins == 0
                                    ? 'Already claimed today'
                                    : '+${args.isWeekly ? _grantedCoins : args.coinReward} coins')),
                        style: textTheme.headlineMedium?.copyWith(
                          color: MythoraColors.softGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Purse: ${profile.coins} coins',
                        style: textTheme.bodyMedium,
                      ),
                      if (!args.isWeekly &&
                          chapter?.nodeById(args.nodeId).isBoss != true) ...[
                        const SizedBox(height: 6),
                        Text(
                          '+1 Vanguard Tonic (prep stash)',
                          style: textTheme.bodyMedium?.copyWith(
                            color: MythoraColors.softGold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (args.won && nextNodeId != null)
                FilledButton(
                  onPressed: () => _goBattle(nextNodeId!),
                  child: const Text('Next battle'),
                ),
              if (args.won && nextNodeId != null) const SizedBox(height: 10),
              if (!args.won)
                FilledButton(
                  onPressed: () => _goBattle(args.nodeId),
                  child: const Text('Retry'),
                ),
              if (!args.won) const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => context.go(
                  args.isWeekly ? '/weekly' : '/campaign',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MythoraColors.parchment,
                  side: const BorderSide(color: MythoraColors.mist),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(args.isWeekly ? 'Weekly' : 'Campaign map'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _goBattle(String nodeId) async {
    if (widget.args.isWeekly || nodeId == 'weekly') {
      if (widget.args.isWeekly) {
        if (!mounted) return;
        context.go('/weekly');
        return;
      }
    }
    if (!mounted) return;
    context.go('/briefing/$nodeId');
  }
}
