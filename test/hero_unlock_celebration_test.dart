import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/heroes/domain/hero_unlocks.dart';
import 'package:mythdusk/features/heroes/presentation/hero_unlock_celebration_screen.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerProfile unlock celebrations', () {
    test('fromJson defaults missing seen ids; round-trip persists them', () {
      final migrated = PlayerProfile.fromJson({
        'completedNodeIds': List.generate(50, (i) => 'n$i'),
      });
      expect(migrated.completedNodeIds, hasLength(50));
      expect(migrated.seenUnlockCelebrationIds, isEmpty);
      expect(
        migrated.pendingUnlockCelebrations,
        ['knight', 'ranger', 'priest', 'ninja'],
      );

      final restored = PlayerProfile.fromJson(migrated.toJson());
      expect(restored.toJson()['schemaVersion'], PlayerProfile.schemaVersion);
      expect(restored.seenUnlockCelebrationIds, isEmpty);

      final marked = restored.copyWith(
        seenUnlockCelebrationIds: {'knight'},
      );
      final again = PlayerProfile.fromJson(marked.toJson());
      expect(again.seenUnlockCelebrationIds, {'knight'});
      expect(again.pendingUnlockCelebrations, ['ranger', 'priest', 'ninja']);
    });

    testWidgets('markUnlockCelebrationSeen is idempotent', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ProfileNotifier(prefs);
      await notifier.unlockAllNodes({
        for (var i = 0; i < 5; i++) 'node_$i',
      });
      expect(notifier.state.pendingUnlockCelebrations, ['knight']);

      notifier.markUnlockCelebrationSeen('knight');
      expect(notifier.state.seenUnlockCelebrationIds, {'knight'});
      expect(notifier.state.pendingUnlockCelebrations, isEmpty);

      notifier.markUnlockCelebrationSeen('knight');
      expect(notifier.state.seenUnlockCelebrationIds, {'knight'});
    });

    test('selectHero still gates locked heroes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ProfileNotifier(prefs);
      expect(notifier.state.selectedHeroId, 'mage');
      notifier.selectHero('knight');
      expect(notifier.state.selectedHeroId, 'mage');

      await notifier.unlockAllNodes({
        for (var i = 0; i < 5; i++) 'node_$i',
      });
      notifier.selectHero('knight');
      expect(notifier.state.selectedHeroId, 'knight');
    });
  });

  group('HeroUnlockCelebrationScreen', () {
    testWidgets('marks celebration seen and can continue home', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ProfileNotifier(prefs);
      await notifier.unlockAllNodes({
        for (var i = 0; i < 5; i++) 'node_$i',
      });

      final router = GoRouter(
        initialLocation: '/hero_unlock/knight',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('home-route')),
          ),
          GoRoute(
            path: '/heroes',
            builder: (_, __) => const Scaffold(body: Text('heroes-route')),
          ),
          GoRoute(
            path: '/hero_unlock/:heroId',
            builder: (context, state) => HeroUnlockCelebrationScreen(
              heroId: state.pathParameters['heroId']!,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            profileProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dusk,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('The spell breaks'), findsOneWidget);
      expect(find.text('Knight'), findsWidgets);
      expect(notifier.state.seenUnlockCelebrationIds, contains('knight'));
      expect(
        HeroUnlocks.pendingUnlockCelebrations(
          completedNodeCount: 5,
          seenCelebrationIds: notifier.state.seenUnlockCelebrationIds,
        ),
        isEmpty,
      );

      await tester.tap(find.text('Welcome Knight'));
      await tester.pumpAndSettle();
      expect(find.text('home-route'), findsOneWidget);
    });
  });
}
