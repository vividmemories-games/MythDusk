import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Open engraved border that leaves the illustration beneath it visible.
class RelicFrame extends StatelessWidget {
  const RelicFrame({super.key});
  @override
  Widget build(BuildContext context) => const IgnorePointer(
        child: CustomPaint(painter: _RelicFramePainter()),
      );
}

class _RelicFramePainter extends CustomPainter {
  const _RelicFramePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MythDuskColors.softGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = (Offset.zero & size).deflate(3);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)), paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(3)),
        paint..color = const Color(0x887D5E28));
    paint.color = MythDuskColors.softGold;
    for (final origin in [
      const Offset(3, 3),
      Offset(size.width - 3, 3),
      Offset(3, size.height - 3),
      Offset(size.width - 3, size.height - 3)
    ]) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.scale(origin.dx > size.width / 2 ? -1 : 1,
          origin.dy > size.height / 2 ? -1 : 1);
      canvas.drawPath(
          Path()
            ..moveTo(0, 16)
            ..lineTo(9, 9)
            ..lineTo(16, 0)
            ..moveTo(0, 10)
            ..lineTo(6, 6)
            ..lineTo(10, 0),
          paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RelicFramePainter oldDelegate) => false;
}
