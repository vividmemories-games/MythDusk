import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/auth/data/auth_service.dart';
import 'package:mythdusk/firebase/firebase_bootstrap.dart';

void main() {
  test('current is null when Firebase bootstrap never succeeded', () {
    // Release R8 used to leave AuthService touching FirebaseAuth.instance
    // after a failed bootstrap, which white-screened the router redirect.
    expect(FirebaseBootstrap.isReady, isFalse);
    expect(AuthService().current, isNull);
  });

  test('authState emits null when Firebase is not ready', () async {
    expect(FirebaseBootstrap.isReady, isFalse);
    await expectLater(AuthService().authState, emits(isNull));
  });
}
