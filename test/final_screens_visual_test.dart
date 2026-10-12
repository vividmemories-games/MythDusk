import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:mythdusk/features/profile/presentation/settings_screen.dart';
import '../tool/hub_preview.dart';

void main() {
  for (final screen in [
    'settings',
    'challenge',
    'expedition',
    'victory',
    'defeat',
    'more'
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$screen at $scale text scale', (tester) async {
        final font = FontLoader('DailySerif')
          ..addFont(rootBundle.load('assets/fonts/LibreBaskerville.ttf'));
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
        await tester.binding.setSurfaceSize(
            scale == 1 ? const Size(440, 956) : const Size(320, 568));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final app = await tester.runAsync(() => hubPreview(
            screen: screen == 'more' ? '' : screen, textScale: scale));
        await tester.pumpWidget(app!);
        await tester.pumpAndSettle();
        if (screen == 'more') {
          await tester.tap(find.text('More'));
          await tester.pumpAndSettle();
          expect(find.text('Settings'), findsOneWidget);
        }
        await tester.runAsync(() async {
          final context = tester.element(find.byKey(const Key('hub-capture')));
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(image.image, context);
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(find.byKey(const Key('hub-capture')),
            matchesGoldenFile('goldens/$screen-final-$scale.png'));
        if (screen == 'settings') {
          final container = ProviderScope.containerOf(
              tester.element(find.byType(SettingsScreen)));
          final before = container.read(profileProvider).hintsEnabled;
          await tester.scrollUntilVisible(find.text('Match hints'), 180,
              scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Match hints'));
          await tester.pumpAndSettle();
          expect(container.read(profileProvider).hintsEnabled, !before);
        }
        if (screen == 'challenge') {
          await tester.scrollUntilVisible(find.text('Create challenge'), 150,
              scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Create challenge'));
          await tester.pumpAndSettle();
          expect(find.textContaining('Code:'), findsOneWidget);
        }
        if (screen == 'victory' || screen == 'defeat') {
          await tester.scrollUntilVisible(find.text('Home'), 180,
              scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
          expect(find.text('Home').hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
