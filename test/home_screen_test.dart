import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/home/presentation/home_progress.dart';
import 'package:mythdusk/features/home/presentation/home_screen.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/shop',
          builder: (_, __) => const Scaffold(
            body: Text('Prep for the next fight. Prices in coins.'),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('profile-route')),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('settings-route')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          homeCampaignProgressProvider.overrideWith(
            (ref) async => const HomeCampaignProgress(
              chapterTitle: 'Twilight Road',
              actTitle: 'Act I',
              completedInChapter: 3,
              totalInChapter: 20,
              chapterId: 'twilight_road',
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dusk,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home hub exposes the reference layout and live actions',
      (tester) async {
    await pumpHome(tester);

    expect(find.text('MythDusk'), findsOneWidget);
    expect(
      find.text('Forge powerful combos. Write your legend.'),
      findsOneWidget,
    );
    expect(find.text('Enter Campaign'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Expedition'), findsOneWidget);
    expect(find.text('Quests'), findsNothing);
    expect(find.text('Events'), findsNothing);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Heroes'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Ranked'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Act I · Twilight Road'), findsOneWidget);
    expect(find.text('Node 3 / 20'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    expect(
      find.text('Prep for the next fight. Prices in coins.'),
      findsOneWidget,
    );
  });

  testWidgets('home hub does not overflow on a compact phone', (tester) async {
    await pumpHome(tester, size: const Size(360, 640));

    expect(find.text('MythDusk'), findsOneWidget);
    expect(find.text('Enter Campaign'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
