import 'package:flutter/material.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cosmetic_hero_art.dart';
import '../../../core/widgets/skill_art.dart';
import '../../../shared/widgets/challenge_art.dart';
import '../../heroes/domain/hero_def.dart';
import '../../prep/domain/prep_item.dart';
import '../../profile/providers/mock_profile_provider.dart';

class BriefingMetaLine extends StatelessWidget {
  const BriefingMetaLine(
      {super.key, required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: MythDuskColors.parchment))),
      ]);
}

class BriefingLoadout extends StatelessWidget {
  const BriefingLoadout(
      {super.key,
      required this.hero,
      required this.profile,
      required this.onEdit});
  final HeroDef hero;
  final PlayerProfile profile;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => ChallengePanel(
          child: Column(children: [
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text('Hero: ${hero.name}',
                  style: challengeTextStyle(18,
                      bold: true, color: MythDuskColors.softGold)),
              TextButton(
                  onPressed: onEdit,
                  child: Text('Edit loadout',
                      style: challengeTextStyle(13,
                          color: MythDuskColors.softGold))),
            ]),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: SizedBox(
                  height: 100,
                  child: CosmeticHeroArt(
                      heroId: hero.id,
                      assetPath: GameAssets.hero(hero.id),
                      profile: profile,
                      showPlate: false))),
          for (final skill in hero.skills)
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(children: [
                      SizedBox(
                          width: 54,
                          height: 54,
                          child: Stack(alignment: Alignment.center, children: [
                            Image.asset(ChallengeArtwork.path('panel_frame'),
                                fit: BoxFit.fill, excludeFromSemantics: true),
                            SkillArt(skill: skill),
                          ])),
                      const SizedBox(height: 5),
                      Text(skill.name,
                          textAlign: TextAlign.center,
                          style: challengeTextStyle(12)),
                      const SizedBox(height: 3),
                      Text('${skill.apCost} AP',
                          style: const TextStyle(
                              fontSize: 12, color: MythDuskColors.muted)),
                    ]))),
        ]),
      ]));
}

class BriefingPrepCard extends StatelessWidget {
  const BriefingPrepCard(
      {super.key,
      required this.id,
      required this.count,
      required this.selected,
      required this.blocked,
      required this.canSelect,
      required this.onTap});
  final PrepItemId id;
  final int count;
  final bool selected;
  final bool blocked;
  final bool canSelect;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        enabled: canSelect || selected,
        label:
            '${id.displayName}, ${blocked ? 'Already used today' : id.blurb}, Own $count',
        child: ExcludeSemantics(
            child: Opacity(
          opacity: canSelect || selected ? 1 : .6,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canSelect || selected ? onTap : null,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      boxShadow: selected
                          ? const [
                              BoxShadow(
                                  color: Color(0x665DCAC5), blurRadius: 10)
                            ]
                          : []),
                  child: ChallengePanel(
                      child: Column(children: [
                    Align(
                        alignment: Alignment.topRight,
                        child: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 18,
                            color: selected
                                ? MythDuskColors.softGold
                                : MythDuskColors.muted)),
                    Image.asset(id.assetPath,
                        height: 54, width: 54, fit: BoxFit.contain),
                    const SizedBox(height: 5),
                    Text(id.displayName,
                        textAlign: TextAlign.center,
                        style: challengeTextStyle(12, bold: true)),
                    const SizedBox(height: 5),
                    Text(blocked ? 'Already used today' : id.blurb,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: MythDuskColors.muted)),
                    const SizedBox(height: 6),
                    Text('Own $count',
                        style: challengeTextStyle(12,
                            color: MythDuskColors.softGold)),
                  ])),
                ),
              )),
        )),
      );
}
