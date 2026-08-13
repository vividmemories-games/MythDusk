import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/opaque_character_art.dart';
import '../domain/battle_state.dart';
import '../domain/enemy_def.dart';

/// Chibi hero (left) + enemy (right). Name floats lightly; HP bar sits under
/// each sprite so top chrome never overlaps health.
class BattleStage extends StatelessWidget {
  const BattleStage({
    super.key,
    required this.battle,
  });

  final BattleState battle;

  /// Stage band for fighters (tall enough for crowns / horns without clipping).
  static const double stageHeight = 280;

  @override
  Widget build(BuildContext context) {
    final intent = battle.enemyIntent;
    final isBoss = battle.enemy.isBoss;
    final form = battle.bossForm;
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
              barColor: MythDuskColors.amber,
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
              barColor: MythDuskColors.ember,
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
  final double slotFill;

  @override
  Widget build(BuildContext context) {
    final isLeft = align == Alignment.bottomLeft;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final cross = isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    return LayoutBuilder(
      builder: (context, constraints) {
        final plateWidth = math.min(constraints.maxWidth, 168.0);
        return Column(
          crossAxisAlignment: cross,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                subtitle == null ? name : '$name · $subtitle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: isLeft ? TextAlign.left : TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 12,
                  color: MythDuskColors.parchment.withValues(alpha: 0.92),
                  shadows: const [
                    Shadow(
                      blurRadius: 6,
                      color: Color(0xCC0B1C22),
                    ),
                  ],
                ),
              ),
            ),
            if (threat != null) ...[
              _ThreatBadge(threat: threat!, pulsing: telegraphPulse),
              const SizedBox(height: 2),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, slot) {
                  final fill = slotFill.clamp(0.7, 1.0);
                  Widget sprite = OpaqueCharacterArt(
                    assetPath: assetPath,
                    fit: BoxFit.contain,
                    alignment: align,
                    borderRadius: 14,
                    showPlate: false,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 72,
                      color: MythDuskColors.muted,
                    ),
                  );

                  if (flash) {
                    final tint = castGlow
                        ? MythDuskColors.softGold.withValues(alpha: 0.45)
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
                                color: MythDuskColors.softGold
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
                                color: MythDuskColors.ember
                                    .withValues(alpha: 0.65),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );

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
                        final wave = math.sin(value * math.pi);
                        final dx = wave * (isLeft ? 22.0 : -22.0);
                        final scale = 1 + wave * 0.12;
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
                            math.sin(value * math.pi * 8) * (1 - value) * 14;
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
                        final wave = math.sin(value * math.pi);
                        final scale = 1 + wave * 0.09;
                        final glow = 0.25 + wave * 0.45;
                        return Transform.scale(
                          scale: scale,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: MythDuskColors.ember
                                      .withValues(alpha: glow),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: sprite,
                    );
                  }

                  return sprite;
                },
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: plateWidth,
              child: _HpBarUnder(
                hp: hp,
                maxHp: maxHp,
                barColor: barColor,
                flash: flash,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Compact HP bar under the fighter sprite.
class _HpBarUnder extends StatefulWidget {
  const _HpBarUnder({
    required this.hp,
    required this.maxHp,
    required this.barColor,
    required this.flash,
  });

  final int hp;
  final int maxHp;
  final Color barColor;
  final bool flash;

  @override
  State<_HpBarUnder> createState() => _HpBarUnderState();
}

class _HpBarUnderState extends State<_HpBarUnder> {
  late double _from;
  late double _to;

  double get _fraction =>
      widget.maxHp <= 0 ? 0.0 : (widget.hp / widget.maxHp).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _from = _fraction;
    _to = _fraction;
  }

  @override
  void didUpdateWidget(covariant _HpBarUnder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _fraction;
    if (next != _to) {
      _from = _to;
      _to = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${widget.hp}/${widget.maxHp}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: MythDuskColors.parchment.withValues(alpha: 0.9),
              shadows: const [
                Shadow(blurRadius: 4, color: Color(0xCC0B1C22)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            key: ValueKey(_to),
            tween: Tween(begin: _from, end: _to),
            duration: widget.flash
                ? BattleController.combatFxDuration
                : const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: MythDuskColors.ink.withValues(alpha: 0.55),
                color: widget.barColor,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThreatBadge extends StatelessWidget {
  const _ThreatBadge({required this.threat, required this.pulsing});

  final EnemySkill threat;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: pulsing ? 1 : 0.85,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: MythDuskColors.ember.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Next: ${threat.name}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: MythDuskColors.parchment,
              ),
        ),
      ),
    );
  }
}
