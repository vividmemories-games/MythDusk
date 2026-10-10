import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/daily/presentation/daily_screen.dart';
import 'package:mythdusk/features/daily/providers/daily_providers.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:mythdusk/features/weekly/presentation/weekly_screen.dart';
import 'package:mythdusk/features/weekly/providers/weekly_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final path in ['/daily', '/weekly']) {
    for (final entry in ['push', 'direct', 'result']) {
      testWidgets('$path back works after $entry entry', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final router = GoRouter(
          initialLocation: entry == 'direct'
              ? path
              : entry == 'push'
                  ? '/previous'
                  : '/result',
          routes: [
            GoRoute(
                path: '/',
                builder: (_, __) =>
                    const Scaffold(body: Text('Home destination'))),
            GoRoute(
                path: '/previous',
                builder: (_, __) =>
                    const Scaffold(body: Text('Previous destination'))),
            GoRoute(
                path: '/result',
                builder: (_, __) =>
                    const Scaffold(body: Text('Battle result'))),
            GoRoute(path: '/daily', builder: (_, __) => const DailyScreen()),
            GoRoute(path: '/weekly', builder: (_, __) => const WeeklyScreen()),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(preferences),
              dailyEffectiveNowProvider
                  .overrideWithValue(DateTime(2026, 10, 6)),
              weeklyEffectiveNowProvider
                  .overrideWithValue(DateTime(2026, 10, 6)),
            ],
            child: MaterialApp.router(
                theme: AppTheme.dusk, routerConfig: router)));
        await tester.pumpAndSettle();
        if (entry == 'push') {
          router.push<void>(path);
        } else if (entry == 'result') {
          // Mirrors the route replacement used by battle results and retries.
          router.go(path);
        }
        await tester.pumpAndSettle();
        expect(router.canPop(), entry == 'push');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(
            find.text(
                entry == 'push' ? 'Previous destination' : 'Home destination'),
            findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path,
            entry == 'push' ? '/previous' : '/');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
