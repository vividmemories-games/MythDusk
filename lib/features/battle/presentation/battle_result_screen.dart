import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/assets/game_assets.dart';
import '../../battle/domain/battle_objective.dart';
import '../../campaign/data/campaign_repository.dart';
import '../../campaign/domain/campaign_models.dart';
import '../../daily/providers/daily_providers.dart';
import '../../heroes/domain/hero_def.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../../../shared/presentation/content_error_screen.dart';

class BattleResultArgs {
  const BattleResultArgs({
    required this.won,
    required this.nodeId,
    required this.nodeName,
    required this.enemyName,
    required this.coinReward,
    this.bossFled = false,
    this.isWeekly = false,
    this.isDaily = false,
    this.isExpedition = false,
    this.weeklyDayKey,
    this.dailyDayKey,
    this.progress,
    this.heroHp = 0,
    this.heroMaxHp = 1,
    this.bossForm,
  });

  final bool won;
  final bool bossFled;
  final bool isWeekly;
  final bool isDaily;
  final bool isExpedition;
  final String? weeklyDayKey;
  final String? dailyDayKey;
  final String nodeId;
  final String nodeName;
  final String enemyName;
  final int coinReward;
  final BattleProgress? progress;
  final int heroHp;
  final int heroMaxHp;
  final int? bossForm;
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
  String? _contentError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyReward());
  }

  Future<void> _applyReward() async {
    if (_applied) return;
    _applied = true;
    if (widget.args.isExpedition) {
      final progress = widget.args.progress ?? const BattleProgress();
      final granted =
          await ref.read(profileProvider.notifier).applyExpeditionBattleResult(
                won: widget.args.won,
                progress: progress,
              );
      if (mounted) setState(() => _grantedCoins = granted);
      return;
    }
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
    if (widget.args.isDaily) {
      final contract = ref.read(dailyContractProvider);
      final progress = widget.args.progress ?? const BattleProgress();
      final result = await ref.read(profileProvider.notifier).applyDailyVictory(
            contract: contract,
            progress: progress,
            heroHp: widget.args.heroHp,
            heroMaxHp: widget.args.heroMaxHp,
          );
      if (mounted) setState(() => _grantedCoins = result.coins);
      return;
    }
    try {
      final chapter = await ref.read(campaignChapterProvider.future);
      final node = chapter.nodeById(widget.args.nodeId);
      final actIndex = chapter.actForNode(widget.args.nodeId)?.index ?? 0;
      await ref.read(profileProvider.notifier).applyVictory(
            nodeId: widget.args.nodeId,
            coinReward: widget.args.coinReward,
            isBoss: node.isBoss,
            actIndex: actIndex,
            nodePrepDrops: node.prepDrops,
            chapterId: chapter.id,
            progress: widget.args.progress,
            heroHp: widget.args.heroHp,
            heroMaxHp: widget.args.heroMaxHp,
            bossForm: widget.args.bossForm ?? node.bossForm,
          );
      if (mounted) setState(() => _grantedCoins = widget.args.coinReward);
    } on Object {
      if (!mounted) return;
      setState(() {
        _contentError =
            'The completed campaign node could not be validated. No reward was granted.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_contentError case final error?) {
      return ContentErrorScreen(
        title: 'Result unavailable',
        message: error,
      );
    }
    if (widget.args.isWeekly ||
        widget.args.isDaily ||
        widget.args.isExpedition) {
      return _buildResult(context);
    }
    final chapterAsync = ref.watch(campaignChapterProvider);
    return chapterAsync.when(
      loading: () => const Scaffold(
        backgroundColor: MythDuskColors.ink,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const ContentErrorScreen(
        title: 'Result unavailable',
        message: 'Campaign content could not be loaded to validate this win.',
      ),
      data: (chapter) {
        final node = chapter.tryNodeById(widget.args.nodeId);
        if (node == null) {
          return ContentErrorScreen(
            title: 'Result unavailable',
            message: 'Campaign node “${widget.args.nodeId}” does not exist.',
          );
        }
        return _buildResult(context, chapter: chapter, currentNode: node);
      },
    );
  }

  Widget _buildResult(
    BuildContext context, {
    CampaignChapter? chapter,
    CampaignNode? currentNode,
  }) {
    final args = widget.args;
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(profileProvider);

    String? nextNodeId;
    if (args.won && chapter != null && currentNode != null) {
      final next = chapter.nodes.where((n) => n.order == currentNode.order + 1);
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
                  color: args.won ? MythDuskColors.amber : MythDuskColors.ember,
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
              if (args.won ||
                  (args.isExpedition && !args.won && _grantedCoins > 0)) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MythDuskColors.deepTeal,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: MythDuskColors.mist),
                  ),
                  child: Column(
                    children: [
                      Text('Rewards', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        !args.won
                            ? (args.isExpedition
                                ? (_grantedCoins > 0
                                    ? '+$_grantedCoins coins (run failed)'
                                    : 'Retry available — return to Expedition')
                                : '+0 coins')
                            : (!_applied
                                ? '+${args.coinReward} coins'
                                : ((args.isWeekly ||
                                            args.isDaily ||
                                            args.isExpedition) &&
                                        _grantedCoins == 0
                                    ? (args.isExpedition
                                        ? 'Choose a relic on the Expedition screen'
                                        : 'Already claimed today')
                                    : '+${(args.isWeekly || args.isDaily || args.isExpedition) ? _grantedCoins : args.coinReward} coins')),
                        style: textTheme.headlineMedium?.copyWith(
                          color: MythDuskColors.softGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Purse: ${profile.coins} coins',
                        style: textTheme.bodyMedium,
                      ),
                      if (args.won &&
                          !args.isWeekly &&
                          !args.isDaily &&
                          !args.isExpedition &&
                          currentNode?.isBoss != true) ...[
                        const SizedBox(height: 6),
                        Text(
                          '+1 Vanguard Tonic (prep stash)',
                          style: textTheme.bodyMedium?.copyWith(
                            color: MythDuskColors.softGold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (args.won &&
                  !args.isWeekly &&
                  !args.isDaily &&
                  !args.isExpedition &&
                  profile.pendingUnlockCelebrations.isNotEmpty) ...[
                FilledButton(
                  onPressed: () {
                    final heroId = profile.pendingUnlockCelebrations.first;
                    context.go('/hero_unlock/$heroId');
                  },
                  child: Text(
                    'Meet ${HeroCatalog.tryById(profile.pendingUnlockCelebrations.first)?.name ?? 'hero'}',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (args.won && nextNodeId != null)
                FilledButton(
                  onPressed: profile.pendingUnlockCelebrations.isNotEmpty
                      ? () {
                          final heroId =
                              profile.pendingUnlockCelebrations.first;
                          context.go('/hero_unlock/$heroId');
                        }
                      : () => _goBattle(nextNodeId!),
                  child: Text(
                    profile.pendingUnlockCelebrations.isNotEmpty
                        ? 'Continue'
                        : 'Next battle',
                  ),
                ),
              if (args.won && nextNodeId != null) const SizedBox(height: 10),
              if (args.isExpedition)
                FilledButton(
                  onPressed: () => context.go('/expedition'),
                  child: Text(
                    args.won ? 'Continue expedition' : 'Back to expedition',
                  ),
                ),
              if (args.isExpedition) const SizedBox(height: 10),
              if (!args.won && !args.isExpedition)
                FilledButton(
                  onPressed: () => _goBattle(args.nodeId),
                  child: const Text('Retry'),
                ),
              if (!args.won && !args.isExpedition) const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  final pending = profile.pendingUnlockCelebrations;
                  if (args.won &&
                      !args.isWeekly &&
                      !args.isDaily &&
                      !args.isExpedition &&
                      pending.isNotEmpty) {
                    context.go('/hero_unlock/${pending.first}');
                    return;
                  }
                  if (args.isWeekly) {
                    context.go('/weekly');
                  } else if (args.isDaily) {
                    context.go('/daily');
                  } else if (args.isExpedition) {
                    context.go('/expedition');
                  } else {
                    context.go('/campaign');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: MythDuskColors.parchment,
                  side: const BorderSide(color: MythDuskColors.mist),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  args.isWeekly
                      ? 'Weekly'
                      : args.isDaily
                          ? 'Daily'
                          : args.isExpedition
                              ? 'Expedition'
                              : 'Campaign map',
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  final pending = profile.pendingUnlockCelebrations;
                  if (args.won &&
                      !args.isWeekly &&
                      !args.isDaily &&
                      !args.isExpedition &&
                      pending.isNotEmpty) {
                    context.go('/hero_unlock/${pending.first}');
                    return;
                  }
                  context.go('/');
                },
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
      if (!mounted) return;
      context.go('/weekly');
      return;
    }
    if (widget.args.isDaily || nodeId == 'daily') {
      if (!mounted) return;
      context.go('/daily');
      return;
    }
    if (widget.args.isExpedition || nodeId == 'expedition') {
      if (!mounted) return;
      context.go('/expedition');
      return;
    }
    if (!mounted) return;
    context.go('/briefing/$nodeId');
  }
}
