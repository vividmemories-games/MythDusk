import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_providers.dart';
import '../../../core/analytics/gameplay_analytics.dart';
import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/myth_hub_shell.dart';
import '../../../shared/widgets/challenge_art.dart';
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

    return MythHubShell(
      title: 'Shop',
      subtitle: 'Supplies for the road ahead.',
      resources: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            HubResourceChip(
                label: '${profile.coins}',
                icon: Icons.monetization_on,
                iconColor: MythDuskColors.amber),
            HubResourceChip(
                label: '${profile.gems}',
                icon: Icons.diamond,
                iconColor: const Color(0xFF5B9BD5))
          ]),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text('Battle supplies', style: challengeTextStyle(18, bold: true)),
          const SizedBox(height: 4),
          Text('Optional aids · prices in coins', style: textTheme.bodyMedium),
          const SizedBox(height: 12),
          for (final id in PrepItemId.values) ...[
            _ShopRow(id: id),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          Text('Offers', style: challengeTextStyle(18, bold: true)),
          const SizedBox(height: 8),
          const _StarterPackCard(),
          const SizedBox(height: 10),
          const _ValuePackCard(),
          const SizedBox(height: 10),
          const _BundlesCard(),
          if (RemoteConfigKeys.defaults[RemoteConfigKeys.battlePassEnabled] ==
              true) ...[
            const SizedBox(height: 10),
            const _BattlePassCard(),
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

    return RelicPanel(
      padding: const EdgeInsets.all(12),
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
                  style: challengeTextStyle(14, bold: true),
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
            child: Semantics(
                label: 'Buy ${id.displayName} for $cost coins',
                child: ExcludeSemantics(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.monetization_on, size: 16),
                  const SizedBox(width: 4),
                  Text('$cost'),
                ]))),
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

    return RelicPanel(
      padding: const EdgeInsets.all(14),
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
                    'Available when the store opens.',
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
    return RelicPanel(
      padding: const EdgeInsets.all(14),
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
            'Available when the store opens.',
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
    return RelicPanel(
      padding: const EdgeInsets.all(14),
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
                ? 'New offers appear as you explore realms and unlock heroes.'
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
    return RelicPanel(
      padding: const EdgeInsets.all(14),
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
