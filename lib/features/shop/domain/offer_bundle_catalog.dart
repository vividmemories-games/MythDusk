import '../../heroes/domain/hero_unlocks.dart';

/// Contextual bundles shown after achievements — never before a hard fight.
class OfferBundle {
  const OfferBundle({
    required this.id,
    required this.title,
    required this.trigger,
    required this.productId,
    this.coins = 0,
    this.gems = 0,
    this.cosmeticId,
  });

  final String id;
  final String title;
  final OfferTrigger trigger;
  final String productId;
  final int coins;
  final int gems;
  final String? cosmeticId;
}

enum OfferTrigger { chapterClear, newHeroUnlocked }

abstract final class OfferBundleCatalog {
  static const chapterClear = OfferBundle(
    id: 'bundle_chapter_clear',
    title: 'Chapter celebration',
    trigger: OfferTrigger.chapterClear,
    productId: 'mythdusk_gems_small',
    gems: 80,
    cosmeticId: 'overlay_dusk_sash',
  );

  static const newHero = OfferBundle(
    id: 'bundle_new_hero',
    title: 'Hero growth cosmetic',
    trigger: OfferTrigger.newHeroUnlocked,
    productId: 'mythdusk_prep_box',
    cosmeticId: 'overlay_dusk_sash',
  );

  static const all = [chapterClear, newHero];

  static List<OfferBundle> visibleFor({
    required int campaignClears,
    required Set<String> unlockedHeroIds,
  }) {
    return [
      if (campaignClears >= 5) chapterClear,
      if (unlockedHeroIds.length > 1) newHero,
    ];
  }

  /// Campaign hero IDs must never appear as bundle exclusives.
  static bool sellsCampaignHero(OfferBundle bundle) {
    return HeroUnlocks.thresholds.containsKey(bundle.productId) ||
        HeroUnlocks.thresholds.containsKey(bundle.id);
  }
}
