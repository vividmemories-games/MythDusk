import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../tool/hub_preview.dart';

void main() {
  for (final fixture in [
    (const Size(440, 956), 1.0, 'pro-max'),
    (const Size(320, 568), 2.0, 'large-text'),
  ]) {
    testWidgets('Realms ${fixture.$3} remains scrollable and readable',
        (tester) async {
      final font = FontLoader('DailySerif')
        ..addFont(rootBundle.load('assets/fonts/LibreBaskerville.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      await tester.binding.setSurfaceSize(fixture.$1);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = await tester
          .runAsync(() => hubPreview(realms: true, textScale: fixture.$2));
      await tester.pumpWidget(app!);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byKey(const Key('hub-capture')));
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(image.image, context);
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('Realms of MythDusk'), findsOneWidget);
      expect(find.text('Ember Path'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(find.byKey(const Key('hub-capture')),
          matchesGoldenFile('goldens/realms-${fixture.$3}.png'));
      await tester.scrollUntilVisible(find.text('Chapter Medals'), 180,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chapter Medals'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ember Path'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Mistfen Marshes'), 180,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mistfen Marshes'));
      await tester.pumpAndSettle();
      expect(find.text('Realms of MythDusk'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Explore Realm'), -180,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore Realm'));
      await tester.pumpAndSettle();
      expect(find.text('/campaign preview route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
