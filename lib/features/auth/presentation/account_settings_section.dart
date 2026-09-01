import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../firebase/firebase_bootstrap.dart';
import '../data/auth_service.dart';
import '../domain/link_conflict.dart';
import '../providers/auth_provider.dart';

class AccountSettingsSection extends ConsumerWidget {
  const AccountSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authIdentityProvider);
    final identity = auth.asData?.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        if (!FirebaseBootstrap.isReady)
          const Text(
            'Cloud save starts after Firebase console setup and emulators '
            '(FLAVOR=dev). Progress stays on this device until then.',
          )
        else if (identity == null)
          const Text('Connecting guest account…')
        else ...[
          Text(
            identity.isAnonymous
                ? 'Guest · ${identity.uid}'
                : 'Signed in · ${identity.displayName ?? identity.uid}',
          ),
          const SizedBox(height: 8),
          if (identity.isAnonymous) ...[
            if (defaultTargetPlatform == TargetPlatform.iOS)
              FilledButton.tonal(
                onPressed: () => _linkApple(context, ref),
                child: const Text('Continue with Apple'),
              ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => _linkGoogle(context, ref),
              child: const Text('Continue with Google'),
            ),
          ] else
            OutlinedButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: const Text('Sign out'),
            ),
        ],
        const Divider(height: 28, color: MythDuskColors.mist),
      ],
    );
  }

  Future<void> _linkApple(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authServiceProvider).linkApple();
    if (!context.mounted) return;
    await _handle(context, ref, result);
  }

  Future<void> _linkGoogle(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authServiceProvider).linkGoogle();
    if (!context.mounted) return;
    await _handle(context, ref, result);
  }

  Future<void> _handle(
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
      if (choice == LinkConflictChoice.switchToExisting &&
          result.existingCredential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sign in on the existing account from the other device, '
              'or retry after signing out of this guest.',
            ),
          ),
        );
      }
      return;
    }
    final message = switch (result.kind) {
      AuthLinkKind.linked => 'Account linked.',
      AuthLinkKind.signedIn => 'Signed in.',
      AuthLinkKind.cancelled => 'Cancelled.',
      AuthLinkKind.unavailable => 'Firebase is not ready.',
      AuthLinkKind.failed => result.message ?? 'Could not link account.',
      AuthLinkKind.conflict => 'Account conflict.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
