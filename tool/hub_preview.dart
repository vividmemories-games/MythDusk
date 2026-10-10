// Deterministic visual fixture; uses isolated in-memory profile storage.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/campaign/data/campaign_repository.dart';
import 'package:mythdusk/features/campaign/domain/campaign_models.dart';
import 'package:mythdusk/features/campaign/presentation/briefing_screen.dart';
import 'package:mythdusk/features/campaign/presentation/chapter_select_screen.dart';
import 'package:mythdusk/features/home/presentation/home_progress.dart';
import 'package:mythdusk/features/home/presentation/home_screen.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/heroes/presentation/heroes_screen.dart';
import 'package:mythdusk/features/profile/presentation/profile_screen.dart';
import 'package:mythdusk/features/profile/presentation/shop_screen.dart';
import 'package:mythdusk/features/prep/domain/prep_item.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';

Future<Widget> hubPreview(
    {bool briefing = false,
    bool realms = false,
    String screen = '',
    double textScale = 1,
    EdgeInsets? safePadding,
    PlayerProfile? fixtureProfile}) async {
  final profile = fixtureProfile ??
      PlayerProfile(
          selectedHeroId: 'knight',
          coins: 760,
          gems: 50,
          completedNodeIds: {
            for (var i = 1; i <= 6; i++) 'node_0$i'
          },
          seenUnlockCelebrationIds: const {
            'knight'
          },
          prepInventory: const {
            PrepItemId.vanguardTonic: 7,
            PrepItemId.aegisFlask: 1,
            PrepItemId.secondWind: 1
          });
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(
      {'mythdusk_profile_v2': jsonEncode(profile.toJson())});
  final preferences = await SharedPreferences.getInstance();
  final chapter = CampaignChapter.fromJson(jsonDecode(
          await rootBundle.loadString('assets/levels/twilight_road.json'))
      as Map<String, dynamic>);
  final index = CampaignIndex.fromJson(jsonDecode(
          await rootBundle.loadString('assets/levels/campaign_index.json'))
      as Map<String, dynamic>);
  final router = GoRouter(
      initialLocation: screen.isNotEmpty
          ? '/$screen'
          : realms
              ? '/chapters'
              : briefing
                  ? '/briefing/node_07'
                  : '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(
            path: '/chapters', builder: (_, __) => const ChapterSelectScreen()),
        GoRoute(
            path: '/briefing/:id',
            builder: (_, s) => BriefingScreen(nodeId: s.pathParameters['id']!)),
        for (final path in [
          '/campaign',
          '/heroes',
          '/challenge',
          '/shop',
          '/daily',
          '/weekly',
          '/settings',
          '/profile',
          '/expedition'
        ])
          GoRoute(
              path: path,
              builder: (_, __) => switch (path) {
                    '/heroes' when screen == 'heroes' => const HeroesScreen(),
                    '/shop' when screen == 'shop' => const ShopScreen(),
                    '/profile' when screen == 'profile' =>
                      const ProfileScreen(),
                    _ => Scaffold(
                        body: Center(child: Text('$path preview route'))),
                  }),
        GoRoute(
            path: '/battle/:id',
            builder: (_, s) =>
                Scaffold(body: Text('battle:${s.pathParameters['id']}'))),
      ]);
  return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        campaignChapterProvider.overrideWith((ref) async => chapter),
        campaignIndexProvider.overrideWith((ref) async => index),
        homeCampaignProgressProvider.overrideWith((ref) async =>
            const HomeCampaignProgress(
                chapterTitle: 'Twilight Road',
                actTitle: 'Act II',
                completedInChapter: 6,
                totalInChapter: 20,
                chapterId: 'twilight_road',
                nextNodeId: 'node_07')),
      ],
      child: MaterialApp.router(
          theme: AppTheme.dusk,
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(textScale),
                    padding: safePadding,
                    viewPadding: safePadding),
                child: RepaintBoundary(
                    key: const Key('hub-capture'), child: child!),
              )));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const heroId = String.fromEnvironment('QA_HERO', defaultValue: 'knight');
  const skills = String.fromEnvironment('QA_SKILLS');
  final customProfile = heroId != 'knight' || skills.isNotEmpty
      ? PlayerProfile(
          selectedHeroId: heroId,
          coins: 760,
          gems: 50,
          completedNodeIds: {for (var i = 0; i < 50; i++) 'qa_clear_$i'},
          seenUnlockCelebrationIds: {
            for (final hero in HeroCatalog.all) hero.id
          },
          unlockedMasterySkillIds: {
            for (final hero in HeroCatalog.all) hero.skills.last.id
          },
          equippedSkillIdsByHero: {
            if (skills.isNotEmpty) heroId: skills.split(',')
          },
          prepInventory: const {
            PrepItemId.vanguardTonic: 7,
            PrepItemId.aegisFlask: 1,
            PrepItemId.secondWind: 1
          },
        )
      : null;
  runApp(await hubPreview(
      fixtureProfile: customProfile,
      briefing: const bool.fromEnvironment('BRIEFING_QA'),
      realms: const bool.fromEnvironment('REALMS_QA'),
      screen: const String.fromEnvironment('QA_SCREEN'),
      textScale: double.parse(
          const String.fromEnvironment('QA_TEXT_SCALE', defaultValue: '1'))));
}
