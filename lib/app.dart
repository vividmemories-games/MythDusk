import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase/server_settlement.dart';

class MythDuskApp extends ConsumerWidget {
  const MythDuskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
