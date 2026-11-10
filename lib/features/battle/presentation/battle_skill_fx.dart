part of 'battle_stage.dart';

class _SkillPainter extends CustomPainter {
  const _SkillPainter({
    required this.animation,
    required this.progress,
    required this.impact,
    required this.amount,
    required this.shieldGain,
    required this.reduceMotion,
  });

  final SkillAnimation animation;
  final double progress;
  final bool impact;
  final int amount;
  final int shieldGain;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.32, size.height * 0.28);
    final target = Offset(size.width * 0.78, size.height * 0.54);
    final radius = (size.width * 0.036).clamp(7.0, 15.0);
    final (flame, core) = switch (animation) {
      SkillAnimation.fireball => (
          const Color(0xFFFF752D),
          const Color(0xFFFFF1B0)
        ),
      SkillAnimation.arcaneBolt => (
          const Color(0xFF9660FF),
          const Color(0xFFF2D9FF)
        ),
      SkillAnimation.smite => (
          const Color(0xFFFFBC54),
          const Color(0xFFFFF5CB)
        ),
      SkillAnimation.mend => (const Color(0xFF46DDA1), const Color(0xFFC8FFDD)),
      SkillAnimation.shieldWall => (
          const Color(0xFF53AFF7),
          const Color(0xFFDCFAFF)
        ),
      SkillAnimation.basicSlash => (
          const Color(0xFF87BDE3),
          const Color(0xFFE9F7FF)
        ),
      SkillAnimation.frostWard => (
          const Color(0xFF87DEFF),
          const Color(0xFFF0FFFF)
        ),
      SkillAnimation.meteorShard => (
          const Color(0xFFFF572F),
          const Color(0xFFFFD581)
        ),
      SkillAnimation.rallyingCry => (
          const Color(0xFFD6A451),
          const Color(0xFFFFECC1)
        ),
      SkillAnimation.bulwarkSlam => (
          const Color(0xFFF9B75F),
          const Color(0xFFFFEDC6)
        ),
      SkillAnimation.arrowShot => (
          const Color(0xFF9CCD82),
          const Color(0xFFE8FFC9)
        ),
      SkillAnimation.markedShot => (
          const Color(0xFFFFB457),
          const Color(0xFFFFEFB2)
        ),
      SkillAnimation.naturesSalve => (
          const Color(0xFF6CD064),
          const Color(0xFFE2FFD1)
        ),
      SkillAnimation.volleyRain => (
          const Color(0xFF8DCF72),
          const Color(0xFFE5FFC6)
        ),
      SkillAnimation.holyBarrier || SkillAnimation.sanctuary => (
          const Color(0xFFF9CD65),
          const Color(0xFFFFF5D2)
        ),
      SkillAnimation.daggerFlurry => (
          const Color(0xFF78D6CE),
          const Color(0xFFDDFFFC)
        ),
      SkillAnimation.shadowStrike || SkillAnimation.shadowBind => (
          const Color(0xFFAD77F4),
          const Color(0xFFF0D7FF)
        ),
      SkillAnimation.smokeBomb => (
          const Color(0xFF9D88BF),
          const Color(0xFFE1D7F3)
        ),
    };

    if (animation.targetsSelf) {
      final hero = Offset(size.width * 0.21, size.height * 0.57);
      if (!reduceMotion) _paintSupport(canvas, hero, radius, flame, core);
      if (impact && amount > 0) _paintAmount(canvas, hero, core, '+$amount');
      if (impact && shieldGain > 0) {
        final shieldLabel = hero + Offset(0, amount > 0 ? 22 : 0);
        _paintAmount(canvas, shieldLabel, core, '+$shieldGain shield');
      }
      return;
    }

    if (animation.motion == SkillMotion.burst && !reduceMotion) {
      _paintSmite(canvas, target, radius, flame, core);
    }
    if (animation.motion == SkillMotion.burst && !impact) return;
    if (animation.motion == SkillMotion.melee && !reduceMotion) {
      _paintSlash(canvas, size, flame, core);
    }
    if (!impact && animation.motion == SkillMotion.melee) return;
    if (!impact && animation.motion == SkillMotion.arrow) {
      _paintArrow(canvas, size, target, radius, flame, core);
      return;
    }
    if (!impact && animation == SkillAnimation.arcaneBolt) {
      _paintArcaneBolt(canvas, origin, target, radius, flame, core);
      return;
    }

    if (!impact) {
      final flight = ((progress - _fireballRelease) / (1 - _fireballRelease))
          .clamp(0.0, 1.0);
      Offset position(double t) =>
          Offset.lerp(origin, target, t)! -
          Offset(0, math.sin(t * math.pi) * size.height * 0.10);
      final charge = (progress / _fireballRelease).clamp(0.0, 1.0);
      final center = position(flight);
      final radiusAtCharge = radius * (0.3 + 1.1 * charge);
      final expansion = Curves.easeOutCubic.transform(
        (flight / 0.25).clamp(0.0, 1.0),
      );
      final flameRadius = radiusAtCharge * (1 + 0.55 * expansion);
      final glowRadius = flameRadius * 1.9;
      canvas.drawCircle(
        center,
        glowRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [flame.withValues(alpha: 0.8), flame.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
      );

      if (flight == 0) {
        canvas.drawCircle(center, radiusAtCharge * 0.56, Paint()..color = core);
        for (var i = 0; i < 5; i++) {
          final angle = i * math.pi * 2 / 5 + charge * 1.6;
          final spark = center +
              Offset.fromDirection(angle, radius * (2.4 - 1.5 * charge));
          canvas.drawCircle(
            spark,
            radius * 0.12,
            Paint()..color = core.withValues(alpha: charge),
          );
        }
        return;
      }

      final behind = position(math.max(0.0, flight - 0.02));
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((center - behind).direction);

      // Grow the flame head after release while keeping the trail proportionate
      // to the distance it has traveled.
      final r = flameRadius;
      final tail = radiusAtCharge *
          (1.4 +
              2.3 *
                  Curves.easeOutCubic.transform(
                    (flight / 0.3).clamp(0.0, 1.0),
                  ));
      final flameBody = Path()
        ..moveTo(-tail, -r * 0.48)
        ..cubicTo(-tail * 0.58, -r * 0.12, -r, -r * 1.15, 0, -r * 0.88)
        ..cubicTo(r * 1.38, -r * 0.79, r * 1.42, r * 0.74, 0, r * 0.86)
        ..cubicTo(-r, r * 0.9, -tail * 0.62, r * 0.35, -tail, r * 0.46)
        ..quadraticBezierTo(-tail * 0.76, 0, -tail, -r * 0.48)
        ..close();
      canvas.drawPath(
        flameBody,
        Paint()
          ..shader = LinearGradient(
            colors: [
              flame.withValues(alpha: 0),
              flame,
              const Color(0xFFFFB844),
              core
            ],
            stops: const [0, 0.42, 0.74, 1],
          ).createShader(Rect.fromLTRB(-tail, -r, r * 1.2, r)),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(r * 0.38, 0), width: r * 1.16, height: r),
        Paint()..color = core.withValues(alpha: 0.88),
      );
      canvas.restore();
      return;
    }

    final fade = 1 - progress;
    if (!reduceMotion) {
      final spread = Curves.easeOutCubic.transform(progress);
      if (animation.motion != SkillMotion.melee) {
        final ringScale = animation == SkillAnimation.arcaneBolt ? 1.35 : 1.0;
        canvas.drawCircle(
          target,
          radius * (0.75 + 2.4 * spread) * ringScale,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * fade * ringScale
            ..color = flame.withValues(alpha: fade),
        );
      }
      canvas.drawCircle(
        target,
        radius * (0.4 + 0.9 * spread),
        Paint()..color = core.withValues(alpha: fade * fade),
      );
      for (var i = 0; i < 8; i++) {
        final direction = Offset.fromDirection(i * math.pi / 4 + 0.24);
        final start =
            target + direction * radius * (0.8 + spread * (2 + i % 3));
        canvas.drawLine(
          start,
          start + direction * radius * 0.65 * fade,
          Paint()
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = core.withValues(alpha: fade),
        );
      }
    }

    if (amount > 0) _paintAmount(canvas, target, core, '−$amount');
    if (shieldGain > 0) {
      final hero = Offset(size.width * 0.21, size.height * 0.57);
      _paintAmount(canvas, hero, core, '+$shieldGain shield');
    }
  }

  void _paintAmount(Canvas canvas, Offset target, Color core, String label) {
    final fade = 1 - progress;
    final number = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: core.withValues(
            alpha: reduceMotion ? 1 : (fade * 3).clamp(0.0, 1.0),
          ),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rise = reduceMotion ? 0.0 : 24 * progress;
    number.paint(canvas, target - Offset(number.width / 2, 28 + rise));
    number.dispose();
  }

  void _paintSmite(
      Canvas canvas, Offset target, double radius, Color gold, Color core) {
    final strength = impact ? (1 - progress) * (1 - progress) : progress;
    final ring = Rect.fromCenter(
      center: target + Offset(0, radius * 2.3),
      width: radius * (4 + progress),
      height: radius * 1.2,
    );
    canvas.drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = gold.withValues(alpha: strength));
    if (animation == SkillAnimation.meteorShard) {
      final approach = impact ? 1.0 : Curves.easeInCubic.transform(progress);
      final head = target - Offset(radius * 3, target.dy) * (1 - approach);
      final intensity = impact ? strength : approach;
      final trail = head - Offset(radius * 2, radius * 4);
      canvas.drawLine(
          trail,
          head,
          Paint()
            ..strokeWidth = radius * 1.5
            ..strokeCap = StrokeCap.round
            ..color = gold.withValues(alpha: intensity * 0.65));
      canvas.drawCircle(head, radius * (impact ? 1.8 + progress : 1.35),
          Paint()..color = core.withValues(alpha: intensity));
      return;
    }
    if (!impact) return;

    if (animation == SkillAnimation.volleyRain) {
      for (var i = -2; i <= 2; i++) {
        final end = target + Offset(i * radius * 0.65, i.abs() * radius * 0.3);
        canvas.drawLine(
            end - Offset(radius * 1.2, radius * 3.5),
            end,
            Paint()
              ..strokeWidth = radius * 0.25
              ..strokeCap = StrokeCap.round
              ..color = core.withValues(alpha: strength));
      }
      return;
    }
    if (animation == SkillAnimation.shadowBind) {
      for (var i = 0; i < 3; i++) {
        canvas.drawOval(
          Rect.fromCenter(
              center: target + Offset(0, (i - 1) * radius),
              width: radius * 3.8,
              height: radius * 1.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * 0.24
            ..color = gold.withValues(alpha: strength),
        );
      }
      return;
    }
    final beamWidth = radius * 1.55;
    final beam = Rect.fromLTRB(
      target.dx - beamWidth,
      0,
      target.dx + beamWidth,
      target.dy,
    );
    canvas.drawRect(
        beam,
        Paint()
          ..shader = LinearGradient(
            colors: [
              gold.withValues(alpha: 0),
              core.withValues(alpha: strength),
              gold.withValues(alpha: 0)
            ],
          ).createShader(beam));
  }

  void _paintSupport(
      Canvas canvas, Offset hero, double radius, Color tint, Color core) {
    final fade = impact ? 1 - progress : progress;
    if (animation.motion != SkillMotion.heal) {
      final height = radius * (3 + 4 * (impact ? 1 : progress));
      final wall = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: hero + Offset(radius * 1.55, 0),
            width: radius * 1.6,
            height: height),
        Radius.circular(radius * 0.7),
      );
      canvas.drawRRect(
          wall, Paint()..color = tint.withValues(alpha: fade * 0.3));
      canvas.drawRRect(
          wall,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = core.withValues(alpha: fade));
      if (animation.motion == SkillMotion.ward) return;
    }

    final ring = Rect.fromCenter(
      center: hero + Offset(0, radius * (2.4 - (impact ? 4 * progress : 0))),
      width: radius * (3 + (impact ? 2 + progress * 0.5 : progress * 2)),
      height: radius * 1.4,
    );
    canvas.drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = tint.withValues(alpha: fade));
    if (!impact) return;
    final spark = Paint()
      ..color = core.withValues(alpha: fade)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final center =
          hero + Offset((i - 2) * radius, -radius * (progress * 3 + i % 2));
      canvas.drawLine(center - Offset(radius * 0.22, 0),
          center + Offset(radius * 0.22, 0), spark);
      canvas.drawLine(center - Offset(0, radius * 0.22),
          center + Offset(0, radius * 0.22), spark);
    }
  }

  void _paintSlash(Canvas canvas, Size size, Color edge, Color core) {
    final slotWidth = (size.width - _fighterGap) / 2;
    final hand = Offset(
      slotWidth * 0.22 + _slashAdvance(slotWidth, progress, impact: impact),
      size.height * 0.61,
    );
    final reach = math.min(slotWidth * 0.68, size.height * 0.45);
    final angle = impact
        ? -0.22 + Curves.easeOutCubic.transform(progress) * 1.55
        : -2.35 + Curves.easeInCubic.transform(progress) * 2.13;
    final opacity = impact
        ? (1 - progress * 1.8).clamp(0.0, 1.0)
        : (progress * 5).clamp(0.0, 1.0);

    if (animation == SkillAnimation.bulwarkSlam) {
      final face = hand + Offset(reach * 0.53, -reach * 0.16);
      final plate = Rect.fromCenter(
        center: face,
        width: reach * 0.39,
        height: reach * 0.64,
      );
      canvas.drawOval(
          plate, Paint()..color = edge.withValues(alpha: opacity * 0.38));
      canvas.drawOval(
          plate.inflate(impact ? progress * reach * 0.5 : 0),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = reach * 0.055
            ..color = core.withValues(alpha: opacity));
      return;
    }

    if (impact) {
      final sweep = Rect.fromCircle(center: hand, radius: reach * 0.94);
      canvas.drawArc(
        sweep,
        angle - 1.15,
        1.15,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = reach * 0.22
          ..color = edge.withValues(alpha: opacity * 0.45),
      );
    }

    canvas.save();
    canvas.translate(hand.dx, hand.dy);
    canvas.rotate(angle);
    final blade = Path()
      ..moveTo(reach * 0.16, -reach * 0.065)
      ..lineTo(reach * 0.82, -reach * 0.05)
      ..lineTo(reach, 0)
      ..lineTo(reach * 0.82, reach * 0.05)
      ..lineTo(reach * 0.16, reach * 0.065)
      ..close();
    canvas.drawPath(blade, Paint()..color = core.withValues(alpha: opacity));
    if (animation == SkillAnimation.daggerFlurry) {
      canvas.save();
      canvas.translate(0, reach * 0.18);
      canvas.rotate(-0.28);
      canvas.drawPath(blade, Paint()..color = edge.withValues(alpha: opacity));
      canvas.restore();
    }
    canvas.drawLine(
      Offset(reach * 0.16, -reach * 0.12),
      Offset(reach * 0.16, reach * 0.12),
      Paint()
        ..strokeWidth = reach * 0.065
        ..strokeCap = StrokeCap.round
        ..color = edge.withValues(alpha: opacity),
    );
    canvas.restore();
  }

  void _paintArrow(Canvas canvas, Size size, Offset target, double radius,
      Color tint, Color core) {
    final launch = Offset(size.width * 0.29, size.height * 0.49);
    final flight = ((progress - 0.30) / 0.70).clamp(0.0, 1.0);
    final tip = Offset.lerp(launch, target, flight)!;
    final axis = (target - launch).direction;
    final length =
        radius * (animation == SkillAnimation.markedShot ? 3.6 : 2.6);
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(axis);
    final shaft = Paint()
      ..strokeWidth = radius * 0.18
      ..strokeCap = StrokeCap.round
      ..color = tint;
    canvas.drawLine(Offset(-length, 0), Offset.zero, shaft);
    canvas.drawPath(
      Path()
        ..moveTo(radius * 0.4, 0)
        ..lineTo(-radius * 0.45, -radius * 0.35)
        ..lineTo(-radius * 0.45, radius * 0.35)
        ..close(),
      Paint()..color = core,
    );
    canvas.restore();
  }

  void _paintArcaneBolt(
    Canvas canvas,
    Offset origin,
    Offset target,
    double radius,
    Color violet,
    Color core,
  ) {
    const release = 0.28;
    final flight = ((progress - release) / (1 - release)).clamp(0.0, 1.0);
    final charge = (progress / release).clamp(0.0, 1.0);
    final head = Offset.lerp(origin, target, flight)!;
    final width =
        radius * (0.25 + charge * 0.85 + math.min(flight * 3, 1) * 0.45);
    final direction = target - origin;
    final tail = math.min(direction.distance * flight, radius * 6.5);
    final glow = Rect.fromCircle(center: head, radius: width * 2.3);
    canvas.drawCircle(
      head,
      glow.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            violet.withValues(alpha: charge * 0.9),
            violet.withValues(alpha: 0)
          ],
        ).createShader(glow),
    );

    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(direction.direction);
    if (tail > 0) {
      final trail = Path()
        ..moveTo(-tail, 0)
        ..quadraticBezierTo(-tail * 0.38, -width * 1.3, 0, -width * 0.52)
        ..lineTo(0, width * 0.52)
        ..quadraticBezierTo(-tail * 0.38, width * 1.3, -tail, 0)
        ..close();
      canvas.drawPath(
          trail,
          Paint()
            ..shader = LinearGradient(
              colors: [violet.withValues(alpha: 0), violet, core],
            ).createShader(Rect.fromLTRB(-tail, -width, 0, width)));
    }
    final shard = Path()
      ..moveTo(width * 1.15, 0)
      ..lineTo(0, -width * 0.68)
      ..lineTo(-width * 0.95, 0)
      ..lineTo(0, width * 0.68)
      ..close();
    canvas.drawPath(shard, Paint()..color = core.withValues(alpha: charge));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkillPainter oldDelegate) =>
      animation != oldDelegate.animation ||
      progress != oldDelegate.progress ||
      impact != oldDelegate.impact ||
      amount != oldDelegate.amount ||
      shieldGain != oldDelegate.shieldGain ||
      reduceMotion != oldDelegate.reduceMotion;
}
