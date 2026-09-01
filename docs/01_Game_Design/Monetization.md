# Monetization

| Field | Value |
|-------|-------|
| **Status** | Active — V1.0 scope locked; later phases specified, not implemented |
| **Last Updated** | 2026-08-21 |
| **Authority** | Numbers in [Balancing_Bible](Balancing_Bible.md); product rules here |
| **Related** | [Economy](Economy.md) · [Progression](Progression.md) · [PHASES](../PHASES.md) · `.cursor/rules/08-monetization-economy.mdc` |

Convenience and cosmetics only. Campaign heroes stay guaranteed milestone unlocks. No gacha on existing campaign heroes. No exclusive combat power behind pay.

## Currencies (locked)

| Currency | Role |
|----------|------|
| Coins | Soft currency — prep shop, light upgrades, paid defeat continue |
| Gems | Premium currency — capped life refills, future packs/cosmetics |
| Lives | Only stamina gate (maps “energy” rules). No second energy meter |

Do not add a third spendable currency in V1.0.

## Campaign heroes (locked)

Unlock thresholds live in `lib/features/heroes/domain/hero_unlocks.dart`: Mage 0 / Knight 5 / Ranger 15 / Priest 30 / Ninja 50 campaign clears.

- Every unlocked hero is fully usable without duplicates.
- Existing free heroes must never move behind a paywall.
- Optional future heroes (events / summons) must not include these campaign IDs.
- Early access, if ever considered, still leaves the milestone free; purchasers get an equivalent reward at that node.

## Never buy

Gems / IAP must not purchase:

- Combat stats (damage, HP, AP, Moves beyond capped prep)
- Uncapped revives or uncapped Second Wind stock
- Extra battle Moves as a paid product
- Premium-only combat mechanics
- Guaranteed win / skip boss
- Mandatory paid continues
- Hero duplicates required for viability
- Stat-based equipment gacha
- Spending-based VIP levels
- Client-trusted reward amounts

## Version 1.0 scope

1. Coins + gems only
2. Lives as the only stamina gate
3. One-time starter pack (QA claim now; real IAP in Phase 2)
4. Capped gem life refills (already live)
5. Capped optional defeat continue (1 rewarded ad + 1 paid per encounter)
6. Small cosmetics (overlay skins + mastery titles/frames; equip/unequip)
7. Optional rewarded ads (stub in Phase 1; SDK in Phase 3)
8. Prep inventory packs (Phase 3, when IAP is live)
9. Remote Config + analytics (names now; Firebase in Phase 2)
10. Battle pass **off** until retention is validated (Phase 4)

**Out of V1.0:** hero summons, early-access campaign heroes, auto-renew subscriptions, interstitial ads, move purchases, large cosmetic art sets, 5+ contextual bundles.

## Phase 0–1 (now)

Local foundations. No real money, no ads SDK, no Firebase settlement.

| Surface | Behavior |
|---------|----------|
| Defeat continue | Optional. 1 ad stub (QA/dev) + 1 coin continue per encounter. Revive = 30% max HP (same as Second Wind). Never required |
| Starter pack | One-time entitlement; QA/dev claim grants capped coins/gems + one overlay cosmetic |
| Cosmetics | Overlay tint/layer on hero portraits; equip persistence; titles/frames from mastery |
| Analytics | Stable event names logged at offer/purchase/equip/continue |

## Phase 2 — Firebase + IAP (later)

Do not ship real SKUs until Cloud Functions validate receipts.

### Settlement

- Client submits store receipt + `productId` + idempotency key
- Function verifies with App Store / Play, grants entitlements, writes `users/{uid}`
- Duplicate receipts no-op
- Restore purchases for non-consumables (starter, cosmetics)

### Product types

| Type | Examples |
|------|----------|
| Consumable | Gem packs, coin packs, prep boxes |
| Non-consumable | Starter pack, cosmetics |
| Non-renewing | 30-day value pack (manual repurchase; no auto-renew at first) |

### Placeholder product IDs

Code: `lib/features/shop/domain/iap_catalog.dart`

| ID | Kind | Notes |
|----|------|-------|
| `mythdusk_starter_pack` | non-consumable | ~€1.99 |
| `mythdusk_value_30d` | non-renewing | ~€4.99 |
| `mythdusk_gems_small` | consumable | Remote-configured grant |
| `mythdusk_gems_medium` | consumable | Remote-configured grant |
| `mythdusk_prep_box` | consumable | Inventory only |

### Remote Config keys

Code: `lib/core/config/remote_config_keys.dart`

| Key | Purpose |
|-----|---------|
| `starter_pack_enabled` | Feature flag |
| `defeat_continue_enabled` | Feature flag |
| `battle_pass_enabled` | Stay false until Phase 4 |
| `gem_life_refill_cost` | Override Bible default |
| `gem_life_refills_per_day` | Cap |
| `defeat_continue_coin_cost` | Paid continue price |
| `rewarded_ad_daily_cap` | 3–5 |
| `starter_pack_coins` / `starter_pack_gems` | Grant amounts |

## Phase 3 — Soft-launch catalog (later)

- Real starter pack purchase
- 30-day value pack: premium currency up front + smaller daily gem claims; optional cosmetic; **manual** repurchase
- 1–2 contextual bundles after achievements (chapter clear / new-hero growth cosmetic). Not before difficult fights. Packs never required for hero viability
- Small cosmetic shop (frames, titles, overlay skins)
- Rewarded ads, daily cap 3–5: double post-victory reward, defeat continue, life-refill assist. No interstitials in battle, campaign nav, or story
- Prep packs/boxes as gem sinks (Bible §3.5)

Show offers after positive achievements, not as difficulty-spike paywalls.

## Phase 4 — Battle pass (later, post D7/D30)

Activate after retention is validated. ~6–8 week season, ~€7.99 localized.

- Free + premium tracks
- Cosmetics, coins/gems, crafting/upgrade **materials**, profile cosmetics
- Seasonal quests
- Premium track may accelerate progression moderately
- **No exclusive combat power** on the premium track
- Campaign heroes remain milestone unlocks

## Analytics (minimum)

| Event | When |
|-------|------|
| `life_refill_offer_shown` | Lives dialog opened |
| `life_refill_purchased` | Gem refill succeeds |
| `prep_item_purchased` | Coin prep shop buy |
| `starter_pack_claimed` | Entitlement granted |
| `iap_started` / `iap_succeeded` / `iap_failed` / `iap_restored` | Phase 2+ |
| `rewarded_ad_started` / `rewarded_ad_completed` / `rewarded_ad_failed` | Ad continue |
| `defeat_continue_offered` / `defeat_continue_used` | Result screen |
| `cosmetic_equipped` | Equip/unequip |
| `battle_pass_*` | Phase 4 |

## Store notes

- Localized prices from the stores, not hardcoded EUR/USD in the client
- Restore for non-consumables
- No false discounts or fake countdown timers
- Consent/privacy for ads (Phase 3)

## Future (investigate only)

Optional non-campaign heroes, hero trials, cosmetic collections, lore “Mythic Echoes”. Evaluate whether early access would weaken campaign milestones before recommending it. Not in V1.0.
