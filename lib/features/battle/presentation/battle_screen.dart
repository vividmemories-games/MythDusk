import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../campaign/data/campaign_repository.dart';
import '../../campaign/domain/campaign_models.dart';
import '../../heroes/domain/hero_def.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../../puzzle/data/board_catalog_repository.dart';
import '../../puzzle/domain/puzzle_engine.dart';
import '../../weekly/domain/weekly_schedule.dart';
import '../../weekly/providers/weekly_providers.dart';
import '../../../shared/presentation/content_error_screen.dart';
import '../domain/battle_state.dart';
import '../domain/enemy_def.dart';
import '../domain/skill_affordability.dart';
import '../providers/battle_provider.dart';
import 'animated_puzzle_board.dart';
import 'battle_hud.dart';
import 'battle_result_screen.dart';
import 'battle_stage.dart';
import 'battle_tutorial_overlay.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key, required this.nodeId});

  final String nodeId;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  static const _hintIdle = Duration(seconds: 5);

  Timer? _hintTimer;
  var _initialHintScheduled = false;

  @override
  void didUpdateWidget(covariant BattleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodeId == widget.nodeId) return;
    _hintTimer?.cancel();
    _initialHintScheduled = false;
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _scheduleHint(BattleState battle) {
    _hintTimer?.cancel();
    final hintsOn = ref.read(profileProvider).hintsEnabled;
    final canHint = hintsOn &&
        battle.phase == BattlePhase.playerTurn &&
        !battle.inputLocked &&
        battle.movesLeft > 0 &&
        battle.hintCells.isEmpty;
    if (!canHint) return;

    _hintTimer = Timer(_hintIdle, () {
      if (!mounted) return;
      final current = ref.read(battleProvider(widget.nodeId));
      if (!ref.read(profileProvider).hintsEnabled) return;
      if (current.phase != BattlePhase.playerTurn) return;
      if (current.inputLocked || current.movesLeft <= 0) return;
      if (current.hintCells.isNotEmpty) return;
      final swap = PuzzleEngine.findFirstColorSwap(current.board);
      if (swap == null) return;
      ref.read(battleProvider(widget.nodeId).notifier).showHint({
        swap.$1,
        swap.$2,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodeId == WeeklyBalance.battleNodeId) {
      return _buildBattle(context);
    }

    final chapterAsync = ref.watch(campaignChapterProvider);
    final overlaysAsync = ref.watch(overlayCatalogProvider);
    final templatesAsync = ref.watch(boardTemplateCatalogProvider);
    if (chapterAsync.hasError ||
        overlaysAsync.hasError ||
        templatesAsync.hasError) {
      return const ContentErrorScreen(
        title: 'Battle content unavailable',
        message: 'The chapter or puzzle-board data could not be loaded.',
      );
    }
    final chapter = chapterAsync.valueOrNull;
    final overlays = overlaysAsync.valueOrNull;
    final templates = templatesAsync.valueOrNull;
    if (chapter == null || overlays == null || templates == null) {
      return const Scaffold(
        backgroundColor: MythDuskColors.ink,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final node = chapter.tryNodeById(widget.nodeId);
    if (node == null) {
      return ContentErrorScreen(
        title: 'Battle unavailable',
        message: 'Campaign node “${widget.nodeId}” does not exist.',
      );
    }
    if (EnemyCatalog.tryById(node.enemyId) == null) {
      return ContentErrorScreen(
        title: 'Enemy unavailable',
        message: 'Enemy content “${node.enemyId}” could not be found.',
      );
    }
    final board = chapter.boardFor(node);
    final templateId = board.templateId;
    if (templateId == null || templates[templateId] == null) {
      return ContentErrorScreen(
        title: 'Board unavailable',
        message: 'Puzzle-board content for “${node.id}” could not be found.',
      );
    }
    final hazardId = board.hazardSpawn?.overlayId;
    if (hazardId != null && overlays[hazardId] == null) {
      return ContentErrorScreen(
        title: 'Board unavailable',
        message: 'Hazard content “$hazardId” could not be found.',
      );
    }
    return _buildBattle(context, chapter: chapter, node: node);
  }

  Widget _buildBattle(
    BuildContext context, {
    CampaignChapter? chapter,
    CampaignNode? node,
  }) {
    final battle = ref.watch(battleProvider(widget.nodeId));
    final notifier = ref.read(battleProvider(widget.nodeId).notifier);

    if (!_initialHintScheduled) {
      _initialHintScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scheduleHint(ref.read(battleProvider(widget.nodeId)));
      });
    }

    ref.listen(battleProvider(widget.nodeId), (prev, next) {
      if (prev != null &&
          prev.phase != next.phase &&
          (next.phase == BattlePhase.victory ||
              next.phase == BattlePhase.defeat)) {
        final args = BattleResultArgs(
          won: next.phase == BattlePhase.victory,
          bossFled: next.bossFled,
          isWeekly: next.isWeekly,
          weeklyDayKey:
              next.isWeekly ? ref.read(weeklyChallengeProvider).dayKey : null,
          nodeId: next.nodeId ?? widget.nodeId,
          nodeName: next.nodeName ?? 'Battle',
          enemyName: next.enemy.name,
          coinReward: next.coinReward,
        );
        context.pushReplacement('/result', extra: args);
        return;
      }

      // Soft-lock recovery: playerTurn with 0 moves (enemy acted but moves
      // never refreshed). Do not treat enemyTurn as soft-lock — that is normal.
      final softLocked =
          next.phase == BattlePhase.playerTurn && next.movesLeft <= 0;
      final wasSoft = prev != null &&
          prev.phase == BattlePhase.playerTurn &&
          prev.movesLeft <= 0;
      if (softLocked && !wasSoft) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref
              .read(battleProvider(widget.nodeId).notifier)
              .recoverIfSoftLocked();
        });
      }

      final idleChanged = prev == null ||
          prev.board != next.board ||
          prev.phase != next.phase ||
          prev.selectedCell != next.selectedCell ||
          prev.movesLeft != next.movesLeft ||
          prev.inputLocked != next.inputLocked ||
          prev.hintCells != next.hintCells;
      if (idleChanged) {
        _scheduleHint(next);
      }
    });

    ref.listen(profileProvider.select((p) => p.hintsEnabled), (_, enabled) {
      if (!enabled) {
        _hintTimer?.cancel();
        notifier.clearHint();
        return;
      }
      _scheduleHint(ref.read(battleProvider(widget.nodeId)));
    });

    final bgPath = GameAssets.battleBackground(
      node?.backgroundId ?? chapter?.backgroundId,
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            bgPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: MythDuskColors.ink),
          ),
          // Light top vignette for HUD legibility; mid/bottom stay open so
          // the background owns the ground plane.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x880B1C22),
                  Color(0x140B1C22),
                  Color(0x000B1C22),
                  Color(0x2E0B1C22),
                ],
                stops: [0.0, 0.24, 0.80, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Clears the floating back/restart buttons above the
                    // HP plates.
                    const SizedBox(height: 44),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: BattleStage(battle: battle),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: BattleHudBar(battle: battle),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedPuzzleBoard(
                          battle: battle,
                          onTap: notifier.tapCell,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: MythDuskColors.ink.withValues(alpha: 0.78),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StatusLine(battle: battle),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              for (var i = 0;
                                  i < battle.hero.skills.length;
                                  i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: _SkillButton(
                                    skill: battle.hero.skills[i],
                                    battle: battle,
                                    onTap: () => notifier
                                        .castSkill(battle.hero.skills[i]),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              _EndTurnButton(
                                enabled:
                                    battle.phase == BattlePhase.playerTurn &&
                                        !battle.inputLocked,
                                onTap: notifier.endPlayerTurn,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 2,
                  left: 8,
                  child: _FloatingActionIcon(
                    icon: Icons.arrow_back,
                    semanticLabel: 'Leave battle',
                    onTap: () => _confirmLeave(context),
                  ),
                ),
                if (AppFlavor.showQaTools &&
                    battle.phase == BattlePhase.playerTurn &&
                    !battle.inputLocked)
                  Positioned(
                    top: 2,
                    left: 64,
                    child: _FloatingActionIcon(
                      icon: Icons.bug_report_outlined,
                      semanticLabel: 'QA: force enemy skill',
                      onTap: () => _showQaEnemySkills(
                        context,
                        battle,
                        notifier,
                      ),
                    ),
                  ),
                Positioned(
                  top: 2,
                  right: 8,
                  child: _FloatingActionIcon(
                    icon: Icons.refresh,
                    semanticLabel: 'Restart battle',
                    onTap: () => _confirmRestart(context, notifier),
                  ),
                ),
                BattleTutorialOverlay(
                  enabled: !battle.isWeekly,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MythDuskColors.deepTeal,
        title: const Text('Leave battle?'),
        content: const Text(
          'Progress in this fight will be lost. A life is only spent on defeat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) context.pop();
  }

  Future<void> _confirmRestart(
      BuildContext context, BattleNotifier notifier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MythDuskColors.deepTeal,
        title: const Text('Restart battle?'),
        content: const Text(
          'The fight resets from the start. Prep already spent stays spent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) notifier.restart();
  }

  Future<void> _showQaEnemySkills(
    BuildContext context,
    BattleState battle,
    BattleNotifier notifier,
  ) async {
    final skill = await showModalBottomSheet<EnemySkill>(
      context: context,
      backgroundColor: MythDuskColors.deepTeal,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Force ${battle.enemy.name} skill',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: MythDuskColors.parchment,
                    ),
              ),
            ),
            for (final candidate in battle.enemy.skills)
              ListTile(
                title: Text(candidate.name),
                subtitle: Text(candidate.intentLabel),
                trailing: candidate.effects.isEmpty
                    ? null
                    : const Icon(
                        Icons.science_outlined,
                        color: MythDuskColors.amber,
                      ),
                onTap: () => Navigator.pop(sheetContext, candidate),
              ),
          ],
        ),
      ),
    );
    if (skill == null || !mounted) return;
    final applied = await notifier.forceEnemySkillForQa(skill);
    if (!context.mounted || applied) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Wait for the player turn, then try again.')),
    );
  }
}

/// Translucent circular back/restart button replacing the old AppBar band.
class _FloatingActionIcon extends StatelessWidget {
  const _FloatingActionIcon({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        button: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: Material(
          color: MythDuskColors.ink.withValues(alpha: 0.5),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, size: 22, color: MythDuskColors.parchment),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact control to discard remaining moves and start the enemy turn.
class _EndTurnButton extends StatelessWidget {
  const _EndTurnButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: enabled
                ? MythDuskColors.deepTeal.withValues(alpha: 0.85)
                : MythDuskColors.ink.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? MythDuskColors.amber.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.skip_next_rounded,
                size: 18,
                color: enabled ? MythDuskColors.amber : MythDuskColors.muted,
              ),
              const SizedBox(height: 2),
              Text(
                'End',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      enabled ? MythDuskColors.parchment : MythDuskColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Game-style ability card: name over current/need cost chips.
/// Glows gold when castable; shows blocking reason when not.
class _SkillButton extends StatelessWidget {
  const _SkillButton({
    required this.skill,
    required this.battle,
    required this.onTap,
  });

  final SkillDef skill;
  final BattleState battle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final afford = SkillAffordability.evaluate(skill, battle);
    final enabled = afford.canCast;

    return Tooltip(
      message: afford.blockingReason ?? 'Ready',
      triggerMode: TooltipTriggerMode.longPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled
                ? [MythDuskColors.mist, MythDuskColors.deepTeal]
                : [
                    MythDuskColors.deepTeal.withValues(alpha: 0.55),
                    MythDuskColors.ink.withValues(alpha: 0.55),
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? MythDuskColors.softGold
                : Colors.white.withValues(alpha: 0.14),
            width: enabled ? 1.6 : 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: MythDuskColors.softGold.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Opacity(
                opacity: enabled ? 1 : 0.72,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? MythDuskColors.softGold
                            : MythDuskColors.parchment,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final line in afford.resourceLines) ...[
                          _CostChip(
                            iconPath: GameAssets.resourceIcon(line.resourceId),
                            label: line.label,
                            ok: line.ok,
                          ),
                          const SizedBox(width: 4),
                        ],
                        _CostChip(
                          iconPath: GameAssets.iconAp,
                          label: '${afford.apHave}/${afford.apNeed}',
                          ok: afford.apOk,
                        ),
                      ],
                    ),
                    if (!enabled && afford.blockingReason != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        afford.blockingReason!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: MythDuskColors.ember,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  const _CostChip({
    required this.iconPath,
    required this.label,
    this.ok = true,
  });

  final String iconPath;
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(3, 2, 5, 2),
      decoration: BoxDecoration(
        color: MythDuskColors.ink.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(9),
        border: ok
            ? null
            : Border.all(color: MythDuskColors.ember.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Image.asset(
              iconPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 10),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: ok ? MythDuskColors.parchment : MythDuskColors.ember,
            ),
          ),
        ],
      ),
    );
  }
}

/// One-line status replacing the scrolling combat log.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.battle});

  final BattleState battle;

  @override
  Widget build(BuildContext context) {
    final line = battle.log.isEmpty ? '' : battle.log.last;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Text(
          line,
          key: ValueKey(line),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: MythDuskColors.muted,
              ),
        ),
      ),
    );
  }
}
