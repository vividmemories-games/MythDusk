class AuthIdentity {
  const AuthIdentity({
    required this.uid,
    required this.isAnonymous,
    this.displayName,
    this.providers = const [],
  });

  final String uid;
  final bool isAnonymous;
  final String? displayName;
  final List<String> providers;

  bool get canLinkApple => isAnonymous || !providers.contains('apple.com');
  bool get canLinkGoogle => isAnonymous || !providers.contains('google.com');
}
