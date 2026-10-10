// Deterministic visual QA entry point; never used by the production app.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mythdusk/core/theme/app_theme.dart';
import 'package:mythdusk/features/daily/presentation/daily_screen.dart';
import 'package:mythdusk/features/daily/providers/daily_providers.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // This isolated visual fixture deliberately avoids real profile storage.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final screenKey = GlobalKey();
  runApp(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        dailyEffectiveNowProvider.overrideWithValue(DateTime(2026, 10,
            const int.fromEnvironment('DAILY_QA_DAY', defaultValue: 5))),
      ],
      child: MaterialApp(
          theme: AppTheme.dusk,
          debugShowCheckedModeBanner: false,
          home: DailyScreen(key: screenKey))));
  if (const bool.fromEnvironment('DAILY_QA_SCROLL_BOTTOM')) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void scroll(Element element) {
        if (element is StatefulElement && element.state is ScrollableState) {
          final position = (element.state as ScrollableState).position;
          position.jumpTo(position.maxScrollExtent);
        }
        element.visitChildElements(scroll);
      }

      (screenKey.currentContext as Element?)?.visitChildElements(scroll);
    });
  }
}
