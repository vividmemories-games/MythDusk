/// Splash must finish once per process before login/home redirects run.
abstract final class AuthSessionGate {
  static var splashComplete = false;

  static void resetForTest() {
    splashComplete = false;
  }
}
