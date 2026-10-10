import 'package:flutter/material.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/opaque_character_art.dart';
import '../../../shared/widgets/challenge_art.dart';
import '../../../shared/widgets/relic_frame.dart';

/// Featured entry into the existing duel mode; all labels remain live text.
class HubArenaTile extends StatelessWidget {
  const HubArenaTile({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
    return Semantics(
      button: true,
      label: '1v1 Arena, Enter Arena',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: largeText ? 140 : 108,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(GameAssets.arenaBackground,
                      fit: BoxFit.cover, excludeFromSemantics: true),
                  const DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                    Color(0x55071118),
                    Color(0xBB170E18),
                    Color(0x55071118)
                  ]))),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                          width: 100,
                          child: OpaqueCharacterArt(
                              assetPath: GameAssets.hero('knight'),
                              showPlate: false))),
                  Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                          width: 100,
                          child: Transform.flip(
                              flipX: true,
                              child: OpaqueCharacterArt(
                                  assetPath: GameAssets.hero('ninja'),
                                  showPlate: false)))),
                  const RelicFrame(),
                  Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.sports_martial_arts,
                        color: MythDuskColors.softGold, size: 24),
                    Text('1v1 Arena',
                        style: challengeTextStyle(21, bold: true)),
                    const SizedBox(height: 4),
                    Text('Enter Arena ›',
                        style: challengeTextStyle(14,
                            color: MythDuskColors.softGold)),
                  ])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
