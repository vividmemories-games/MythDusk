import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/challenge_art.dart';

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
        border: Border.all(color: HubColors.frameGold.withValues(alpha: 0.85)),
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
          border: Border.all(color: HubColors.frameGold),
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
            Flexible(
                child: Column(
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
            )),
          ],
        ),
      ),
    );
  }
}

/// Campaign progress and the primary journey action.
class HubPlayPanel extends StatelessWidget {
  const HubPlayPanel(
      {super.key,
      required this.progressTitle,
      required this.progressSubtitle,
      required this.completed,
      required this.total,
      required this.onEnterCampaign,
      required this.onWorldMap});
  final String progressTitle;
  final String progressSubtitle;
  final int completed;
  final int total;
  final VoidCallback onEnterCampaign;
  final VoidCallback onWorldMap;
  @override
  Widget build(BuildContext context) => ChallengePanel(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HubProgressStrip(
              title: progressTitle,
              subtitle: progressSubtitle,
              completed: completed,
              total: total),
          const SizedBox(height: 8),
          ChallengePlayButton(
              enabled: true,
              onPressed: onEnterCampaign,
              label: 'Continue Journey'),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onWorldMap,
                icon: const Icon(Icons.map_outlined, size: 16),
                label: Text('World Map', style: challengeTextStyle(12)),
              )),
        ],
      ));
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
                    style: challengeTextStyle(16, bold: true),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          height: 64,
          decoration: BoxDecoration(
            color: HubColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HubColors.frameGold),
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
                  if (label == 'Daily' || label == 'Weekly') ...[
                    ChallengeArtIcon(label == 'Daily' ? 'spiral' : 'coin',
                        size: 36),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'DailySerif',
                      fontSize: 15,
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
    return Expanded(
        child: InkWell(
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
    ));
  }
}
