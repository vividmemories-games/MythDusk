import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../firebase/firebase_bootstrap.dart';
import '../domain/auth_identity.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _injected = auth;

  final FirebaseAuth? _injected;

  FirebaseAuth get _auth {
    final injected = _injected;
    if (injected != null) return injected;
    return FirebaseAuth.instance;
  }

  Stream<AuthIdentity?> get authState {
    if (!FirebaseBootstrap.isReady) {
      return Stream<AuthIdentity?>.value(null);
    }
    return _auth.authStateChanges().map(_mapUser);
  }

  AuthIdentity? get current => _mapUser(_auth.currentUser);

  Future<AuthIdentity?> signInAnonymously() async {
    if (!FirebaseBootstrap.isReady) return null;
    final cred = await _auth.signInAnonymously();
    return _mapUser(cred.user);
  }

  Future<AuthLinkResult> linkApple() async {
    if (!FirebaseBootstrap.isReady) {
      return const AuthLinkResult.unavailable();
    }
    try {
      final rawNonce = _randomNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final oauth = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: rawNonce,
        accessToken: apple.authorizationCode,
      );
      return _linkOrSignIn(oauth);
    } on FirebaseAuthException catch (error) {
      return AuthLinkResult.fromFirebase(error);
    } catch (error) {
      debugPrint('Apple link failed: $error');
      return AuthLinkResult.failed(error.toString());
    }
  }

  Future<AuthLinkResult> linkGoogle() async {
    if (!FirebaseBootstrap.isReady) {
      return const AuthLinkResult.unavailable();
    }
    try {
      final google = GoogleSignIn();
      final account = await google.signIn();
      if (account == null) {
        return const AuthLinkResult.cancelled();
      }
      final tokens = await account.authentication;
      final oauth = GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
      return _linkOrSignIn(oauth);
    } on FirebaseAuthException catch (error) {
      return AuthLinkResult.fromFirebase(error);
    } catch (error) {
      debugPrint('Google link failed: $error');
      return AuthLinkResult.failed(error.toString());
    }
  }

  Future<void> signOut() async {
    if (!FirebaseBootstrap.isReady) return;
    await _auth.signOut();
  }

  Future<AuthLinkResult> _linkOrSignIn(AuthCredential credential) async {
    final user = _auth.currentUser;
    try {
      if (user != null && user.isAnonymous) {
        final linked = await user.linkWithCredential(credential);
        return AuthLinkResult.linked(_mapUser(linked.user)!);
      }
      final signed = await _auth.signInWithCredential(credential);
      return AuthLinkResult.signedIn(_mapUser(signed.user)!);
    } on FirebaseAuthException catch (error) {
      return AuthLinkResult.fromFirebase(error);
    }
  }

  static AuthIdentity? _mapUser(User? user) {
    if (user == null) return null;
    return AuthIdentity(
      uid: user.uid,
      isAnonymous: user.isAnonymous,
      displayName: user.displayName,
      providers: [
        for (final info in user.providerData)
          if (info.providerId.isNotEmpty) info.providerId,
      ],
    );
  }

  static String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }
}

class AuthLinkResult {
  const AuthLinkResult._({
    required this.kind,
    this.identity,
    this.message,
    this.existingCredential,
  });

  const AuthLinkResult.linked(AuthIdentity identity)
      : this._(kind: AuthLinkKind.linked, identity: identity);

  const AuthLinkResult.signedIn(AuthIdentity identity)
      : this._(kind: AuthLinkKind.signedIn, identity: identity);

  const AuthLinkResult.cancelled() : this._(kind: AuthLinkKind.cancelled);

  const AuthLinkResult.unavailable() : this._(kind: AuthLinkKind.unavailable);

  const AuthLinkResult.failed(String message)
      : this._(kind: AuthLinkKind.failed, message: message);

  factory AuthLinkResult.fromFirebase(FirebaseAuthException error) {
    if (error.code == 'credential-already-in-use' ||
        error.code == 'account-exists-with-different-credential') {
      return AuthLinkResult._(
        kind: AuthLinkKind.conflict,
        message: error.message,
        existingCredential: error.credential,
      );
    }
    return AuthLinkResult.failed(error.message ?? error.code);
  }

  final AuthLinkKind kind;
  final AuthIdentity? identity;
  final String? message;
  final AuthCredential? existingCredential;

  bool get isConflict => kind == AuthLinkKind.conflict;
}

enum AuthLinkKind { linked, signedIn, cancelled, unavailable, failed, conflict }
