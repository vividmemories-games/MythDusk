import 'package:flutter/material.dart';

/// Painted stand-in for board overlays. There is no vine, rock, or poison
/// sprite yet — this reads as the mechanic until those assets exist.
class BoardOverlayArt extends StatelessWidget {
  const BoardOverlayArt({
    super.key,
    required this.overlayId,
    this.emphasize = false,
  });

  final String overlayId;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BoardOverlayPainter(
        overlayId: overlayId,
        emphasize: emphasize,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BoardOverlayPainter extends CustomPainter {
  const _BoardOverlayPainter({
    required this.overlayId,
    required this.emphasize,
  });

  final String overlayId;
  final bool emphasize;

  @override
  void paint(Canvas canvas, Size size) {
    if (overlayId == 'ovl_poison') {
      _paintPoison(canvas, size);
    } else if (overlayId == 'ovl_rock') {
      _paintRock(canvas, size);
    } else {
      _paintVine(canvas, size);
    }
  }

  void _paintVine(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(w * 0.16),
      ),
      Paint()
        ..color = const Color(0xFF1B4D32).withValues(
          alpha: emphasize ? 0.5 : 0.34,
        ),
    );

    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF0E2A1C)
      ..strokeWidth = w * 0.16;
    final stem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF3D9B5C)
      ..strokeWidth = w * 0.09;

    Path curve(Offset a, Offset control, Offset b) {
      return Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy);
    }

    final tendrils = [
      curve(
        Offset(-w * 0.05, h * 0.22),
        Offset(w * 0.28, h * 0.02),
        Offset(w * 0.72, h * 0.38),
      ),
      curve(
        Offset(w * 0.08, h * 1.05),
        Offset(w * 0.48, h * 0.48),
        Offset(w * 1.02, h * 0.18),
      ),
      curve(
        Offset(-w * 0.02, h * 0.78),
        Offset(w * 0.42, h * 0.42),
        Offset(w * 0.98, h * 0.88),
      ),
    ];
    for (final path in tendrils) {
      canvas.drawPath(path, shadow);
      canvas.drawPath(path, stem);
    }

    final leaf = Paint()..color = const Color(0xFF57C47A);
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..color = const Color(0xFF1B4D32);
    void leafAt(Offset center, double angle) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: w * 0.32,
        height: h * 0.16,
      );
      canvas.drawOval(rect, leaf);
      canvas.drawLine(
        Offset(-rect.width * 0.35, 0),
        Offset(rect.width * 0.35, 0),
        vein,
      );
      canvas.restore();
    }

    leafAt(Offset(w * 0.3, h * 0.2), -0.7);
    leafAt(Offset(w * 0.66, h * 0.46), 0.9);
    leafAt(Offset(w * 0.34, h * 0.74), 0.35);
    leafAt(Offset(w * 0.78, h * 0.22), -0.2);
  }

  void _paintPoison(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(w * 0.16),
      ),
      Paint()
        ..color = const Color(0xFF6A3A8C).withValues(
          alpha: emphasize ? 0.55 : 0.38,
        ),
    );
    final drop = Paint()..color = const Color(0xFFC58BFF);
    final core = Paint()..color = const Color(0xFF4A2068);
    void bubble(Offset c, double r) {
      canvas.drawCircle(c, r, drop);
      canvas.drawCircle(c, r * 0.35, core);
    }

    bubble(Offset(w * 0.32, h * 0.34), w * 0.16);
    bubble(Offset(w * 0.64, h * 0.58), w * 0.2);
    bubble(Offset(w * 0.42, h * 0.78), w * 0.1);
  }

  void _paintRock(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stone = Path()
      ..moveTo(w * 0.18, h * 0.72)
      ..lineTo(w * 0.12, h * 0.4)
      ..lineTo(w * 0.34, h * 0.16)
      ..lineTo(w * 0.68, h * 0.18)
      ..lineTo(w * 0.88, h * 0.42)
      ..lineTo(w * 0.8, h * 0.8)
      ..close();
    canvas.drawPath(stone, Paint()..color = const Color(0xFF6E6258));
    canvas.drawPath(
      stone,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..color = const Color(0xFF2C2622),
    );
    final crack = Path()
      ..moveTo(w * 0.4, h * 0.28)
      ..lineTo(w * 0.48, h * 0.5)
      ..lineTo(w * 0.36, h * 0.66);
    canvas.drawPath(
      crack,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2C2622),
    );
  }

  @override
  bool shouldRepaint(covariant _BoardOverlayPainter oldDelegate) {
    return oldDelegate.overlayId != overlayId ||
        oldDelegate.emphasize != emphasize;
  }
}
