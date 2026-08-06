import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';

/// Hub accents from the MythDusk home mockup (gold frames + teal glow).
abstract final class HubColors {
  static const glow = Color(0xFF3ECFCB);
  static const glowDim = Color(0xFF2A9A96);
  static const frameGold = Color(0xFFD4AF5A);
  static const frameGoldDeep = Color(0xFF9A7428);
  static const panel = Color(0xCC0A1520);
  static const panelEdge = Color(0xFFE6C87A);
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
        border: Border.all(color: HubColors.frameGold.withValues(alpha: 0.55)),
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

/// Vertical shortcut rail (Shop / Profile / Mock).
class HubSideRail extends StatelessWidget {
  const HubSideRail({super.key, required this.items});

  final List<HubRailItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HubColors.frameGold, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: HubColors.frameGold.withValues(alpha: 0.28),
                ),
              _RailButton(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class HubRailItem {
  const HubRailItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool badge;
}

class _RailButton extends StatelessWidget {
  const _RailButton({required this.item});

  final HubRailItem item;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          child: SizedBox(
            width: 60,
            height: 64,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(3, 9, 3, 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: HubColors.frameGold, size: 24),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: MythDuskColors.parchment,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.badge)
                  Positioned(
                    right: 9,
                    top: 7,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: MythDuskColors.ember,
                        shape: BoxShape.circle,
                        border: Border.all(color: MythDuskColors.ink, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cosmetic path rank from campaign clears (not competitive ranked).
class HubRankBadge extends StatelessWidget {
  const HubRankBadge({super.key, required this.clears, this.onTap});

  final int clears;
  final VoidCallback? onTap;

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.fromLTRB(5, 7, 5, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xEE13222B), Color(0xF20A151D)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HubColors.frameGold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.shield,
                  size: 35,
                  color: const Color(0xFF8D552D),
                  shadows: [
                    Shadow(
                      color: HubColors.frameGold.withValues(alpha: 0.55),
                      blurRadius: 6,
                    ),
                  ],
                ),
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: HubColors.frameGold,
                ),
              ],
            ),
            const Text(
              'RANK',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: HubColors.frameGold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: MythDuskColors.softGold,
                height: 1.15,
              ),
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
              width: 62,
              height: 68,
              child: Padding(
                padding: const EdgeInsets.all(10),
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
            width: 62,
            height: 68,
            child: Icon(Icons.lock_outline, color: MythDuskColors.muted),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 64,
          child: Text(
            unlockHint,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 8,
              color: MythDuskColors.muted,
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
      ..color = HubColors.panel.withValues(alpha: dim ? 0.5 : 0.85);
    final stroke = Paint()
      ..color = HubColors.frameGold.withValues(alpha: dim ? 0.35 : 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final glow = Paint()
      ..color = HubColors.frameGold.withValues(alpha: dim ? 0.0 : 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glow);
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
        height: 62,
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
                        fontSize: 20,
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
              top: -7,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 15,
                  height: 15,
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

/// Weekly / Heroes secondary toggle row.
class HubModeTabs extends StatelessWidget {
  const HubModeTabs({
    super.key,
    required this.onWeekly,
    required this.onHeroes,
  });

  final VoidCallback onWeekly;
  final VoidCallback onHeroes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeTab(
            label: 'Weekly',
            onTap: onWeekly,
            active: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeTab(
            label: 'Heroes',
            onTap: onHeroes,
          ),
        ),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: HubColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: HubColors.frameGold.withValues(alpha: 0.4),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active ? HubColors.glow : MythDuskColors.parchment,
                ),
              ),
              if (active)
                const Positioned(
                  bottom: -3,
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 15,
                    color: HubColors.frameGold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chapter / act campaign progress card (mockup style).
class HubProgressBar extends StatelessWidget {
  const HubProgressBar({
    super.key,
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HubColors.frameGold.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.22,
              child: Image.asset(
                GameAssets.homeBackground,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xF20A1520), Color(0xA80A1520)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
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
                            subtitle.isEmpty
                                ? 'Node $completed / $total'
                                : subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: MythDuskColors.muted,
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
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.all_inbox_rounded,
                      size: 26,
                      color: HubColors.frameGold,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    children: [
                      Container(height: 9, color: MythDuskColors.mist),
                      FractionallySizedBox(
                        widthFactor: t,
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [HubColors.glowDim, HubColors.glow],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: HubColors.glow.withValues(alpha: 0.55),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom hub navigation (Home active; others bind later).
class HubBottomNav extends StatelessWidget {
  const HubBottomNav({
    super.key,
    required this.onHome,
    required this.onHero,
    required this.onInventory,
    required this.onRanked,
    required this.onMore,
    this.onMoreLongPress,
  });

  final VoidCallback onHome;
  final VoidCallback onHero;
  final VoidCallback onInventory;
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
          top: BorderSide(color: HubColors.frameGold.withValues(alpha: 0.25)),
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
            label: 'Hero',
            onTap: onHero,
          ),
          _NavItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            onTap: onInventory,
          ),
          _NavItem(
            icon: Icons.shield_outlined,
            label: 'Ranked',
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
