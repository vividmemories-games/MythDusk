// Illustrated battle controls; gameplay affordability remains domain-owned.
import 'package:flutter/material.dart';
import 'package:mythdusk/core/assets/game_assets.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/core/widgets/skill_art.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';

import '../domain/battle_state.dart';
import '../domain/skill_affordability.dart';

enum _SkillVisualState { ready, unavailable, pressed, casting }

/// Color follows the illustration, never the resource payment color.
Color skillAccent(String id) => switch (id) {
      'fireball' || 'meteor_shard' => const Color(0xFFE99A51),
      'arcane_bolt' ||
      'shadow_strike' ||
      'shadow_bind' =>
        const Color(0xFFB49BDF),
      'frost_ward' ||
      'basic_slash' ||
      'dagger_flurry' =>
        const Color(0xFF9AC8E4),
      'rallying_cry' ||
      'natures_salve' ||
      'volley_rain' =>
        const Color(0xFF9FCB99),
      'arrow_shot' => const Color(0xFF91BCAE),
      'smoke_bomb' => const Color(0xFFB6ADC9),
      'mend' => const Color(0xFFE2A6A7),
      'holy_barrier' || 'sanctuary' => const Color(0xFFF0DBA5),
      _ => MythDuskColors.softGold,
    };

/// Skill-specific artwork and live costs, with presentation-only cast feedback.
class BattleSkillButton extends StatefulWidget {
  const BattleSkillButton(
      {super.key,
      required this.skill,
      required this.battle,
      required this.onTap});
  final SkillDef skill;
  final BattleState battle;
  final Future<void> Function() onTap;

  @override
  State<BattleSkillButton> createState() => _BattleSkillButtonState();
}

class _BattleSkillButtonState extends State<BattleSkillButton> {
  bool _pressed = false;
  bool _casting = false;

  Future<void> _cast() async {
    if (_casting ||
        widget.battle.inputLocked ||
        !SkillAffordability.evaluate(widget.skill, widget.battle).canCast) {
      return;
    }
    setState(() {
      _casting = true;
      _pressed = false;
    });
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _casting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final afford = SkillAffordability.evaluate(widget.skill, widget.battle);
    final canCast = afford.canCast && !widget.battle.inputLocked;
    final state = _casting
        ? _SkillVisualState.casting
        : !canCast
            ? _SkillVisualState.unavailable
            : _pressed
                ? _SkillVisualState.pressed
                : _SkillVisualState.ready;
    final unavailable = state == _SkillVisualState.unavailable;
    final casting = state == _SkillVisualState.casting;
    final pressed = state == _SkillVisualState.pressed;
    final accent = skillAccent(widget.skill.id);
    final label = switch (state) {
      _SkillVisualState.ready => 'Ready',
      _SkillVisualState.unavailable => switch (widget.battle.phase) {
          BattlePhase.resolving => 'Resolving…',
          BattlePhase.enemyTurn => 'Enemy turn',
          BattlePhase.victory => 'Victory',
          BattlePhase.defeat => 'Defeat',
          BattlePhase.playerTurn => widget.battle.inputLocked
              ? 'Resolving…'
              : afford.blockingReason ?? 'Unavailable',
        },
      _SkillVisualState.pressed => 'Release to cast',
      _SkillVisualState.casting => 'Casting…',
    };
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 140);
    final enabled = !unavailable && !casting;
    final compact = MediaQuery.sizeOf(context).height < 640 ||
        MediaQuery.textScalerOf(context).scale(14) > 18;
    final iconSize = compact ? 34.0 : 42.0;
    final titleSize = compact ? 11.0 : 12.0;
    final statusSize = compact ? 8.0 : 9.0;
    final pad = compact
        ? const EdgeInsets.fromLTRB(6, 5, 6, 5)
        : const EdgeInsets.fromLTRB(8, 7, 8, 7);
    return Semantics(
      button: true,
      enabled: enabled,
      label:
          '${widget.skill.name}. $label. AP ${afford.apHave} of ${afford.apNeed} required. '
          '${afford.resourceLines.map((line) => '${line.resourceId} ${line.have} of ${line.need} required').join(', ')}',
      onTap: enabled ? _cast : null,
      excludeSemantics: true,
      child: Tooltip(
          message: '${widget.skill.name}: $label',
          triggerMode: TooltipTriggerMode.longPress,
          child: AnimatedScale(
              scale: pressed ? .97 : 1,
              duration: duration,
              child: AnimatedContainer(
                duration: duration,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(
                            MythDuskColors.ink,
                            accent,
                            unavailable
                                ? .06
                                : pressed
                                    ? .27
                                    : .17)!,
                        MythDuskColors.ink,
                      ]),
                  border: Border.all(
                      width: casting ? 1.8 : 1,
                      color: unavailable
                          ? MythDuskColors.muted.withValues(alpha: .45)
                          : casting
                              ? accent
                              : MythDuskColors.amber.withValues(alpha: .85)),
                  boxShadow: unavailable
                      ? []
                      : [
                          BoxShadow(
                              color:
                                  accent.withValues(alpha: casting ? .3 : .08),
                              blurRadius: casting ? 16 : 8)
                        ],
                ),
                child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: enabled ? _cast : null,
                      onHighlightChanged: (value) {
                        if (mounted) setState(() => _pressed = value);
                      },
                      splashColor: accent.withValues(alpha: .2),
                      highlightColor: accent.withValues(alpha: .1),
                      child: Padding(
                          padding: pad,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Row(children: [
                              Container(
                                  width: iconSize,
                                  height: iconSize,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(colors: [
                                        accent.withValues(
                                            alpha: unavailable ? .08 : .25),
                                        accent.withValues(alpha: 0)
                                      ])),
                                  child: Opacity(
                                      opacity: unavailable ? .5 : 1,
                                      child: SkillArt(
                                          skill: widget.skill,
                                          size: iconSize))),
                              const SizedBox(width: 5),
                              Expanded(
                                  child: Text(widget.skill.name,
                                      maxLines: compact ? 1 : 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontFamily: 'DailySerif',
                                          fontSize: titleSize,
                                          height: 1.2,
                                          color: unavailable
                                              ? MythDuskColors.parchment
                                              : MythDuskColors.softGold))),
                            ]),
                            SizedBox(height: compact ? 3 : 5),
                            Container(
                                height: 1,
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                  accent.withValues(alpha: 0),
                                  accent.withValues(alpha: .45),
                                  accent.withValues(alpha: 0)
                                ]))),
                            SizedBox(height: compact ? 4 : 7),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                    spacing: 7,
                                    runSpacing: 2,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      for (final line in afford.resourceLines)
                                        _SkillCost(
                                            asset: GameAssets.resourceIcon(
                                                line.resourceId),
                                            label: line.label,
                                            name: line.resourceId,
                                            missing: !line.ok),
                                      _SkillCost(
                                          asset: GameAssets.iconAp,
                                          label:
                                              '${afford.apHave}/${afford.apNeed}',
                                          name: 'AP',
                                          missing: !afford.apOk),
                                    ])),
                            SizedBox(height: compact ? 4 : 7),
                            Row(children: [
                              Icon(
                                  unavailable
                                      ? Icons.lock_outline
                                      : casting
                                          ? Icons.auto_awesome
                                          : Icons.diamond_outlined,
                                  size: 10,
                                  color: unavailable
                                      ? MythDuskColors.muted
                                      : accent),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(label,
                                      maxLines: compact ? 1 : 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontFamily: 'DailySerif',
                                          fontSize: statusSize,
                                          height: 1.15,
                                          color: unavailable
                                              ? MythDuskColors.muted
                                              : accent))),
                              if (casting)
                                Icon(Icons.bolt, size: 12, color: accent),
                            ]),
                          ])),
                    )),
              ))),
    );
  }
}

class _SkillCost extends StatelessWidget {
  const _SkillCost(
      {required this.asset,
      required this.label,
      required this.name,
      this.missing = false});
  final String asset;
  final String label;
  final String name;
  final bool missing;
  @override
  Widget build(BuildContext context) => Tooltip(
      message: '$name: $label',
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(asset, width: 13, height: 13, excludeFromSemantics: true),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontFamily: 'DailySerif',
                fontSize: 11,
                color: missing
                    ? const Color(0xFFF0AD91)
                    : MythDuskColors.parchment)),
      ]));
}
