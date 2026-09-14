import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../firebase/firebase_bootstrap.dart';
import '../providers/auth_provider.dart';
import 'auth_brand_buttons.dart';
import 'auth_link_feedback.dart';

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
            'Cloud save starts after Firebase is ready. Progress stays on '
            'this device until then.',
          )
        else if (identity == null)
          const Text('Connecting account…')
        else
          AuthBrandPanel(
            children: [
              Text(
                identity.isAnonymous
                    ? 'Playing as Guest'
                    : 'Signed in as ${identity.displayName ?? 'Wanderer'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                identity.isAnonymous
                    ? 'Link a brand account to keep this save in the cloud.'
                    : 'Cloud save is on. Sign out returns you to login.',
              ),
              const SizedBox(height: 14),
              if (identity.isAnonymous) ...[
                if (AuthBrandButtons.showApple) ...[
                  AuthBrandButtons.apple(
                    onPressed: () => _apple(context, ref),
                    label: 'Sign in with Apple',
                  ),
                  const SizedBox(height: 10),
                ],
                AuthBrandButtons.google(
                  onPressed: () => _google(context, ref),
                  label: 'Sign in with Google',
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MythDuskColors.parchment,
                    side: const BorderSide(color: MythDuskColors.softGold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    identity.isAnonymous ? 'Back to login' : 'Sign out',
                  ),
                ),
              ),
            ],
          ),
        const Divider(height: 28, color: MythDuskColors.mist),
      ],
    );
  }

  Future<void> _apple(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authServiceProvider).linkApple();
    if (!context.mounted) return;
    await showAuthLinkFeedback(context, ref, result);
  }

  Future<void> _google(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authServiceProvider).linkGoogle();
    if (!context.mounted) return;
    await showAuthLinkFeedback(context, ref, result);
  }
}
