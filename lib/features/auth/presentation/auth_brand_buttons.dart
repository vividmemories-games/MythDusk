import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/theme/app_theme.dart';

/// MythDusk-shaped actions that still carry Apple / Google marks and wording.
abstract final class AuthBrandButtons {
  static bool get showApple => defaultTargetPlatform == TargetPlatform.iOS;

  static Widget apple({
    required VoidCallback onPressed,
    String label = 'Continue with Apple',
  }) {
    return MythDuskAuthButton(
      onPressed: onPressed,
      label: label,
      leading: const SizedBox(
        width: 18,
        height: 22,
        child: CustomPaint(
          painter: AppleLogoPainter(color: MythDuskColors.ink),
        ),
      ),
    );
  }

  static Widget google({
    required VoidCallback onPressed,
    String label = 'Continue with Google',
  }) {
    return MythDuskAuthButton(
      onPressed: onPressed,
      label: label,
      leading: const SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(painter: _GoogleGPainter()),
      ),
    );
  }

  static Widget guest({required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: MythDuskColors.parchment,
          side: const BorderSide(color: MythDuskColors.softGold, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Continue as Guest'),
      ),
    );
  }
}

class MythDuskAuthButton extends StatelessWidget {
  const MythDuskAuthButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.leading,
  });

  final VoidCallback onPressed;
  final String label;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: MythDuskColors.amber,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: MythDuskColors.softGold.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                leading,
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dusk frame around account actions.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MythDuskColors.deepTeal.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MythDuskColors.softGold.withValues(alpha: 0.38),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect.deflate(stroke), -0.25, 1.6, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect.deflate(stroke), 1.35, 1.4, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect.deflate(stroke), 2.75, 0.9, false, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect.deflate(stroke), 3.65, 1.1, false, paint);

    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.42,
        size.width * 0.42,
        stroke,
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
