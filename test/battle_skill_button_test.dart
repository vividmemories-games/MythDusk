import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/core/widgets/skill_art.dart';
import 'package:mythdusk/features/battle/domain/battle_state.dart';
import 'package:mythdusk/features/battle/presentation/battle_screen.dart';
import 'package:mythdusk/features/battle/presentation/battle_skill_button.dart';
import 'package:mythdusk/features/battle/presentation/animated_puzzle_board.dart';
import 'package:mythdusk/features/campaign/data/campaign_repository.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:mythdusk/features/puzzle/data/board_catalog_repository.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';

BattleState _ready(HeroDef hero) =>
    BattleState.initial(hero: hero).copyWith(ap: hero.maxAp, resources: {
      'attack': 20,
      'mana': 20,
      'healing': 20,
      'shield': 20,
      'ultimate': 20
    });

void main() {
  testWidgets(
      'all 20 skills display live costs and charge exactly once per cast',
      (tester) async {
    for (final hero in HeroCatalog.all) {
      for (final skill in hero.skills) {
        var battle = _ready(hero);
        var casts = 0;
        final finished = Completer<void>();
        late StateSetter update;
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.dusk,
            home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
              update = setState;
              return SizedBox(
                  width: 220,
                  child: BattleSkillButton(
                      key: ValueKey(skill.id),
                      skill: skill,
                      battle: battle,
                      onTap: () async {
                        casts++;
                        final controller = BattleController(battle)
                          ..castSkill(skill);
                        update(() => battle = controller.state);
                        await finished.future;
                      }));
            }))));
        await tester.pumpAndSettle();
        expect(find.byType(SkillArt), findsOneWidget);
        expect(find.text('${hero.maxAp}/${skill.apCost}'), findsOneWidget);
        await tester.tap(find.byType(BattleSkillButton));
        await tester.pump();
        expect(find.text('Casting…'), findsOneWidget);
        await tester.tap(find.byType(BattleSkillButton));
        expect(casts, 1);
        expect(battle.ap, hero.maxAp - skill.apCost);
        for (final cost in skill.resourceCosts.entries) {
          expect(battle.resources[cost.key], 20 - cost.value);
        }
        finished.complete();
        await tester.pumpAndSettle();
        expect(find.text('Casting…'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('missing AP or resources and non-player phases block input',
      (tester) async {
    const hero = HeroCatalog.mage;
    final skill = hero.skills.first;
    final ready = _ready(hero);
    var casts = 0;
    final blocked = [
      ready.copyWith(ap: 0),
      for (final resource in skill.resourceCosts.keys)
        ready.copyWith(resources: {...ready.resources, resource: 0}),
      for (final phase
          in BattlePhase.values.where((p) => p != BattlePhase.playerTurn))
        ready.copyWith(phase: phase),
    ];
    for (final battle in blocked) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 180,
                  child: BattleSkillButton(
                      skill: skill,
                      battle: battle,
                      onTap: () async {
                        casts++;
                      })))));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BattleSkillButton));
      await tester.pumpAndSettle();
      expect(casts, 0);
      expect(find.text('Ready'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('casting can complete safely after leaving the screen',
      (tester) async {
    final finished = Completer<void>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: BattleSkillButton(
                skill: HeroCatalog.knight.skills.first,
                battle: _ready(HeroCatalog.knight),
                onTap: () => finished.future))));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BattleSkillButton));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    finished.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'full battle keeps board visible and skills reachable on compact phones',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'mythdusk_profile_v2': jsonEncode(const PlayerProfile(
          selectedHeroId: 'mage',
          firstBattleTutorialDone: true,
          hintsEnabled: false,
          unlockedMasterySkillIds: {
            'meteor_shard'
          },
          equippedSkillIdsByHero: {
            'mage': ['frost_ward', 'meteor_shard']
          }).toJson())
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    await container.read(campaignChapterProvider.future);
    await container.read(overlayCatalogProvider.future);
    await container.read(boardTemplateCatalogProvider.future);
    container.read(profileProvider.notifier).skipFirstBattleTutorial();
    for (final size in [const Size(320, 568), const Size(390, 844)]) {
      for (final scale in [1.0, 2.0]) {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final router = GoRouter(initialLocation: '/battle/node_07', routes: [
          GoRoute(
              path: '/battle/:id',
              builder: (_, s) => BattleScreen(nodeId: s.pathParameters['id']!)),
          GoRoute(path: '/result', builder: (_, __) => const Scaffold()),
        ]);
        await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
                theme: AppTheme.dusk,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!))));
        await tester.pumpAndSettle();
        expect(find.byType(BattleSkillButton), findsNWidgets(2));
        expect(find.text('Meteor Shard'), findsOneWidget);
        expect(tester.getSize(find.byType(AnimatedPuzzleBoard)).height,
            greaterThan(120));
        await tester.ensureVisible(find.byType(BattleSkillButton).first);
        await tester.pumpAndSettle();
        expect(
            find.byType(BattleSkillButton).first.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$size / $scale');
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      }
    }
  });
}
