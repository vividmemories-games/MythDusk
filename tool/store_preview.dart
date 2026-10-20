// Local Android store capture fixture; never used by the production entry point.
// Run in profile mode so production UI is captured without debug QA controls.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/battle/presentation/battle_screen.dart';
import 'package:mythdusk/features/battle/providers/battle_provider.dart';
import 'package:mythdusk/features/campaign/data/campaign_repository.dart';
import 'package:mythdusk/features/campaign/domain/campaign_models.dart';
import 'package:mythdusk/features/heroes/domain/hero_def.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:mythdusk/features/puzzle/data/board_catalog_repository.dart';
import 'package:mythdusk/features/puzzle/domain/puzzle_engine.dart';

import 'hub_preview.dart';

const _shots = {
  '01_puzzle_combat': ('Match gems. Fuel your skills.', 'knight', 'node_01'),
  '02_hero_skills': ('Your hero. Your strategy.', 'mage', 'node_07'),
  '03_boss_encounter': ('Face powerful bosses.', 'knight', 'node_20'),
  '04_heroes': ('Find your favorite hero.', 'heroes', ''),
  '05_campaign': ('Explore the dusk realms.', 'realms', ''),
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final captureKey = GlobalKey();
  runApp(const MaterialApp(
      home: Scaffold(
          body: Center(
    child: Text('MythDusk local store capture fixture'),
  ))));
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8765);
  debugPrint('STORE_CAPTURE_READY port=8765');
  await for (final request in server) {
    final shot = _shots[request.uri.pathSegments.lastOrNull];
    if (shot == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      continue;
    }
    ProviderContainer? container;
    try {
      // Unmount first so async profile/board state cannot leak between captures.
      runApp(const SizedBox.shrink());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final profile = PlayerProfile(
        selectedHeroId: shot.$2 == 'mage' ? 'mage' : 'knight',
        coins: 760,
        gems: 50,
        firstBattleTutorialDone: true,
        hintsEnabled: false,
        completedNodeIds: {
          for (var i = 1; i <= 19; i++) 'node_${i.toString().padLeft(2, '0')}'
        },
        seenUnlockCelebrationIds: {for (final hero in HeroCatalog.all) hero.id},
      );
      Widget game;
      if (shot.$3.isEmpty) {
        game = await hubPreview(
          fixtureProfile: profile,
          screen: shot.$2 == 'heroes' ? 'heroes' : '',
          realms: shot.$2 == 'realms',
          safePadding: EdgeInsets.zero,
        );
      } else {
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues(
          {'mythdusk_profile_v2': jsonEncode(profile.toJson())},
        );
        final prefs = await SharedPreferences.getInstance();
        final chapter = CampaignChapter.fromJson(jsonDecode(
          await rootBundle.loadString('assets/levels/twilight_road.json'),
        ) as Map<String, dynamic>);
        container = ProviderContainer(overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          campaignChapterProvider.overrideWith((ref) async => chapter),
        ]);
        await container.read(campaignChapterProvider.future);
        await container.read(overlayCatalogProvider.future);
        await container.read(boardTemplateCatalogProvider.future);
        final router = GoRouter(initialLocation: '/battle/${shot.$3}', routes: [
          GoRoute(
              path: '/battle/:id',
              builder: (_, s) => BattleScreen(nodeId: s.pathParameters['id']!)),
          GoRoute(path: '/result', builder: (_, __) => const SizedBox.shrink()),
        ]);
        game = UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
                theme: AppTheme.dusk,
                debugShowCheckedModeBanner: false,
                routerConfig: router));
      }
      final raw = request.uri.queryParameters['raw'] == '1';
      runApp(MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
              backgroundColor: const Color(0xFF0B1C24),
              body: Center(
                  child: FittedBox(
                      child: RepaintBoundary(
                key: captureKey,
                child: SizedBox(
                    width: 540,
                    height: 960,
                    child: Column(children: [
                      if (!raw)
                        Container(
                            height: 112,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                                color: Color(0xFF0B1C24),
                                border: Border(
                                    bottom:
                                        BorderSide(color: Color(0xFFD4A24C)))),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text(shot.$1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'DailySerif',
                                    fontSize: 30,
                                    color: Color(0xFFE6C87A),
                                    height: 1.2))),
                      Expanded(
                          child: MediaQuery(
                              data: MediaQueryData(
                                  size: Size(540, raw ? 960 : 848),
                                  devicePixelRatio: 2),
                              child: game)),
                    ])),
              ))))));
      await Future<void>.delayed(const Duration(seconds: 3));
      // Advance real puzzle actions, without assigning fabricated battle values.
      if (container != null) {
        final notifier = container.read(battleProvider(shot.$3).notifier);
        for (var i = 0; i < 2; i++) {
          final state = container.read(battleProvider(shot.$3));
          final swap = PuzzleEngine.findFirstColorSwap(state.board);
          if (swap == null || state.inputLocked || state.movesLeft <= 1) break;
          notifier.swipeCell(swap.$1, swap.$2);
          for (var tick = 0; tick < 100; tick++) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            if (!container.read(battleProvider(shot.$3)).inputLocked) break;
          }
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await WidgetsBinding.instance.endOfFrame;
      final boundary = captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(bytes!.buffer.asUint8List());
      await request.response.close();
      debugPrint('STORE_CAPTURE_SAVED ${request.uri}');
    } catch (error, stack) {
      debugPrint('$error\n$stack');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(error);
      await request.response.close();
    } finally {
      runApp(const SizedBox.shrink());
      await Future<void>.delayed(const Duration(milliseconds: 100));
      container?.dispose();
    }
  }
}
