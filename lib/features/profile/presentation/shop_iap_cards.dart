import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_flavor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/iap/iap_providers.dart';
import '../../../services/iap/iap_service.dart';
import '../../../shared/widgets/myth_hub_shell.dart';
import '../../shop/domain/iap_catalog.dart';
import '../domain/economy_balance.dart';
import '../providers/mock_profile_provider.dart';

/// Product id currently confirming with the server (null = idle).
final iapConfirmingProductIdProvider = StateProvider<String?>((ref) => null);

String _successMessage(IapPurchaseResult result) {
  if (result.alreadyProcessed) {
    return 'Already owned — balance unchanged.';
  }
  switch (result.productId) {
    case 'mythdusk_starter_pack':
      return '+${StarterPackBalance.coins} coins, +${StarterPackBalance.gems} gems, '
          'and Dusk Sash added.';
    case 'mythdusk_value_30d':
      return '+${IapGrantTable.value30DayUpfrontGems} gems added. '
          'Daily gems unlock over ${IapGrantTable.value30DayLengthDays} days.';
    case 'mythdusk_gems_small':
      return '+${IapGrantTable.gemsSmall} gems added.';
    case 'mythdusk_gems_medium':
      return '+${IapGrantTable.gemsMedium} gems added.';
    case 'mythdusk_prep_box':
      return 'Prep box added to inventory.';
    default:
      return 'Purchase complete — balance updated.';
  }
}

Future<void> _runBuy(
  BuildContext context,
  WidgetRef ref, {
  required String productId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirming = ref.read(iapConfirmingProductIdProvider.notifier);
  if (ref.read(iapConfirmingProductIdProvider) != null) return;

  confirming.state = productId;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: MythDuskColors.ink,
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Confirming purchase…\nUpdating your balance.',
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                        color: MythDuskColors.parchment,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  IapPurchaseResult result;
  try {
    result = await ref.read(iapCheckoutProvider).buy(productId);
  } finally {
    confirming.state = null;
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.success
            ? _successMessage(result)
            : (result.message ?? 'Purchase failed.'),
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

String? _localizedPrice(WidgetRef ref, bool ready, String productId) {
  if (!ready) return null;
  return ref.watch(storeIapServiceProvider).localizedPrice(productId);
}

Future<void> _runQaClaim(
  BuildContext context,
  WidgetRef ref, {
  required String productId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirming = ref.read(iapConfirmingProductIdProvider.notifier);
  if (ref.read(iapConfirmingProductIdProvider) != null) return;

  confirming.state = productId;
  final result = await ref.read(iapCheckoutProvider).qaClaim(productId);
  confirming.state = null;
  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.success
            ? (result.alreadyProcessed
                ? 'Already claimed'
                : _successMessage(result))
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
    final busy = ref.watch(iapConfirmingProductIdProvider) != null;
    final price = _localizedPrice(ref, ready, IapCatalog.starterPack.id);

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
                onPressed: claimed || !ready || busy
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
                  onPressed: busy
                      ? null
                      : () => _runQaClaim(
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
    final busy = ref.watch(iapConfirmingProductIdProvider) != null;
    final price = _localizedPrice(ref, ready, IapCatalog.value30Day.id);

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
                onPressed: claimed || !ready || busy
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
                  onPressed: busy
                      ? null
                      : () => _runQaClaim(
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
    final busy = ref.watch(iapConfirmingProductIdProvider) != null;
    final price = _localizedPrice(ref, ready, productId);

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
                onPressed: !ready || busy
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
                  onPressed: busy
                      ? null
                      : () => _runQaClaim(context, ref, productId: productId),
                  child: const Text('Claim (QA)'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
