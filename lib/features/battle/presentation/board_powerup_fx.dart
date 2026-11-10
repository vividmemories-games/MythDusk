import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../puzzle/domain/board_cell.dart';
import '../../puzzle/domain/powerup_event.dart';
import '../domain/battle_state.dart';

/// Board-space effects keep rockets and shockwaves aligned with their cells.
const powerupActivation = 0.18;
const powerupTravelEnd = 0.72;

const boardCellGap = 3.0;
const comboRelease = 0.35;
const comboRocketTravelEnd = 0.79;

bool isBombRocketCombo(PowerupCombination combo) =>
    (combo.first == TileSpecial.bomb && combo.second.isRocket) ||
    (combo.second == TileSpecial.bomb && combo.first.isRocket);

double gemPopProgress(double delay) => delay + (1 - delay) * 0.28;

/// Shared board geometry and timing for gem pops and their resource shards.
class BoardClearTiming {
  BoardClearTiming(this.battle, this.size)
      : cellWidth = (size.width - boardCellGap * (battle.board.width - 1)) /
            battle.board.width,
        cellHeight = (size.height - boardCellGap * (battle.board.height - 1)) /
            battle.board.height,
        specials = battle.clearingCells
            .where((cell) => battle.board.at(cell.$1, cell.$2).hasSpecial)
            .toList();

  final BattleState battle;
  final Size size;
  final double cellWidth;
  final double cellHeight;
  final List<(int, int)> specials;

  Offset center((int, int) cell) => Offset(
        cell.$2 * (cellWidth + boardCellGap) + cellWidth / 2,
        cell.$1 * (cellHeight + boardCellGap) + cellHeight / 2,
      );

  double delayFor((int, int) cell) {
    final combo = battle.activeCascadeStep?.combination;
    if (combo != null) {
      if (!isBombRocketCombo(combo)) return comboRelease;
      final origin = center(combo.at);
      final target = center(cell);
      final onRow = (combo.at.$1 - cell.$1).abs() <= 1;
      final onColumn = (combo.at.$2 - cell.$2).abs() <= 1;
      final x = onRow ? _laneFraction(origin.dx, target.dx, size.width) : 1.0;
      final y =
          onColumn ? _laneFraction(origin.dy, target.dy, size.height) : 1.0;
      return comboRelease +
          (comboRocketTravelEnd - comboRelease) * math.min(x, y);
    }

    var earliest = double.infinity;
    for (final source in specials) {
      final tile = battle.board.at(source.$1, source.$2).special;
      if (tile == TileSpecial.bomb &&
          ((source.$1 - cell.$1).abs() > 1 ||
              (source.$2 - cell.$2).abs() > 1)) {
        continue;
      }
      final delay = powerupClearDelay(
        special: tile,
        origin: center(source),
        target: center(cell),
        boardSize: size,
        cellSize: math.min(cellWidth, cellHeight),
      );
      if (delay > 0) earliest = math.min(earliest, delay);
    }
    return earliest.isFinite ? earliest : 0;
  }
}

double _laneFraction(double origin, double target, double extent) {
  final delta = target - origin;
  final reach = delta < 0 ? origin : extent - origin;
  return reach <= 0 ? 0 : (delta.abs() / reach).clamp(0.0, 1.0);
}

double powerupClearDelay({
  required TileSpecial special,
  required Offset origin,
  required Offset target,
  required Size boardSize,
  required double cellSize,
}) {
  final delta = target - origin;
  double distance;
  if (special.isRocket) {
    final horizontal = special == TileSpecial.rocketHorizontal;
    final along = horizontal ? delta.dx : delta.dy;
    final across = horizontal ? delta.dy : delta.dx;
    if (across.abs() > 0.01) return 0;
    final start = horizontal ? origin.dx : origin.dy;
    final extent = horizontal ? boardSize.width : boardSize.height;
    distance = _laneFraction(start, start + along, extent);
  } else if (special == TileSpecial.bomb) {
    if (delta.dx.abs() >= cellSize * 1.8 || delta.dy.abs() >= cellSize * 1.8) {
      return 0;
    }
    distance = (delta.distance / cellSize - 0.12) / 1.8;
  } else if (special == TileSpecial.seeker || special == TileSpecial.fireball) {
    return delta == Offset.zero ? powerupActivation : powerupTravelEnd;
  } else {
    return 0;
  }
  return powerupActivation +
      (powerupTravelEnd - powerupActivation) * distance.clamp(0.0, 1.0);
}

class BoardPowerupFx extends StatefulWidget {
  const BoardPowerupFx({
    super.key,
    required this.special,
    required this.origin,
    required this.targets,
    required this.cellSize,
    required this.duration,
    this.activationDelay = powerupActivation,
  });

  final TileSpecial special;
  final Offset origin;
  final List<Offset> targets;
  final double cellSize;
  final Duration duration;
  final double activationDelay;

  @override
  State<BoardPowerupFx> createState() => _BoardPowerupFxState();
}

class _BoardPowerupFxState extends State<BoardPowerupFx>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _PowerupPainter(
              special: widget.special,
              origin: widget.origin,
              targets: widget.targets,
              cellSize: widget.cellSize,
              progress: _controller.value,
              activationDelay: widget.activationDelay,
            ),
          ),
        ),
      );
}

class _PowerupPainter extends CustomPainter {
  const _PowerupPainter({
    required this.special,
    required this.origin,
    required this.targets,
    required this.cellSize,
    required this.progress,
    required this.activationDelay,
  });

  final TileSpecial special;
  final Offset origin;
  final List<Offset> targets;
  final double cellSize;
  final double progress;
  final double activationDelay;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < activationDelay) {
      final charge = progress / activationDelay;
      canvas.drawCircle(
        origin,
        cellSize * (0.45 - charge * 0.15),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cellSize * 0.07
          ..color = Colors.white.withValues(alpha: charge * 0.85),
      );
      return;
    }
    final t =
        ((progress - activationDelay) / (1 - activationDelay)).clamp(0.0, 1.0);
    final flight = ((progress - activationDelay) /
            (math.max(powerupTravelEnd, activationDelay + 0.20) -
                activationDelay))
        .clamp(0.0, 1.0);
    final travel = special.isRocket || special == TileSpecial.bomb
        ? flight
        : Curves.easeInOut.transform(flight);
    final fade = 1 - t;
    final color = switch (special) {
      TileSpecial.bomb => const Color(0xFFFFB75B),
      TileSpecial.fireball => const Color(0xFFFF7851),
      TileSpecial.seeker => const Color(0xFF8CE9E0),
      _ => const Color(0xFFFFE8AB),
    };
    final paint = Paint()
      ..color = color.withValues(alpha: fade * 0.8)
      ..strokeWidth = cellSize * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (special.isRocket) {
      final horizontal = special == TileSpecial.rocketHorizontal;
      final ends = horizontal
          ? [Offset(0, origin.dy), Offset(size.width, origin.dy)]
          : [Offset(origin.dx, 0), Offset(origin.dx, size.height)];
      for (final end in ends) {
        final head = Offset.lerp(origin, end, travel)!;
        paintFlyingRocket(
            canvas, head, (end - origin).direction, cellSize, fade);
      }
    } else if (special == TileSpecial.bomb) {
      final radius = cellSize * (0.12 + travel * 1.8);
      canvas.drawCircle(origin, radius, paint);
      canvas.drawCircle(
          origin, radius * 0.72, paint..strokeWidth = cellSize * 0.025);
      for (var i = 0; i < 10; i++) {
        final angle = i * math.pi * 2 / 10;
        final direction = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(origin + direction * radius * 0.8,
            origin + direction * radius * 1.12, paint);
      }
    } else {
      // Use actual resolved clear cells so effect paths agree with gameplay.
      final destinations = special == TileSpecial.seeker
          ? targets
              .where((target) => (target - origin).distance >= cellSize * 0.2)
              .take(8)
          : targets;
      var i = 0;
      for (final target in destinations) {
        if ((target - origin).distance < cellSize * 0.2) continue;
        final delta = target - origin;
        final bend = special == TileSpecial.seeker
            ? Offset(-delta.dy, delta.dx) * (i.isEven ? 0.22 : -0.22)
            : Offset.zero;
        final head = Offset.lerp(origin, target, travel)! +
            bend * math.sin(travel * math.pi);
        final tailT = math.max(0.0, travel - 0.25);
        final tail = Offset.lerp(origin, target, tailT)! +
            bend * math.sin(tailT * math.pi);
        final seeker = special == TileSpecial.seeker;
        final arrival = ((progress - powerupTravelEnd) / (1 - powerupTravelEnd))
            .clamp(0.0, 1.0);
        if (flight < 1) {
          canvas.drawLine(tail, head,
              paint..strokeWidth = cellSize * (seeker ? 0.07 : 0.14));
          _paintProjectile(canvas, head, (head - tail).direction, color, fade);
        } else {
          canvas.drawCircle(
            target,
            cellSize * (0.12 + arrival * 0.36),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = cellSize * 0.075 * (1 - arrival)
              ..color = color.withValues(alpha: 1 - arrival),
          );
          canvas.drawCircle(
              target,
              cellSize * (seeker ? 0.14 : 0.23),
              Paint()
                ..color = Colors.white.withValues(alpha: (1 - arrival) * 0.75));
        }
        i++;
      }
    }
    canvas.restore();
  }

  void _paintProjectile(
      Canvas canvas, Offset head, double angle, Color color, double opacity) {
    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(angle);
    final r = cellSize * 0.18;
    final bright = Paint()..color = Colors.white.withValues(alpha: opacity);
    final body = Paint()..color = color.withValues(alpha: opacity);
    if (special == TileSpecial.seeker) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: r * 1.2, height: r * 3.2),
          body);
      canvas.drawCircle(Offset.zero, r * 0.66, bright);
    } else {
      final flame = Path()
        ..moveTo(-r * 2.3, 0)
        ..quadraticBezierTo(r, -r * 1.55, r, 0)
        ..quadraticBezierTo(r, r * 1.55, -r * 2.3, 0)
        ..close();
      canvas.drawPath(flame, body);
      canvas.drawCircle(Offset(r * 0.38, 0), r * 0.43, bright);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PowerupPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.special != special ||
      oldDelegate.activationDelay != activationDelay ||
      oldDelegate.origin != origin ||
      oldDelegate.cellSize != cellSize ||
      oldDelegate.targets != targets;
}

/// A rocket's nose marks the leading edge of its clear.
void paintFlyingRocket(
    Canvas canvas, Offset nose, double angle, double cellSize, double opacity) {
  canvas.save();
  canvas.translate(nose.dx, nose.dy);
  canvas.rotate(angle);
  canvas.scale(cellSize);
  final casing = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(-0.14, -0.15, -0.34, -0.1)
    ..lineTo(-0.46, -0.1)
    ..lineTo(-0.46, 0.1)
    ..lineTo(-0.34, 0.1)
    ..quadraticBezierTo(-0.14, 0.15, 0, 0)
    ..close();
  final fins = Path()
    ..moveTo(-0.32, -0.07)
    ..lineTo(-0.48, -0.17)
    ..lineTo(-0.47, 0.17)
    ..lineTo(-0.32, 0.07)
    ..close();
  final exhaust = Path()
    ..moveTo(-0.44, -0.085)
    ..quadraticBezierTo(-0.68, -0.09, -1.02, 0)
    ..quadraticBezierTo(-0.68, 0.09, -0.44, 0.085)
    ..close();
  canvas.drawPath(
      exhaust,
      Paint()
        ..shader = LinearGradient(colors: [
          const Color(0xFFFF752D).withValues(alpha: 0),
          const Color(0xFFFFDC77).withValues(alpha: opacity),
        ]).createShader(const Rect.fromLTRB(-1.02, -0.09, -0.44, 0.09)));
  canvas.drawPath(fins,
      Paint()..color = const Color(0xFFEF653E).withValues(alpha: opacity));
  canvas.drawPath(casing,
      Paint()..color = const Color(0xFFFFE9A8).withValues(alpha: opacity));
  canvas.drawCircle(const Offset(-0.2, 0), 0.045,
      Paint()..color = const Color(0xFF457793).withValues(alpha: opacity));
  canvas.restore();
}
