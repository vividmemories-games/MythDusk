import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/battle_state.dart';
import 'match_collect_fx.dart';

/// Compact battle HUD: Moves · AP · resource gems · phase.
class BattleHudBar extends ConsumerWidget {
  const BattleHudBar({super.key, required this.battle});

  final BattleState battle;

  static const _resourceOrder = [
    'attack',
    'mana',
    'healing',
    'shield',
    'ultimate',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flyTargets = ref.watch(resourceFlyTargetsProvider);
    final statusBadges = <Widget>[
      if (battle.enraged) const _PhaseBadge(label: 'Enraged', danger: true),
      if (battle.movers.isNotEmpty)
        _PhaseBadge(
          label: battle.combatFx == CombatFx.wind ? 'Wind!' : 'Windy',
          danger: battle.combatFx == CombatFx.wind,
        ),
      if (battle.combatFx == CombatFx.hazard ||
          battle.hazardPulseCells.isNotEmpty)
        const _PhaseBadge(label: 'Hazard!', danger: true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _HudChip(
              iconPath: GameAssets.iconMoves,
              value: '${battle.movesLeft}',
              label: 'MOVES',
              accent: MythDuskColors.softGold,
            ),
            const SizedBox(width: 8),
            _HudChip(
              iconPath: GameAssets.iconAp,
              value: '${battle.ap}/${battle.hero.maxAp}',
              label: 'AP',
              accent: MythDuskColors.amber,
            ),
            const Spacer(),
            _PhaseBadge(label: _phaseLabel(battle)),
          ],
        ),
        if (statusBadges.isNotEmpty) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.end,
              children: statusBadges,
            ),
          ),
        ],
        if (battle.objective != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: _PhaseBadge(
              label: battle.objective!.progressText(
                playerTurnNumber: battle.playerTurnNumber,
                tilesCleared: battle.tilesCleared,
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < _resourceOrder.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: KeyedSubtree(
                  key: flyTargets.resourceKeys[_resourceOrder[i]],
                  child: _ResourceChip(
                    resourceId: _resourceOrder[i],
                    value: battle.resources[_resourceOrder[i]] ?? 0,
                    bumpToken:
                        ref.watch(hudResourceBumpProvider)[_resourceOrder[i]] ??
                            0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _phaseLabel(BattleState battle) => switch (battle.phase) {
        BattlePhase.playerTurn => 'Your turn',
        BattlePhase.resolving => 'Matching…',
        BattlePhase.enemyTurn => 'Enemy turn',
        BattlePhase.victory => battle.bossFled ? 'Fled' : 'Victory',
        BattlePhase.defeat => 'Defeat',
      };
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.iconPath,
    required this.value,
    required this.label,
    required this.accent,
  });

  final String iconPath;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 12, 3),
      decoration: BoxDecoration(
        color: MythDuskColors.ink.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: Image.asset(
              iconPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.circle,
                size: 18,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      height: 1.0,
                      color: MythDuskColors.parchment,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 8,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: accent,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({
    required this.resourceId,
    required this.value,
    required this.bumpToken,
  });

  final String resourceId;
  final int value;
  final int bumpToken;

  static const _tooltips = {
    'attack': 'Attack Energy — match red gems',
    'mana': 'Mana — match blue gems',
    'healing': 'Healing Energy — match green gems',
    'shield': 'Shield Energy — match yellow gems',
    'ultimate': 'Ultimate Energy — match purple gems',
  };

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: MythDuskColors.ink.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 27,
            height: 27,
            child: Image.asset(
              GameAssets.resourceIcon(resourceId),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: MythDuskColors.parchment,
                  ),
            ),
          ),
        ],
      ),
    );

    return Tooltip(
      message: _tooltips[resourceId] ?? resourceId,
      triggerMode: TooltipTriggerMode.longPress,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('bump-$resourceId-$bumpToken'),
        tween: Tween(begin: bumpToken == 0 ? 1.0 : 1.18, end: 1.0),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AnimatedOpacity(
          opacity: value == 0 ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: chip,
        ),
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.label, this.danger = false});

  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? MythDuskColors.ember : MythDuskColors.softGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MythDuskColors.deepTeal.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 12,
              color: accent,
            ),
      ),
    );
  }
}
