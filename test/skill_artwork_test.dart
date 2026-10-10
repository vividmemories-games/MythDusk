import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/assets/skill_artwork.dart';
import 'package:mythdusk/core/widgets/skill_art.dart';
import 'package:mythdusk/features/campaign/presentation/briefing_screen.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import '../tool/hub_preview.dart';

class _UnavailableArtworkBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      Future.error(StateError('Artwork unavailable'));
}

PlayerProfile _allHeroesProfile(String heroId, List<String> loadout) =>
    PlayerProfile(
      selectedHeroId: heroId,
      completedNodeIds: {for (var i = 0; i < 50; i++) 'cleared_$i'},
      seenUnlockCelebrationIds: const {'knight', 'ranger', 'priest', 'ninja'},
      unlockedMasterySkillIds: {
        for (final hero in HeroCatalog.all) hero.skills.last.id
      },
      equippedSkillIdsByHero: {heroId: loadout},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Every catalog skill has a distinct artwork cell', () {
    final ids = {
      for (final hero in HeroCatalog.all)
        for (final skill in hero.skills) skill.id
    };
    expect(SkillArtwork.bySkillId.keys.toSet(), ids);
    final cells = <String>{};
    for (final id in ids) {
      final art = SkillArtwork.forSkill(id)!;
      expect(art.column, inInclusiveRange(0, 1));
      expect(art.row, inInclusiveRange(0, 1));
      expect(cells.add('${art.assetPath}:${art.column}:${art.row}'), isTrue);
    }
    expect(SkillArtwork.forSkill('future_skill'), isNull);
  });

  test('Every skill atlas is bundled', () async {
    for (final asset
        in SkillArtwork.bySkillId.values.map((a) => a.assetPath).toSet()) {
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
    }
  });

  for (final hero in HeroCatalog.all) {
    for (final pair in [
      [0, 1],
      [2, 3]
    ]) {
      final ids = [for (final index in pair) hero.skills[index].id];
      testWidgets(
          '${hero.name} briefing renders equipped $ids with their own artwork',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(440, 956));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final app = await tester.runAsync(() => hubPreview(
            briefing: true, fixtureProfile: _allHeroesProfile(hero.id, ids)));
        await tester.pumpWidget(app!);
        await tester.pumpAndSettle();
        expect(find.text('Hero: ${hero.name}'), findsOneWidget);
        expect(
            tester
                .widgetList<SkillArt>(find.byType(SkillArt))
                .map((w) => w.skill.id),
            ids);
        for (final skill in hero.skills) {
          expect(find.text(skill.name),
              ids.contains(skill.id) ? findsOneWidget : findsNothing);
        }
        for (final image in tester.widgetList<Image>(find.descendant(
            of: find.byType(SkillArt), matching: find.byType(Image)))) {
          expect((image.image as AssetImage).assetName,
              SkillArtwork.forSkill(ids.first)!.assetPath);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Unknown future skills have a visible fallback', (tester) async {
    const futureSkill = SkillDef(
        id: 'future_skill',
        name: 'Future Skill',
        apCost: 1,
        resourceCosts: {},
        damage: 0,
        heal: 10);
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SkillArt(skill: futureSkill))));
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'A failed atlas load still shows the skill fallback in the visible cell',
      (tester) async {
    final skill = HeroCatalog.knight.skills[1];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DefaultAssetBundle(
      bundle: _UnavailableArtworkBundle(),
      child: SkillArt(skill: skill),
    ))));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.shield).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Changing hero and equipped skills refreshes the open briefing',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = await tester.runAsync(() => hubPreview(
        briefing: true,
        fixtureProfile:
            _allHeroesProfile('mage', ['fireball', 'arcane_bolt'])));
    await tester.pumpWidget(app!);
    await tester.pumpAndSettle();
    final container =
        ProviderScope.containerOf(tester.element(find.byType(BriefingScreen)));
    final notifier = container.read(profileProvider.notifier);
    for (final hero in HeroCatalog.all) {
      notifier.selectHero(hero.id);
      // Deliberately reverse the catalog order and include the mastery skill.
      final equippedIds = [hero.skills[3].id, hero.skills[2].id];
      notifier.setEquippedSkills(hero.id, equippedIds);
      await tester.pumpAndSettle();
      expect(find.text('Hero: ${hero.name}'), findsOneWidget);
      expect(
          tester
              .widgetList<SkillArt>(find.byType(SkillArt))
              .map((w) => w.skill.id),
          equippedIds);
      expect(find.text(hero.skills[0].name), findsNothing);
      expect(find.text(hero.skills[1].name), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
