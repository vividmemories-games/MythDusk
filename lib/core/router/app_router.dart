import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/battle/presentation/battle_result_screen.dart';
import '../../features/battle/presentation/battle_screen.dart';
import '../../features/campaign/presentation/briefing_screen.dart';
import '../../features/campaign/presentation/campaign_screen.dart';
import '../../features/campaign/presentation/chapter_select_screen.dart';
import '../../features/heroes/presentation/hero_unlock_celebration_screen.dart';
import '../../features/heroes/presentation/heroes_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/shop_screen.dart';
import '../../features/weekly/presentation/weekly_screen.dart';
import '../../shared/presentation/content_error_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/heroes',
        name: 'heroes',
        builder: (context, state) => const HeroesScreen(),
      ),
      GoRoute(
        path: '/hero_unlock/:heroId',
        name: 'hero_unlock',
        builder: (context, state) {
          final heroId = state.pathParameters['heroId']!;
          return HeroUnlockCelebrationScreen(heroId: heroId);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/shop',
        name: 'shop',
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/chapters',
        name: 'chapters',
        builder: (context, state) => const ChapterSelectScreen(),
      ),
      GoRoute(
        path: '/campaign',
        name: 'campaign',
        builder: (context, state) => const CampaignScreen(),
      ),
      GoRoute(
        path: '/briefing/:nodeId',
        name: 'briefing',
        builder: (context, state) {
          final nodeId = state.pathParameters['nodeId']!;
          return BriefingScreen(nodeId: nodeId);
        },
      ),
      GoRoute(
        path: '/weekly',
        name: 'weekly',
        builder: (context, state) => const WeeklyScreen(),
      ),
      GoRoute(
        path: '/battle/:nodeId',
        name: 'battle',
        builder: (context, state) {
          final nodeId = state.pathParameters['nodeId']!;
          return BattleScreen(nodeId: nodeId);
        },
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) {
          final args = state.extra;
          if (args is! BattleResultArgs) {
            return const ContentErrorScreen(
              title: 'Battle result unavailable',
              message: 'This result link is incomplete or no longer valid.',
            );
          }
          return BattleResultScreen(args: args);
        },
      ),
    ],
  );
});
