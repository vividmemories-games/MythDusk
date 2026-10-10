import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/widgets/skill_art.dart';
import 'package:mythdusk/features/heroes/presentation/heroes_screen.dart';
import 'package:mythdusk/features/profile/presentation/shop_screen.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:mythdusk/features/prep/domain/prep_item.dart';
import '../tool/hub_preview.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, String screen,
      {PlayerProfile? profile}) async {
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await tester
        .runAsync(() => hubPreview(screen: screen, fixtureProfile: profile));
    await tester.pumpWidget(app!);
    await tester.pumpAndSettle();
  }

  testWidgets('Shop aid purchase deducts exact coins and adds one item',
      (tester) async {
    await pumpScreen(tester, 'shop');
    final container =
        ProviderScope.containerOf(tester.element(find.byType(ShopScreen)));
    final before = container.read(profileProvider);
    final label =
        'Buy Vanguard Tonic for ${PrepBalance.shopCoinCost[PrepItemId.vanguardTonic]} coins';
    await tester.tap(find.bySemanticsLabel(label));
    await tester.pumpAndSettle();
    final after = container.read(profileProvider);
    expect(after.coins,
        before.coins - PrepBalance.shopCoinCost[PrepItemId.vanguardTonic]!);
    expect(after.prepCount(PrepItemId.vanguardTonic),
        before.prepCount(PrepItemId.vanguardTonic) + 1);
    expect(after.gems, before.gems);
  });
  testWidgets('Shop blocks purchases without enough coins', (tester) async {
    await pumpScreen(tester, 'shop', profile: const PlayerProfile(coins: 0));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(ShopScreen)));
    final before =
        container.read(profileProvider).prepCount(PrepItemId.vanguardTonic);
    final button = find.ancestor(
        of: find.bySemanticsLabel(
            'Buy Vanguard Tonic for ${PrepBalance.shopCoinCost[PrepItemId.vanguardTonic]} coins'),
        matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(container.read(profileProvider).prepCount(PrepItemId.vanguardTonic),
        before);
  });
  testWidgets('Heroes swaps an ability and preserves mastery lock',
      (tester) async {
    await pumpScreen(tester, 'heroes');
    final container =
        ProviderScope.containerOf(tester.element(find.byType(HeroesScreen)));
    await tester.scrollUntilVisible(find.text('Rallying Cry'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rallying Cry'));
    await tester.pumpAndSettle();
    final equipped =
        container.read(profileProvider).equippedSkillIdsFor('knight');
    expect(equipped, contains('rallying_cry'));
    expect(equipped.length, 2);
    await tester.scrollUntilVisible(find.text('Bulwark Slam'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bulwark Slam'));
    await tester.pumpAndSettle();
    expect(container.read(profileProvider).equippedSkillIdsFor('knight'),
        equipped);
    expect(find.byType(SkillArt), findsWidgets);
  });
  testWidgets('Browsing a locked hero leaves selected hero intact',
      (tester) async {
    await pumpScreen(tester, 'heroes', profile: const PlayerProfile());
    final container =
        ProviderScope.containerOf(tester.element(find.byType(HeroesScreen)));
    await tester.tap(find.byTooltip('Next hero'));
    await tester.pumpAndSettle();
    expect(container.read(profileProvider).selectedHeroId, 'mage');
    expect(find.text('Knight'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
