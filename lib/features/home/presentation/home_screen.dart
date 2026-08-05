import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../campaign/data/campaign_repository.dart';
import '../../heroes/domain/hero_def.dart';
import '../../heroes/domain/hero_unlocks.dart';
import '../../prep/domain/prep_item.dart';
import '../../profile/domain/economy_balance.dart';
import '../../profile/providers/mock_profile_provider.dart';
import 'coming_soon_sheet.dart';
import 'home_hub_widgets.dart';
import 'home_progress.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final selected = profile.selectedHero;
    final nextLife = profile.timeUntilNextLife();
    final livesLabel = nextLife == null
        ? '${profile.lives}'
        : '${profile.lives} · ${_formatRegen(nextLife)}';
    final progressAsync = ref.watch(homeCampaignProgressProvider);
    final clears = profile.completedNodeIds.length;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            GameAssets.homeBackground,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => Image.asset(
              GameAssets.homeBackgroundFallback,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: MythoraColors.ink),
            ),
          ),
          // Soft vignette so UI stays readable without flattening the art.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66071118),
                  Color(0x33071118),
                  Color(0x99071118),
                  Color(0xE6071118),
                ],
                stops: [0, 0.28, 0.62, 1],
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HubHeader(
                          coins: profile.coins,
                          gems: profile.gems,
                          livesLabel: livesLabel,
                          onLivesTap: () => _onLivesTap(context, ref),
                          onSettings: () => context.push('/settings'),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final heroH = (constraints.maxHeight - 64)
                                  .clamp(100.0, 235.0);
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: _HeroStage(
                                      hero: selected,
                                      height: heroH,
                                      onTap: () => context.push('/heroes'),
                                      onPrev: () => _cycleHero(ref, -1),
                                      onNext: () => _cycleHero(ref, 1),
                                    ),
                                  ),
                                  Align(
                                    alignment: const Alignment(-0.98, -0.05),
                                    child: HubRankBadge(
                                      clears: clears,
                                      onTap: () => showComingSoonSheet(
                                        context,
                                        title: 'Path rank',
                                        blurb:
                                            'Cosmetic path tier from campaign '
                                            'clears. Competitive Ranked comes later.',
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: const Alignment(1.0, -0.08),
                                    child: HubSideRail(
                                      items: [
                                        HubRailItem(
                                          icon: Icons.shopping_bag_outlined,
                                          label: 'Shop',
                                          onTap: () => context.push('/shop'),
                                        ),
                                        HubRailItem(
                                          icon: Icons.person_outline,
                                          label: 'Profile',
                                          onTap: () => context.push('/profile'),
                                        ),
                                        HubRailItem(
                                          icon: Icons.science_outlined,
                                          label: 'Mock',
                                          onTap: () => showComingSoonSheet(
                                            context,
                                            title: 'Mock',
                                            blurb:
                                                'Placeholder slot — replace with '
                                                'a real mode later.',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final id in PrepItemId.values) ...[
                              HubPrepSlot(
                                assetPath: id.assetPath,
                                count: profile.prepCount(id),
                                onTap: () => context.push('/shop'),
                              ),
                              const SizedBox(width: 10),
                            ],
                            const HubLockedPrepSlot(
                              unlockHint: 'Unlocks at Act III',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        progressAsync.when(
                          data: (p) => HubProgressBar(
                            title: '${p.actTitle} · ${p.chapterTitle}',
                            subtitle:
                                'Node ${p.completedInChapter} / ${p.totalInChapter}',
                            completed: p.completedInChapter,
                            total: p.totalInChapter,
                          ),
                          loading: () => const HubProgressBar(
                            title: 'Campaign',
                            subtitle: 'Loading…',
                            completed: 0,
                            total: 20,
                          ),
                          error: (_, __) => HubProgressBar(
                            title: 'Campaign',
                            subtitle: 'Node $clears',
                            completed: clears.clamp(0, 20),
                            total: 20,
                          ),
                        ),
                        const SizedBox(height: 12),
                        HubCampaignButton(
                          onPressed: () => _enterCampaign(context, ref),
                        ),
                        const SizedBox(height: 10),
                        HubModeTabs(
                          onWeekly: () => context.push('/weekly'),
                          onHeroes: () => context.push('/heroes'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: HubBottomNav(
                  onHome: () {},
                  onHero: () => context.push('/heroes'),
                  onInventory: () => context.push('/shop'),
                  onRanked: () => showComingSoonSheet(
                    context,
                    title: 'Ranked',
                    blurb: 'Competitive ranked mode is planned for later. '
                        'Your path rank badge tracks campaign clears for now.',
                  ),
                  onMore: () => context.push('/profile'),
                  onMoreLongPress: AppFlavor.showQaTools
                      ? () => _showQaToolsSheet(context, ref)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _enterCampaign(BuildContext context, WidgetRef ref) {
    ref.read(profileProvider.notifier).tickLifeRegen();
    final lives = ref.read(profileProvider).lives;
    if (lives <= 0) {
      _showNoLivesDialog(context, ref);
      return;
    }
    final progress = ref.read(homeCampaignProgressProvider).asData?.value;
    if (progress != null) {
      ref.read(selectedCampaignChapterIdProvider.notifier).state =
          progress.chapterId;
    }
    context.push('/chapters');
  }

  void _cycleHero(WidgetRef ref, int delta) {
    final profile = ref.read(profileProvider);
    final clears = profile.completedNodeIds.length;
    final unlocked = [
      for (final h in HeroCatalog.all)
        if (HeroUnlocks.isUnlocked(h.id, clears)) h,
    ];
    if (unlocked.length < 2) return;
    final idx = unlocked.indexWhere((h) => h.id == profile.selectedHeroId);
    final safeIdx = idx < 0 ? 0 : idx;
    final next =
        unlocked[(safeIdx + delta + unlocked.length * 4) % unlocked.length];
    ref.read(profileProvider.notifier).selectHero(next.id);
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

  void _showQaToolsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MythoraColors.deepTeal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QA tools',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.lock_open,
                  color: MythoraColors.amber,
                ),
                title: const Text('Unlock all campaign content'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _unlockAllForQa(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.restart_alt,
                  color: MythoraColors.ember,
                ),
                title: const Text('Reset local progress'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(profileProvider.notifier).resetProgress();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader({
    required this.coins,
    required this.gems,
    required this.livesLabel,
    required this.onLivesTap,
    required this.onSettings,
  });

  final int coins;
  final int gems;
  final String livesLabel;
  final VoidCallback onLivesTap;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mythora',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 29,
                        color: MythoraColors.parchment,
                        height: 1.05,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HubResourceChip(
                      label: '$coins',
                      icon: Icons.monetization_on,
                      iconColor: MythoraColors.amber,
                    ),
                    const SizedBox(width: 4),
                    HubResourceChip(
                      label: '$gems',
                      icon: Icons.diamond,
                      iconColor: const Color(0xFF5B9BD5),
                    ),
                    const SizedBox(width: 4),
                    HubResourceChip(
                      label: livesLabel,
                      icon: Icons.favorite,
                      iconColor: MythoraColors.ember,
                      onTap: onLivesTap,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: onSettings,
              icon: const Icon(
                Icons.settings,
                color: HubColors.frameGold,
                size: 22,
              ),
            ),
          ],
        ),
        Text(
          'Forge powerful combos. Write your legend.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: MythoraColors.muted,
              ),
        ),
      ],
    );
  }
}

class _HeroStage extends StatelessWidget {
  const _HeroStage({
    required this.hero,
    required this.height,
    required this.onTap,
    required this.onPrev,
    required this.onNext,
  });

  final HeroDef hero;
  final double height;
  final VoidCallback onTap;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            height: height,
            width: height * 1.05,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: height * 0.02,
                  child: SizedBox(
                    width: height * 0.88,
                    height: height * 0.24,
                    child: CustomPaint(
                      painter: _HeroPedestalPainter(),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: height * 0.06),
                    child: Image.asset(
                      GameAssets.hero(hero.id),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: height * 0.45,
                        color: MythoraColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onPrev,
              icon: const Icon(
                Icons.chevron_left,
                color: HubColors.frameGold,
                size: 28,
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: Text(
                hero.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      color: MythoraColors.parchment,
                    ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(
                Icons.chevron_right,
                color: HubColors.frameGold,
                size: 28,
              ),
            ),
          ],
        ),
        Text(
          'Tap for heroes',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MythoraColors.muted,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}

class _HeroPedestalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        Rect.fromLTWH(0, size.height * 0.12, size.width, size.height * 0.7);
    final glow = Paint()
      ..color = HubColors.glow.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(rect, glow);

    canvas.drawOval(
      rect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xB8326370), Color(0xE810222C)],
        ).createShader(rect),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = HubColors.glow.withValues(alpha: 0.55),
    );

    final inner = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.72,
      height: rect.height * 0.58,
    );
    canvas.drawOval(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = HubColors.frameGold.withValues(alpha: 0.42),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
