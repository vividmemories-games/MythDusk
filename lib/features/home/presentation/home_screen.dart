import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_providers.dart';
import '../../../core/analytics/gameplay_analytics.dart';
import '../../../core/assets/game_assets.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cosmetic_hero_art.dart';
import '../../campaign/data/campaign_repository.dart';
import '../../cosmetics/domain/cosmetic_catalog.dart';
import '../../expedition/domain/expedition_models.dart';
import '../../heroes/domain/hero_def.dart';
import '../../heroes/domain/hero_unlocks.dart';
import '../../prep/domain/prep_item.dart';
import '../../profile/domain/economy_balance.dart';
import '../../profile/providers/mock_profile_provider.dart';
import 'home_hub_widgets.dart';
import 'home_more_sheet.dart';
import 'home_progress.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _checkedUnlockCelebration = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _checkedUnlockCelebration) return;
      _checkedUnlockCelebration = true;
      final pending = ref.read(profileProvider).pendingUnlockCelebrations;
      if (pending.isEmpty) return;
      context.go('/hero_unlock/${pending.first}');
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  const ColoredBox(color: MythDuskColors.ink),
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
                          clears: clears,
                          coins: profile.coins,
                          gems: profile.gems,
                          livesLabel: livesLabel,
                          onLivesTap: () => _onLivesTap(context, ref),
                          onSettings: () => context.push('/settings'),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final heroH = (constraints.maxHeight - 48)
                                  .clamp(88.0, 220.0);
                              return Center(
                                child: _HeroStage(
                                  hero: selected,
                                  profile: profile,
                                  height: heroH,
                                  onTap: () => context.push('/heroes'),
                                  onPrev: () => _cycleHero(ref, -1),
                                  onNext: () => _cycleHero(ref, 1),
                                ),
                              );
                            },
                          ),
                        ),
                        progressAsync.when(
                          data: (p) => HubPlayPanel(
                            prepSlots: _prepSlots(context, profile),
                            onShop: () => context.push('/shop'),
                            progressTitle: '${p.actTitle} · ${p.chapterTitle}',
                            progressSubtitle:
                                'Node ${p.completedInChapter} / ${p.totalInChapter}',
                            completed: p.completedInChapter,
                            total: p.totalInChapter,
                            onEnterCampaign: () => _enterCampaign(context, ref),
                          ),
                          loading: () => HubPlayPanel(
                            prepSlots: _prepSlots(context, profile),
                            onShop: () => context.push('/shop'),
                            progressTitle: 'Campaign',
                            progressSubtitle: 'Loading…',
                            completed: 0,
                            total: 20,
                            onEnterCampaign: () => _enterCampaign(context, ref),
                          ),
                          error: (_, __) => HubPlayPanel(
                            prepSlots: _prepSlots(context, profile),
                            onShop: () => context.push('/shop'),
                            progressTitle: 'Campaign',
                            progressSubtitle: 'Node $clears',
                            completed: clears.clamp(0, 20),
                            total: 20,
                            onEnterCampaign: () => _enterCampaign(context, ref),
                          ),
                        ),
                        const SizedBox(height: 8),
                        HubRetentionChips(
                          onDaily: () => context.push('/daily'),
                          onWeekly: () => context.push('/weekly'),
                          showExpedition: profile.completedNodeIds.length >=
                              ExpeditionBalance.minCampaignClears,
                          expeditionInProgress:
                              profile.activeExpedition?.isInProgress ?? false,
                          onExpedition: () => context.push('/expedition'),
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
                  onHeroes: () => context.push('/heroes'),
                  onShop: () => context.push('/shop'),
                  onRanked: () => context.push('/challenge'),
                  onMore: () => showHomeMoreSheet(
                    context,
                    expeditionUnlocked: profile.completedNodeIds.length >=
                        ExpeditionBalance.minCampaignClears,
                    expeditionInProgress:
                        profile.activeExpedition?.isInProgress ?? false,
                    onProfile: () => context.push('/profile'),
                    onExpedition: () => context.push('/expedition'),
                  ),
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

  Widget _prepSlots(BuildContext context, PlayerProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final id in PrepItemId.values) ...[
          HubPrepSlot(
            assetPath: id.assetPath,
            count: profile.prepCount(id),
            onTap: () => context.push('/shop'),
          ),
          const SizedBox(width: 8),
        ],
        const HubLockedPrepSlot(
          unlockHint: 'Unlocks at Act III',
        ),
      ],
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

    ref.read(gameplayAnalyticsProvider).log(
      GameplayAnalyticsEvents.lifeRefillOfferShown,
      {'remaining': remaining},
    );

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MythDuskColors.deepTeal,
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
                    if (ok) {
                      ref.read(gameplayAnalyticsProvider).log(
                        GameplayAnalyticsEvents.lifeRefillPurchased,
                        {
                          'amount': EconomyBalance.gemLifeRefillAmount,
                          'cost': EconomyBalance.gemLifeRefillCost,
                        },
                      );
                    }
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
      backgroundColor: MythDuskColors.deepTeal,
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
                  color: MythDuskColors.amber,
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
                  color: MythDuskColors.ember,
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
    required this.clears,
    required this.coins,
    required this.gems,
    required this.livesLabel,
    required this.onLivesTap,
    required this.onSettings,
  });

  final int clears;
  final int coins;
  final int gems;
  final String livesLabel;
  final VoidCallback onLivesTap;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HubRankBadge(clears: clears),
        const SizedBox(width: 6),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HubResourceChip(
                  label: '$coins',
                  icon: Icons.monetization_on,
                  iconColor: MythDuskColors.amber,
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
                  iconColor: MythDuskColors.ember,
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
          icon: Icon(
            Icons.settings,
            color: MythDuskColors.parchment.withValues(alpha: 0.85),
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _HeroStage extends StatelessWidget {
  const _HeroStage({
    required this.hero,
    required this.profile,
    required this.height,
    required this.onTap,
    required this.onPrev,
    required this.onNext,
  });

  final HeroDef hero;
  final PlayerProfile profile;
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
                    child: CosmeticHeroArt(
                      heroId: hero.id,
                      assetPath: GameAssets.hero(hero.id),
                      profile: profile,
                      fit: BoxFit.contain,
                      showPlate: false,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: height * 0.45,
                        color: MythDuskColors.muted,
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
              icon: Icon(
                Icons.chevron_left,
                color: MythDuskColors.parchment.withValues(alpha: 0.85),
                size: 28,
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: Text(
                [
                  hero.name,
                  if (profile.equippedTitleId != null)
                    CosmeticCatalog.byId(profile.equippedTitleId!)?.name,
                ].whereType<String>().join(' · '),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      color: MythDuskColors.parchment,
                    ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: Icon(
                Icons.chevron_right,
                color: MythDuskColors.parchment.withValues(alpha: 0.85),
                size: 28,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroPedestalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.42,
      size.width * 0.8,
      size.height * 0.4,
    );
    canvas.drawOval(
      shadow,
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final rect =
        Rect.fromLTWH(0, size.height * 0.22, size.width, size.height * 0.58);
    canvas.drawOval(
      rect,
      Paint()
        ..color = HubColors.glow.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x66325868), Color(0xE808141C)],
        ).createShader(rect),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = HubColors.glow.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
