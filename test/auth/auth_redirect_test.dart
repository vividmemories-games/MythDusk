import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/auth/domain/auth_redirect.dart';

void main() {
  test('holds on splash until the gate completes', () {
    expect(
      authRedirect(
        location: '/splash',
        splashComplete: false,
        firebaseReady: true,
        signedIn: false,
      ),
      isNull,
    );
    expect(
      authRedirect(
        location: '/',
        splashComplete: false,
        firebaseReady: true,
        signedIn: false,
      ),
      '/splash',
    );
  });

  test('sends signed-out users to login after splash', () {
    expect(
      authRedirect(
        location: '/',
        splashComplete: true,
        firebaseReady: true,
        signedIn: false,
      ),
      '/login',
    );
    expect(
      authRedirect(
        location: '/login',
        splashComplete: true,
        firebaseReady: true,
        signedIn: false,
      ),
      isNull,
    );
  });

  test('sends signed-in users home from splash or login', () {
    expect(
      authRedirect(
        location: '/login',
        splashComplete: true,
        firebaseReady: true,
        signedIn: true,
      ),
      '/',
    );
  });

  test('skips login when Firebase is not ready', () {
    expect(
      authRedirect(
        location: '/splash',
        splashComplete: true,
        firebaseReady: false,
        signedIn: false,
      ),
      '/',
    );
  });
}
