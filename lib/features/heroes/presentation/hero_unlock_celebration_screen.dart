import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../domain/hero_def.dart';
import '../domain/hero_unlocks.dart';

/// Spell-break unlock celebration: shadowed boss form dissolves into the hero.
class HeroUnlockCelebrationScreen extends ConsumerStatefulWidget {
  const HeroUnlockCelebrationScreen({super.key, required this.heroId});

  final String heroId;

  @override
  ConsumerState<HeroUnlockCelebrationScreen> createState() =>
      _HeroUnlockCelebrationScreenState();
}

class _HeroUnlockCelebrationScreenState
    extends ConsumerState<HeroUnlockCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _marked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
      _markSeen();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markSeen() {
    if (_marked) return;
    _marked = true;
    ref.read(profileProvider.notifier).markUnlockCelebrationSeen(widget.heroId);
  }

  void _continue() {
    _markSeen();
    final pending = ref.read(profileProvider).pendingUnlockCelebrations;
    if (pending.isNotEmpty) {
      context.go('/hero_unlock/${pending.first}');
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final hero = HeroCatalog.tryById(widget.heroId);
    if (hero == null || widget.heroId == HeroUnlocks.mageId) {
      return Scaffold(
        backgroundColor: MythDuskColors.ink,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Unlock unavailable',
                  style: TextStyle(color: MythDuskColors.parchment),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final clears = HeroUnlocks.requiredClears(hero.id);

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _continue,
                  child: const Text('Skip'),
                ),
              ),
              const Spacer(),
              Text(
                'The spell breaks',
                textAlign: TextAlign.center,
                style: textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  color: MythDuskColors.amber,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A captive ally sheds the curse and joins your road.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              Semantics(
                label: '${hero.name} unlocked',
                child: SizedBox(
                  height: 220,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = Curves.easeInOut.transform(_controller.value);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: (1 - t).clamp(0.0, 1.0),
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Color(0xCC0B1C24),
                                BlendMode.srcATop,
                              ),
                              child: Image.asset(
                                GameAssets.enemy('warchief', bossForm: 1),
                                height: 200,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.shield_moon_outlined,
                                  size: 120,
                                  color: MythDuskColors.mist
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: t.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.92 + (0.08 * t),
                              child: Image.asset(
                                GameAssets.hero(hero.id),
                                height: 200,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 120,
                                  color: MythDuskColors.softGold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                hero.name,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: MythDuskColors.parchment,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Unlocked after $clears campaign clears',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: MythDuskColors.softGold,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _continue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text('Welcome ${hero.name}'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  _markSeen();
                  context.go('/heroes');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: MythDuskColors.parchment,
                  side: const BorderSide(color: MythDuskColors.mist),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('View heroes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
