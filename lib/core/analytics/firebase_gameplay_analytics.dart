import 'package:firebase_analytics/firebase_analytics.dart';

import '../../firebase/firebase_bootstrap.dart';
import 'gameplay_analytics.dart';

class FirebaseGameplayAnalytics implements GameplayAnalytics {
  FirebaseGameplayAnalytics({FirebaseAnalytics? analytics})
      : _analytics = analytics;

  final FirebaseAnalytics? _analytics;

  @override
  void log(String name, [Map<String, Object?> payload = const {}]) {
    if (!FirebaseBootstrap.isReady) return;
    final analytics = _analytics ?? FirebaseAnalytics.instance;
    final params = <String, Object>{
      for (final e in payload.entries)
        if (e.value != null) e.key: e.value!,
    };
    analytics.logEvent(
      name: name,
      parameters: params.isEmpty ? null : params,
    );
  }
}
