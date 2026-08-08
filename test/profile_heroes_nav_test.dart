import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mythdusk/core/router/app_router.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/heroes/presentation/heroes_screen.dart';
import 'package:mythdusk/features/home/presentation/home_progress.dart';
import 'package:mythdusk/features/home/presentation/home_screen.dart';
import 'package:mythdusk/features/profile/presentation/profile_screen.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('app router includes hub routes', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final routes = container
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>();
    expect(routes.any((r) => r.path == '/heroes'), isTrue);
    expect(routes.any((r) => r.path == '/hero_unlock/:heroId'), isTrue);
    expect(routes.any((r) => r.path == '/profile'), isTrue);
    expect(routes.any((r) => r.path == '/shop'), isTrue);
    expect(routes.any((r) => r.path == '/settings'), isTrue);
  });

  testWidgets('HeroesScreen shows detail carousel without roster list',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.dusk,
          home: const HeroesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Roster'), findsNothing);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Skills'), findsOneWidget);
    expect(find.text('Personality'), findsOneWidget);
    expect(find.text('Max HP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileScreen shows progress and hub links', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/heroes',
          builder: (_, __) => const Scaffold(body: Text('heroes-route')),
        ),
        GoRoute(
          path: '/shop',
          builder: (_, __) => const Scaffold(body: Text('shop-route')),
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
          sharedPreferencesProvider.overrideWithValue(prefs),
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

    expect(find.text('Coins'), findsOneWidget);
    expect(find.text('Gems'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Prep inventory'), 200);
    expect(find.text('Prep inventory'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Heroes'),
      200,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Shop'));
    await tester.pumpAndSettle();
    expect(find.text('shop-route'), findsOneWidget);
  });

  testWidgets('Home Hero and More navigate to Heroes and Profile',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/heroes',
          builder: (_, __) => const Scaffold(body: Text('heroes-route')),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('profile-route')),
        ),
        GoRoute(
          path: '/shop',
          builder: (_, __) => const Scaffold(body: Text('shop-route')),
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
          sharedPreferencesProvider.overrideWithValue(prefs),
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

    await tester.tap(find.text('Hero'));
    await tester.pumpAndSettle();
    expect(find.text('heroes-route'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('profile-route'), findsOneWidget);
  });
}
