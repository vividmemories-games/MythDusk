import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'match_collect_fx.dart';

/// Full-screen overlay that flies matched gem shards into HUD resource piles.
class MatchCollectOverlay extends ConsumerStatefulWidget {
  const MatchCollectOverlay({super.key});

  @override
  ConsumerState<MatchCollectOverlay> createState() =>
      _MatchCollectOverlayState();
}

class _MatchCollectOverlayState extends ConsumerState<MatchCollectOverlay>
    with TickerProviderStateMixin {
  final _active = <_Flight>[];
  var _seq = 0;

  @override
  void dispose() {
    for (final f in _active) {
      f.controller.dispose();
    }
    super.dispose();
  }

  void _spawn(List<MatchCollectParticle> particles) {
    if (particles.isEmpty) return;
    final targets = ref.read(resourceFlyTargetsProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    for (final p in particles) {
      final end = targets.globalCenterOf(targets.resourceKeys[p.resourceId]!);
      if (end == null) continue;
      final controller = AnimationController(
        vsync: this,
        duration: reduceMotion
            ? const Duration(milliseconds: 1)
            : const Duration(milliseconds: 420),
      );
      final flight = _Flight(
        id: ++_seq,
        particle: p,
        end: end,
        controller: controller,
      );
      _active.add(flight);
      controller.forward().whenComplete(() {
        if (!mounted) return;
        setState(() {
          _active.remove(flight);
          flight.controller.dispose();
        });
      });
    }
    if (mounted) setState(() {});
    ref.read(matchCollectFlightsProvider.notifier).state = const [];
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<MatchCollectParticle>>(matchCollectFlightsProvider,
        (prev, next) {
      if (next.isNotEmpty) _spawn(next);
    });

    if (_active.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final flight in _active)
            AnimatedBuilder(
              animation: flight.controller,
              builder: (context, _) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null || !box.hasSize) {
                  return const SizedBox.shrink();
                }
                final t =
                    Curves.easeInOutCubic.transform(flight.controller.value);
                final start = flight.particle.startGlobal;
                final global = Offset.lerp(start, flight.end, t)!;
                final pos = box.globalToLocal(global);
                final scale = 1.0 - 0.45 * t;
                final opacity = (1.0 - t * 0.15).clamp(0.0, 1.0);
                return Positioned(
                  left: pos.dx - 14,
                  top: pos.dy - 14,
                  width: 28,
                  height: 28,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Image.asset(
                        gemAssetForResource(flight.particle.resourceId),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Flight {
  _Flight({
    required this.id,
    required this.particle,
    required this.end,
    required this.controller,
  });

  final int id;
  final MatchCollectParticle particle;
  final Offset end;
  final AnimationController controller;
}
