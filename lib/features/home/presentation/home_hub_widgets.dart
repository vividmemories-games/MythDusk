import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Hub accents: gold is reserved for the primary campaign CTA.
abstract final class HubColors {
  static const glow = Color(0xFF3ECFCB);
  static const glowDim = Color(0xFF2A9A96);
  static const frameGold = Color(0xFFD4AF5A);
  static const frameGoldDeep = Color(0xFF9A7428);
  static const frameMuted = Color(0xFF4A6570);
  static const panel = Color(0xF20A1520);
  static const panelEdge = Color(0xFF4A6570);
}

/// Compact currency / lives pill for the hub header.
class HubResourceChip extends StatelessWidget {
  const HubResourceChip({
    super.key,
    required this.label,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HubColors.frameMuted.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? MythDuskColors.amber),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MythDuskColors.parchment,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}

/// Cosmetic path rank from campaign clears (not competitive ranked).
class HubRankBadge extends StatelessWidget {
  const HubRankBadge({super.key, required this.clears});

  final int clears;

  static String labelFor(int clears) {
    if (clears >= 150) return 'Myth III';
    if (clears >= 100) return 'Gold II';
    if (clears >= 50) return 'Silver I';
    if (clears >= 20) return 'Bronze III';
    if (clears >= 5) return 'Bronze II';
    return 'Bronze I';
  }

  @override
  Widget build(BuildContext context) {
    final label = labelFor(clears);
    return Tooltip(
      message: 'Cosmetic path rank from campaign clears',
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        decoration: BoxDecoration(
          color: HubColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HubColors.frameMuted),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 18,
              color: MythDuskColors.parchment.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PATH RANK',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: MythDuskColors.parchment.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: MythDuskColors.parchment,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hex-framed prep inventory slot.
class HubPrepSlot extends StatelessWidget {
  const HubPrepSlot({
    super.key,
    required this.assetPath,
    required this.count,
    required this.onTap,
  });

  final String assetPath;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            painter: _HexFramePainter(),
            child: SizedBox(
              width: 54,
              height: 60,
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.science_outlined,
                    color: MythDuskColors.muted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '×$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MythDuskColors.parchment,
            ),
          ),
        ],
      ),
    );
  }
}

class HubLockedPrepSlot extends StatelessWidget {
  const HubLockedPrepSlot({super.key, required this.unlockHint});

  final String unlockHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: _HexFramePainter(dim: true),
          child: const SizedBox(
            width: 54,
            height: 60,
            child: Icon(Icons.lock_outline, color: MythDuskColors.muted),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 58,
          child: Text(
            unlockHint,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 9,
              color: MythDuskColors.parchment.withValues(alpha: 0.72),
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _HexFramePainter extends CustomPainter {
  _HexFramePainter({this.dim = false});

  final bool dim;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size);
    final fill = Paint()
      ..color = HubColors.panel.withValues(alpha: dim ? 0.5 : 0.92);
    final stroke = Paint()
      ..color = HubColors.frameMuted.withValues(alpha: dim ? 0.45 : 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  Path _hexPath(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = math.min(w, h) / 2 - 1;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HexFramePainter oldDelegate) =>
      oldDelegate.dim != dim;
}

/// Ornate primary campaign CTA (beveled gold plate).
class HubCampaignButton extends StatelessWidget {
  const HubCampaignButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Enter Campaign',
      child: SizedBox(
        height: 58,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _CampaignButtonPainter()),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  customBorder: const StadiumBorder(),
                  child: const Center(
                    child: Text(
                      'Enter Campaign',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFF3D1),
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(color: Color(0xAA5A2F08), blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -6,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3A83C),
                    border: Border.all(color: const Color(0xFFFFE5A2)),
                    boxShadow: const [
                      BoxShadow(color: Color(0xAAE3A83C), blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(18, 2)
      ..lineTo(size.width - 18, 2)
      ..lineTo(size.width - 2, size.height / 2)
      ..lineTo(size.width - 18, size.height - 2)
      ..lineTo(18, size.height - 2)
      ..lineTo(2, size.height / 2)
      ..close();

    final glow = Paint()
      ..color = const Color(0xBBD28B20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);
    canvas.drawPath(path, glow);

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF0B94A), Color(0xFFC77B1C), Color(0xFF8E4B11)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fill);

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFD873);
    canvas.drawPath(path, outer);

    final innerPath = Path()
      ..moveTo(24, 7)
      ..lineTo(size.width - 24, 7)
      ..lineTo(size.width - 9, size.height / 2)
      ..lineTo(size.width - 24, size.height - 7)
      ..lineTo(24, size.height - 7)
      ..lineTo(9, size.height / 2)
      ..close();
    canvas.drawPath(
      innerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x99FFF0BE),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Combined prep peek + campaign progress + primary CTA.
class HubPlayPanel extends StatelessWidget {
  const HubPlayPanel({
    super.key,
    required this.prepSlots,
    required this.onShop,
    required this.progressTitle,
    required this.progressSubtitle,
    required this.completed,
    required this.total,
    required this.onEnterCampaign,
  });

  final Widget prepSlots;
  final VoidCallback onShop;
  final String progressTitle;
  final String progressSubtitle;
  final int completed;
  final int total;
  final VoidCallback onEnterCampaign;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HubColors.frameMuted),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Prep',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: MythDuskColors.parchment.withValues(alpha: 0.95),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onShop,
                child: Text(
                  'Shop',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: HubColors.glow.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          prepSlots,
          const SizedBox(height: 10),
          _HubProgressStrip(
            title: progressTitle,
            subtitle: progressSubtitle,
            completed: completed,
            total: total,
          ),
          const SizedBox(height: 10),
          HubCampaignButton(onPressed: onEnterCampaign),
        ],
      ),
    );
  }
}

class _HubProgressStrip extends StatelessWidget {
  const _HubProgressStrip({
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.total,
  });

  final String title;
  final String subtitle;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = total <= 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final pct = (t * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: MythDuskColors.parchment,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle.isEmpty ? 'Node $completed / $total' : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MythDuskColors.parchment.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$pct%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: HubColors.glow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              Container(height: 8, color: MythDuskColors.mist),
              FractionallySizedBox(
                widthFactor: t,
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [HubColors.glowDim, HubColors.glow],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Quiet retention chips under the campaign CTA.
class HubRetentionChips extends StatelessWidget {
  const HubRetentionChips({
    super.key,
    required this.onDaily,
    required this.onWeekly,
    this.showExpedition = false,
    this.expeditionInProgress = false,
    this.onExpedition,
  });

  final VoidCallback onDaily;
  final VoidCallback onWeekly;
  final bool showExpedition;
  final bool expeditionInProgress;
  final VoidCallback? onExpedition;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RetentionChip(
            label: 'Daily',
            onTap: onDaily,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RetentionChip(
            label: 'Weekly',
            onTap: onWeekly,
          ),
        ),
        if (showExpedition && onExpedition != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _RetentionChip(
              label: expeditionInProgress ? 'Continue' : 'Expedition',
              onTap: onExpedition!,
              badge: expeditionInProgress,
            ),
          ),
        ],
      ],
    );
  }
}

class _RetentionChip extends StatelessWidget {
  const _RetentionChip({
    required this.label,
    required this.onTap,
    this.badge = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: HubColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HubColors.frameMuted),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (badge) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: HubColors.glow,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MythDuskColors.parchment.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom hub navigation.
class HubBottomNav extends StatelessWidget {
  const HubBottomNav({
    super.key,
    required this.onHome,
    required this.onHeroes,
    required this.onShop,
    required this.onRanked,
    required this.onMore,
    this.onMoreLongPress,
  });

  final VoidCallback onHome;
  final VoidCallback onHeroes;
  final VoidCallback onShop;
  final VoidCallback onRanked;
  final VoidCallback onMore;
  final VoidCallback? onMoreLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xEE071018),
        border: Border(
          top: BorderSide(color: HubColors.frameMuted.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            active: true,
            onTap: onHome,
          ),
          _NavItem(
            icon: Icons.face_retouching_natural,
            label: 'Heroes',
            onTap: onHeroes,
          ),
          _NavItem(
            icon: Icons.storefront_outlined,
            label: 'Shop',
            onTap: onShop,
          ),
          _NavItem(
            icon: Icons.shield_outlined,
            label: '1v1',
            onTap: onRanked,
          ),
          _NavItem(
            icon: Icons.menu,
            label: 'More',
            onTap: onMore,
            onLongPress: onMoreLongPress,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = active ? HubColors.glow : MythDuskColors.muted;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
              shadows: active
                  ? [
                      Shadow(
                        color: HubColors.glow.withValues(alpha: 0.7),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
