import 'dart:math' as math;

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
  final _overlayKey = GlobalKey(debugLabel: 'match_collect_overlay');
  final _active = <_Flight>[];
  var _seq = 0;
  var _spawnGen = 0;

  @override
  void dispose() {
    _spawnGen++;
    for (final f in _active) {
      f.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _spawn(List<MatchCollectParticle> particles) async {
    final capped = capMatchCollectParticles(particles);
    // Consume the queue immediately so cascade waves can enqueue cleanly.
    ref.read(matchCollectFlightsProvider.notifier).state = const [];
    if (capped.isEmpty) return;

    final gen = ++_spawnGen;
    final targets = ref.read(resourceFlyTargetsProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    for (var i = 0; i < capped.length; i++) {
      if (!mounted || gen != _spawnGen) return;
      final p = capped[i];
      final end = targets.globalCenterOf(targets.resourceKeys[p.resourceId]!);
      if (end == null) continue;

      if (!reduceMotion && i > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 22));
        if (!mounted || gen != _spawnGen) return;
      }

      final controller = AnimationController(
        vsync: this,
        duration: reduceMotion
            ? const Duration(milliseconds: 1)
            : Duration(milliseconds: 440 + (i % 3) * 20),
      );
      final flight = _Flight(
        id: ++_seq,
        particle: p,
        end: end,
        arcLift: 28.0 + (i % 4) * 10.0,
        controller: controller,
      );
      _active.add(flight);
      if (mounted) setState(() {});
      controller.forward().whenComplete(() {
        if (!mounted) return;
        final bumps = Map<String, int>.from(ref.read(hudResourceBumpProvider));
        bumps[p.resourceId] = (bumps[p.resourceId] ?? 0) + 1;
        ref.read(hudResourceBumpProvider.notifier).state = bumps;
        setState(() {
          _active.remove(flight);
          flight.controller.dispose();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<MatchCollectParticle>>(matchCollectFlightsProvider,
        (prev, next) {
      if (next.isNotEmpty) _spawn(next);
    });

    // Keep an expanded Stack so global→local uses a stable full-screen box.
    return IgnorePointer(
      child: Stack(
        key: _overlayKey,
        fit: StackFit.expand,
        children: [
          for (final flight in _active)
            _FlightShard(
              key: ValueKey(flight.id),
              flight: flight,
              overlayKey: _overlayKey,
            ),
        ],
      ),
    );
  }
}

/// Positions one shard; [Positioned] is the build root so Stack parent-data applies.
class _FlightShard extends StatefulWidget {
  const _FlightShard({
    super.key,
    required this.flight,
    required this.overlayKey,
  });

  final _Flight flight;
  final GlobalKey overlayKey;

  @override
  State<_FlightShard> createState() => _FlightShardState();
}

class _FlightShardState extends State<_FlightShard> {
  @override
  void initState() {
    super.initState();
    widget.flight.controller.addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant _FlightShard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flight.controller != widget.flight.controller) {
      oldWidget.flight.controller.removeListener(_onTick);
      widget.flight.controller.addListener(_onTick);
    }
  }

  @override
  void dispose() {
    widget.flight.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final box =
        widget.overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return const SizedBox.shrink();
    }

    final t = Curves.easeInOutCubic.transform(widget.flight.controller.value);
    final global = matchCollectFlightGlobal(
      startGlobal: widget.flight.particle.startGlobal,
      endGlobal: widget.flight.end,
      t: t,
      arcLift: widget.flight.arcLift,
    );
    final pos = box.globalToLocal(global);
    final scale = 1.05 - 0.5 * t;
    final opacity = (1.0 - t * 0.12).clamp(0.0, 1.0);

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
            gemAssetForResource(widget.flight.particle.resourceId),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// Global flight path used by the overlay (lerp + vertical arc).
Offset matchCollectFlightGlobal({
  required Offset startGlobal,
  required Offset endGlobal,
  required double t,
  required double arcLift,
}) {
  final straight = Offset.lerp(startGlobal, endGlobal, t)!;
  final arc = math.sin(t * math.pi) * arcLift;
  return Offset(straight.dx, straight.dy - arc);
}

class _Flight {
  _Flight({
    required this.id,
    required this.particle,
    required this.end,
    required this.arcLift,
    required this.controller,
  });

  final int id;
  final MatchCollectParticle particle;
  final Offset end;
  final double arcLift;
  final AnimationController controller;
}
