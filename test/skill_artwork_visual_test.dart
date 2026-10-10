import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/assets/skill_artwork.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/core/widgets/skill_art.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/shared/widgets/challenge_art.dart';

void main() {
  testWidgets('All twenty skill icons render in their own atlas cells',
      (tester) async {
    final font = FontLoader('DailySerif')
      ..addFont(rootBundle.load('assets/fonts/LibreBaskerville.ttf'));
    await font.load();
    await tester.binding.setSurfaceSize(const Size(640, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dusk,
      home: RepaintBoundary(
          key: const Key('skill-roster'),
          child: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('MythDusk · Ability artwork',
                        style: challengeTextStyle(22, bold: true)),
                    const SizedBox(height: 12),
                    for (final hero in HeroCatalog.all)
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hero.name,
                              style: challengeTextStyle(16,
                                  color: MythDuskColors.softGold)),
                          const SizedBox(height: 8),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final skill in hero.skills)
                                  Expanded(
                                      child: Column(children: [
                                    SkillArt(skill: skill, size: 76),
                                    const SizedBox(height: 4),
                                    Text(skill.name,
                                        textAlign: TextAlign.center,
                                        style: challengeTextStyle(12)),
                                  ])),
                              ]),
                        ],
                      )),
                  ],
                )),
          )),
    ));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byKey(const Key('skill-roster')));
      for (final asset in SkillArtwork.bySkillId.values
          .map((art) => art.assetPath)
          .toSet()) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    expect(find.byType(SkillArt), findsNWidgets(20));
    expect(tester.takeException(), isNull);
    await expectLater(find.byKey(const Key('skill-roster')),
        matchesGoldenFile('goldens/skill-artwork-roster.png'));
  });
}
