import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/expedition/domain/expedition_models.dart';
import 'package:mythdusk/features/home/presentation/home_progress.dart';
import 'package:mythdusk/features/home/presentation/home_screen.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    PlayerProfile? profile,
  }) async {
    final stored = profile == null
        ? <String, Object>{}
        : <String, Object>{
            'mythdusk_profile_v2': jsonEncode(profile.toJson()),
          };
    SharedPreferences.setMockInitialValues(stored);
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
          path: '/challenge',
          builder: (_, __) => const Scaffold(body: Text('challenge-route')),
        ),
        GoRoute(
          path: '/heroes',
          builder: (_, __) => const Scaffold(body: Text('heroes-route')),
        ),
        GoRoute(
          path: '/expedition',
          builder: (_, __) => const Scaffold(body: Text('expedition-route')),
        ),
        GoRoute(
          path: '/daily',
          builder: (_, __) => const Scaffold(body: Text('daily-route')),
        ),
        GoRoute(
          path: '/weekly',
          builder: (_, __) => const Scaffold(body: Text('weekly-route')),
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

  testWidgets('home hub exposes campaign-first layout and live actions',
      (tester) async {
    await pumpHome(tester);

    expect(find.text('PATH RANK'), findsOneWidget);
    expect(find.text('Bronze I'), findsOneWidget);
    expect(find.text('Prep'), findsOneWidget);
    expect(find.text('Enter Campaign'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Heroes'), findsOneWidget);
    expect(find.text('Shop'), findsAtLeastNWidgets(2));
    expect(find.text('1v1'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Act I · Twilight Road'), findsOneWidget);
    expect(find.text('Node 3 / 20'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
    expect(find.text('Expedition'), findsNothing);
    expect(find.text('Inventory'), findsNothing);
    expect(find.text('Tap for heroes'), findsNothing);
    expect(
        find.text('Forge powerful combos. Write your legend.'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Shop').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Prep for the next fight. Prices in coins.'),
      findsOneWidget,
    );
  });

  testWidgets('More sheet exposes Profile and locked Expedition',
      (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Expedition'), findsOneWidget);
    expect(
      find.text('Clear ${ExpeditionBalance.minCampaignClears} campaign nodes'),
      findsOneWidget,
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('profile-route'), findsOneWidget);
  });

  testWidgets('unlocked Expedition appears as a Home chip', (tester) async {
    await pumpHome(
      tester,
      profile: PlayerProfile(
        completedNodeIds: {
          for (var i = 0; i < ExpeditionBalance.minCampaignClears; i++) 'n$i',
        },
        seenUnlockCelebrationIds: const {'knight'},
      ),
    );

    expect(find.text('Expedition'), findsOneWidget);
    await tester.tap(find.text('Expedition'));
    await tester.pumpAndSettle();
    expect(find.text('expedition-route'), findsOneWidget);
  });

  testWidgets('active Expedition run uses a Continue chip', (tester) async {
    await pumpHome(
      tester,
      profile: PlayerProfile(
        completedNodeIds: {
          for (var i = 0; i < ExpeditionBalance.minCampaignClears; i++) 'n$i',
        },
        seenUnlockCelebrationIds: const {'knight'},
        activeExpedition: ExpeditionRunState.start(heroId: 'mage', seed: 1),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Expedition'), findsNothing);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('expedition-route'), findsOneWidget);
  });

  testWidgets('home hub does not overflow on a compact phone', (tester) async {
    await pumpHome(tester, size: const Size(360, 640));

    expect(find.text('PATH RANK'), findsOneWidget);
    expect(find.text('Enter Campaign'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
