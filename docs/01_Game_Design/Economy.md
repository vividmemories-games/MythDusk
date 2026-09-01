# Economy

| Field | Value |
|-------|-------|
| **Status** | Active — numbers owned by Balancing Bible v1.2 |
| **Last Updated** | 2026-08-21 |
| **Related** | [Balancing_Bible](Balancing_Bible.md) · [Monetization](Monetization.md) · [Progression](Progression.md) · [PHASES](../PHASES.md) · `.cursor/rules/08-monetization-economy.mdc` |

## Philosophy

Premium feel first. Monetization supports convenience and cosmetics — not pay-to-win combat power. Align with [Monetization](Monetization.md) (no unlimited paid revives, no client-side currency grants in production, campaign heroes stay free milestone unlocks).

**Authoritative numbers:** [Balancing_Bible.md](Balancing_Bible.md) §3.6 and §4–5.

## Currencies (V1.0)

| Currency | Earn | Spend |
|----------|------|-------|
| Coins | Battle `coinReward`, campaign clears | Prep shop, upgrade stubs (≤30% combat), paid defeat continue |
| Gems | Starting stash, later milestones/IAP | Capped life refills, later packs/cosmetics |
| Lives | Passive regen (+1 / 20 min, max 5) | −1 on every campaign/weekly defeat |

Lives are the only stamina gate. Do not add a second energy meter.

## Phase 1 mock defaults

From `PlayerProfile` / `EconomyBalance`:

| Resource | Default |
|----------|---------|
| Coins | 500 |
| Gems | 50 |
| Lives | 5 |

## Config

| Area | Code |
|------|------|
| Lives / gems / upgrades | `lib/features/profile/domain/economy_balance.dart` |
| Defeat continue / starter pack | same file (`DefeatContinueBalance`, `StarterPackBalance`) |
| Prep shop prices / drops | `lib/features/prep/domain/prep_item.dart` |
| Cosmetics catalog | `lib/features/cosmetics/domain/cosmetic_catalog.dart` |
| Match resources / AP | `lib/features/puzzle/domain/match_balance.dart` |
| Future IAP ids | `lib/features/shop/domain/iap_catalog.dart` |
| Future Remote Config keys | `lib/core/config/remote_config_keys.dart` |

## Anti-patterns

- Client-trusted reward amounts (Firebase phase: server validate)
- Gem-paid combat stats
- Uncapped revives or gem full-life spam
- Mandatory paid continues
- Interstitials during an active player turn
- Pay-to-win PvP (when PvP exists)
- Gacha on campaign heroes

## Later hooks

Roadmap: [Monetization](Monetization.md) Phases 2–4 (IAP, 30-day pack, ads SDK, battle pass after retention).
