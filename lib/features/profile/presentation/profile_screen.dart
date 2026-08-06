import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/presentation/home_hub_widgets.dart';
import '../../home/presentation/home_progress.dart';
import '../../prep/domain/prep_item.dart';
import '../domain/economy_balance.dart';
import '../providers/mock_profile_provider.dart';

/// Progress / economy hub for the player.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final hero = profile.selectedHero;
    final clears = profile.completedNodeIds.length;
    final progressAsync = ref.watch(homeCampaignProgressProvider);
    final textTheme = Theme.of(context).textTheme;
    final nextLife = profile.timeUntilNextLife();
    final livesDetail =
        nextLife == null ? 'Full' : 'Next in ${_formatRegen(nextLife)}';

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Center(
            child: SizedBox(
              height: 140,
              child: Image.asset(
                GameAssets.hero(hero.id),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  size: 88,
                  color: MythDuskColors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hero.name,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          Text(
            'Path rank · ${HubRankBadge.labelFor(clears)}',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: MythDuskColors.softGold,
            ),
          ),
          const SizedBox(height: 16),
          _Panel(
            child: Column(
              children: [
                _StatRow(
                  icon: Icons.monetization_on,
                  iconColor: MythDuskColors.amber,
                  label: 'Coins',
                  value: '${profile.coins}',
                ),
                const Divider(color: MythDuskColors.mist, height: 18),
                _StatRow(
                  icon: Icons.diamond,
                  iconColor: const Color(0xFF5B9BD5),
                  label: 'Gems',
                  value: '${profile.gems}',
                ),
                const Divider(color: MythDuskColors.mist, height: 18),
                _StatRow(
                  icon: Icons.favorite,
                  iconColor: MythDuskColors.ember,
                  label: 'Lives',
                  value: '${profile.lives} / ${EconomyBalance.maxLives}',
                  subtitle: livesDetail,
                ),
                const Divider(color: MythDuskColors.mist, height: 18),
                _StatRow(
                  icon: Icons.flag_outlined,
                  iconColor: HubColors.frameGold,
                  label: 'Nodes cleared',
                  value: '$clears',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          progressAsync.when(
            data: (p) => _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Campaign', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    '${p.actTitle} · ${p.chapterTitle}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: MythDuskColors.parchment,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Node ${p.completedInChapter} / ${p.totalInChapter}',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: p.totalInChapter <= 0
                          ? 0
                          : (p.completedInChapter / p.totalInChapter)
                              .clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: MythDuskColors.mist,
                      color: HubColors.glow,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const _Panel(
              child: Text('Loading campaign…',
                  style: TextStyle(color: MythDuskColors.muted)),
            ),
            error: (_, __) => _Panel(
              child: Text(
                '$clears campaign nodes cleared',
                style: textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prep inventory', style: textTheme.titleMedium),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final id in PrepItemId.values)
                      Column(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Image.asset(
                              id.assetPath,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.science,
                                color: MythDuskColors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '×${profile.prepCount(id)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: MythDuskColors.parchment,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Combat upgrades', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final stat in EconomyBalance.upgradeStatKeys)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${_upgradeLabel(stat)} · '
                      'tier ${profile.upgradeLevel(stat)} / '
                      '${EconomyBalance.upgradeMaxTiers}',
                      style: textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/heroes'),
            child: const Text('Heroes'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.push('/shop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: MythDuskColors.parchment,
              side: const BorderSide(color: MythDuskColors.mist),
            ),
            child: const Text('Shop'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.push('/settings'),
            style: OutlinedButton.styleFrom(
              foregroundColor: MythDuskColors.parchment,
              side: const BorderSide(color: MythDuskColors.mist),
            ),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  static String _upgradeLabel(String stat) => switch (stat) {
        EconomyBalance.upgradeStatHp => 'Max HP',
        EconomyBalance.upgradeStatDamage => 'Skill damage',
        EconomyBalance.upgradeStatShield => 'Shield power',
        _ => stat,
      };

  static String _formatRegen(Duration d) {
    final m = d.inMinutes;
    if (m <= 0) return '<1m';
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HubColors.frameGold.withValues(alpha: 0.45)),
      ),
      child: child,
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: MythDuskColors.parchment,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                      ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: MythDuskColors.softGold,
          ),
        ),
      ],
    );
  }
}
