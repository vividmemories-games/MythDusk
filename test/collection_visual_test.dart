import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../tool/hub_preview.dart';

void main() {
  for (final screen in ['heroes', 'shop', 'profile']) {
    for (final fixture in [
      (const Size(440, 956), 1.0, 'pro-max'),
      (const Size(320, 568), 2.0, 'large-text'),
    ]) {
      testWidgets('$screen ${fixture.$3} layout and back navigation',
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
            screen: screen,
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
        expect(tester.takeException(), isNull);
        await expectLater(find.byKey(const Key('hub-capture')),
            matchesGoldenFile('goldens/$screen-${fixture.$3}.png'));
        if (screen == 'heroes') {
          await tester.scrollUntilVisible(find.text('Bulwark Slam'), 200,
              scrollable: find.byType(Scrollable).first);
        } else if (screen == 'shop') {
          await tester.scrollUntilVisible(find.text('Celebration bundles'), 200,
              scrollable: find.byType(Scrollable).first);
          expect(find.textContaining('SKU'), findsNothing);
          expect(find.text('Battle pass'), findsNothing);
        } else {
          await tester.scrollUntilVisible(find.text('Settings'), 200,
              scrollable: find.byType(Scrollable).first);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.text('MYTHDUSK'), findsOneWidget);
      });
    }
  }
}
