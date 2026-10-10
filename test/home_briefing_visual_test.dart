import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../tool/hub_preview.dart';

void main() {
  for (final briefing in [false, true]) {
    for (final fixture in [
      (const Size(440, 956), 1.0, 'pro-max'),
      (const Size(360, 640), 1.0, 'compact'),
      (const Size(320, 568), 2.0, 'large-text')
    ]) {
      final name = '${briefing ? 'briefing' : 'home'}-${fixture.$3}';
      testWidgets('$name renders and keeps primary action usable',
          (tester) async {
        final font = FontLoader('DailySerif')
          ..addFont(rootBundle.load('assets/fonts/LibreBaskerville.ttf'));
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
        await tester.binding.setSurfaceSize(fixture.$1);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final app = await tester.runAsync(() => hubPreview(
            briefing: briefing,
            textScale: fixture.$2,
            safePadding: fixture.$3 == 'pro-max'
                ? const EdgeInsets.only(top: 62, bottom: 34)
                : EdgeInsets.zero));
        await tester.pumpWidget(app!);
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final context = tester.element(find.byKey(const Key('hub-capture')));
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(image.image, context);
          }
        });
        await tester.pumpAndSettle();
        if (briefing) {
          expect(find.text('Battle').hitTestable(), findsOneWidget);
          expect(find.text('Bog Shaman'), findsOneWidget);
          expect(find.text('Shaman Bog'), findsNothing);
          expect(find.text('Board'), findsNothing);
          if (fixture.$3 == 'pro-max') {
            for (final label in [
              'Vanguard Tonic',
              'Aegis Flask',
              'Second Wind'
            ]) {
              expect(find.text(label).hitTestable(), findsOneWidget);
            }
          }
        } else {
          expect(find.text('Prep'), findsNothing);
          if (fixture.$3 != 'large-text') {
            expect(find.text('Continue Journey').hitTestable(), findsOneWidget);
            expect(find.text('Enter Arena ›').hitTestable(), findsOneWidget);
          }
          if (fixture.$3 == 'pro-max') {
            expect(find.text('Daily').hitTestable(), findsOneWidget);
            expect(find.text('Weekly').hitTestable(), findsOneWidget);
          }
        }
        expect(tester.takeException(), isNull);
        await expectLater(find.byKey(const Key('hub-capture')),
            matchesGoldenFile('goldens/$name.png'));
      });
    }
  }
}
