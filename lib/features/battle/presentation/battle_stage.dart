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

    final casting = battle.combatFx == CombatFx.heroCast;
    final heroHit = battle.combatFx == CombatFx.heroHit;
    final enemyHit = battle.combatFx == CombatFx.enemyHit;
    final telegraphed = battle.phase == BattlePhase.enemyTurn;

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
              flash: heroHit || casting,
              castGlow: casting,
              shake: heroHit,
              showHitFx: heroHit,
              lungeTowardEnemy: casting,
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
              flash: enemyHit,
              shake: enemyHit,
              showHitFx: enemyHit,
              enraged: battle.enraged,
              telegraphPulse: telegraphed,
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
    this.castGlow = false,
    this.shake = false,
    this.showHitFx = false,
    this.lungeTowardEnemy = false,
    this.enraged = false,
    this.telegraphPulse = false,
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
  final bool castGlow;
  final bool shake;
  final bool showHitFx;
  final bool lungeTowardEnemy;
  final bool enraged;
  final bool telegraphPulse;
  final EnemySkill? threat;

  /// How much of the sprite band to use (0–1). Bosses higher than trash.
  final double slotFill;

  @override
  Widget build(BuildContext context) {
    final isLeft = align == Alignment.bottomLeft;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

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
                  _ThreatBadge(
                    threat: threat!,
                    pulsing: telegraphPulse,
                  ),
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
                    final tint = castGlow
                        ? MythoraColors.softGold.withValues(alpha: 0.45)
                        : barColor.withValues(alpha: 0.35);
                    sprite = ColorFiltered(
                      colorFilter: ColorFilter.mode(tint, BlendMode.srcATop),
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
                      if (castGlow)
                        IgnorePointer(
                          child: Image.asset(
                            GameAssets.fxSpecialCreate,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Align(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.auto_awesome,
                                size: 36,
                                color: MythoraColors.softGold
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ),
                      if (enraged)
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    MythoraColors.ember.withValues(alpha: 0.65),
                                width: 2,
                              ),
                            ),
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

                  if (lungeTowardEnemy && !reduceMotion) {
                    sprite = TweenAnimationBuilder<double>(
                      key: ValueKey('cast-$name-$hp'),
                      tween: Tween(begin: 0, end: 1),
                      duration: BattleController.castFxDuration,
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        final dx =
                            math.sin(value * math.pi) * (isLeft ? 14.0 : -14.0);
                        final scale = 1 + math.sin(value * math.pi) * 0.06;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: Transform.scale(scale: scale, child: child),
                        );
                      },
                      child: sprite,
                    );
                  }

                  if (shake && !reduceMotion) {
                    sprite = TweenAnimationBuilder<double>(
                      key: ValueKey('shake-$name-$hp-$flash'),
                      tween: Tween(begin: 0, end: 1),
                      duration: BattleController.combatFxDuration,
                      builder: (context, value, child) {
                        final dx =
                            math.sin(value * math.pi * 6) * (1 - value) * 10;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: sprite,
                    );
                  }

                  if (telegraphPulse && !reduceMotion) {
                    sprite = TweenAnimationBuilder<double>(
                      key: ValueKey('telegraph-$name'),
                      tween: Tween(begin: 0, end: 1),
                      duration: BattleController.enemyTelegraph,
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        final scale = 1 + math.sin(value * math.pi) * 0.04;
                        return Transform.scale(scale: scale, child: child);
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
  const _ThreatBadge({
    required this.threat,
    this.pulsing = false,
  });

  final EnemySkill threat;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MythoraColors.ink.withValues(alpha: pulsing ? 0.85 : 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: MythoraColors.ember.withValues(alpha: pulsing ? 0.95 : 0.55),
          width: pulsing ? 2 : 1,
        ),
        boxShadow: pulsing
            ? [
                BoxShadow(
                  color: MythoraColors.ember.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, size: 14, color: MythoraColors.ember),
          const SizedBox(width: 4),
          Text(
            threat.damage > 0 ? '${threat.damage}' : '!',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: MythoraColors.ember,
            ),
          ),
        ],
      ),
    );

    if (pulsing && !MediaQuery.disableAnimationsOf(context)) {
      badge = TweenAnimationBuilder<double>(
        key: ValueKey('threat-pulse-${threat.id}'),
        tween: Tween(begin: 0.92, end: 1.08),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: badge,
      );
    }

    return Tooltip(
      message: 'Next: ${threat.intentLabel}',
      triggerMode: TooltipTriggerMode.tap,
      child: badge,
    );
  }
}
