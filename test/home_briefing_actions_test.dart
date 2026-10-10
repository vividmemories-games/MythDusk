import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/campaign/presentation/briefing_screen.dart';
import 'package:mythdusk/features/campaign/presentation/briefing_widgets.dart';
import 'package:mythdusk/features/campaign/presentation/chapter_select_screen.dart';
import 'package:mythdusk/features/prep/domain/prep_item.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import '../tool/hub_preview.dart';

void main() {
  Future<void> pumpFixture(WidgetTester tester, {bool briefing = false}) async {
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await tester.runAsync(() => hubPreview(briefing: briefing));
    await tester.pumpWidget(app!);
    await tester.pumpAndSettle();
  }

  for (final action in [
    'World Map',
    'Enter Arena ›',
    '1v1',
    'Daily',
    'Weekly'
  ]) {
    testWidgets('Home $action opens the existing route', (tester) async {
      await pumpFixture(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      final route = switch (action) {
        'World Map' => '/chapters',
        'Enter Arena ›' || '1v1' => '/challenge',
        'Daily' => '/daily',
        _ => '/weekly',
      };
      if (action == 'World Map') {
        expect(find.byType(ChapterSelectScreen), findsOneWidget);
      } else {
        expect(find.text('$route preview route'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Continue Journey skips realm and node selection',
      (tester) async {
    await pumpFixture(tester);
    await tester.tap(find.text('Continue Journey'));
    await tester.pumpAndSettle();
    expect(find.byType(BriefingScreen), findsOneWidget);
    expect(find.text('Bog Shaman'), findsOneWidget);
    await tester.tap(find.text('Battle'));
    await tester.pumpAndSettle();
    expect(find.text('battle:node_07'), findsOneWidget);
  });

  testWidgets('Selecting aids spends inventory only when Battle is pressed',
      (tester) async {
    await pumpFixture(tester, briefing: true);
    await tester.pumpAndSettle();
    final container =
        ProviderScope.containerOf(tester.element(find.byType(BriefingScreen)));
    final tonic = find.byWidgetPredicate(
        (w) => w is BriefingPrepCard && w.id == PrepItemId.vanguardTonic);
    await tester.ensureVisible(tonic);
    await tester.tap(tonic);
    await tester.pumpAndSettle();
    expect(
        container.read(profileProvider).prepCount(PrepItemId.vanguardTonic), 7);
    expect(find.text('Battle (1 prep)').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Battle (1 prep)'));
    await tester.pumpAndSettle();
    expect(find.text('battle:node_07'), findsOneWidget);
    expect(
        container.read(profileProvider).prepCount(PrepItemId.vanguardTonic), 6);
    expect(container.read(profileProvider).prepCount(PrepItemId.aegisFlask), 1);
    expect(container.read(pendingBossPrepProvider), [PrepItemId.vanguardTonic]);
  });

  testWidgets('Deselecting aid leaves inventory intact', (tester) async {
    await pumpFixture(tester, briefing: true);
    await tester.pumpAndSettle();
    final container =
        ProviderScope.containerOf(tester.element(find.byType(BriefingScreen)));
    final tonic = find.byWidgetPredicate(
        (w) => w is BriefingPrepCard && w.id == PrepItemId.vanguardTonic);
    await tester.ensureVisible(tonic);
    await tester.tap(tonic);
    await tester.pump();
    await tester.tap(tonic);
    await tester.pump();
    expect(find.text('Battle'), findsOneWidget);
    await tester.tap(find.text('Battle'));
    await tester.pumpAndSettle();
    expect(
        container.read(profileProvider).prepCount(PrepItemId.vanguardTonic), 7);
    expect(container.read(pendingBossPrepProvider), isEmpty);
  });

  testWidgets('Briefing back and edit loadout retain their routes',
      (tester) async {
    await pumpFixture(tester, briefing: true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit loadout'));
    await tester.pumpAndSettle();
    expect(find.text('/heroes preview route'), findsOneWidget);
    GoRouter.of(tester.element(find.text('/heroes preview route'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to campaign'));
    await tester.pumpAndSettle();
    expect(find.text('/campaign preview route'), findsOneWidget);
  });

  testWidgets('Unavailable aids and used Second Wind cannot be selected',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final today = DateTime.now();
    final dayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final app = await tester.runAsync(() => hubPreview(
        briefing: true,
        fixtureProfile:
            PlayerProfile(secondWindUsedDay: dayKey, prepInventory: const {
          PrepItemId.vanguardTonic: 0,
          PrepItemId.aegisFlask: 0,
          PrepItemId.secondWind: 1,
        })));
    await tester.pumpWidget(app!);
    await tester.pumpAndSettle();
    for (final id in PrepItemId.values) {
      final card =
          find.byWidgetPredicate((w) => w is BriefingPrepCard && w.id == id);
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pump();
      expect((tester.widget(card) as BriefingPrepCard).selected, isFalse);
    }
    expect(find.text('Already used today'), findsOneWidget);
    expect(find.text('Battle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Battle stays pinned while enlarged preparation content scrolls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app =
        await tester.runAsync(() => hubPreview(briefing: true, textScale: 2));
    await tester.pumpWidget(app!);
    await tester.pumpAndSettle();
    expect(find.text('Battle').hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Second Wind'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Second Wind').hitTestable(), findsOneWidget);
    expect(find.text('Battle').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
