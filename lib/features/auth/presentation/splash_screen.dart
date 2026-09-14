import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../firebase/firebase_bootstrap.dart';
import '../domain/auth_session_gate.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _finish();
  }

  Future<void> _finish() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    AuthSessionGate.splashComplete = true;
    if (!FirebaseBootstrap.isReady) {
      context.go('/');
      return;
    }
    final user = ref.read(authServiceProvider).current;
    context.go(user == null ? '/login' : '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/backgrounds/bg_splash_dusk.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 36),
                Image.asset(
                  'assets/images/ui/crest_dusk_ember.png',
                  width: 96,
                  height: 96,
                ),
                const SizedBox(height: 12),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
