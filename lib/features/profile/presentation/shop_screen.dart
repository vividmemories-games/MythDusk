import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/presentation/home_hub_widgets.dart';
import '../../prep/domain/prep_item.dart';
import '../providers/mock_profile_provider.dart';

/// Prep shop: buy consumables with coins.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: MythoraColors.ink,
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
                iconColor: MythoraColors.amber,
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
                  const Icon(Icons.science, color: MythoraColors.muted),
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
                    color: MythoraColors.parchment,
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
