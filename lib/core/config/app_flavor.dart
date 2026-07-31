import 'package:flutter/foundation.dart';

/// Build flavor from `--dart-define=FLAVOR=dev|prod` (default prod).
abstract final class AppFlavor {
  static const name = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

  static bool get isDev => name == 'dev';

  /// QA controls (unlock-all, pin edit, weekly day override).
  /// Shown in debug builds or when FLAVOR=dev.
  static bool get showQaTools => isDev || kDebugMode;
}
