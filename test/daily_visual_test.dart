import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/daily/presentation/daily_screen.dart';
import 'package:mythdusk/features/daily/providers/daily_providers.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final fixture in [
    (const Size(393, 852), 1.0, 'daily-contract-2026-10-05'),
    (const Size(440, 956), 1.0, 'daily-pro-max-2026-10-06'),
    (const Size(320, 568), 1.0, 'daily-compact-controls'),
    (const Size(320, 568), 2.0, 'daily-large-text-controls')
  ]) {
    testWidgets('Daily rendered ${fixture.$3}', (tester) async {
      final font = FontLoader('DailySerif')
        ..addFont(rootBundle.load('assets/fonts/LibreBaskerville.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      await tester.binding.setSurfaceSize(fixture.$1);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            dailyEffectiveNowProvider.overrideWithValue(
                DateTime(2026, 10, fixture.$3.contains('10-06') ? 6 : 5)),
          ],
          child: MaterialApp(
              theme: AppTheme.dusk,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(fixture.$2),
                    padding: fixture.$1.width == 440
                        ? const EdgeInsets.only(top: 62, bottom: 34)
                        : EdgeInsets.zero,
                    viewPadding: fixture.$1.width == 440
                        ? const EdgeInsets.only(top: 62, bottom: 34)
                        : EdgeInsets.zero,
                  ),
                  child: child!),
              home: const RepaintBoundary(
                  key: Key('daily-capture'), child: DailyScreen()))));
      await tester.pumpAndSettle();
      // Asset decoding occurs asynchronously; wait for all images before capture.
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DailyScreen));
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(image.image, context);
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('Play contract').hitTestable(), findsOneWidget);
      expect(find.text('Lives 5/5').hitTestable(), findsOneWidget);
      if (fixture.$1.width == 440) {
        for (final title in ['Healing Kept', 'Bare Hands', 'Vital Line']) {
          expect(find.text(title).hitTestable(), findsOneWidget);
        }
      }
      expect(tester.takeException(), isNull);
      await expectLater(find.byKey(const Key('daily-capture')),
          matchesGoldenFile('goldens/${fixture.$3}.png'));
    });
  }
}
