import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mythdusk/core/router/app_router.dart';
import 'package:mythdusk/features/campaign/data/campaign_repository.dart';
import 'package:mythdusk/features/campaign/domain/campaign_models.dart';
import 'package:mythdusk/features/campaign/presentation/briefing_screen.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

CampaignChapter _stubChapter() {
  return CampaignChapter.fromJson({
    'id': 'twilight_road',
    'title': 'Twilight Road',
    'subtitle': 'Test',
    'backgroundId': 'bg_battle_twilight_road',
    'boardDefaults': {'templateId': 'board_open_6x6'},
    'acts': [
      {
        'id': 'act1',
        'title': 'Act I',
        'mapAsset': 'assets/images/maps/map_ch_twilight_road_a1.png',
        'nodes': [
          {
            'id': 'ch_twilight_n01',
            'name': 'First Steps',
            'enemyId': 'goblin',
            'coinReward': 30,
            'order': 0,
            'mapX': 0.5,
            'mapY': 0.5,
          },
        ],
      },
    ],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BriefingScreen Battle pushes /battle/:nodeId', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final chapter = _stubChapter();

    final router = GoRouter(
      initialLocation: '/briefing/ch_twilight_n01',
      routes: [
        GoRoute(
          path: '/briefing/:nodeId',
          builder: (context, state) =>
              BriefingScreen(nodeId: state.pathParameters['nodeId']!),
        ),
        GoRoute(
          path: '/battle/:nodeId',
          builder: (context, state) => Scaffold(
            body: Text('battle:${state.pathParameters['nodeId']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          campaignChapterProvider.overrideWith((ref) async => chapter),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('Battle'), findsOneWidget);

    await tester.ensureVisible(find.text('Battle'));
    await tester.tap(find.text('Battle'));
    await tester.pumpAndSettle();

    expect(find.text('battle:ch_twilight_n01'), findsOneWidget);
  });

  testWidgets('unknown briefing node shows a recoverable content error',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final chapter = _stubChapter();
    final router = GoRouter(
      initialLocation: '/briefing/missing_node',
      routes: [
        GoRoute(
          path: '/briefing/:nodeId',
          builder: (context, state) =>
              BriefingScreen(nodeId: state.pathParameters['nodeId']!),
        ),
        GoRoute(
          path: '/chapters',
          builder: (_, __) => const Scaffold(body: Text('chapters')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          campaignChapterProvider.overrideWith((ref) async => chapter),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Battle unavailable'), findsOneWidget);
    expect(find.textContaining('missing_node'), findsOneWidget);
    expect(find.text('First Steps'), findsNothing);

    await tester.tap(find.text('Back to Campaign'));
    await tester.pumpAndSettle();
    expect(find.text('chapters'), findsOneWidget);
  });

  testWidgets('briefing remains usable on a compact phone with larger text',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final chapter = _stubChapter();
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final router = GoRouter(
      initialLocation: '/briefing/ch_twilight_n01',
      routes: [
        GoRoute(
          path: '/briefing/:nodeId',
          builder: (context, state) =>
              BriefingScreen(nodeId: state.pathParameters['nodeId']!),
        ),
        GoRoute(
          path: '/battle/:nodeId',
          builder: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          campaignChapterProvider.overrideWith((ref) async => chapter),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Steps'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Battle'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  test('app router includes /briefing/:nodeId', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    final routes = router.configuration.routes.whereType<GoRoute>();
    expect(
      routes.any((r) => r.path == '/briefing/:nodeId'),
      isTrue,
      reason: 'campaign path requires briefing before battle',
    );
  });
}
