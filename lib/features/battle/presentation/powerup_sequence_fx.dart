import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/game_assets.dart';
import '../../puzzle/domain/board_cell.dart';
import '../../puzzle/domain/powerup_event.dart';
import 'board_powerup_fx.dart';

/// A short convergence followed by a reveal at the engine's creation cell.
class PowerupCreationFx extends StatelessWidget {
  const PowerupCreationFx({
    super.key,
    required this.origin,
    required this.sources,
    required this.special,
    required this.cellSize,
    required this.duration,
  });

  final Offset origin;
  final Map<Offset, String> sources;
  final TileSpecial special;
  final double cellSize;
  final Duration duration;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: duration,
          builder: (context, t, _) {
            final pull =
                const Interval(0, 0.46, curve: Curves.easeInCubic).transform(t);
            final reveal = const Interval(0.46, 1).transform(t);
            final flash = math.sin(reveal * math.pi);
            return Stack(clipBehavior: Clip.none, children: [
              if (t < 0.46)
                for (final source in sources.entries)
                  Positioned(
                    left: Offset.lerp(source.key, origin, pull)!.dx -
                        cellSize / 2,
                    top: Offset.lerp(source.key, origin, pull)!.dy -
                        cellSize / 2,
                    width: cellSize,
                    height: cellSize,
                    child: Opacity(
                      opacity: 1 - pull,
                      child: Transform.scale(
                        scale: 1 - pull * 0.7,
                        child: Image.asset(source.value, fit: BoxFit.contain),
                      ),
                    ),
                  ),
              if (t >= 0.46)
                Positioned(
                  left: origin.dx - cellSize / 2,
                  top: origin.dy - cellSize / 2,
                  width: cellSize,
                  height: cellSize,
                  child: Transform.scale(
                    scale: 0.58 + 0.42 * Curves.easeOutBack.transform(reveal),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFE8AB)
                                .withValues(alpha: flash * 0.8),
                            blurRadius: cellSize * 0.35,
                            spreadRadius: cellSize * flash * 0.08,
                          )
                        ],
                      ),
                      child: PowerupTileArt(special: special),
                    ),
                  ),
                ),
            ]);
          },
        ),
      );
}

/// One synchronized charge/release for the swapped pair, using resolved targets.
class PowerupCombinationFx extends StatelessWidget {
  const PowerupCombinationFx({
    super.key,
    required this.combination,
    required this.origin,
    required this.partner,
    required this.targets,
    required this.rocketLaneCenters,
    required this.cellSize,
    required this.duration,
  });

  final PowerupCombination combination;
  final Offset origin;
  final Offset partner;
  final List<Offset> targets;
  final List<(bool, Offset)> rocketLaneCenters;
  final double cellSize;
  final Duration duration;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: duration,
          builder: (context, t, _) {
            final charge =
                const Interval(0, comboRelease, curve: Curves.easeInOutCubic)
                    .transform(t);
            return Stack(children: [
              Positioned.fill(
                  child: CustomPaint(
                      painter: _CombinationPainter(
                combination: combination,
                origin: origin,
                targets: targets,
                rocketLaneCenters: rocketLaneCenters,
                cellSize: cellSize,
                progress: t,
              ))),
              if (t < comboRelease)
                for (final (special, start) in [
                  (combination.first, partner),
                  (combination.second, origin),
                ])
                  Positioned(
                    left: Offset.lerp(start, origin, charge)!.dx - cellSize / 2,
                    top: Offset.lerp(start, origin, charge)!.dy - cellSize / 2,
                    width: cellSize,
                    height: cellSize,
                    child: Transform.scale(
                      scale: 1 + charge * 0.18,
                      child: PowerupTileArt(special: special),
                    ),
                  ),
            ]);
          },
        ),
      );
}

class _CombinationPainter extends CustomPainter {
  const _CombinationPainter({
    required this.combination,
    required this.origin,
    required this.targets,
    required this.rocketLaneCenters,
    required this.cellSize,
    required this.progress,
  });

  final PowerupCombination combination;
  final Offset origin;
  final List<Offset> targets;
  final List<(bool, Offset)> rocketLaneCenters;
  final double cellSize;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final pair = {combination.first, combination.second};
    final fire = pair.contains(TileSpecial.fireball);
    final seeker = pair.contains(TileSpecial.seeker);
    final bomb = pair.contains(TileSpecial.bomb);
    final color = fire
        ? const Color(0xFFFF9975)
        : seeker
            ? const Color(0xFF8CE9E0)
            : const Color(0xFFFFDF8E);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellSize * 0.05;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (progress < comboRelease) {
      final charge = progress / comboRelease;
      paint.color = color.withValues(alpha: charge * 0.85);
      canvas.drawCircle(origin, cellSize * (0.8 - charge * 0.45), paint);
    } else {
      final t = (progress - comboRelease) / (1 - comboRelease);
      final travel = Curves.easeOutCubic.transform(t);
      final fade = 1 - t;
      paint.color = color.withValues(alpha: fade * 0.85);
      final reach = targets.fold<double>(cellSize,
          (value, point) => math.max(value, (point - origin).distance));
      if (rocketLaneCenters.isNotEmpty) {
        final sweep = const Interval(comboRelease, comboRocketTravelEnd)
            .transform(progress);
        final ignition = (1 - t * 4).clamp(0.0, 1.0);
        canvas.drawCircle(origin, cellSize * (0.45 + t),
            Paint()..color = Colors.white.withValues(alpha: ignition * 0.85));
        for (final (horizontal, center) in rocketLaneCenters) {
          final ends = horizontal
              ? [Offset(0, center.dy), Offset(size.width, center.dy)]
              : [Offset(center.dx, 0), Offset(center.dx, size.height)];
          for (final end in ends) {
            paintFlyingRocket(canvas, Offset.lerp(center, end, sweep)!,
                (end - center).direction, cellSize * 1.2, fade);
          }
        }
        canvas.restore();
        return;
      }
      if (bomb || (fire && combination.first == combination.second)) {
        final radius =
            (bomb && !fire ? math.min(reach, cellSize * 2.7) : reach) * travel;
        canvas.drawCircle(origin, radius, paint);
        canvas.drawCircle(origin, radius * 0.7, paint);
      }
      if (!fire && !seeker && pair.any((special) => special.isRocket)) {
        _paintRocketLanes(canvas, size, paint, travel);
      }
      if (fire || seeker) {
        for (final target
            in targets.take(seeker && !fire ? 16 : targets.length)) {
          final delta = target - origin;
          final bend =
              seeker ? Offset(-delta.dy, delta.dx) * 0.22 : Offset.zero;
          Offset point(double p) =>
              Offset.lerp(origin, target, p)! + bend * math.sin(p * math.pi);
          canvas.drawLine(
              point(math.max(0, travel - 0.18)), point(travel), paint);
          canvas.drawCircle(point(travel), cellSize * 0.065 * fade,
              Paint()..color = Colors.white.withValues(alpha: fade));
        }
      }
      // Lighting only resolved cells avoids inventing extra blast coverage.
      for (final target in targets) {
        final arrival = (target - origin).distance / reach * 0.55;
        final glow = (1 - ((t - arrival) / 0.45).abs()).clamp(0.0, 1.0);
        if (glow == 0 || t < arrival) continue;
        final rect = Rect.fromCenter(
            center: target, width: cellSize * 0.85, height: cellSize * 0.85);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(cellSize * 0.15)),
            Paint()..color = color.withValues(alpha: glow * fade * 0.45));
      }
    }
    canvas.restore();
  }

  void _paintRocketLanes(Canvas canvas, Size size, Paint paint, double travel) {
    final rows = <double, List<Offset>>{};
    final cols = <double, List<Offset>>{};
    for (final target in targets) {
      rows.putIfAbsent(target.dy, () => []).add(target);
      cols.putIfAbsent(target.dx, () => []).add(target);
    }
    for (final (horizontal, lanes, extent) in [
      (true, rows, size.width),
      (false, cols, size.height),
    ]) {
      for (final lane in lanes.values) {
        final values = lane
            .map((point) => horizontal ? point.dx : point.dy)
            .toList()
          ..sort();
        if (values.last - values.first < extent * 0.65) continue;
        final start = horizontal
            ? Offset(values.first, lane.first.dy)
            : Offset(lane.first.dx, values.first);
        final end = horizontal
            ? Offset(values.last, lane.first.dy)
            : Offset(lane.first.dx, values.last);
        final center = horizontal
            ? Offset(origin.dx, lane.first.dy)
            : Offset(lane.first.dx, origin.dy);
        for (final destination in [start, end]) {
          paintFlyingRocket(canvas, Offset.lerp(center, destination, travel)!,
              (destination - center).direction, cellSize, paint.color.a);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CombinationPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      origin != oldDelegate.origin ||
      cellSize != oldDelegate.cellSize ||
      targets != oldDelegate.targets ||
      combination != oldDelegate.combination ||
      rocketLaneCenters != oldDelegate.rocketLaneCenters;
}

/// A shared frame keeps the power-up silhouette visible on bright boards.
class PowerupTileArt extends StatelessWidget {
  const PowerupTileArt({super.key, required this.special});

  final TileSpecial special;

  @override
  Widget build(BuildContext context) {
    final asset = GameAssets.powerup(special);
    if (asset == null) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, bounds) {
      final size = math.min(bounds.maxWidth, bounds.maxHeight);
      final accent = switch (special) {
        TileSpecial.bomb => const Color(0xFFFFB75B),
        TileSpecial.fireball => const Color(0xFFFF7851),
        TileSpecial.seeker => const Color(0xFF8CE9E0),
        _ => const Color(0xFFFFE8AB),
      };
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Container(
              width: size * 0.76,
              height: size * 0.76,
              decoration: BoxDecoration(
                color: const Color(0xD9142131),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.7)),
              ),
            ),
          ),
          Image.asset(asset, fit: BoxFit.contain),
          if (special.isRocket)
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                special == TileSpecial.rocketHorizontal
                    ? Icons.swap_horiz
                    : Icons.swap_vert,
                color: accent,
                size: size * 0.35,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
        ],
      );
    });
  }
}
