# Content Architecture — Master Plan

| Field | Value |
|-------|-------|
| **Status** | Active |
| **Last Updated** | 2026-07-22 |
| **Authority** | Extends [Vision](../00_Project/Vision.md) · [GAMEPLAY](../GAMEPLAY.md) · [Decisions](../00_Project/Decisions.md) |
| **Art prompts** | [Master Prompts](../06_Asset_Bible/Master_Prompts.md) — one Leonardo prompt per artwork ID below |

This is the **master content plan** for Mythora’s first 200-level campaign, weekly mode shell, home hub, meta prep, and the artwork inventory required to ship it.

---

## 1. Goals

- Prove a long campaign without unique art per level
- One **returning chapter boss** with 4 escalating forms
- Light **meta prep** before bosses; core combat loop unchanged
- Vertical **Candy Crush–style** map; home is a hub, not the map

---

## 2. Campaign structure

| Spec | Value |
|------|-------|
| Total levels | **200** (stub all in JSON for v1) |
| Chapters | **10** × **20** levels |
| Acts | **4** acts × **5** levels per chapter |
| Map | Vertical Candy Crush–style path; **one portrait map per act** (not one mega-strip per chapter) |
| Map art count | **40** (`map_ch_{slug}_a1`…`_a4` × 10 chapters) |
| Boss sightings | Chapter levels **5 / 10 / 15 / 20** |
| Boss outcome | Flees at 5, 10, 15 → **dies** at 20 |
| Regular levels | Trash enemies + chapter board rule; grant prep items / coins |
| Hero unlocks | ~levels **50 / 100 / 150 / 200** (4 unlocks); Mage starter |

### Decade beat sheet (each chapter)

| Level | Role |
|------:|------|
| 1–4 | Easy; teach/reinforce chapter board rule |
| **5** | Boss form 1 (weak) → flee |
| 6–9 | Harder trash; prep rewards |
| **10** | Boss form 2 (elite) → flee |
| 11–14 | Pressure + obstacles |
| **15** | Boss form 3 (larger scale / stronger kit) → flee |
| 16–19 | Peak trash / gauntlet |
| **20** | Boss form 4 (final) → death → chapter clear |

### Chapter themes

| Ch | ID | Name | Environment | Board lesson (stub) | Boss ID |
|---:|----|------|-------------|---------------------|---------|
| 1 | `ch_twilight_road` | Twilight Road | Dusk path / woods | Basics | `boss_warchief_ruk` |
| 2 | `ch_mistfen` | Mistfen Marshes | Fog swamp | Poison / sticky tiles | `boss_mirelord` |
| 3 | `ch_howling` | Howling Ridge | Wind cliffs | Row shove / wind (**movers start here**) | `boss_pack_alpha` |
| 4 | `ch_ashen` | Ashen Quarries | Ember mines | Rock layers | `boss_quarry_overseer` |
| 5 | `ch_candlecrypt` | Candlecrypt | Catacombs | Masked holes | `boss_bone_seer` |
| 6 | `ch_mirror` | Mirror Lake | Water ruins | Color-lock / mirror swaps | `boss_lake_wraith` |
| 7 | `ch_thornmarket` | Thornmarket | Night bazaar | Match tax / costs | `boss_gilded_fence` |
| 8 | `ch_skybridge` | Skybridge Siege | Broken spans | Narrow / bridge masks | `boss_siege_captain` |
| 9 | `ch_eclipse` | Eclipse Forge | Magma foundry | Burn / fire hazards | `boss_ember_smith` |
| 10 | `ch_mythspire` | Mythspire Gate | Final fortress | Rule mash | `boss_mythspire_tyrant` |

---

## 3. Meta prep (v1 locked)

Carry up to **3** items into a boss battle (5/10/15/20). Earned from non-boss clears + weekly.

| ID | Name | Effect |
|----|------|--------|
| `prep_vanguard_tonic` | Vanguard Tonic | Start battle with **+1 Move** |
| `prep_aegis_flask` | Aegis Flask | Start battle with **small shield** |
| `prep_second_wind` | Second Wind | Once per day: on would-be defeat, revive to **~30% HP** |

Does **not** change match→resource→skill rules. Numbers → Balancing Bible later.

---

## 3b. Combat pressure locks (2026-07-20)

| Topic | Lock |
|-------|------|
| Campaign win/lose | HP death (or boss flee/death) — **no** global chance-cap lose |
| Weekly | Objectives / survive-N-turns OK |
| Moves formula | `hero.movesPerTurn + prep + level − boss debuff` |
| Min moves | Default clamp **2**; nightmare bosses may go to **1** |
| Moving parts | Start **Ch3 Howling Ridge** |
| Masks / obstacles | Templates + JSON; Ch2+ as needed |
| Boss enrage | After **8 player turns**, boss hits harder (flag per level) |

See [Decisions](../00_Project/Decisions.md) 2026-07-20 board/moves/enrage.

---

## 4. Weekly mode (structure lock)

| Day | Mode | Fail |
|-----|------|------|
| Mon–Fri | Puzzle objective (clear N tiles / survive X turns / collect resource) | −1 life |
| Sat–Sun | Extreme boss | −1 life |

Rewards (coins, weekly tokens, chests) → Balancing Bible / Economy later. Lives shown on **home from day one**.

---

## 5. Home hub (structure lock)

| Element | Spec |
|---------|------|
| Background | Dusk gradient + soft silhouette (`bg_home_dusk.png`) |
| Top bar | Brand · coins · gems · **lives** · profile · settings |
| Hero spotlight | Selected hero sprite; tap → Heroes |
| Primary CTA | **Enter Campaign** → vertical map (+ chapter/level teaser) |
| Secondary | Daily dungeon · Weekly · Challenge (async friend duel) |
| Retention | Daily missions badge/entry (separate from dungeon) |
| Meta | Heroes · Shop · Prep inventory |
| Not on home | Full level path (Campaign screen only); full shop catalog |

Own screens (not embedded on Home): **Settings**, **Profile**, **Shop** (tabbed). See [Decisions](../00_Project/Decisions.md) 2026-07-22.

---

## 6. Artwork inventory (what to generate)

Style lock: chibi / glossy toy dusk — [AB1](../06_Asset_Bible/AB1_Production_Standards.md).  
Prompts: [Master Prompts](../06_Asset_Bible/Master_Prompts.md).

### 6.1 Summary counts

| Category | Count | Directory |
|----------|------:|-----------|
| Heroes (full-body) | **5** | `assets/heroes/` |
| Trash enemies | **8** | `assets/enemies/` |
| Chapter bosses × forms | **40** | `assets/enemies/bosses/` |
| Battle stage backgrounds | **10** | `assets/images/backgrounds/battle/` |
| Campaign act maps | **40** | `assets/images/maps/` (4 acts × 10 chapters) |
| Home background | **1** | `assets/images/backgrounds/` |
| Board power-ups | **5** | `assets/images/powerups/` |
| Meta prep icons | **3** | `assets/images/prep/` |
| Light VFX | **4** | `assets/images/vfx/` |
| Tiles (shipped) | **5** | `assets/images/tiles/` |

Track creation checkboxes + prompts: [Master Prompts](../06_Asset_Bible/Master_Prompts.md) (P0→P4 order).


### 6.2 Heroes

| File | Unlock |
|------|--------|
| `hero_mage.png` | Starter (exists) |
| `hero_knight.png` | ~Level 50 |
| `hero_ranger.png` | ~Level 100 |
| `hero_priest.png` | ~Level 150 |
| `hero_ninja.png` | ~Level 200 |

### 6.3 Trash enemies

| File | Chapters (primary) |
|------|--------------------|
| `enemy_goblin.png` | Ch1 (exists) |
| `enemy_wolf.png` | Ch1–3 |
| `enemy_shaman.png` | Ch2 |
| `enemy_brute.png` | Ch4 |
| `enemy_mire_spawn.png` | Ch2 |
| `enemy_ridge_hawk.png` | Ch3 |
| `enemy_crypt_skel.png` | Ch5 |
| `enemy_forge_imp.png` | Ch9 |

### 6.4 Bosses (4 forms each)

Pattern: `assets/enemies/bosses/boss_{id}_f{1-4}.png`  
f1 = sighting (small/weak), f2 = elite, f3 = oversized intimidation, f4 = final armored form.

| Boss ID | Chapter |
|---------|---------|
| `boss_warchief_ruk` | 1 Twilight Road |
| `boss_mirelord` | 2 Mistfen |
| `boss_pack_alpha` | 3 Howling Ridge |
| `boss_quarry_overseer` | 4 Ashen Quarries |
| `boss_bone_seer` | 5 Candlecrypt |
| `boss_lake_wraith` | 6 Mirror Lake |
| `boss_gilded_fence` | 7 Thornmarket |
| `boss_siege_captain` | 8 Skybridge |
| `boss_ember_smith` | 9 Eclipse Forge |
| `boss_mythspire_tyrant` | 10 Mythspire Gate |

### 6.5 Environments

| File | Path |
|------|------|
| Battle BGs | `assets/images/backgrounds/battle/bg_battle_*.png` |
| Act maps | `assets/images/maps/map_ch_*_a{1-4}.png` |
| Home | `assets/images/backgrounds/bg_home_dusk.png` |

### 6.6 Board power-ups

| File | Path |
|------|------|
| `powerup_rocket_v.png` etc. | `assets/images/powerups/` |

### 6.7 Meta prep icons

| File | Path |
|------|------|
| `prep_*.png` | `assets/images/prep/` |

### 6.8 Optional VFX

| File | Path |
|------|------|
| `fx_*.png` | `assets/images/vfx/` |

---

## 7. Implementation plan (phased)

| Phase | Work | Depends on |
|-------|------|------------|
| **A — Docs** | This file + Master Prompts + Decisions | Done |
| **B — Board juice** | Power-up art + create/destroy animations | Power-up prompts |
| **C — Meta prep stub** | Inventory model + pre-boss picker UI | Prep icons |
| **D — Home hub** | Lives chip, Enter Campaign CTA, hero spotlight | `bg_home_dusk` optional |
| **E — Vertical map** | Candy Crush path for Ch1 (20 nodes) | Map strip Ch1 |
| **F — JSON expand** | Stub 200 levels from chapter template | Done — `campaign_index.json` + Ch1–10 |
| **G — Boss pipeline** | Ch1 boss f1–f4 + flee/death flow | Boss prompts |
| **H — Weekly shell** | Objectives + weekend boss + energy | Lives system |
| **I — Remaining chapters** | Art + JSON fill chapters 2–10 | Master Prompts batch |

Do **not** generate all 86 assets before B–E feel good. Priority art order:

1. Board power-ups (5)  
2. Meta prep icons (3)  
3. Ch1 boss forms f1–f4 + battle BG + act maps a1–a4  
4. Remaining heroes as unlocks approach  
5. Chapters 2–10 in order  

---

## 8. JSON level stub (contract sketch)

Each level node should eventually support:

```json
{
  "id": "ch1_l05",
  "chapterId": "ch_twilight_road",
  "order": 5,
  "kind": "boss_sighting",
  "enemyId": "boss_warchief_ruk",
  "bossForm": 1,
  "backgroundId": "bg_battle_twilight_road",
  "board": {
    "templateId": "board_open_6x6",
    "spawnWeights": { "purple": 1.2 },
    "movers": [
      { "type": "row_shove", "rows": [2], "direction": "left", "everyNTurns": 1 }
    ]
  },
  "minMoves": 2,
  "enrageAfterTurns": 8,
  "coinReward": 40,
  "prepDrops": ["prep_vanguard_tonic"]
}
```

Chapter files may set `boardDefaults` (merged under node `board`).  
Board geometry lives in `assets/boards/templates.json` + `overlays.json` — see [Decisions](../00_Project/Decisions.md) 2026-07-23.

**Ch1–3 progression (P1.2):** Twilight / Mistfen / Howling use real per-node `board` overrides (intro → reinforce → finale). Defaults stay soft; lists on a node **replace** chapter movers/hazard entirely. Ch4–10 remain chapter-flat stubs until a later content pass. Template IDs are checked by `test/board_content_variety_test.dart`.

Full 200-level stub generator → later PR; Twilight Road defaults to `board_open_6x6` with mid/late vines and bridge boards.

---

## 9. Related docs

- [Decisions](../00_Project/Decisions.md) — 2026-07-20 lock  
- [Master Prompts](../06_Asset_Bible/Master_Prompts.md) — Leonardo prompts  
- [AB1 Production Standards](../06_Asset_Bible/AB1_Production_Standards.md) — sizes/naming  
- [Enemies](Enemies.md) · [Heroes](Heroes.md) · [Economy](Economy.md)  
