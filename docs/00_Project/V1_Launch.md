# MythDusk — V1 Launch Plan

| Field | Value |
|-------|-------|
| **Status** | Active — execution authority for production push |
| **Last Updated** | 2026-09-28 |
| **Related** | [Decisions](Decisions.md) · [PHASES](../PHASES.md) · [Monetization](../01_Game_Design/Monetization.md) · [Firebase](../04_Technical/Firebase.md) · [Content Architecture](../01_Game_Design/Content_Architecture.md) |

This document locks **what V1 ships**, **what it cuts**, and **the ordered workstreams** to reach production. When it conflicts with older “Phase 2 later” wording in [PHASES](../PHASES.md), **this file wins** for launch sequencing.

---

## 1. Goal

Ship a **trustworthy, single-hero Puzzle RPG** to TestFlight / Play closed testing, then public store, without waiting for parties, equipment, battle pass, or a full admin dashboard.

**Product promise at V1:** Match tiles → spend AP on skills → clear a long campaign → daily/weekly retention → optional safe monetization.

---

## 2. Current baseline (do not rebuild)

Already in repo and treated as **done enough for V1 content spine**:

- Battle loop (moves, resources, AP, skills, enemy turn, specials, juice baseline)
- 200-level campaign JSON + chapter/act maps
- 5 heroes (unlocks, 2-of-N loadouts, per-hero upgrades)
- Prep, lives/coins/gems local foundations
- Daily / Weekly / Expedition / friend Challenge
- Home / Heroes / Shop / Profile / Settings
- Firebase packages + Auth bootstrap + Functions stubs (`ensureUser`, `tickLives`, `refillLivesWithGems`, `submitBattleRun`, `validateIapReceipt`)
- Local monetization catalogs; battle pass **off**

**Known gap:** client still settles most economy via SharedPreferences. Functions exist but are not the live client path. That is the #1 production blocker.

---

## 3. V1 definition — ship / cut

### Must ship (V1.0)

| Area | Requirement |
|------|-------------|
| Auth | Guest + Google + Apple; `ensureUser` on sign-in |
| Progress | Campaign clears + coins + lives granted only via **server settlement** when Firebase is ready |
| Offline / no-Firebase | Dev/emulator and graceful degrade allowed; **store builds require Firebase ready** |
| Campaign | Full 200-node spine playable (stub balance OK if early chapters feel fair) |
| Heroes | Milestone unlocks Mage→Ninja; loadouts; coin upgrades |
| Retention | Daily + Weekly reachable from Home |
| Economy UI | Lives gate, gem life refill (capped), prep shop (coins), starter pack path |
| Stability | Crashlytics on; no known crash on critical journey (home → briefing → battle → result) |
| Store | Privacy policy URL, store listings, icons, basic screenshots |
| Safety | No client-trusted coin/gem/IAP grants in release flavor |

### Soft-launch minimum money (V1 Soft)

| Area | Requirement |
|------|-------------|
| IAP | Real SDK + `validateIapReceipt` for **starter pack** at minimum (sandbox first) |
| Ads | **Not required** for Soft; keep defeat-continue ad as stub or hide |
| Battle pass | **Off** (`battle_pass_enabled = false`) |
| Restore | Restore non-consumables works |

### Explicitly cut from V1

- Equipment feature
- Multi-hero parties
- Admin content dashboard
- Live ops calendar / guilds
- Interstitial ads
- Hero gacha / paid campaign heroes
- Large cosmetic art sets
- Ranked competitive ladder (Challenge may stay as soft friend mode; do not market as Ranked)
- Full Balancing Bible retune of all 200 nodes (ship with **Early chapters tuned**; later chapters acceptable stub)

---

## 4. Launch gates (technical, not calendar)

Progress is measured by **gates**. Do not call the game “in production” until Gate B is green.

### Gate A — Internal soft build

Playable closed build for owner + testers.

- [ ] Client calls `ensureUser` after auth
- [ ] Campaign win/loss goes through `submitBattleRun` (idempotent) when Firebase ready
- [ ] Lives consume/refill match Functions behavior
- [ ] Release flavor refuses local QA IAP/ad cheats
- [ ] Crashlytics + core analytics events fire
- [ ] Critical journey test + store smoke on one iOS and one Android device
- [ ] Privacy / data collection copy matches actual SDK use

**Exit:** TestFlight / Play internal track uploaded.

### Gate B — Closed soft launch

Limited external players; money path real in sandbox/production stores.

- [ ] Store IAP SDK live; starter pack purchase + restore
- [ ] Receipt validation rejects forged client grants
- [ ] First 3 chapters (Twilight → Howling) playtested for fairness/clarity
- [ ] Skill icons present for equipped skills (no empty slots)
- [ ] Sound/haptics: either minimal implement or remove “coming soon” dead ends
- [ ] Support email / crash triage workflow

**Exit:** Soft launch cohort active; economy not trivially hackable.

### Gate C — Public V1.0 store

- [ ] Soft-launch feedback folded (clarity + early balance)
- [ ] Optional: rewarded ads SDK with daily cap (Monetization Phase 3)
- [ ] Store screenshots, age rating, ATT/consent if ads enabled
- [ ] Production Firebase project hardened; App Check enforced
- [ ] No open high-severity crashes; settlement monitored

**Exit:** Public App Store + Play listing.

---

## 5. Workstreams (execute in order)

Do not parallelize W1 with feature sprawl. Finish each stream’s exit criteria before starting the next unless blocked on store credentials.

### W0 — Lock & cut (this doc)

- [x] V1 ship/cut table
- [ ] Owner confirms Gate A vs “wait for ads/IAP” preference (default: **Gate A without real ads**)

### W1 — Server-authoritative settlement (highest priority)

**Why:** Store release without this is unsafe.

1. Client `CloudFunctions` port: `ensureUser`, `tickLives`, `refillLivesWithGems`, `submitBattleRun`
2. On auth success → `ensureUser` → hydrate profile from Firestore (or merge local→server once)
3. Battle result path writes `battle_runs/{runId}` then calls `submitBattleRun`
4. Mirror pure math already in `battle_run_settlement.dart`
5. Release flavor: disable local coin/gem grant shortcuts
6. Emulator tests for duplicate run / insufficient gems / unauthenticated

**Exit:** With emulators up, a campaign clear only increases coins via Function response.

### W2 — Release hygiene & observability

1. Flavor matrix: `dev` (emulators OK) vs `prod` (real project, no QA claims)
2. Crashlytics + Analytics events from Monetization.md minimum table
3. Remote Config fetch for feature flags (battle pass stays false)
4. Remove or gate debug enemy picker / mock rail in prod
5. Content error screens already exist — verify deep links

**Exit:** Prod APK/IPA builds; crashes visible in console.

### W3 — Soft IAP (starter pack)

1. Add official `in_app_purchase` (or approved package) — **owner approval for dependency**
2. Wire Shop starter pack to store purchase → `validateIapReceipt`
3. Replace QA claim in prod; keep QA claim behind `FLAVOR=dev`
4. Restore purchases flow in Settings
5. App Store Connect / Play Console product IDs matching `iap_catalog.dart`

**Exit:** Sandbox purchase grants coins/gems/cosmetic once; duplicate receipt no-ops.

### W4 — Early-game feel pass

1. Playtest chapters 1–3; fix unfair spikes / unclear movers/hazards
2. Fill missing skill icons for all catalog skills used in loadouts
3. Minimal SFX: match clear, skill cast, victory/defeat (or silence + no false “coming soon”)
4. Tutorial completeness for first battle only

**Exit:** New player can clear Twilight Road without external help.

### W5 — Store packaging

1. Privacy policy + terms hosted
2. Store screenshots (battle, home, campaign)
3. Age rating questionnaire honesty (ads/IAP)
4. Production Firebase checklist ([Firebase_Console_Checklist](Firebase_Console_Checklist.md)) — **deploy only with owner approval**
5. Soft launch notes / known issues list

**Exit:** Gate B upload ready.

---

## 6. What “picking up the pace” means

| Do | Don’t |
|----|-------|
| Finish W1 before new modes | Add equipment / parties / pass before settlement |
| Prefer shipping Gate A this cycle | Perfect all 200 node balances first |
| One PR per workstream when possible | Drive-by refactors unrelated to the gate |
| Keep battle rules locked | Change combat model without approval |
| Ask before `firebase deploy` | Deploy production Firebase unprompted |

---

## 7. Suggested immediate next PR (after this plan)

**Implement W1 slice 1:** Flutter callable client + `ensureUser` on auth + feature flag `useServerSettlement`.

Keep local profile as cache; server wins for coins/lives/`completedNodeIds` when Firebase ready.

---

## 8. Success metrics (post Gate B)

Track in Analytics / store consoles (no vanity dashboards required):

| Signal | Healthy early signal |
|--------|----------------------|
| D1 return | Any retention above throwaway prototype |
| Crash-free sessions | ≥ 99% on soft cohort |
| Starter pack funnel | `iap_started` → `iap_succeeded` without spikes of `iap_failed` |
| Soft launch feedback | Movers/hazards understood; early difficulty fair |

Battle pass stays off until D7/D30 look intentional ([Monetization](../01_Game_Design/Monetization.md) Phase 4).
