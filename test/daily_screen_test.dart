import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mythdusk/core/assets/game_assets.dart';
import 'package:mythdusk/features/daily/domain/daily_schedule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/daily/presentation/daily_screen.dart';
import 'package:mythdusk/features/daily/providers/daily_providers.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('Daily remains scrollable on a compact phone at scale $scale',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          dailyEffectiveNowProvider.overrideWithValue(DateTime(2026, 10, 5)),
        ],
        child: MaterialApp(
          theme: AppTheme.dusk,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: const DailyScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Lives 5/5').hitTestable(), findsOneWidget);
      expect(find.text('Play contract').hitTestable(), findsOneWidget);
      await Scrollable.ensureVisible(
          tester.element(find.text('Under Pressure')),
          alignment: 0.5);
      await tester.pumpAndSettle();
      expect(find.text('Under Pressure').hitTestable(), findsOneWidget);
      expect(find.text('Play contract').hitTestable(), findsOneWidget);
      expect(find.text('Lives 5/5').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Daily retains each scheduled enemy and objective',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    for (var day = 5; day < 12; day++) {
      final date = DateTime(2026, 10, day);
      final contract = DailySchedule.forDate(date);
      await tester.pumpWidget(ProviderScope(
          key: ValueKey(day),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            dailyEffectiveNowProvider.overrideWithValue(date),
          ],
          child: MaterialApp(theme: AppTheme.dusk, home: const DailyScreen())));
      await tester.pumpAndSettle();
      expect(find.text(contract.title), findsOneWidget);
      expect(find.text(contract.enemyName), findsOneWidget);
      expect(find.text(contract.objective.progressLabel), findsOneWidget);
      expect(
          tester.widgetList<Image>(find.byType(Image)).any((image) =>
              image.image is AssetImage &&
              (image.image as AssetImage).assetName ==
                  GameAssets.enemy(contract.enemyId)),
          isTrue);
      expect(tester.takeException(), isNull);
    }
  });

  for (final completed in [false, true]) {
    testWidgets(
        completed
            ? 'Completed contracts disable play and show claimed rewards'
            : 'Empty lives disable play', (tester) async {
      final profile = PlayerProfile(
          lives: completed ? 5 : 0,
          lastLifeRegenAt: DateTime.now(),
          dailyLastCompletedDay: completed ? '2026-10-05' : '');
      SharedPreferences.setMockInitialValues(
          {'mythdusk_profile_v2': jsonEncode(profile.toJson())});
      final preferences = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        dailyEffectiveNowProvider.overrideWithValue(DateTime(2026, 10, 5)),
      ], child: MaterialApp(theme: AppTheme.dusk, home: const DailyScreen())));
      await tester.pumpAndSettle();
      final label = completed ? 'Completed — come back tomorrow' : 'No lives';
      final button = find.ancestor(
          of: find.text(label), matching: find.byType(TextButton));
      expect(tester.widget<TextButton>(button).onPressed, isNull);
      if (completed) expect(find.text('CONTRACT COMPLETE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
