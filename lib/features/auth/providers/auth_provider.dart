import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firebase/firebase_bootstrap.dart';
import '../data/auth_service.dart';
import '../domain/auth_identity.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authIdentityProvider = StreamProvider<AuthIdentity?>((ref) {
  if (!FirebaseBootstrap.isReady) {
    return Stream<AuthIdentity?>.value(null);
  }
  return ref.watch(authServiceProvider).authState;
});
