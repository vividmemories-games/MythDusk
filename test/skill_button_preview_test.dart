import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/assets/skill_artwork.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';

import '../tool/skill_button_preview.dart';

Future<void> _artReady(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final path
        in SkillArtwork.bySkillId.values.map((art) => art.assetPath).toSet()) {
      await precacheImage(AssetImage(path), context);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> _savePreview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('EXPORT_SKILL_PREVIEWS')) return;
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(find.byKey(const Key('capture')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('art_sources/ui/battle_skills/v1/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    final font = FontLoader('DailySerif')
      ..addFont(rootBundle.load('assets/fonts/LibreBaskerville.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets(
      'all twenty illustrated skill buttons render including mastery skills',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1040, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dusk,
        debugShowCheckedModeBanner: false,
        home: const RepaintBoundary(
            key: Key('capture'), child: SkillButtonPreview())));
    await _artReady(tester);
    expect(find.byType(SkillButtonConcept), findsNWidgets(20));
    for (final hero in HeroCatalog.all) {
      for (final skill in hero.skills) {
        expect(find.text(skill.name), findsOneWidget);
      }
    }
    expect(tester.takeException(), isNull);
    await _savePreview(tester, 'all-20-skills');
  });

  testWidgets('state comparisons render and ready button responds to a tap',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1040, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dusk,
        debugShowCheckedModeBanner: false,
        home: const RepaintBoundary(
            key: Key('capture'), child: SkillButtonPreview(statesOnly: true))));
    await _artReady(tester);
    expect(find.byType(SkillButtonConcept), findsNWidgets(4));
    expect(find.text('Need 1 more AP'), findsOneWidget);
    expect(find.text('Release to cast'), findsOneWidget);
    expect(find.text('Casting…'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _savePreview(tester, 'interaction-states');
    await tester.tap(find.byType(SkillButtonConcept).first);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Casting…'), findsNWidgets(2));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('unavailable and casting buttons cannot activate',
      (tester) async {
    var taps = 0;
    for (final state in SkillPreviewState.values) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Center(
                  child: SizedBox(
                      width: 180,
                      child: SkillButtonConcept(
                          skill: HeroCatalog.mage.skills.first,
                          visualState: state,
                          onTap: () => taps++))))));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SkillButtonConcept));
      await tester.pumpAndSettle();
    }
    expect(taps, 2);
  });

  testWidgets(
      'two mastery buttons fit a compact dock at normal and enlarged text',
      (tester) async {
    for (final scale in [1.0, 2.0]) {
      await tester.binding.setSurfaceSize(const Size(320, 460));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dusk,
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
              key: const Key('capture'),
              child: Scaffold(
                  body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: SkillButtonConcept(
                                  skill: HeroCatalog.mage.skills.last)),
                          const SizedBox(width: 6),
                          Expanded(
                              child: SkillButtonConcept(
                                  skill: HeroCatalog.knight.skills.last)),
                          const SizedBox(width: 6),
                          const SizedBox(
                              width: 42,
                              child: Padding(
                                  padding: EdgeInsets.only(top: 30),
                                  child: Text('End\nturn',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontFamily: 'DailySerif',
                                          color: MythDuskColors.softGold,
                                          fontSize: 11)))),
                        ])),
              )))));
      await _artReady(tester);
      expect(tester.takeException(), isNull, reason: 'text scale $scale');
      if (scale == 1) await _savePreview(tester, 'compact-mastery-dock');
    }
  });
}
