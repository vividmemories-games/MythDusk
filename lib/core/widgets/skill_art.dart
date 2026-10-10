import 'package:flutter/material.dart';

import '../../features/heroes/domain/hero_def.dart';
import '../assets/skill_artwork.dart';
import '../theme/app_theme.dart';

/// Reusable decorative skill art. The surrounding control supplies its label.
class SkillArt extends StatelessWidget {
  const SkillArt({super.key, required this.skill, this.size = 54});
  final SkillDef skill;
  final double size;

  @override
  Widget build(BuildContext context) {
    final artwork = SkillArtwork.forSkill(skill.id);
    final fallback = Icon(
      skill.shield > 0
          ? Icons.shield
          : skill.heal > 0
              ? Icons.favorite
              : Icons.bolt,
      size: size * .6,
      color: MythDuskColors.softGold,
    );
    if (artwork == null) {
      return ExcludeSemantics(
          child: SizedBox(width: size, height: size, child: fallback));
    }
    final alignment =
        Alignment(artwork.column == 0 ? -1 : 1, artwork.row == 0 ? -1 : 1);
    return ExcludeSemantics(
        child: SizedBox(
      width: size,
      height: size,
      child: ClipRect(
          child: OverflowBox(
        minWidth: size * 2,
        maxWidth: size * 2,
        minHeight: size * 2,
        maxHeight: size * 2,
        alignment: alignment,
        child: Image.asset(
          artwork.assetPath,
          width: size * 2,
          height: size * 2,
          fit: BoxFit.fill,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => Align(
              alignment: alignment,
              child: SizedBox(width: size, height: size, child: fallback)),
        ),
      )),
    ));
  }
}
