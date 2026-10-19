import 'package:flutter/foundation.dart';

/// Single production target (no separate `dev` / `prod` flavors).
///
/// QA controls appear only in debug builds. Release/profile never show them.
abstract final class AppFlavor {
  static const name = 'prod';

  /// QA controls (unlock-all, pin edit, weekly day override, QA IAP claims).
  static bool get showQaTools => kDebugMode;
}
