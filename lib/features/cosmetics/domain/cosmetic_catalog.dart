import '../../mastery/domain/mastery_catalog.dart';

/// Cosmetic slots. Overlays are visual-only (no combat stats).
enum CosmeticSlot { overlay, title, frame }

/// Data-driven cosmetic definition.
class CosmeticDef {
  const CosmeticDef({
    required this.id,
    required this.name,
    required this.slot,
    this.heroId,
    this.overlayTintArgb,
    this.overlayAssetPath,
  });

  final String id;
  final String name;
  final CosmeticSlot slot;

  /// Null = any hero.
  final String? heroId;

  /// 0xAARRGGBB tint for the middle-approach overlay (no extra art required).
  final int? overlayTintArgb;

  /// Optional PNG/WebP overlay when art lands.
  final String? overlayAssetPath;

  bool availableFor(String heroId) =>
      this.heroId == null || this.heroId == heroId;
}

abstract final class CosmeticCatalog {
  static const duskSash = CosmeticDef(
    id: StarterOverlayId.duskSash,
    name: 'Dusk Sash',
    slot: CosmeticSlot.overlay,
    overlayTintArgb: 0xE6E6C87A,
  );

  static List<CosmeticDef> get all {
    final fromMastery = <CosmeticDef>[];
    for (final m in MasteryCatalog.all) {
      final id = m.rewardCosmeticId;
      if (id == null) continue;
      if (m.rewardType == MasteryRewardType.cosmeticTitle) {
        fromMastery.add(
          CosmeticDef(
            id: id,
            name: m.title,
            slot: CosmeticSlot.title,
            heroId: m.heroId,
          ),
        );
      } else if (m.rewardType == MasteryRewardType.cosmeticFrame) {
        fromMastery.add(
          CosmeticDef(
            id: id,
            name: '${m.title} Frame',
            slot: CosmeticSlot.frame,
            heroId: m.heroId,
          ),
        );
      }
    }
    return [duskSash, ...fromMastery];
  }

  static CosmeticDef? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<CosmeticDef> claimedFor({
    required Set<String> claimedIds,
    required CosmeticSlot slot,
    String? heroId,
  }) {
    return [
      for (final c in all)
        if (c.slot == slot &&
            claimedIds.contains(c.id) &&
            (heroId == null || c.availableFor(heroId)))
          c,
    ];
  }
}

abstract final class StarterOverlayId {
  static const duskSash = 'overlay_dusk_sash';
}
