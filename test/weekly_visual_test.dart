import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/weekly/presentation/weekly_screen.dart';
import 'package:mythdusk/features/weekly/providers/weekly_providers.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final fixture in [
    (const Size(440, 956), 1.0, 'weekly-weekday'),
    (const Size(440, 956), 1.0, 'weekly-weekend'),
    (const Size(320, 568), 1.0, 'weekly-compact-controls'),
    (const Size(320, 568), 2.0, 'weekly-large-text-controls'),
    (const Size(320, 568), 2.0, 'weekly-weekend-large-text')
  ]) {
    testWidgets('Weekly rendered ${fixture.$3}', (tester) async {
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
            weeklyEffectiveNowProvider.overrideWithValue(
                DateTime(2026, 10, fixture.$3.contains('weekend') ? 10 : 6)),
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
                  key: Key('weekly-capture'), child: WeeklyScreen()))));
      await tester.pumpAndSettle();
      // Asset decoding occurs asynchronously; wait for all images before capture.
      await tester.runAsync(() async {
        final context = tester.element(find.byType(WeeklyScreen));
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(image.image, context);
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('Play').hitTestable(), findsOneWidget);
      expect(find.text('Lives 5/5').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(find.byKey(const Key('weekly-capture')),
          matchesGoldenFile('goldens/${fixture.$3}.png'));
    });
  }
}
