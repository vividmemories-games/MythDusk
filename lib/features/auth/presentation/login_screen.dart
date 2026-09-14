import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../firebase/firebase_bootstrap.dart';
import '../providers/auth_provider.dart';
import 'auth_brand_buttons.dart';
import 'auth_link_feedback.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgrounds/bg_login_dusk.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  Image.asset(
                    'assets/images/ui/crest_dusk_ember.png',
                    width: 72,
                    height: 72,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MythDusk',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      shadows: const [
                        Shadow(
                          color: MythDuskColors.ink,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Match tiles. Spend AP. Survive the dusk.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  AuthBrandPanel(
                    children: [
                      if (AuthBrandButtons.showApple) ...[
                        AuthBrandButtons.apple(
                          onPressed: () => _apple(context, ref),
                        ),
                        const SizedBox(height: 10),
                      ],
                      AuthBrandButtons.google(
                        onPressed: () => _google(context, ref),
                      ),
                      const SizedBox(height: 10),
                      AuthBrandButtons.guest(
                        onPressed: () => _guest(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guest(BuildContext context, WidgetRef ref) async {
    if (!FirebaseBootstrap.isReady) {
      context.go('/');
      return;
    }
    await ref.read(authServiceProvider).signInAnonymously();
    if (!context.mounted) return;
    context.go('/');
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
