import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Dart-only emulator stub. Replace via `flutterfire configure` after the
/// Firebase console project exists (see docs/00_Project/Firebase_Console_Checklist.md).
///
/// Real API keys are not required for Auth/Firestore/Functions emulators.
class DefaultFirebaseOptions {
  static const emulatorProjectId = 'mythdusk-emulator';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return emulator;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return emulator;
    }
  }

  static const FirebaseOptions emulator = FirebaseOptions(
    apiKey: 'fake-api-key-for-emulator',
    appId: '1:0:web:emulator',
    messagingSenderId: '0',
    projectId: emulatorProjectId,
    storageBucket: 'mythdusk-emulator.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'fake-api-key-for-emulator',
    appId: '1:0:android:emulator',
    messagingSenderId: '0',
    projectId: emulatorProjectId,
    storageBucket: 'mythdusk-emulator.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'fake-api-key-for-emulator',
    appId: '1:0:ios:emulator',
    messagingSenderId: '0',
    projectId: emulatorProjectId,
    storageBucket: 'mythdusk-emulator.appspot.com',
    iosBundleId: 'com.vividmemories.mythdusk',
  );
}
