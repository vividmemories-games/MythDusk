# Economy

| Field | Value |
|-------|-------|
| **Status** | Draft — numbers owned by Balancing Bible v1 |
| **Last Updated** | 2026-07-27 |
| **Related** | [Balancing_Bible](Balancing_Bible.md) · [Progression](Progression.md) · [PHASES](../PHASES.md) · `.cursor/rules/08-monetization-economy.mdc` |

## Philosophy

Premium feel first. Monetization supports convenience and cosmetics — not pay-to-win combat power. Align with Mythora monetization rules (no unlimited paid revives, no client-side currency grants in production).

**Authoritative numbers:** [Balancing_Bible.md](Balancing_Bible.md) §4–5. This page is a short pointer for product/UX.

## Currencies (v1)

| Currency | Earn | Spend |
|----------|------|-------|
| Coins | Battle `coinReward`, campaign clears | Prep shop, upgrade stubs (≤30% combat) |
| Gems | Milestones, IAP (later), sparse rewards | Capped life refills, capped prep bundles, cosmetics |
| Lives | Passive regen (+1 / 20 min, max 5) | −1 on every campaign defeat |

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
| Prep shop prices / drops | `lib/features/prep/domain/prep_item.dart` |
| Match resources / AP | `lib/features/puzzle/domain/match_balance.dart` |

## Anti-patterns

- Client-trusted reward amounts (Phase 4: server validate)
- Gem-paid combat stats
- Uncapped revives or gem full-life spam
- Interstitials during an active player turn
- Pay-to-win PvP (when PvP exists)

## Later hooks

- Rewarded ads at natural decision points (post-battle, optional revive with caps)
- Remote Config / `remote_balance` for costs
- Server-validated settlement (Firebase)
