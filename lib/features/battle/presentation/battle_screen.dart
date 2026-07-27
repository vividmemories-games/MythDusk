import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../campaign/data/campaign_repository.dart';
import '../../heroes/domain/hero_def.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../../puzzle/domain/puzzle_engine.dart';
import '../domain/battle_state.dart';
import '../providers/battle_provider.dart';
import 'animated_puzzle_board.dart';
import 'battle_hud.dart';
import 'battle_result_screen.dart';
import 'battle_stage.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key, required this.nodeId});

  final String nodeId;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  static const _hintIdle = Duration(seconds: 5);

  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleHint(ref.read(battleProvider(widget.nodeId)));
    });
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
    final battle = ref.watch(battleProvider(widget.nodeId));
    final notifier = ref.read(battleProvider(widget.nodeId).notifier);

    ref.listen(battleProvider(widget.nodeId), (prev, next) {
      if (prev != null &&
          prev.phase != next.phase &&
          (next.phase == BattlePhase.victory ||
              next.phase == BattlePhase.defeat)) {
        final args = BattleResultArgs(
          won: next.phase == BattlePhase.victory,
          bossFled: next.bossFled,
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

    final chapter = ref.watch(campaignChapterProvider).valueOrNull;
    final node = chapter?.nodeById(widget.nodeId);
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
                const ColoredBox(color: MythoraColors.ink),
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
                        color: MythoraColors.ink.withValues(alpha: 0.78),
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
                                    enabled:
                                        notifier.canCast(battle.hero.skills[i]),
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
                    onTap: () => context.pop(),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 8,
                  child: _FloatingActionIcon(
                    icon: Icons.refresh,
                    onTap: notifier.restart,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent circular back/restart button replacing the old AppBar band.
class _FloatingActionIcon extends StatelessWidget {
  const _FloatingActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MythoraColors.ink.withValues(alpha: 0.5),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 20, color: MythoraColors.parchment),
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
                ? MythoraColors.deepTeal.withValues(alpha: 0.85)
                : MythoraColors.ink.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? MythoraColors.amber.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.skip_next_rounded,
                size: 18,
                color: enabled ? MythoraColors.amber : MythoraColors.muted,
              ),
              const SizedBox(height: 2),
              Text(
                'End',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      enabled ? MythoraColors.parchment : MythoraColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Game-style ability card: name over gem/AP cost chips.
/// Glows gold when castable; stays readable (dimmed) when not.
class _SkillButton extends StatelessWidget {
  const _SkillButton({
    required this.skill,
    required this.enabled,
    required this.onTap,
  });

  final SkillDef skill;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: enabled
              ? [MythoraColors.mist, MythoraColors.deepTeal]
              : [
                  MythoraColors.deepTeal.withValues(alpha: 0.55),
                  MythoraColors.ink.withValues(alpha: 0.55),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? MythoraColors.softGold
              : Colors.white.withValues(alpha: 0.14),
          width: enabled ? 1.6 : 1,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: MythoraColors.softGold.withValues(alpha: 0.35),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Opacity(
              opacity: enabled ? 1 : 0.6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    skill.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? MythoraColors.softGold
                          : MythoraColors.parchment,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final entry in skill.resourceCosts.entries) ...[
                        _CostChip(
                          iconPath: GameAssets.resourceIcon(entry.key),
                          value: entry.value,
                        ),
                        const SizedBox(width: 6),
                      ],
                      _CostChip(
                          iconPath: GameAssets.iconAp, value: skill.apCost),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  const _CostChip({required this.iconPath, required this.value});

  final String iconPath;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(3, 2, 6, 2),
      decoration: BoxDecoration(
        color: MythoraColors.ink.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Image.asset(
              iconPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 10),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MythoraColors.parchment,
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
                color: MythoraColors.muted,
              ),
        ),
      ),
    );
  }
}
