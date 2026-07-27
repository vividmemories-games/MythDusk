import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/battle_state.dart';
import '../domain/enemy_def.dart';

/// Chibi hero (left) + enemy (right) with HP plates floating on the sprites
/// and the enemy threat shown as a badge instead of a full-width caption.
class BattleStage extends StatelessWidget {
  const BattleStage({
    super.key,
    required this.battle,
  });

  final BattleState battle;

  /// Stage band for fighters (tall enough for crowns / horns without clipping).
  static const double stageHeight = 300;

  @override
  Widget build(BuildContext context) {
    // Telegraphed action for the next enemy turn (rolled at turn start).
    final intent = battle.enemyIntent;
    final isBoss = battle.enemy.isBoss;
    final form = battle.bossForm;
    // Fraction of the sprite slot to fill (BoxFit.contain — never crops).
    // Bosses fill more of the slot so they read bigger than trash.
    final enemyFill = !isBoss
        ? 0.88
        : (form != null && form >= 4)
            ? 1.0
            : 0.96;

    return SizedBox(
      height: stageHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _FighterSlot(
              assetPath: GameAssets.hero(battle.hero.id),
              name: battle.hero.name,
              subtitle: battle.shield > 0 ? 'shield ${battle.shield}' : null,
              hp: battle.heroHp,
              maxHp: battle.hero.maxHp,
              barColor: MythoraColors.amber,
              flash: battle.combatFx == CombatFx.heroHit ||
                  battle.combatFx == CombatFx.heroCast,
              shake: battle.combatFx == CombatFx.heroHit,
              showHitFx: battle.combatFx == CombatFx.heroHit,
              align: Alignment.bottomLeft,
              slotFill: 0.92,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FighterSlot(
              assetPath: GameAssets.enemy(
                battle.enemy.id,
                bossForm: battle.bossForm,
              ),
              name: battle.enemy.name,
              hp: battle.enemyHp,
              maxHp: battle.enemy.maxHp,
              barColor: MythoraColors.ember,
              flash: battle.combatFx == CombatFx.enemyHit,
              shake: battle.combatFx == CombatFx.enemyHit,
              showHitFx: battle.combatFx == CombatFx.enemyHit,
              align: Alignment.bottomRight,
              threat: intent,
              slotFill: enemyFill,
            ),
          ),
        ],
      ),
    );
  }
}

class _FighterSlot extends StatelessWidget {
  const _FighterSlot({
    required this.assetPath,
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.barColor,
    required this.align,
    this.subtitle,
    this.flash = false,
    this.shake = false,
    this.showHitFx = false,
    this.threat,
    this.slotFill = 1.0,
  });

  final String assetPath;
  final String name;
  final String? subtitle;
  final int hp;
  final int maxHp;
  final Color barColor;
  final Alignment align;
  final bool flash;
  final bool shake;
  final bool showHitFx;
  final EnemySkill? threat;

  /// How much of the sprite band to use (0–1). Bosses higher than trash.
  final double slotFill;

  @override
  Widget build(BuildContext context) {
    final isLeft = align == Alignment.bottomLeft;

    // Plate above the character's head; sprite band below never overlaps it.
    return LayoutBuilder(
      builder: (context, constraints) {
        final plateWidth = math.min(constraints.maxWidth, 168.0);
        return Column(
          crossAxisAlignment:
              isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: plateWidth,
                  child: _HpPlate(
                    name: subtitle == null ? name : '$name · $subtitle',
                    hp: hp,
                    maxHp: maxHp,
                    barColor: barColor,
                    flash: flash,
                  ),
                ),
                if (threat != null) ...[
                  const SizedBox(height: 3),
                  _ThreatBadge(threat: threat!),
                ],
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, slot) {
                  final fill = slotFill.clamp(0.7, 1.0);
                  Widget sprite = Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    alignment: align,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 72,
                      color: MythoraColors.muted,
                    ),
                  );

                  if (flash) {
                    sprite = ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        barColor.withValues(alpha: 0.35),
                        BlendMode.srcATop,
                      ),
                      child: sprite,
                    );
                  }

                  sprite = Stack(
                    fit: StackFit.expand,
                    children: [
                      sprite,
                      if (showHitFx)
                        IgnorePointer(
                          child: Image.asset(
                            GameAssets.fxHit,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                    ],
                  );

                  // Size within the slot — no Transform.scale, so crowns/horns
                  // stay fully visible and never paint over the HP plate.
                  sprite = Align(
                    alignment: align,
                    child: SizedBox(
                      width: slot.maxWidth,
                      height: slot.maxHeight * fill,
                      child: sprite,
                    ),
                  );

                  if (shake) {
                    sprite = TweenAnimationBuilder<double>(
                      key: ValueKey('shake-$name-$hp-$flash'),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 320),
                      builder: (context, value, child) {
                        final dx =
                            math.sin(value * math.pi * 6) * (1 - value) * 8;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: sprite,
                    );
                  }

                  return sprite;
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Translucent name + HP bar plate floating over the sprite's head.
class _HpPlate extends StatelessWidget {
  const _HpPlate({
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.barColor,
    required this.flash,
  });

  final String name;
  final int hp;
  final int maxHp;
  final Color barColor;
  final bool flash;

  @override
  Widget build(BuildContext context) {
    final t = (hp / maxHp).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
      decoration: BoxDecoration(
        color: MythoraColors.ink.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$hp/$maxHp',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 10, height: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              key: ValueKey('hp-$name-$hp-$maxHp'),
              tween: Tween(begin: 0, end: t),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: MythoraColors.mist,
                  color: flash ? MythoraColors.parchment : barColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact enemy-intent badge; tap for the skill name and full text.
class _ThreatBadge extends StatelessWidget {
  const _ThreatBadge({required this.threat});

  final EnemySkill threat;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Next: ${threat.name} — ${threat.damage} damage',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: MythoraColors.ink.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MythoraColors.ember.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 12,
              color: MythoraColors.ember,
            ),
            const SizedBox(width: 3),
            Text(
              '${threat.damage}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 11,
                    color: MythoraColors.parchment,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
