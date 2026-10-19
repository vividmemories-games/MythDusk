import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../firebase/firebase_bootstrap.dart';
import 'remote_config_keys.dart';

/// Live Remote Config reads with client [RemoteConfigKeys.defaults] fallback.
abstract final class RemoteConfigValues {
  static bool boolFor(String key) {
    final fallback = RemoteConfigKeys.defaults[key];
    final defaultBool = fallback is bool ? fallback : false;
    if (!FirebaseBootstrap.isReady) return defaultBool;
    try {
      return FirebaseRemoteConfig.instance.getBool(key);
    } catch (_) {
      return defaultBool;
    }
  }

  static int intFor(String key) {
    final fallback = RemoteConfigKeys.defaults[key];
    final defaultInt = fallback is int ? fallback : 0;
    if (!FirebaseBootstrap.isReady) return defaultInt;
    try {
      return FirebaseRemoteConfig.instance.getInt(key);
    } catch (_) {
      return defaultInt;
    }
  }

  static bool get starterPackEnabled =>
      boolFor(RemoteConfigKeys.starterPackEnabled);

  static bool get defeatContinueEnabled =>
      boolFor(RemoteConfigKeys.defeatContinueEnabled);

  static bool get battlePassEnabled =>
      boolFor(RemoteConfigKeys.battlePassEnabled);

  static bool get useServerSettlement =>
      boolFor(RemoteConfigKeys.useServerSettlement);
}
