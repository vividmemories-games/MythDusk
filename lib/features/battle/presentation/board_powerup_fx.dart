import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../puzzle/domain/board_cell.dart';

/// Board-space effects keep rockets and shockwaves aligned with their cells.
class BoardPowerupFx extends StatefulWidget {
  const BoardPowerupFx({
    super.key,
    required this.special,
    required this.origin,
    required this.targets,
    required this.cellSize,
    required this.duration,
  });

  final TileSpecial special;
  final Offset origin;
  final List<Offset> targets;
  final double cellSize;
  final Duration duration;

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
  });

  final TileSpecial special;
  final Offset origin;
  final List<Offset> targets;
  final double cellSize;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.15) return;
    final t = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
    final travel = Curves.easeOutCubic.transform(t);
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
        canvas.drawLine(origin, head, paint..strokeWidth = cellSize * 0.12);
        canvas.drawLine(
            origin,
            head,
            paint
              ..color = Colors.white.withValues(alpha: fade)
              ..strokeWidth = cellSize * 0.035);
        canvas.drawCircle(head, cellSize * 0.09 * fade, paint);
        paint.color = color.withValues(alpha: fade * 0.8);
      }
    } else if (special == TileSpecial.bomb) {
      final radius = cellSize * (0.2 + travel * 1.4);
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
        canvas.drawLine(tail, head, paint);
        canvas.drawCircle(head, cellSize * 0.07 * fade,
            Paint()..color = Colors.white.withValues(alpha: fade));
        i++;
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PowerupPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.special != special ||
      oldDelegate.origin != origin ||
      oldDelegate.cellSize != cellSize ||
      oldDelegate.targets != targets;
}
