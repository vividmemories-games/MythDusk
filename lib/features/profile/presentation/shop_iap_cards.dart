import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/iap/iap_providers.dart';
import '../../../shared/widgets/myth_hub_shell.dart';
import '../../shop/domain/iap_catalog.dart';
import '../domain/economy_balance.dart';
import '../providers/mock_profile_provider.dart';

Future<void> _runBuy(
  BuildContext context,
  WidgetRef ref, {
  required String productId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await ref.read(iapCheckoutProvider).buy(productId);
  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.success
            ? (result.alreadyProcessed
                ? 'Already owned — no duplicate grant.'
                : 'Purchase complete.')
            : (result.message ?? 'Purchase failed.'),
      ),
    ),
  );
}

Future<void> _runQaClaim(
  BuildContext context,
  WidgetRef ref, {
  required String productId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await ref.read(iapCheckoutProvider).qaClaim(productId);
  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.success
            ? (result.alreadyProcessed ? 'Already claimed' : 'QA claim granted')
            : (result.message ?? 'QA claim failed'),
      ),
    ),
  );
}

class StarterPackIapCard extends ConsumerWidget {
  const StarterPackIapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimed = ref.watch(profileProvider).hasClaimedStarterPack();
    final ready = ref.watch(storeIapReadyProvider).valueOrNull ?? false;
    final price = ref
        .watch(storeIapServiceProvider)
        .localizedPrice(IapCatalog.starterPack.id);

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
                    'Visuals and currency only.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: claimed || !ready
                    ? null
                    : () => _runBuy(
                          context,
                          ref,
                          productId: IapCatalog.starterPack.id,
                        ),
                child: Text(
                  claimed
                      ? 'Claimed'
                      : ready
                          ? (price != null ? 'Buy · $price' : 'Buy')
                          : 'Store unavailable',
                ),
              ),
              if (AppFlavor.showQaTools && !claimed)
                OutlinedButton(
                  onPressed: () => _runQaClaim(
                    context,
                    ref,
                    productId: IapCatalog.starterPack.id,
                  ),
                  child: const Text('Claim (QA)'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ValuePackIapCard extends ConsumerWidget {
  const ValuePackIapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimed =
        ref.watch(profileProvider).hasClaimedStarterPack('value_pack_30d');
    final ready = ref.watch(storeIapReadyProvider).valueOrNull ?? false;
    final price = ref
        .watch(storeIapServiceProvider)
        .localizedPrice(IapCatalog.value30Day.id);

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
            '${IapGrantTable.value30DayLengthDays} days. Manual repurchase.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: claimed || !ready
                    ? null
                    : () => _runBuy(
                          context,
                          ref,
                          productId: IapCatalog.value30Day.id,
                        ),
                child: Text(
                  claimed
                      ? 'Claimed'
                      : ready
                          ? (price != null ? 'Buy · $price' : 'Buy')
                          : 'Store unavailable',
                ),
              ),
              if (AppFlavor.showQaTools && !claimed)
                OutlinedButton(
                  onPressed: () => _runQaClaim(
                    context,
                    ref,
                    productId: IapCatalog.value30Day.id,
                  ),
                  child: const Text('Claim (QA)'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ConsumableIapCard extends ConsumerWidget {
  const ConsumableIapCard({
    super.key,
    required this.title,
    required this.blurb,
    required this.productId,
  });

  final String title;
  final String blurb;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(storeIapReadyProvider).valueOrNull ?? false;
    final price = ref.watch(storeIapServiceProvider).localizedPrice(productId);

    return RelicPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: MythDuskColors.parchment,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            blurb,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: !ready
                    ? null
                    : () => _runBuy(context, ref, productId: productId),
                child: Text(
                  ready
                      ? (price != null ? 'Buy · $price' : 'Buy')
                      : 'Store unavailable',
                ),
              ),
              if (AppFlavor.showQaTools)
                OutlinedButton(
                  onPressed: () =>
                      _runQaClaim(context, ref, productId: productId),
                  child: const Text('Claim (QA)'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
