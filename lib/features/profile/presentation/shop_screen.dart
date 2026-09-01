import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_providers.dart';
import '../../../core/analytics/gameplay_analytics.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/presentation/home_hub_widgets.dart';
import '../../prep/domain/prep_item.dart';
import '../../heroes/domain/hero_unlocks.dart';
import '../../shop/domain/iap_catalog.dart';
import '../../shop/domain/offer_bundle_catalog.dart';
import '../../battle_pass/domain/battle_pass_catalog.dart';
import '../../../core/config/remote_config_keys.dart';
import '../domain/economy_balance.dart';
import '../providers/mock_profile_provider.dart';

/// Prep shop: buy consumables with coins.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      appBar: AppBar(
        title: const Text('Shop'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: HubResourceChip(
                label: '${profile.coins}',
                icon: Icons.monetization_on,
                iconColor: MythDuskColors.amber,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'Prep for the next fight. Prices in coins.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const _StarterPackCard(),
          const SizedBox(height: 16),
          const _ValuePackCard(),
          const SizedBox(height: 16),
          const _BundlesCard(),
          const SizedBox(height: 16),
          const _BattlePassCard(),
          const SizedBox(height: 16),
          for (final id in PrepItemId.values) ...[
            _ShopRow(id: id),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ShopRow extends ConsumerWidget {
  const _ShopRow({required this.id});

  final PrepItemId id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final cost = PrepBalance.shopCoinCost[id] ?? 0;
    final canBuy = profile.coins >= cost;
    final owned = profile.prepCount(id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HubColors.frameGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Image.asset(
              id.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.science, color: MythDuskColors.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MythDuskColors.parchment,
                  ),
                ),
                Text(
                  '${id.blurb} · owned ×$owned',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: canBuy
                ? () {
                    final ok =
                        ref.read(profileProvider.notifier).purchasePrepItem(id);
                    if (ok) {
                      ref.read(gameplayAnalyticsProvider).log(
                        GameplayAnalyticsEvents.prepItemPurchased,
                        {'itemId': id.storageKey, 'cost': cost},
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Bought ${id.displayName}' : 'Not enough coins',
                        ),
                      ),
                    );
                  }
                : null,
            child: Text('$cost'),
          ),
        ],
      ),
    );
  }
}

class _StarterPackCard extends ConsumerWidget {
  const _StarterPackCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final claimed = profile.hasClaimedStarterPack();
    final canClaim = AppFlavor.showQaTools && !claimed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HubColors.frameGold.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Starter pack',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: MythDuskColors.parchment,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            claimed
                ? 'Claimed — one-time entitlement.'
                : '+${StarterPackBalance.coins} coins, '
                    '+${StarterPackBalance.gems} gems, Dusk Sash overlay. '
                    'Visuals and currency only. '
                    'Future SKU: ${IapCatalog.starterPack.id}.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: canClaim
                ? () {
                    final ok =
                        ref.read(profileProvider.notifier).claimStarterPack();
                    if (ok) {
                      ref.read(gameplayAnalyticsProvider).log(
                        GameplayAnalyticsEvents.starterPackClaimed,
                        {'packId': StarterPackBalance.id},
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Starter pack claimed' : 'Already claimed',
                        ),
                      ),
                    );
                  }
                : null,
            child: Text(
              claimed
                  ? 'Claimed'
                  : AppFlavor.showQaTools
                      ? 'Claim (QA)'
                      : 'Coming with store',
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuePackCard extends ConsumerWidget {
  const _ValuePackCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimed =
        ref.watch(profileProvider).hasClaimedStarterPack('value_pack_30d');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HubColors.frameGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '30-day value pack',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: MythDuskColors.parchment,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+${IapGrantTable.value30DayUpfrontGems} gems up front, then '
            '${IapGrantTable.value30DayDailyGems}/day for '
            '${IapGrantTable.value30DayLengthDays} days. Manual repurchase. '
            'SKU ${IapCatalog.value30Day.id}.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: AppFlavor.showQaTools && !claimed
                ? () {
                    final ok = ref
                        .read(profileProvider.notifier)
                        .claimValuePack30Day();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? '30-day pack claimed (QA)' : 'Already claimed',
                        ),
                      ),
                    );
                  }
                : null,
            child: Text(
              claimed
                  ? 'Claimed'
                  : AppFlavor.showQaTools
                      ? 'Claim (QA)'
                      : 'Coming with store',
            ),
          ),
        ],
      ),
    );
  }
}

class _BundlesCard extends ConsumerWidget {
  const _BundlesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final bundles = OfferBundleCatalog.visibleFor(
      campaignClears: profile.completedNodeIds.length,
      unlockedHeroIds: {
        for (final id in HeroUnlocks.thresholds.keys)
          if (HeroUnlocks.isUnlocked(id, profile.completedNodeIds.length)) id,
      },
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HubColors.frameGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Celebration bundles',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: MythDuskColors.parchment,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bundles.isEmpty
                ? 'Unlocks after a chapter celebration or extra hero — never '
                    'as a difficulty-spike paywall.'
                : bundles.map((b) => b.title).join(' · '),
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BattlePassCard extends StatelessWidget {
  const _BattlePassCard();

  @override
  Widget build(BuildContext context) {
    final enabled =
        RemoteConfigKeys.defaults[RemoteConfigKeys.battlePassEnabled] as bool;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HubColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HubColors.frameGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Battle pass',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: MythDuskColors.parchment,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            enabled
                ? 'Season ${BattlePassCatalog.seasonId}: cosmetics, coins, gems, '
                    'materials. No exclusive combat power.'
                : 'Hidden until retention is proven '
                    '(${RemoteConfigKeys.battlePassEnabled}=false).',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
