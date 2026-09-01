import 'package:flutter_test/flutter_test.dart';
import 'package:mythdusk/core/config/remote_config_keys.dart';
import 'package:mythdusk/features/battle_pass/domain/battle_pass_catalog.dart';
import 'package:mythdusk/features/shop/domain/iap_catalog.dart';
import 'package:mythdusk/features/shop/domain/offer_bundle_catalog.dart';
import 'package:mythdusk/services/iap/iap_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mythdusk/services/rewarded_ad/rewarded_ad_service.dart';

void main() {
  test('IAP catalog ids are stable', () {
    expect(IapCatalog.byId('mythdusk_starter_pack')?.entitlementId,
        'starter_pack_001');
    expect(IapGrantTable.gemsSmall, 80);
  });

  test('unavailable port does not grant', () async {
    const port = UnavailableIapPurchasePort();
    final result = await port.purchase(
      const IapPurchaseRequest(
        productId: 'mythdusk_starter_pack',
        receiptId: 'r1',
      ),
    );
    expect(result.success, isFalse);
  });

  test('battle pass has no exclusive combat power and stays off by default',
      () {
    expect(BattlePassCatalog.enabledByDefault, isFalse);
    expect(
      RemoteConfigKeys.defaults[RemoteConfigKeys.battlePassEnabled],
      isFalse,
    );
    expect(BattlePassCatalog.premiumHasExclusiveCombatPower, isFalse);
    for (final reward in BattlePassCatalog.rewards) {
      expect(reward.grantsCombatPower, isFalse);
    }
  });

  test('contextual bundles never sell campaign heroes', () {
    for (final bundle in OfferBundleCatalog.all) {
      expect(OfferBundleCatalog.sellsCampaignHero(bundle), isFalse);
    }
    expect(
      OfferBundleCatalog.visibleFor(
        campaignClears: 0,
        unlockedHeroIds: {'mage'},
      ),
      isEmpty,
    );
    expect(
      OfferBundleCatalog.visibleFor(
        campaignClears: 5,
        unlockedHeroIds: {'mage', 'knight'},
      ),
      isNotEmpty,
    );
  });

  test('rewarded ads honor a daily cap', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const ads = RewardedAdService();
    expect(ads.canShow(prefs, cap: 1), isTrue);
    await ads.record(prefs);
    expect(ads.usedToday(prefs), 1);
    expect(ads.canShow(prefs, cap: 1), isFalse);
  });
}
