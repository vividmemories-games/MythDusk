/// Pure gate for splash → login → home. Keep UI out of this.
String? authRedirect({
  required String location,
  required bool splashComplete,
  required bool firebaseReady,
  required bool signedIn,
}) {
  if (!splashComplete) {
    return location == '/splash' ? null : '/splash';
  }
  if (!firebaseReady) {
    if (location == '/splash' || location == '/login') return '/';
    return null;
  }
  if (!signedIn) {
    return location == '/login' ? null : '/login';
  }
  if (location == '/splash' || location == '/login') return '/';
  return null;
}
