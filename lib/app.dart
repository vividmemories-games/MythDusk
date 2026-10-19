import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/analytics/analytics_providers.dart';
import 'core/analytics/gameplay_analytics.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase/server_settlement.dart';

class MythDuskApp extends ConsumerStatefulWidget {
  const MythDuskApp({super.key});

  @override
  ConsumerState<MythDuskApp> createState() => _MythDuskAppState();
}

class _MythDuskAppState extends ConsumerState<MythDuskApp> {
  var _loggedSessionStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loggedSessionStart) return;
      _loggedSessionStart = true;
      ref.read(gameplayAnalyticsProvider).log(
            GameplayAnalyticsEvents.sessionStart,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep auth→ensureUser→hydrate alive for the app lifetime.
    ref.watch(authProfileSyncProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MythDusk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dusk,
      routerConfig: router,
    );
  }
}
