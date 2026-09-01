import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/analytics/gameplay_analytics.dart';
import 'package:mythdusk/core/config/remote_config_keys.dart';
import 'package:mythdusk/features/cosmetics/domain/cosmetic_catalog.dart';
import 'package:mythdusk/features/profile/domain/economy_balance.dart';
import 'package:mythdusk/features/profile/providers/mock_profile_provider.dart';
import 'package:mythdusk/features/shop/domain/iap_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DefeatContinueRules', () {
    test('allows one ad and one paid continue', () {
      expect(
        DefeatContinueRules.canUseAd(adUsed: 0, paidUsed: 0),
        isTrue,
      );
      expect(
        DefeatContinueRules.canUsePaid(
          adUsed: 1,
          paidUsed: 0,
          coins: DefeatContinueBalance.paidContinueCoinCost,
        ),
        isTrue,
      );
      expect(
        DefeatContinueRules.canUseAd(adUsed: 1, paidUsed: 0),
        isFalse,
      );
      expect(
        DefeatContinueRules.canUsePaid(
          adUsed: 1,
          paidUsed: 1,
          coins: 9999,
        ),
        isFalse,
      );
    });

    test('paid continue requires coins', () {
      expect(
        DefeatContinueRules.canUsePaid(
          adUsed: 0,
          paidUsed: 0,
          coins: DefeatContinueBalance.paidContinueCoinCost - 1,
        ),
        isFalse,
      );
    });
  });

  group('ProfileNotifier monetization foundations', () {
    late ProfileNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      notifier = ProfileNotifier(prefs);
    });

    test('encounter id persists for the same node and resets on a new node',
        () {
      final first = notifier.ensureActiveEncounterId(nodeId: 'node_a');
      final again = notifier.ensureActiveEncounterId(nodeId: 'node_a');
      expect(again, first);
      final other = notifier.ensureActiveEncounterId(nodeId: 'node_b');
      expect(other, isNot(first));
      expect(notifier.state.encounterAdContinuesUsed, 0);
    });

    test('ad then paid continue arms revive once each', () {
      notifier.ensureActiveEncounterId(nodeId: 'node_a');
      expect(notifier.consumeAdContinueAndArmRevive(), isTrue);
      expect(notifier.state.pendingContinueRevive, isTrue);
      expect(notifier.consumeAdContinueAndArmRevive(), isFalse);

      expect(notifier.consumePaidContinueAndArmRevive(), isTrue);
      expect(
        notifier.state.coins,
        500 - DefeatContinueBalance.paidContinueCoinCost,
      );
      expect(notifier.consumePaidContinueAndArmRevive(), isFalse);
    });

    test('pending continue revive is consumed once for the active encounter',
        () {
      final id = notifier.ensureActiveEncounterId(nodeId: 'node_a');
      expect(notifier.consumeAdContinueAndArmRevive(), isTrue);
      expect(notifier.consumePendingContinueRevive(id), isTrue);
      expect(notifier.state.pendingContinueRevive, isFalse);
      expect(notifier.consumePendingContinueRevive(id), isFalse);
    });

    test('starter pack is one-time and grants cosmetic without combat stats',
        () {
      final coinsBefore = notifier.state.coins;
      expect(notifier.claimStarterPack(), isTrue);
      expect(notifier.state.coins, coinsBefore + StarterPackBalance.coins);
      expect(notifier.state.gems, 50 + StarterPackBalance.gems);
      expect(
        notifier.state.claimedCosmeticIds,
        contains(StarterPackBalance.cosmeticId),
      );
      expect(notifier.claimStarterPack(), isFalse);
    });

    test('equip and unequip overlay persists per hero', () {
      expect(notifier.claimStarterPack(), isTrue);
      expect(
        notifier.equipCosmetic(StarterPackBalance.cosmeticId, heroId: 'mage'),
        isTrue,
      );
      expect(notifier.state.equippedOverlayIdFor('mage'), 'overlay_dusk_sash');
      expect(notifier.state.equippedOverlayIdFor('knight'), isNull);

      final encoded = jsonEncode(notifier.state.toJson());
      final restored = PlayerProfile.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(restored.equippedOverlayIdFor('mage'), 'overlay_dusk_sash');

      expect(
        notifier.unequipCosmetic(StarterPackBalance.cosmeticId, heroId: 'mage'),
        isTrue,
      );
      expect(notifier.state.equippedOverlayIdFor('mage'), isNull);
    });

    test('cannot equip an unclaimed cosmetic', () {
      expect(
        notifier.equipCosmetic(StarterPackBalance.cosmeticId, heroId: 'mage'),
        isFalse,
      );
    });

    test('dusk sash overlay is visual-only in the catalog', () {
      final def = CosmeticCatalog.byId(StarterOverlayId.duskSash);
      expect(def, isNotNull);
      expect(def!.slot, CosmeticSlot.overlay);
      expect(def.overlayTintArgb, isNotNull);
    });
  });

  group('economy analytics event names', () {
    test('stable names are defined for refill, shop, continue, cosmetic', () {
      expect(GameplayAnalyticsEvents.lifeRefillOfferShown,
          'life_refill_offer_shown');
      expect(
          GameplayAnalyticsEvents.lifeRefillPurchased, 'life_refill_purchased');
      expect(GameplayAnalyticsEvents.prepItemPurchased, 'prep_item_purchased');
      expect(
          GameplayAnalyticsEvents.starterPackClaimed, 'starter_pack_claimed');
      expect(GameplayAnalyticsEvents.defeatContinueOffered,
          'defeat_continue_offered');
      expect(
          GameplayAnalyticsEvents.defeatContinueUsed, 'defeat_continue_used');
      expect(GameplayAnalyticsEvents.cosmeticEquipped, 'cosmetic_equipped');
      expect(GameplayAnalyticsEvents.rewardedAdStarted, 'rewarded_ad_started');
      expect(GameplayAnalyticsEvents.iapStarted, 'iap_started');
      expect(RemoteConfigKeys.battlePassEnabled, 'battle_pass_enabled');
      expect(IapCatalog.starterPack.id, 'mythdusk_starter_pack');
    });
  });
}
