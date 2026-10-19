import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/features/auth/data/auth_service.dart';

void main() {
  group('AuthLinkResult.fromFirebase', () {
    test('maps credential-already-in-use to conflict with credential', () {
      final credential = GoogleAuthProvider.credential(
        idToken: 'id-token',
        accessToken: 'access-token',
      );
      final result = AuthLinkResult.fromFirebase(
        FirebaseAuthException(
          code: 'credential-already-in-use',
          message: 'already used',
          credential: credential,
        ),
      );

      expect(result.isConflict, isTrue);
      expect(result.existingCredential, same(credential));
    });

    test('maps account-exists-with-different-credential to conflict', () {
      final result = AuthLinkResult.fromFirebase(
        FirebaseAuthException(
          code: 'account-exists-with-different-credential',
          message: 'exists',
        ),
      );

      expect(result.isConflict, isTrue);
      expect(result.kind, AuthLinkKind.conflict);
    });

    test('maps other codes to failed', () {
      final result = AuthLinkResult.fromFirebase(
        FirebaseAuthException(
            code: 'network-request-failed', message: 'offline'),
      );

      expect(result.isConflict, isFalse);
      expect(result.kind, AuthLinkKind.failed);
      expect(result.message, 'offline');
    });
  });
}
