import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_flavor.dart';
import '../core/config/remote_config_keys.dart';
import 'firebase_options.dart';

/// Firebase init is optional. The game stays on local profile until the
/// console project exists and emulators (dev) or real options (prod) work.
abstract final class FirebaseBootstrap {
  static var _ready = false;
  static var _attempted = false;

  static bool get isReady => _ready;

  /// Dev flavor talks to emulators. Prod waits for a real Project ID via
  /// `--dart-define=FIREBASE_PROJECT_ID=...` after console setup.
  static bool get shouldInitialize {
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if (projectId.isNotEmpty) return true;
    return AppFlavor.isDev;
  }

  static Future<void> initialize() async {
    if (_attempted) return;
    _attempted = true;
    if (!shouldInitialize) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (AppFlavor.isDev) {
        await _connectEmulators();
      }
      await _activateObservability();
      _ready = true;
    } catch (error, stack) {
      debugPrint('Firebase bootstrap skipped: $error');
      debugPrint('$stack');
      _ready = false;
    }
  }

  static Future<void> _connectEmulators() async {
    const host = String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: '127.0.0.1',
    );
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  }

  static Future<void> _activateObservability() async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (!AppFlavor.isDev) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (!AppFlavor.isDev) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };

    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AppFlavor.isDev
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider:
            AppFlavor.isDev ? AppleProvider.debug : AppleProvider.appAttest,
      );
    } catch (error) {
      debugPrint('App Check skipped: $error');
    }

    try {
      final remote = FirebaseRemoteConfig.instance;
      await remote.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              AppFlavor.isDev ? Duration.zero : const Duration(hours: 1),
        ),
      );
      await remote.setDefaults(RemoteConfigKeys.defaults);
      await remote.fetchAndActivate();
    } catch (error) {
      debugPrint('Remote Config skipped: $error');
    }
  }
}
