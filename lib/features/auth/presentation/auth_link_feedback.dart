import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_service.dart';
import '../domain/link_conflict.dart';
import '../providers/auth_provider.dart';

Future<void> showAuthLinkFeedback(
  BuildContext context,
  WidgetRef ref,
  AuthLinkResult result,
) async {
  if (result.isConflict) {
    final choice = await showDialog<LinkConflictChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account already exists'),
        content: const Text(
          'This Apple/Google account already has a MythDusk cloud save. '
          'Keep this guest progress, or switch to the existing cloud '
          'profile. Currencies are never merged.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, LinkConflictChoice.keepGuest),
            child: const Text('Keep guest'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              LinkConflictChoice.switchToExisting,
            ),
            child: const Text('Switch to cloud'),
          ),
        ],
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == LinkConflictChoice.keepGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kept guest progress on this device.')),
      );
      return;
    }
    if (choice == LinkConflictChoice.switchToExisting) {
      final credential = result.existingCredential;
      if (credential == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not switch automatically. Use Back to login, then '
              'Continue with Google or Apple.',
            ),
          ),
        );
        return;
      }
      final switched = await ref
          .read(authServiceProvider)
          .switchToExistingAccount(credential);
      if (!context.mounted) return;
      _showAuthSnackBar(context, switched);
    }
    return;
  }
  _showAuthSnackBar(context, result);
}

void _showAuthSnackBar(BuildContext context, AuthLinkResult result) {
  final message = switch (result.kind) {
    AuthLinkKind.linked => 'Account linked.',
    AuthLinkKind.signedIn => 'Signed in.',
    AuthLinkKind.cancelled => 'Cancelled.',
    AuthLinkKind.unavailable => 'Firebase is not ready.',
    AuthLinkKind.failed => result.message ?? 'Could not link account.',
    AuthLinkKind.conflict =>
      'Could not switch accounts. Use Back to login, then Continue with '
          'Google or Apple.',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
