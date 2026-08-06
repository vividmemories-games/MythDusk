import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mythora/core/theme/app_theme.dart';
import 'package:mythora/features/battle/presentation/battle_result_screen.dart';
import 'package:mythora/features/campaign/presentation/briefing_screen.dart';
import 'package:mythora/features/campaign/presentation/campaign_screen.dart';
import 'package:mythora/features/campaign/presentation/chapter_select_screen.dart';
import 'package:mythora/features/home/presentation/home_screen.dart';
import 'package:mythora/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('critical campaign journey reaches a validated battle result',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/chapters',
          builder: (_, __) => const ChapterSelectScreen(),
        ),
        GoRoute(
          path: '/campaign',
          builder: (_, __) => const CampaignScreen(),
        ),
        GoRoute(
          path: '/briefing/:nodeId',
          builder: (_, state) =>
              BriefingScreen(nodeId: state.pathParameters['nodeId']!),
        ),
        GoRoute(
          path: '/battle/:nodeId',
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.go(
                  '/result',
                  extra: BattleResultArgs(
                    won: true,
                    nodeId: state.pathParameters['nodeId']!,
                    nodeName: 'Goblin Path',
                    enemyName: 'Goblin Scout',
                    coinReward: 30,
                  ),
                ),
                child: const Text('Complete test battle'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/result',
          builder: (_, state) =>
              BattleResultScreen(args: state.extra! as BattleResultArgs),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(
          theme: AppTheme.dusk,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enter Campaign'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterSelectScreen), findsOneWidget);

    await tester.tap(find.text('Twilight Road'));
    await _pumpUntilFound(tester, find.text('1. Goblin Path'));
    expect(find.byType(CampaignScreen), findsOneWidget);

    await tester.tap(find.text('1. Goblin Path'));
    await tester.pumpAndSettle();
    expect(find.byType(BriefingScreen), findsOneWidget);
    expect(find.text('Goblin Path'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Battle'));
    await tester.pumpAndSettle();
    expect(find.text('Complete test battle'), findsOneWidget);

    await tester.tap(find.text('Complete test battle'));
    await tester.pumpAndSettle();
    expect(find.text('Victory'), findsOneWidget);
    expect(find.textContaining('Goblin Scout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for the campaign node');
}
