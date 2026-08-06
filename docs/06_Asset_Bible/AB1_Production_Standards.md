# AB1 — Production Standards

| Field | Value |
|-------|-------|
| **Status** | Active — chibi battle stage lock |
| **Last Updated** | 2026-07-11 |
| **Authority** | Sizes, naming, export, AI workflow; visual identity → [Theme](../02_Design_System/Theme.md) |
| **Related** | [Asset Bible README](README.md) · [Decisions](../00_Project/Decisions.md) · [Leonardo Prompt Pack](AB1_Leonardo_Prompt_Pack.md) |

AB1 locks how MythDusk assets are **named, sized, exported, reviewed, and wired into Flutter**. Art style lock: **chibi battle stage** (2026-07-11).

---

## 1. Scope

### In scope (Phase 1 art pass)

| Domain | Purpose | Priority |
|--------|---------|----------|
| Style board | Lock chibi + glossy tile look before batch generation | P0 |
| Puzzle tiles | 5 resource colors + shape overlay (same style family as characters) | P0 |
| Hero battle sprites | Full-body chibi for battle stage (left) + roster cards | P0 |
| Enemy battle sprites | Full-body chibi for battle stage (right) + campaign nodes | P0 |
| Skill icons | Hero + enemy skill buttons (matching outline weight) | P1 |
| UI chrome | Prefer Flutter widgets; optional panel textures | P2 |
| VFX | Match clear, hit flash, cast puff (single-frame or 2–3 frames) | P2 |

### Out of scope (AB1)

- Multi-frame idle/attack spritesheets (→ **AB2**)
- Full painted battle environments / forest scenes
- Store marketing packs (AB4+)
- 3D meshes
- Semi-realistic or painterly **adult bust** portraits as primary art

---

## 2. Art direction lock (Dusk + Chibi battle)

All generated assets must read as **one game**: dusk palette + **chibi / SD** characters + **glossy cartoon** tiles.

### Do

- Deep teal / ink backgrounds (`#0B1C24`, `#123A44`)
- Parchment skin / cloth highlights (`#E8DFC8`, `#D4A24C`, `#E6C87A`)
- Ember for enemy danger accents (`#C45C3A`)
- **Chibi / super-deformed** full-body figures (large head, short body)
- **Thick clean outlines**, soft **cel shading**, readable silhouette at phone scale
- Glossy match-3 icons that share the same outline/toy finish as characters
- Battle stage framing: hero left, enemy right; **HP bars stay in UI** (Flutter), not baked into PNG

### Don't

- Photoreal / cinematic faces, skin pores, Unreal/octane look
- Painterly adult bust portraits as the style board
- Cyan/magenta neon (Dot Clash)
- Grey stone fortress / LLDL citadel motifs
- Mixing styles (realistic mage + chibi goblin + flat color squares)
- Text baked into PNGs (Flutter renders all copy)
- Busy full environment art behind characters (solid teal or soft simple ground only)

### Style anchor sentence

Use this verbatim in AI prompts until a custom LoRA / Element exists:

> Mobile puzzle RPG battle art, chibi super-deformed character, thick clean outlines, soft cel shading, dusk teal and amber palette, glossy toy-like finish, premium casual fantasy match-3 RPG, readable at phone size, no photorealism, no neon.

---

## 3. Tooling

| Role | Tool | Use for |
|------|------|---------|
| **Primary** | [Leonardo AI](https://leonardo.ai) | Heroes, enemies, tiles, skill icons, VFX |
| **UI batch** | [ForgeGUI](https://forgegui.com) or [UI Forge](https://uiforge.vikings.studio) | Panel textures (if not pure Flutter) |
| **Concept only** | Midjourney | Mood boards — **not** production batches |
| **Scale later** | Scenario.gg | 100+ assets with trained private model |

### Production workflow

```text
1. Use bootstrap style seed style_seed_battle_mage.png
   as Leonardo Style Reference @ High (Phoenix text-only drifts realistic)
2. Generate style board (§4) → human approve
3. Upload approved board as Style Reference / train Element (optional)
4. Batch generate by domain using [Leonardo Prompt Pack](AB1_Leonardo_Prompt_Pack.md)
5. Human review checklist (§11)
6. Export reviewed PNG sources to `art_sources/runtime_png/`
7. Run `python3 scripts/optimize_runtime_assets.py --apply`
8. Wire the generated WebP delivery assets in battle stage + board
```

**Rule:** No asset ships without passing §11 review.

---

## 4. Golden reference set (style board)

Create **five** approved PNGs before batch production. Store in `assets/images/style_board/`.

| File | Content | Tool |
|------|---------|------|
| `style_board_hero_mage.png` | Full-body chibi mage, idle battle pose, teal bg | Leonardo |
| `style_board_enemy_goblin.png` | Full-body chibi goblin, slight menace, teal bg | Leonardo |
| `style_board_tile_red.png` | Glossy red attack tile (same outline family) | Leonardo |
| `style_board_skill_fireball.png` | Fireball skill icon, square | Leonardo |
| `style_board_ui_panel.png` | Optional panel sample OR skip (Flutter only) | ForgeGUI |

Bootstrap seed (not approved board): `style_seed_battle_mage.png`.

Deprecated: `style_seed_hero_mage_bust_deprecated.png` (painterly bust experiment — do not use).

These five define palette, outline weight, chibi proportions, and tile gloss. Compare every later asset side-by-side.

---

## 5. Directory layout

```text
art_sources/runtime_png/ # reviewed PNG masters, never bundled
assets/
├── heroes/              # hero_{id}.webp  (full-body chibi battle sprite)
├── enemies/             # enemy_{id}.webp (full-body chibi battle sprite)
├── images/
│   ├── style_board/     # AB1 golden references (§4)
│   ├── tiles/           # tile_{color}.png, tile_{color}_shape.png
│   ├── skills/          # skill_{id}.png, enemy_skill_{id}.png
│   ├── icons/           # resource chips, intent badges, status
│   ├── ui/              # optional 9-slice panel PNGs
│   └── vfx/             # fx_{name}.png or fx_{name}_{frame}.png
└── levels/              # JSON only — not art
```

---

## 6. Naming conventions

Pattern: `{category}_{stable_id}.{format}` — lowercase, underscores, **no spaces**, IDs match domain models. Large runtime art uses WebP; tiles, icons, and VFX remain PNG.

### Heroes & enemies

| Pattern | Example | Maps to |
|---------|---------|---------|
| `hero_{id}.webp` | `hero_mage.webp` | `HeroDef.id` |
| `enemy_{id}.webp` | `enemy_goblin.webp` | `EnemyDef.id` |

Phase 1 roster:

| Asset file | Code id |
|------------|---------|
| `hero_mage.webp` | `mage` |
| `hero_knight.webp` | `knight` |
| `enemy_goblin.webp` | `goblin` |
| `enemy_wolf.webp` | `wolf` |
| `enemy_shaman.webp` | `shaman` |
| `enemy_brute.webp` | `brute` |
| `enemy_warchief.webp` | `warchief` |

### Tiles

| Pattern | Example | Maps to |
|---------|---------|---------|
| `tile_{color}.png` | `tile_red.png` | `TileColor.red` |
| `tile_{color}_shape.png` | `tile_red_shape.png` | Accessibility overlay (§9) |

Colors: `red`, `blue`, `green`, `yellow`, `purple`.

### Skills / icons / VFX

Same patterns as before: `skill_{id}.png`, `icon_resource_{id}.png`, `fx_{name}.png`.

### Forbidden

- Display names in filenames
- Random hashes / `final_FINAL`
- Mixed casing

---

## 7. Export specifications

### Global rules

| Property | Value |
|----------|-------|
| Source format | PNG-24, sRGB under `art_sources/runtime_png/` |
| Delivery format | WebP for heroes, enemies, maps, and backgrounds; PNG for tiles/icons/VFX |
| Alpha | Straight alpha |
| Max file size (guideline) | ≤ 350 KB per battle sprite; ≤ 80 KB per tile @2x |
| Compression | Category quality tiers in `scripts/optimize_runtime_assets.py`; alpha and dimensions must remain exact |

### Master vs delivery

| Asset | Master (px) | Delivery @2x (px) | Display @1x (logical pt) | Notes |
|-------|------------:|------------------:|-------------------------:|-------|
| Hero battle sprite | 1024 × 1024 | 512 × 512 | ~180–220 tall on stage | Full body; feet near bottom; ~10% margin |
| Enemy battle sprite | 1024 × 1024 | 512 × 512 | Same scale family as hero | Align ground line with hero |
| Puzzle tile | 512 × 512 | 256 × 256 | ~44–56 pt (6×6 board) | Square; radius in UI |
| Tile shape overlay | 512 × 512 | 256 × 256 | Same as tile | White glyph, full alpha |
| Skill icon | 512 × 512 | 128 × 128 | 64 × 64 | Simple icon; no text |
| Resource icon | 256 × 256 | 64 × 64 | 32 × 32 | HUD chip |
| VFX single | 512 × 512 | 256 × 256 | — | Center-origin |

### 7.1 Nine-slice UI panels

Prefer **Flutter `DecoratedBox` + `MythDuskColors`**. If raster: fixed corners 48×48 @2x; document insets optionally.

---

## 8. Domain specs

### 8.1 Hero & enemy battle sprites

- **Framing:** Full-body chibi; standing idle / battle-ready; feet near bottom third
- **Proportions:** Large head, short limbs — consistent across roster
- **Background:** Solid `#123A44` — **no** busy forest/ruin scenes (Flutter can add a simple stage later)
- **Outline:** Thick, even, dark; soft cel fill (not skin-pore realism)
- **Weapons:** Readable at stage size (staff, sword, daggers)
- **Alignment:** Same ground line / scale across heroes and enemies for Flutter `Row` staging
- **HP / names:** Never painted into the PNG — Flutter widgets only

Roster / collection cards may reuse these sprites (scale down or soft vignette in UI).

### 8.2 Puzzle tiles

Board is **6×6**. Tiles must feel like the **same product** as chibi characters: glossy, outlined, bold.

Each color tile includes:

1. **Base icon** — fill close to `MythDuskColors.tile*` ([Theme](../02_Design_System/Theme.md))
2. **Inner highlight** — toy/gloss highlight
3. **Shape overlay** (separate PNG):

| Color | Resource | Shape |
|-------|----------|-------|
| red | attack | sword / chevron |
| blue | mana | droplet / arcane swirl |
| green | healing | leaf / cross |
| yellow | shield | shield |
| purple | ultimate | star / crown |

### 8.3 Skill icons

- Square, 80% glyph / 20% padding
- Same outline weight as tiles
- No tiny unreadable detail

### 8.4 VFX (lightweight)

Match timings in [Animations](../02_Design_System/Animations.md). Prefer Flutter tweens + 1 PNG when possible. Character idle/attack sheets → **AB2**.

---

## 9. Accessibility

- Every tile color has `tile_{color}_shape.png` (white silhouette)
- Minimum contrast tile vs `deepTeal` board: **3:1**
- Test sprites/icons desaturated for shape readability

---

## 10. Prompt templates

Replace `{SUBJECT}` and `{DETAIL}`. Append the style anchor sentence (§2). Full copy-paste packs live in [AB1_Leonardo_Prompt_Pack.md](AB1_Leonardo_Prompt_Pack.md).

### Leonardo — hero battle sprite

```text
Full-body chibi mobile game character, {SUBJECT}, {DETAIL},
large head short body, standing idle battle pose, facing slightly right,
centered, solid flat deep teal background #123A44,
thick clean outlines, soft cel shading, glossy toy finish,
no text, no UI bars, no environment.
Mobile puzzle RPG battle art, chibi super-deformed character, thick clean outlines,
soft cel shading, dusk teal and amber palette, glossy toy-like finish,
premium casual fantasy match-3 RPG, readable at phone size, no photorealism, no neon.
```

### Leonardo — enemy battle sprite

```text
Full-body chibi mobile game enemy, {SUBJECT}, {DETAIL},
large head short body, standing combat pose, facing slightly left,
centered, solid flat deep teal background #123A44,
thick clean outlines, soft cel shading, subtle ember accents,
no gore, no text, no UI bars.
Mobile puzzle RPG battle art, chibi super-deformed character, thick clean outlines,
soft cel shading, dusk teal and amber palette, glossy toy-like finish,
premium casual fantasy match-3 RPG, readable at phone size, no photorealism, no neon.
```

### Leonardo — puzzle tile

```text
Single glossy match-3 puzzle icon, {COLOR_NAME}, color hex {HEX},
thick clean outline, soft cel shading, toy highlight,
centered, transparent background, bold readable at small size, no text.
Mobile puzzle RPG battle art, glossy toy-like finish, dusk teal and amber palette,
premium casual fantasy match-3 RPG, no photorealism, no neon.
```

| Color | `{COLOR_NAME}` | `{HEX}` |
|-------|----------------|---------|
| red | red attack energy orb or gem with sword hint | `#C94B4B` |
| blue | blue mana droplet crystal | `#3D7CC9` |
| green | green healing leaf crystal | `#3FA86A` |
| yellow | yellow shield energy gem | `#D4B03C` |
| purple | purple ultimate star gem | `#8B5CB8` |

### Leonardo — skill icon

```text
Square skill icon, {SKILL_DESCRIPTION}, thick outline, soft cel shading,
centered glyph, transparent background, amber gold accents, no text.
Mobile puzzle RPG battle art, glossy toy-like finish, dusk teal and amber palette,
premium casual fantasy match-3 RPG, no photorealism, no neon.
```

---

## 11. Review checklist (required before ship)

- [ ] Matches style board (§4) — chibi proportions + outline weight + tile gloss
- [ ] Correct filename and folder (§5–§6)
- [ ] Delivery dimensions (§7)
- [ ] Readable at target size on 375 × 667 (iPhone SE class)
- [ ] No baked text, HP bars, logos, or watermarks
- [ ] Alpha clean on teal
- [ ] File size within guideline
- [ ] ID matches code catalog
- [ ] Desaturated shape test (tiles/skills)
- [ ] Same ground-line scale as paired battle sprites

**Reject** photoreal faces, adult proportions, or tiles that look like a different game.

---

## 12. Flutter integration (when wiring)

```dart
Image.asset('assets/heroes/hero_${hero.id}.png')
Image.asset('assets/enemies/enemy_${enemy.id}.png')
Image.asset('assets/images/tiles/tile_red.png')
Image.asset('assets/images/skills/skill_${skill.id}.png')
```

Battle stage (future): hero sprite left + enemy sprite right + Flutter HP bars overlaid. Until sprites land, keep color blocks + typography.

---

## 13. Phase 1 production order

| Step | Deliverables |
|------|--------------|
| 1 | Style seed → style board (§4) approved |
| 2 | Five tiles + five shape overlays |
| 3 | `hero_mage`, `hero_knight` full-body |
| 4 | Twilight Road enemies (5) full-body |
| 5 | Mage/knight skills (4 icons) |
| 6 | Goblin enemy skills (3) — optional P1 |
| 7 | Wire battle stage sprites above board |
| 8 | `fx_match_clear`, `fx_hit` — optional P2 |

---

## 14. What comes next (AB2+)

| Doc | When |
|-----|------|
| AB2 — Animation & VFX sheets | Idle / attack / hit frames for stage characters |
| AB3 — Cosmetic / rarity frames | Shop cosmetics |
| AB4 — Store & marketing | Store listing |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-07-10 | AB1 initial lock — sizes, naming, tooling, painterly bust prompts |
| 2026-07-11 | **Art style relock:** chibi battle stage + matching glossy tiles; bust portraits deprecated |
