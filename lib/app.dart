import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class MythDuskApp extends ConsumerWidget {
  const MythDuskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MythDusk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dusk,
      routerConfig: router,
    );
  }
}
