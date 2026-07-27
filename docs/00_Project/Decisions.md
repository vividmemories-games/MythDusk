# Decisions

Log material decisions here. Format: date, decision, reason, status.

Authority: product/engineering choices that override or clarify [PHASES](../PHASES.md) / [GAMEPLAY](../GAMEPLAY.md).

---

## 2026-07-10 — New Flutter app (not Dot Clash)

**Decision:** Build Mythora as a standalone Flutter app at `Documents/Personal Projects/Mythora`.

**Reason:** Different genre, identity, and Firebase project needs; reuse patterns only.

**Status:** Accepted

---

## 2026-07-10 — Combat model locked

**Decision:** Puzzle generates resources; skills cost resources + AP; Moves are the turn budget; then enemy turn. See [GAMEPLAY](../GAMEPLAY.md).

**Reason:** Core product differentiator vs match-3 that deals damage on match.

**Status:** Accepted

---

## 2026-07-10 — Phase 1 scope: 1 hero, 6×6, mock profile

**Decision:** Single hero in battle; first boards 6×6; mock/local profile until the loop feels good.

**Reason:** Prove feel before parties, Firebase, and content pipeline.

**Status:** Accepted

---

## 2026-07-10 — Cascade + no-match spawn

**Decision:** Boards spawn with zero matches. After a successful swap, resolve clear → gravity → spawn in a loop until stable. Cascades grant resources/AP; only the player swap spends a Move.

**Reason:** Leftover on-board matches and in-place refill felt broken.

**Status:** Accepted — implemented in `PuzzleEngine` / `BattleNotifier`

---

## 2026-07-10 — Weighted enemy skill stubs

**Decision:** Enemies pick from weighted skills (e.g. Goblin: Nick / Slash / Heavy Swing). Numbers are Phase 1 stubs for the [Balancing Bible](../01_Game_Design/Balancing_Bible.md).

**Reason:** Flat damage every turn felt lifeless; full AI/balance deferred to Phase 2.

**Status:** Accepted — stub in `EnemyCatalog`

---

## 2026-07-10 — Docs system adapted from Labyrinth Legends

**Decision:** Adopt LL’s lean documentation taxonomy (Vision → Gameplay → Design → Tech → Asset Bible) without maze/LLDL content.

**Reason:** Keep solo-dev + AI discipline without importing the wrong game.

**Status:** Accepted

---

## 2026-07-10 — Vertical slice: campaign + power-ups + persistence

**Decision:** Ship a playable product path: Home → Twilight Road (5 nodes) → battle → result (coins / unlock) with local profile persistence. Match-4 creates a rocket (row+col blast when matched); match-5+ creates a bomb (3×3).

**Reason:** Move from sandbox stub to a closable 10-minute loop before Phase 2 Balancing Bible.

**Impact:** `assets/levels/twilight_road.json`, campaign screens, `profileProvider` + SharedPreferences, puzzle specials, battle result flow.

**Status:** Accepted — implemented

---

## 2026-07-10 — Shape catalog, four specials, merges

**Decision:** Matches follow the spreadsheet catalog (lines, 2×2, mix-of-five L/T/plus). Specials: V/H rocket, bomb, fireball, seeker (L → seeker; T/plus/2×2 → bomb; H4 → V-rocket; V4 → H-rocket; line5 → fireball). Create at swap destination. Special↔special uses the merge matrix.

**Reason:** Richer match-3 feel; Seeker is the 4th special for L pentominoes.

**Status:** Accepted — implemented

---

## 2026-07-10 — Colorless power-ups, fireball rules, bomb+rocket cross

**Decision:** Power-ups do not participate in color matching. Activate by tap or by swapping with any adjacent tile. Fireball tap clears a random board color; fireball swap clears the swapped tile’s color; cleared power-ups chain. Bomb + V-rocket and bomb + H-rocket both produce the same fat 3×3 cross (3 rows + 3 cols).

**Reason:** Clearer activation UX; fireball feels intentional on swap vs lucky on tap; rocket+bomb should not be direction-dependent.

**Status:** Accepted — implemented

---

## 2026-07-10 — AB1 production standards locked

**Decision:** Adopt [AB1 — Production Standards](../06_Asset_Bible/AB1_Production_Standards.md) for the first art pass: Dusk style board, Leonardo AI + ForgeGUI workflow, stable `{category}_{id}.png` naming, export sizes, and human review checklist.

**Reason:** Lock specs before generating hero/enemy/tile assets so AI output stays consistent and Flutter-ready.

**Impact:** `docs/06_Asset_Bible/AB1_Production_Standards.md`, `assets/images/*` subfolders, style board in `assets/images/style_board/`.

**Status:** Accepted — art *style* superseded by 2026-07-11 chibi battle lock below; naming/sizes/tooling still apply

---

## 2026-07-11 — Art style: chibi battle stage (not painterly busts)

**Decision:** Mythora production art is **chibi / super-deformed 2D** matched to a puzzle-RPG **battle stage**:

- Full-body hero (left) and enemy (right) on the upper battle half
- HP bars stay on/near characters (characters do not replace numbers)
- Puzzle tiles and skill icons share the same thick-outline, soft cel-shaded, glossy “toy” look
- Dusk palette (teal / parchment / amber / ember) remains — not neon, not photoreal
- Collection / roster cards reuse the same full-body sprites (or crops), not a separate semi-real portrait style

**Rejected:** Painterly adult bust portraits as the primary style lock (Leonardo Phoenix text-only drifted cinematic; busts do not stage well above the board).

**Reason:** Future battle UI replaces the flat name/HP header with staged characters; board + characters must be one language. Chibi reads at phone scale and is cheaper to idle/hit-polish later (AB2).

**Impact:** Rewrite [AB1 Production Standards](../06_Asset_Bible/AB1_Production_Standards.md) + [Leonardo Prompt Pack](../06_Asset_Bible/AB1_Leonardo_Prompt_Pack.md); style seed `assets/images/style_board/style_seed_battle_mage.png`; old bust seed deprecated.

**Status:** Accepted

---

## 2026-07-20 — Campaign content architecture (200 levels)

**Decision:** Ship a **200-level** linear campaign stubbed in JSON, structured as **10 chapters × 20 levels**.

| Item | Lock |
|------|------|
| Map UI | Vertical Candy Crush–style path |
| Chapter boss sightings | Levels **5 / 10 / 15 / 20** — same foe, escalating forms; flees until **20** (final death) |
| Level identity | Board rules **and** enemy kits equally |
| Hero unlocks | **4** unlocks across the arc (~every 50 levels); starter Mage available from start |
| Meta prep | Light inventory before boss fights — **Vanguard Tonic**, **Aegis Flask**, **Second Wind** only (v1) |
| Core combat | Unchanged — match → resources/AP → skills; prep does **not** deal boss damage from the puzzle |
| Weekly | Mon–Fri puzzle objectives; weekend extreme bosses; fail spends **life/energy** |
| Home | Hub (not the map); primary CTA **Enter Campaign**; show **lives** from day one |

**Chapter themes (locked names):**

1. Twilight Road  
2. Mistfen Marshes  
3. Howling Ridge  
4. Ashen Quarries  
5. Candlecrypt  
6. Mirror Lake  
7. Thornmarket  
8. Skybridge Siege  
9. Eclipse Forge  
10. Mythspire Gate  

**Reason:** Solo-dev scalable content — reuse enemy art via forms/variants; narrative boss returns; systems over unique-per-level art.

**Impact:** [Content Architecture](../01_Game_Design/Content_Architecture.md), [Master Prompts](../06_Asset_Bible/Master_Prompts.md), future campaign JSON schema, home/weekly/meta-prep features.

**Status:** Accepted

---

## 2026-07-20 — Board complexity, moves clamp, win condition, enrage

**Decision:**

### Board complexity
- Boards are **data-driven templates + modifiers** (masks, layered obstacles, movers) — not unique art per level.
- **Masked / blocked cells** and layered obstacles roll out from mid-campaign (Ch2+ as content needs).
- **Moving parts** (row/col shove, sliding segments) start in **Chapter 3 — Howling Ridge**, not before.

### Moves budget
```text
movesThisTurn = hero.movesPerTurn
              + prep (e.g. Vanguard Tonic +1)
              + level modifiers
              − boss/level debuffs
```
- Default **minimum clamp = 2**.
- **Nightmare bosses** may clamp as low as **1**.
- Moves still refresh each player turn and do not carry over ([GAMEPLAY](../GAMEPLAY.md)).

### Win / lose (campaign)
- Campaign default: fight until **hero HP ≤ 0** (defeat) or **enemy HP ≤ 0** / boss **flee or death** (victory).
- **No** global “N chances then lose” for campaign.
- Weekly / special nodes may use survive-N-turns or tile objectives.

### Boss enrage
- Optional level flag: after **8 player turns**, boss **enrages** (increased damage / tougher skill weights) — not an instant lose.
- Exact multipliers → Balancing Bible.

**Reason:** Preserve RPG HP fantasy; use moves and board geometry as tactical pressure; introduce movers only when Ch1–2 basics are solid.

**Impact:** [Content Architecture](../01_Game_Design/Content_Architecture.md), [GAMEPLAY](../GAMEPLAY.md), future level JSON (`maskId`, `moverId`, `enrageAfterTurns`, `minMoves`).

**Status:** Accepted

---

## 2026-07-22 — Full-game build order (post–vertical slice)

**Decision:** Treat Mythora as a **full game** built around the 200-level campaign spine — not an MVP-only scope. Agreed build order:

| # | Phase | Scope |
|--:|-------|--------|
| **1** | Campaign spine | 200-level **structure** + chapter maps + board **types/templates** (masks, obstacles, movers). Stub/fill via reusable templates — not 200 uniquely hand-tuned fights before systems exist. |
| **2** | Balancing Bible | Formulas, curves, resource/AP/damage, enemy kits — tune on representative chapters, then apply across templates. |
| **3** | Shell polish | Splash + Home hub (full layout) + **Settings** and **Profile** as own screens. |
| **4** | Full stack | Daily missions → Shop → Weekly → Daily dungeon → Firebase/economy → Friend Challenge → cosmetics/events |

**Reason:** Campaign is the content spine; balance needs representative boards before retention/social; shell and economy stack after the loop feels fair.

**Impact:** [PHASES](../PHASES.md) (directional), Home/Shop/Profile/Settings routes, retention features below.

**Status:** Accepted

---

## 2026-07-22 — Full-game surface: modes, hub, Challenge rule A

**Decision:** Product surface around the campaign:

### Modes
| Mode | Role |
|------|------|
| **Campaign** | Primary progress (200 levels) |
| **Daily missions** | Checklist retention (e.g. clear N boards, match N greens/blues) — separate from Daily dungeon |
| **Daily dungeon** | One rotating special fight |
| **Weekly** | Mon–Fri objectives → weekend extreme boss; fail spends life |
| **Challenge** | Async **friend duel** using normal Mythora loop (**rule A**): moves → match → resources/AP → skills; puzzle does **not** deal direct damage. Same balance as PvE at first. |
| **Events** | Later; limited modifiers/cosmetics — not a second campaign |

Defer early: realtime ranked PvP, guilds, season-pass sprawl.

### Shell / navigation
- **Home** remains a **hub** (not the map); primary CTA **Enter Campaign**; mode tiles for Daily / Weekly / Challenge; secondary icons for Heroes / Shop / Missions.
- **No bottom tab bar** until Shop + Profile are daily habits; optional later cap at **3 tabs** (Play · Shop · Profile).
- **Splash** → Home (Auth when Firebase).
- **Settings** — own screen (not sheet-only).
- **Profile** — own screen (progress, friend code, account).
- **Shop** — own screen with tabs (Featured / Cosmetics / Boosts / Heroes / Gems as needed). Cosmetics + capped convenience; no pay-to-win Challenge power.

**Reason:** Retention and social orbit the campaign without a second combat language or live-ops dashboard Home.

**Impact:** [Content Architecture](../01_Game_Design/Content_Architecture.md) §5 Home hub; future `missions/`, `shop/`, `challenge/` features; Settings/Profile routes.

**Status:** Accepted

---

## 2026-07-22 — Four act maps per chapter (art inventory)

**Decision:** Each campaign chapter uses **4 act maps** (one portrait map per act, **5 nodes** each) — matching the Ch1 / campaign UI pattern. Across **10 chapters** that is **40** map artworks (`map_ch_{slug}_a1.png` … `_a4.png`), not one mega-strip per chapter.

Legacy single-strip filenames (`map_ch_*.png` without `_aN`) remain **deprecated**.

**Reason:** Act-sized 1024×1536 maps are generator-friendly, match `CampaignAct.mapAsset`, and let each act densify visually without stitching 5800px strips.

**Impact:** [Content Architecture](../01_Game_Design/Content_Architecture.md) art counts; [Master Prompts](../06_Asset_Bible/Master_Prompts.md) P2 (Ch1 done) + P4 (Ch2–10 × 4).

**Status:** Accepted

---

## 2026-07-23 — Board primitives + JSON templates

**Decision:** Board content is **templates + modifiers**, not unique art/code per level.

### Primitives
| Primitive | Semantics |
|-----------|-----------|
| **Mask** | Hole / blocked cell — gravity skips (already in engine) |
| **Blocker overlay** | Static rock-style; breaks on **adjacent match**; does **not** fall |
| **Binder overlay** | Vine/poison on a cell; breaks on **match under**; tile can fall through, overlay stays on cell |
| **Mover** | Start of **player turn**, tiles **wrap** at edges (execution deferred; JSON contract now) |
| **Hazard** | v1: **suppress resources** on matched hazard tiles (execution deferred) |

### JSON layout
- `assets/boards/overlays.json` — overlay catalog (`ovl_rock`, `ovl_vine`, `ovl_poison`, …)
- `assets/boards/templates.json` — reusable ASCII grids + legend (`board_open_6x6`, …)
- Chapter `boardDefaults` + node `board` merge (node wins); movers/hazardSpawn/spawnWeights inline on config
- Defer Ch6/Ch7 rule-modifier fields until those mechanics are designed

### Engine notes
- `BoardBuilder.fromTemplate` builds playable no-match boards
- Gravity/fill treat solid blockers like masks; binders stay cell-fixed
- Overlay **break rules** and hazard resource suppression are catalogued but not yet executed in match resolution

**Reason:** Solo-dev scalable chapter gimmicks; Ch2 overlays → Ch3 movers → Ch5 masks reuse the same stack.

**Impact:** `BoardCell.overlayId` / archetype; campaign `board` / `minMoves` / `enrageAfterTurns` / `prepDrops`; battle start uses template when catalogs load.

**Status:** Accepted — schema + builder + overlay break/suppress landed; mover execution still deferred

---

## 2026-07-23 — Campaign spine stubs (200 levels)

**Decision:** Ship **10 chapter JSON files** + `campaign_index.json` (200 nodes total). Ch2–10 are structural stubs: 4 acts × 5 nodes, boss forms 1–4, chapter `boardDefaults` (template / movers / hazardSpawn as data). Map art paths point at future `map_ch_*_aN.png` (UI `errorBuilder` until P4). Missing enemy art falls back to goblin / warchief forms.

**Reason:** Unlock Balancing Bible and chapter select without waiting on all art.

**Impact:** `assets/levels/*.json`, `EnemyCatalog` boss stubs, `selectedCampaignChapterIdProvider`.

**Status:** Accepted

---

## 2026-07-23 — Mover execution + chapter picker

**Decision:**
- Movers run at **start of each player turn** (including battle start), wrap within segments split by masks/solid blockers; binders stay cell-fixed.
- Wind-created matches resolve (inline at battle start; animated after enemy turns) and **do not** spend a Move.
- Home **Enter Campaign** → chapter select (`/chapters`) → act map; unlock via prior chapter finale node id in `campaign_index.json`.

**Status:** Accepted

---

## 2026-07-27 — Balancing Bible v1 (combat + soft progression)

**Decision:** Authoritative [Balancing_Bible](../01_Game_Design/Balancing_Bible.md) for combat formulas and soft progression. Board stays fair; friction is prep / lives / boosts. Every campaign defeat spends 1 life (max 5, +1 / 20 min). Gem partial life refill: 75 gems → +3 lives, max 3/day. Fight length targets: trash 3–5 turns, act boss 6–10, finale 10–15. Act 3+ bosses expect prep. Coin upgrades capped at ~30% per stat line. No gem combat power.

**Reason:** Unlock tunable, monetization-safe economy before shop/IAP and Firebase settlement.

**Impact:** `EconomyBalance`, `LifeRegenMath`, profile schema v5 (regen + gem refill + `upgradeLevels`), `PrepDrops` act chances, `HeroDef.withCombatMultipliers`, enemy HP pass-1 retune, home/campaign lives gate.

**Status:** Accepted
