import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mythdusk/features/battle/presentation/battle_screen.dart';
import 'package:mythdusk/features/battle/providers/battle_provider.dart';
import 'package:mythdusk/features/campaign/data/campaign_repository.dart';
import 'package:mythdusk/features/campaign/domain/campaign_models.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:mythdusk/features/puzzle/data/board_catalog_repository.dart';
import 'package:mythdusk/features/puzzle/domain/board_template.dart';
import 'package:mythdusk/features/puzzle/domain/overlay_def.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('unknown battle deep link never starts a fallback battle',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final chapter = CampaignChapter.fromJson({
      'id': 'test_chapter',
      'title': 'Test Chapter',
      'boardDefaults': {'templateId': 'board_test'},
      'acts': [
        {
          'id': 'act_one',
          'mapAsset': 'test.webp',
          'nodes': [
            {
              'id': 'real_node',
              'name': 'Real Node',
              'enemyId': 'goblin',
              'coinReward': 10,
              'order': 0,
            },
          ],
        },
      ],
    });
    final router = GoRouter(
      initialLocation: '/battle/missing_node',
      routes: [
        GoRoute(
          path: '/battle/:nodeId',
          builder: (_, state) =>
              BattleScreen(nodeId: state.pathParameters['nodeId']!),
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
          overlayCatalogProvider.overrideWith(
            (ref) async => OverlayCatalog([]),
          ),
          boardTemplateCatalogProvider.overrideWith(
            (ref) async => BoardTemplateCatalog([]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Battle unavailable'), findsOneWidget);
    expect(find.textContaining('missing_node'), findsOneWidget);
    expect(find.text('Goblin Scout'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('battle confirms leave/restart and QA can force enemy effects',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final chapter = CampaignChapter.fromJson({
      'id': 'test_chapter',
      'title': 'Test Chapter',
      'backgroundId': 'bg_battle_mistfen_marshes',
      'boardDefaults': {'templateId': 'board_open_6x6'},
      'acts': [
        {
          'id': 'act_one',
          'mapAsset': 'test.webp',
          'nodes': [
            {
              'id': 'effect_node',
              'name': 'Effect Node',
              'enemyId': 'mire_spawn',
              'coinReward': 10,
              'order': 0,
            },
          ],
        },
      ],
    });
    final router = GoRouter(
      initialLocation: '/battle/effect_node',
      routes: [
        GoRoute(
          path: '/battle/:nodeId',
          builder: (_, state) =>
              BattleScreen(nodeId: state.pathParameters['nodeId']!),
        ),
        GoRoute(
          path: '/result',
          builder: (_, __) => const Scaffold(body: Text('result')),
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

    await tester.tap(find.bySemanticsLabel('Restart battle'));
    await tester.pumpAndSettle();
    expect(find.text('Restart battle?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Leave battle'));
    await tester.pumpAndSettle();
    expect(find.text('Leave battle?'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('QA: force enemy skill'));
    await tester.pumpAndSettle();
    expect(find.text('Force Mire Spawn skill'), findsOneWidget);
    expect(find.text('Smother'), findsOneWidget);

    await tester.tap(find.text('Smother'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BattleScreen)),
    );
    final battle = container.read(battleProvider('effect_node'));
    final poisoned =
        battle.board.cells.where((cell) => cell.overlayId == 'ovl_poison');
    expect(battle.lastEnemySkillName, 'Smother');
    expect(poisoned, hasLength(2));
  });
}
