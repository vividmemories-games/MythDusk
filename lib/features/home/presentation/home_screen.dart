import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../campaign/data/campaign_repository.dart';
import '../../heroes/domain/hero_def.dart';
import '../../prep/domain/prep_item.dart';
import '../../profile/domain/economy_balance.dart';
import '../../profile/providers/mock_profile_provider.dart';
import 'settings_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final textTheme = Theme.of(context).textTheme;
    final selected = profile.selectedHero;
    final nextLife = profile.timeUntilNextLife();
    final livesLabel = nextLife == null
        ? '${profile.lives}'
        : '${profile.lives} · ${_formatRegen(nextLife)}';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            GameAssets.homeBackground,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: MythoraColors.ink),
          ),
          Container(color: MythoraColors.ink.withValues(alpha: 0.5)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Mythora',
                        style: textTheme.displayLarge?.copyWith(fontSize: 30),
                      ),
                      const Spacer(),
                      _ResourceChip(
                        label: '${profile.coins}',
                        icon: Icons.monetization_on_outlined,
                      ),
                      const SizedBox(width: 6),
                      _ResourceChip(
                        label: '${profile.gems}',
                        icon: Icons.diamond_outlined,
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _onLivesTap(context, ref),
                        child: _ResourceChip(
                          label: livesLabel,
                          icon: Icons.favorite_outline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: () => showSettingsSheet(context),
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: MythoraColors.parchment,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Match tiles. Fuel skills. Outlast the enemy.',
                    style: textTheme.bodyMedium,
                  ),
                  const Spacer(flex: 1),
                  GestureDetector(
                    onTap: () => _showHeroPicker(context, ref),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 168,
                          child: Image.asset(
                            GameAssets.hero(selected.id),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 96,
                              color: MythoraColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(selected.name, style: textTheme.headlineMedium),
                        Text(
                          'Tap to change hero',
                          style: textTheme.bodyMedium?.copyWith(
                            color: MythoraColors.softGold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final id in PrepItemId.values) ...[
                        _PrepBadge(
                          path: id.assetPath,
                          count: profile.prepCount(id),
                        ),
                        if (id != PrepItemId.values.last)
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const Spacer(flex: 2),
                  FilledButton(
                    onPressed: () {
                      ref.read(profileProvider.notifier).tickLifeRegen();
                      final lives = ref.read(profileProvider).lives;
                      if (lives <= 0) {
                        _showNoLivesDialog(context, ref);
                        return;
                      }
                      context.push('/chapters');
                    },
                    child: const Text('Enter Campaign'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showWeeklyStub(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MythoraColors.parchment,
                            side: const BorderSide(color: MythoraColors.mist),
                          ),
                          child: const Text('Weekly'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showHeroPicker(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MythoraColors.parchment,
                            side: const BorderSide(color: MythoraColors.mist),
                          ),
                          child: const Text('Heroes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${profile.completedNodeIds.length} nodes cleared',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _unlockAllForQa(context, ref),
                        child: const Text('Unlock all (QA)'),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.read(profileProvider.notifier).resetProgress(),
                        child: const Text('Reset progress'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRegen(Duration d) {
    final m = d.inMinutes;
    if (m <= 0) return '<1m';
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem == 0 ? '${h}h' : '${h}h ${rem}m';
  }

  void _onLivesTap(BuildContext context, WidgetRef ref) {
    ref.read(profileProvider.notifier).tickLifeRegen();
    final profile = ref.read(profileProvider);
    if (profile.lives >= EconomyBalance.maxLives) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lives are full')),
      );
      return;
    }
    _showNoLivesDialog(context, ref, title: 'Refill lives');
  }

  void _showNoLivesDialog(
    BuildContext context,
    WidgetRef ref, {
    String title = 'Out of lives',
  }) {
    final profile = ref.read(profileProvider);
    final remaining = profile.gemLifeRefillsRemainingToday;
    final next = profile.timeUntilNextLife();
    final regenText = next == null
        ? 'Lives regenerate over time.'
        : 'Next life in ${_formatRegen(next)}.';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MythoraColors.deepTeal,
        title: Text(title),
        content: Text(
          '$regenText\n\n'
          'Gem refill: +${EconomyBalance.gemLifeRefillAmount} lives for '
          '${EconomyBalance.gemLifeRefillCost} gems '
          '($remaining left today).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: remaining <= 0 ||
                    profile.gems < EconomyBalance.gemLifeRefillCost
                ? null
                : () {
                    final ok = ref
                        .read(profileProvider.notifier)
                        .purchaseGemLifeRefill();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Lives refilled (+${EconomyBalance.gemLifeRefillAmount})'
                              : 'Could not refill',
                        ),
                      ),
                    );
                  },
            child: const Text('Use gems'),
          ),
        ],
      ),
    );
  }

  Future<void> _unlockAllForQa(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Unlocking all chapters & levels…')),
    );
    try {
      final ids = await loadAllCampaignNodeIds();
      await ref.read(profileProvider.notifier).unlockAllNodes(ids);
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'QA unlock: ${ids.length} nodes open. Enter Campaign → any chapter.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Unlock failed: $e')),
      );
    }
  }

  void _showWeeklyStub(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MythoraColors.deepTeal,
        title: const Text('Weekly'),
        content: const Text(
          'Weekly objectives land in M7. Mon–Fri puzzles, weekend boss — coming soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHeroPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MythoraColors.deepTeal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final profile = ref.watch(profileProvider);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Heroes',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  ...HeroCatalog.all.map((hero) {
                    final selected = hero.id == profile.selectedHeroId;
                    return ListTile(
                      leading: SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.asset(
                          GameAssets.hero(hero.id),
                          errorBuilder: (_, __, ___) => Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.person_outline,
                            color: MythoraColors.amber,
                          ),
                        ),
                      ),
                      title: Text(hero.name),
                      subtitle: Text(
                        '${hero.movesPerTurn} moves · ${hero.maxHp} HP',
                      ),
                      trailing: selected
                          ? const Icon(Icons.check, color: MythoraColors.amber)
                          : null,
                      onTap: () {
                        ref.read(profileProvider.notifier).selectHero(hero.id);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PrepBadge extends StatelessWidget {
  const _PrepBadge({required this.path, required this.count});

  final String path;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Image.asset(
            path,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        Text(
          '×$count',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: MythoraColors.deepTeal.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MythoraColors.mist),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: MythoraColors.amber),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}
