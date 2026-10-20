// Review-only prototype. No production battle screens import this file.
import 'package:flutter/material.dart';
import 'package:mythdusk/core/assets/game_assets.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/core/widgets/skill_art.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/battle/presentation/battle_skill_button.dart'
    show skillAccent;

enum SkillPreviewState { ready, unavailable, pressed, casting }

/// Illustrative states and example costs; this prototype cannot cast a skill.
class SkillButtonConcept extends StatefulWidget {
  const SkillButtonConcept(
      {super.key,
      required this.skill,
      this.visualState = SkillPreviewState.ready,
      this.onTap});
  final SkillDef skill;
  final SkillPreviewState visualState;
  final VoidCallback? onTap;

  @override
  State<SkillButtonConcept> createState() => _SkillButtonConceptState();
}

class _SkillButtonConceptState extends State<SkillButtonConcept> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final state = _pressed ? SkillPreviewState.pressed : widget.visualState;
    final unavailable = state == SkillPreviewState.unavailable;
    final casting = state == SkillPreviewState.casting;
    final pressed = state == SkillPreviewState.pressed;
    final accent = skillAccent(widget.skill.id);
    final label = switch (state) {
      SkillPreviewState.ready => 'Ready',
      SkillPreviewState.unavailable => 'Need 1 more AP',
      SkillPreviewState.pressed => 'Release to cast',
      SkillPreviewState.casting => 'Casting…',
    };
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 140);
    final enabled = !unavailable && !casting;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${widget.skill.name}. $label. ${widget.skill.apCost} AP. '
          '${widget.skill.resourceCosts.entries.map((e) => '${e.value} ${e.key}').join(', ')}',
      excludeSemantics: true,
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
                          color: accent.withValues(alpha: casting ? .3 : .08),
                          blurRadius: casting ? 16 : 8)
                    ],
            ),
            child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: enabled ? widget.onTap : null,
                  onHighlightChanged: (value) {
                    if (mounted) setState(() => _pressed = value);
                  },
                  splashColor: accent.withValues(alpha: .2),
                  highlightColor: accent.withValues(alpha: .1),
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [
                                    accent.withValues(
                                        alpha: unavailable ? .08 : .25),
                                    accent.withValues(alpha: 0)
                                  ])),
                              child: Opacity(
                                  opacity: unavailable ? .5 : 1,
                                  child:
                                      SkillArt(skill: widget.skill, size: 42))),
                          const SizedBox(width: 5),
                          Expanded(
                              child: Text(widget.skill.name,
                                  maxLines: 2,
                                  style: TextStyle(
                                      fontFamily: 'DailySerif',
                                      fontSize: 12,
                                      height: 1.25,
                                      color: unavailable
                                          ? MythDuskColors.parchment
                                          : MythDuskColors.softGold))),
                        ]),
                        const SizedBox(height: 5),
                        Container(
                            height: 1,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                              accent.withValues(alpha: 0),
                              accent.withValues(alpha: .45),
                              accent.withValues(alpha: 0)
                            ]))),
                        const SizedBox(height: 7),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                                spacing: 7,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  for (final cost
                                      in widget.skill.resourceCosts.entries)
                                    _PreviewCost(
                                        asset:
                                            GameAssets.resourceIcon(cost.key),
                                        label: '${cost.value}',
                                        name: cost.key),
                                  _PreviewCost(
                                      asset: GameAssets.iconAp,
                                      label: unavailable
                                          ? '${widget.skill.apCost - 1}/${widget.skill.apCost}'
                                          : '${widget.skill.apCost}',
                                      name: 'AP',
                                      missing: unavailable),
                                ])),
                        const SizedBox(height: 7),
                        Row(children: [
                          Icon(
                              unavailable
                                  ? Icons.lock_outline
                                  : casting
                                      ? Icons.auto_awesome
                                      : Icons.diamond_outlined,
                              size: 10,
                              color:
                                  unavailable ? MythDuskColors.muted : accent),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(label,
                                  style: TextStyle(
                                      fontFamily: 'DailySerif',
                                      fontSize: 9,
                                      height: 1.2,
                                      color: unavailable
                                          ? MythDuskColors.muted
                                          : accent))),
                          if (casting)
                            Icon(Icons.bolt, size: 12, color: accent),
                        ]),
                      ])),
                )),
          )),
    );
  }
}

class _PreviewCost extends StatelessWidget {
  const _PreviewCost(
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

class SkillButtonPreview extends StatefulWidget {
  const SkillButtonPreview({super.key, this.statesOnly = false});
  final bool statesOnly;
  @override
  State<SkillButtonPreview> createState() => _SkillButtonPreviewState();
}

class _SkillButtonPreviewState extends State<SkillButtonPreview> {
  String _selected = 'fireball';
  int _castToken = 0;
  String? _castingSkill;

  Future<void> _cast(String skillId) async {
    final token = ++_castToken;
    setState(() => _castingSkill = skillId);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted && token == _castToken) setState(() => _castingSkill = null);
  }

  @override
  Widget build(BuildContext context) {
    final allSkills = HeroCatalog.all.expand((hero) => hero.skills).toList();
    final selected = allSkills.firstWhere((skill) => skill.id == _selected);
    return Scaffold(
        backgroundColor: MythDuskColors.ink,
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MythDusk',
                          style: TextStyle(
                              fontFamily: 'DailySerif',
                              fontSize: 27,
                              color: MythDuskColors.softGold)),
                      const SizedBox(height: 6),
                      Text(
                          widget.statesOnly
                              ? 'Ability states · design preview'
                              : 'Battle abilities · all 20 skills',
                          style: const TextStyle(
                              fontFamily: 'DailySerif',
                              fontSize: 16,
                              color: MythDuskColors.parchment)),
                      const SizedBox(height: 8),
                      const Text(
                          'Illustrative states and costs · tap a ready ability to preview its cast response',
                          style: TextStyle(
                              fontFamily: 'DailySerif',
                              fontSize: 11,
                              color: MythDuskColors.muted)),
                      const SizedBox(height: 20),
                      if (!widget.statesOnly)
                        for (final hero in HeroCatalog.all) ...[
                          Text(hero.name,
                              style: const TextStyle(
                                  fontFamily: 'DailySerif',
                                  fontSize: 18,
                                  color: MythDuskColors.softGold)),
                          const SizedBox(height: 10),
                          LayoutBuilder(builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 760 ? 4 : 2;
                            final width =
                                (constraints.maxWidth - (columns - 1) * 12) /
                                    columns;
                            return Wrap(spacing: 12, runSpacing: 12, children: [
                              for (final skill in hero.skills)
                                SizedBox(
                                    width: width,
                                    child: SkillButtonConcept(
                                        skill: skill,
                                        visualState: _castingSkill == skill.id
                                            ? SkillPreviewState.casting
                                            : SkillPreviewState.ready,
                                        onTap: () => _cast(skill.id))),
                            ]);
                          }),
                          const SizedBox(height: 22),
                        ],
                      if (widget.statesOnly) ...[
                        DropdownButton<String>(
                            value: _selected,
                            dropdownColor: MythDuskColors.deepTeal,
                            style: const TextStyle(
                                fontFamily: 'DailySerif',
                                color: MythDuskColors.parchment),
                            items: [
                              for (final skill in allSkills)
                                DropdownMenuItem(
                                    value: skill.id, child: Text(skill.name))
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selected = value);
                              }
                            }),
                        const SizedBox(height: 16),
                        LayoutBuilder(builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 760 ? 4 : 2;
                          final width =
                              (constraints.maxWidth - (columns - 1) * 12) /
                                  columns;
                          return Wrap(spacing: 12, runSpacing: 12, children: [
                            for (final state in SkillPreviewState.values)
                              SizedBox(
                                  width: width,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(state.name.toUpperCase(),
                                            style: const TextStyle(
                                                fontFamily: 'DailySerif',
                                                fontSize: 10,
                                                color: MythDuskColors.muted)),
                                        const SizedBox(height: 10),
                                        SkillButtonConcept(
                                            skill: selected,
                                            visualState: state ==
                                                        SkillPreviewState
                                                            .ready &&
                                                    _castingSkill == selected.id
                                                ? SkillPreviewState.casting
                                                : state,
                                            onTap: () => _cast(selected.id)),
                                      ])),
                          ]);
                        }),
                      ],
                    ]))));
  }
}

void main() => runApp(MaterialApp(
    theme: AppTheme.dusk,
    debugShowCheckedModeBanner: false,
    home: const SkillButtonPreview(
        statesOnly: bool.fromEnvironment('SKILL_STATES'))));
