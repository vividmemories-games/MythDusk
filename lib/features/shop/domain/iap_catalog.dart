import '../../profile/domain/economy_balance.dart';

/// Placeholder store product ids. No IAP SDK in this phase.
/// Grants must go through Cloud Functions when wired (see
/// docs/01_Game_Design/Monetization.md Phase 2).
abstract final class IapCatalog {
  static const starterPack = IapProductDef(
    id: 'mythdusk_starter_pack',
    entitlementId: StarterPackBalance.id,
    kind: IapProductKind.nonConsumable,
  );

  static const value30Day = IapProductDef(
    id: 'mythdusk_value_30d',
    entitlementId: 'value_pack_30d',
    kind: IapProductKind.nonRenewing,
  );

  static const gemsSmall = IapProductDef(
    id: 'mythdusk_gems_small',
    entitlementId: 'gems_small',
    kind: IapProductKind.consumable,
  );

  static const gemsMedium = IapProductDef(
    id: 'mythdusk_gems_medium',
    entitlementId: 'gems_medium',
    kind: IapProductKind.consumable,
  );

  static const prepBox = IapProductDef(
    id: 'mythdusk_prep_box',
    entitlementId: 'prep_box',
    kind: IapProductKind.consumable,
  );

  static const all = [
    starterPack,
    value30Day,
    gemsSmall,
    gemsMedium,
    prepBox,
  ];

  static IapProductDef? byId(String id) {
    for (final product in all) {
      if (product.id == id) return product;
    }
    return null;
  }
}

/// Server-authoritative IAP grants. Client UI may display these; Functions
/// must look up the same table and ignore client-supplied amounts.
abstract final class IapGrantTable {
  static const gemsSmall = 80;
  static const gemsMedium = 250;
  static const value30DayUpfrontGems = 200;
  static const value30DayDailyGems = 5;
  static const value30DayLengthDays = 30;
  static const prepBox = {'vanguard_tonic': 2, 'aegis_flask': 1};
}

enum IapProductKind { consumable, nonConsumable, nonRenewing }

class IapProductDef {
  const IapProductDef({
    required this.id,
    required this.entitlementId,
    required this.kind,
  });

  final String id;
  final String entitlementId;
  final IapProductKind kind;
}
