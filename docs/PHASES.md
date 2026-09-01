# MythDusk — Phases & Locked Decisions

| Field | Value |
|-------|-------|
| **Status** | Active |
| **Last Updated** | 2026-07-10 |
| **Related** | [docs home](README.md) · [Vision](00_Project/Vision.md) · [Decisions](00_Project/Decisions.md) · [GAMEPLAY](GAMEPLAY.md) |

Living decision log: [00_Project/Decisions.md](00_Project/Decisions.md).

## Locked product decisions

| Decision | Choice |
|----------|--------|
| Name | **MythDusk** |
| App approach | **New Flutter app** (not inside Dot Clash) |
| Path | `Documents/Personal Projects/MythDusk` |
| Stack | Flutter, Riverpod, go_router; Firebase later |
| Architecture patterns | Feature-first like Dot Clash (`domain/` / `data/` / `providers/` / `presentation/`) |
| Visual identity | **Not** Dot Clash neon — dusk adventure (teal/ink + amber/gold) |
| Combat | Per [GAMEPLAY.md](GAMEPLAY.md) — resources + AP + skills |
| Team size in battle | **1 hero** (parties in Phase 3–4) |
| First boards | **6×6 square**; complex/asymmetric later |
| Profile / backend | **Mock/local** until battle feels good, then Firebase |
| Balancing Bible | **Phase 2** session |
| Content pipeline / admin editors | **Phase 2** session |

---

## What we reuse from Dot Clash (patterns only)

- Feature-first module layout
- Pure Dart rules engines + unit tests
- Riverpod provider conventions
- Later: Auth, Firestore settlement, lives/economy, ads/IAP callables

## What we do **not** copy

- Neon UI / Dot Clash theme tokens
- Dots & Boxes rules or board painter
- Dot Clash Firebase projects (MythDusk gets its own when wired)

---

## Phase 1 — Playable loop → vertical slice

**Goal:** Prove the battle loop feels good, then close a mini-campaign path.

1. Scaffold app + dusk theme shell
2. Pure-Dart match-3 engine (start 6×6; design for masks later)
3. Battle loop: moves → resources → AP → cast skill → enemy turn
4. Cascades + no-match spawn + rocket/bomb power-ups
5. Playable heroes (Mage, Knight stubs)
6. Weighted enemy skills (5 campaign enemies)
7. Local persisted profile (coins, progress, selected hero)
8. Twilight Road campaign (5 nodes) → battle → result → unlock

**Out of Phase 1**

- Final balance formulas, XP curves, loot tables, rarity system
- Admin dashboard / content editors
- Multi-hero parties
- Full Royal Match event calendar
- Guilds, PvP, season pass

**Stub balance:** use example numbers from GAMEPLAY.md; expect to replace in Phase 2.

---

## Phase 2 — Balancing Bible + Content Pipeline

Dedicated session. Scope to refine then:

### Balancing Bible

See [01_Game_Design/Balancing_Bible.md](01_Game_Design/Balancing_Bible.md). Scope includes:

- Hero stats
- Resource generation rates
- AP formulas
- Damage formulas
- XP curves
- Loot tables
- Rarity system

### Content Pipeline

- Admin dashboard
- Hero / skill / enemy / event editors
- Firestore data models for live content
- Balance updates without full app releases where possible

Until Phase 2 ships, content lives as **local JSON** under `assets/`.

---

## Phase 3–4 (directional)

- Multi-hero teams / party composition
- Asymmetric boards, special tiles, moving parts, power-up matrix
- Campaign chapters, bosses with board modifiers
- Daily dungeon
- Firebase Auth + Firestore + Cloud Functions economy
- Equipment that changes rules
- Later: weekly bosses, tower, seasonal events, guilds, PvP

Monetization phases (local foundations now; IAP/Firebase later): [Monetization](01_Game_Design/Monetization.md). Battle pass stays off until retention is validated. Campaign heroes stay milestone unlocks.

---

## Suggested lib layout

```text
lib/
  main.dart / app.dart
  core/           # router, theme, env
  features/
    puzzle/       # match-3 engine
    battle/       # combat loop
    heroes/
    equipment/
    campaign/
    daily/
    profile/      # mock first
    shop/         # later
  services/       # firebase later
  shared/
assets/
  levels/ heroes/ enemies/ images/
docs/                 # see docs/README.md
```

---

## Identity rule

Someone who played Dot Clash should not recognize MythDusk as the same product after removing the logo. Different palette, type, iconography, and metaphor (fantasy shards / heroes, not neon notebook dots).
