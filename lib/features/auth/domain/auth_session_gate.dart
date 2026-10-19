import 'package:flutter/foundation.dart';

/// Splash must finish once per process before login/home redirects run.
abstract final class AuthSessionGate {
  static var splashComplete = false;

  /// When true, [authRedirect] stays put so signOut→signIn switches do not
  /// flash the login screen.
  static var suppressAuthRedirect = false;

  /// Bumped when a silent transition ends so GoRouter re-evaluates.
  static final transitionTick = ValueNotifier<int>(0);

  static void beginSilentAuthTransition() {
    suppressAuthRedirect = true;
  }

  static void endSilentAuthTransition() {
    suppressAuthRedirect = false;
    transitionTick.value++;
  }

  static void resetForTest() {
    splashComplete = false;
    suppressAuthRedirect = false;
  }
}
