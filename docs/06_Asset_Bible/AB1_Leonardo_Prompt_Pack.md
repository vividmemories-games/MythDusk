# AB1 — Leonardo Prompt Pack


| Field            | Value                                                                   |
| ---------------- | ----------------------------------------------------------------------- |
| **Status**       | Active                                                                  |
| **Last Updated** | 2026-07-11                                                              |
| **Use with**     | [AB1 Production Standards](AB1_Production_Standards.md)                 |
| **Art lock**     | Chibi battle stage ([Decisions](../00_Project/Decisions.md) 2026-07-11) |


Copy prompts **exactly**. Prompt Enhance **OFF** until a style-board image is approved.

**Phoenix note:** Text-only runs drift to cinematic realism. Always attach the **chibi style seed** (§1.1) as Style Reference.

---

## 1. First session (10 minutes)

1. Sign up at [leonardo.ai](https://leonardo.ai).
2. Left sidebar → **AI Image Generation**.
3. **Private Mode** ON (paid plans).
4. Model: **Leonardo Phoenix**.
5. Style preset: **Illustration** (avoid **Dynamic**).
6. Alchemy ON for finals; OFF while exploring.
7. Attach style seed via Image Guidance (§1.1).
8. Sizes — table in §3.
9. Generate **4** while exploring; **1** for finals.
10. Download → rename per [AB1 §6](AB1_Production_Standards.md#6-naming-conventions).



### 1.1 Bootstrap style seed (required)

Repo file:

`assets/images/style_board/style_seed_battle_mage.png`

**In Leonardo:**

1. **Image Guidance** → upload that PNG.
2. Type: **Style Reference** (not Character Reference on first board pass).
3. Strength: **High** for first mage/goblin board runs → **Mid** once consistent.
4. Paste §5.1 prompt + §2 negative → generate 4 → pick winner → `style_board_hero_mage.png`.
5. After mage board is approved, use **it** as Style Ref for goblin/tiles/heroes (seed is bootstrap only).

Do **not** use `style_seed_hero_mage_bust_deprecated.png`.

Reject: skin pores, adult proportions, cinematic busts, busy environments.

---



## 2. Universal negative prompt

Paste for **every** MythDusk generation:

```text
text, words, letters, numbers, watermark, logo, signature, username, frame, border, UI, caption,
health bar, HP bar, level badge, star rating,
blurry, low quality, jpeg artifacts, noisy, pixelated, oversaturated, neon colors, cyan glow, magenta glow,
photorealistic, photograph, 3d render, octane, unreal engine, plastic skin,
realistic face, detailed skin texture, subsurface scattering, hyper detailed, cinematic lighting,
adult proportions, realistic anatomy, fashion model, oil painting portrait, bust only,
disney, pixar, cartoon network, manga panel,
multiple characters, crowd, duplicate face, extra limbs, deformed hands, bad anatomy,
busy background, detailed environment, forest ruins, castle, cathedral, stone fortress, dungeon corridor,
bright white background, harsh spotlight, lens flare,
modern clothing, sci-fi, cyberpunk, guns, robots, gore
```

---



## 3. Universal settings by asset type


| Asset type                | Size        | Alchemy | Guidance                                   | Notes                   |
| ------------------------- | ----------- | ------- | ------------------------------------------ | ----------------------- |
| Style board characters    | 1024 × 1024 | ON      | Style Ref @ High from seed / approved mage | Full-body chibi         |
| Production battle sprites | 1024 × 1024 | ON      | Style Ref @ Mid                            | Approved mage or goblin |
| Puzzle tiles              | 768 × 768   | ON      | Style Ref @ Low–Mid from tile board        | Then Remove Background  |
| Tile shape overlays       | 768 × 768   | OFF     | None                                       | White glyph             |
| Skill icons               | 768 × 768   | ON      | Style Ref @ Low–Mid                        | Keep simple             |
| VFX                       | 768 × 768   | ON      | None                                       | Transparent preferred   |




### Image Guidance (after style board approved)

1. Upload `style_board_hero_mage.png` (or goblin for enemies).
2. **Style Reference** @ **Mid** (High if drift).
3. Character Reference only when matching one hero’s face/outfit — Mid max; don’t stack both at High.

---



## 4. Production order

```text
Day 1 — Style seed → style board (§5) → approve 5 PNGs
Day 2 — Tiles + shapes (§6)
Day 3 — Heroes full-body (§7)
Day 4 — Enemies full-body (§8)
Day 5 — Skills (§9)
Day 6 — Wire battle stage in Flutter
Day 7 — Optional Element train + VFX
```

---



## 5. Style board prompts (generate first)

Each run: Style Reference attached. Pick one winner → `assets/images/style_board/`.

### 5.1 `style_board_hero_mage.png`

**Image Guidance:** `style_seed_battle_mage.png` → Style Reference @ **High**

**Prompt:**

```text
Full-body chibi mobile game character, young arcane mage, large head short body,
hooded deep teal cloak with amber trim, pale parchment skin, soft hair under hood,
wooden staff with faint purple crystal, idle battle-ready standing pose,
facing slightly right, centered, feet near bottom,
solid flat background color deep teal #123A44,
thick clean dark outlines, soft cel shading, glossy toy-like finish,
premium casual fantasy match-3 RPG battle sprite, readable silhouette,
dusk adventure mood, no environment, no UI, no health bar
```

**Negative:** §2 universal

**Save as:** `assets/images/style_board/style_board_hero_mage.png`

---



### 5.2 `style_board_enemy_goblin.png`

**Image Guidance:** approved mage board (or seed) → Style Reference @ **Mid–High**

**Prompt:**

```text
Full-body chibi mobile game enemy, goblin scout, large head short body,
green-grey skin, large pointed ears, brown leather scraps, dual small daggers,
wary mischievous combat pose, facing slightly left, centered, feet near bottom,
solid flat background color deep teal #123A44, subtle ember orange accents,
thick clean dark outlines, soft cel shading, glossy toy-like finish,
premium casual fantasy match-3 RPG battle sprite, no gore, no environment, no UI
```

**Negative:** §2 universal

**Save as:** `assets/images/style_board/style_board_enemy_goblin.png`

---



### 5.3 `style_board_tile_red.png`

**Image Guidance:** mage or goblin board @ **Low** (keep tile colorful)

**Prompt:**

```text
Single glossy match-3 puzzle tile icon, one object only, centered,
red attack energy gem with subtle sword chevron hint, rich red #C94B4B,
thick clean outline, soft cel shading, bright toy highlight on top,
bold readable shape for mobile puzzle board, transparent background,
no shadow floor, no text, dusk fantasy casual match-3 RPG
```

**Negative:** §2 + `multiple gems, grid, board, hand, character, frame`

**Post:** Remove Background → verify transparency

**Save as:** `assets/images/style_board/style_board_tile_red.png`

---



### 5.4 `style_board_skill_fireball.png`

**Prompt:**

```text
Single square RPG skill icon, one centered symbol only,
fireball spell glyph, orange and amber flames in a compact sphere,
thick clean outline, soft cel shading, soft gold accents #E6C87A,
bold shape readable at 64 pixels, transparent background, no circle border, no text,
casual fantasy mobile game ability icon, dusk adventure palette
```

**Negative:** §2 + `square frame, button, UI panel, character, runes text`

**Save as:** `assets/images/style_board/style_board_skill_fireball.png`

---



### 5.5 `style_board_ui_panel.png` (optional)

Prefer Flutter-only chrome. If generating:

```text
Game UI panel texture swatch, square canvas, dusk fantasy mobile RPG,
deep teal panel fill #123A44, subtle mist border #1E4D57,
small amber gold corner ornament, flat empty center for stretching,
no text, no buttons, no characters, 2D flat UI texture
```

**Negative:** §2 + `mockup, phone, screenshot, multiple panels`

---



## 6. Puzzle tiles (after style board)

**Settings:** 768 × 768, Alchemy ON, Style Ref = `style_board_tile_red.png` @ **Low–Mid**

### 6.1 Base tiles → `assets/images/tiles/`



#### `tile_red.png`

```text
Single glossy match-3 puzzle tile icon, one object only, centered,
red attack energy gem, rich red #C94B4B, thick clean outline, soft cel shading,
toy highlight, bold readable, transparent background, casual dusk match-3 RPG
```



####  ``

```text
Single glossy match-3 puzzle tile icon, one object only, centered,
blue mana crystal droplet, rich blue #3D7CC9, thick clean outline, soft cel shading,
toy highlight, bold readable, transparent background, casual dusk match-3 RPG
```



#### `tile_green.png`

```text
Single glossy match-3 puzzle tile icon, one object only, centered,
green healing leaf crystal, rich green #3FA86A, thick clean outline, soft cel shading,
toy highlight, bold readable, transparent background, casual dusk match-3 RPG
```



#### `tile_yellow.png`

```text
Single glossy match-3 puzzle tile icon, one object only, centered,
yellow shield energy gem, rich gold-yellow #D4B03C, thick clean outline, soft cel shading,
toy highlight, bold readable, transparent background, casual dusk match-3 RPG
```



#### `tile_purple.png`

```text
Single glossy match-3 puzzle tile icon, one object only, centered,
purple ultimate star gem, rich purple #8B5CB8, thick clean outline, soft cel shading,
toy highlight, bold readable, transparent background, casual dusk match-3 RPG
```

**Negative (all tiles):** §2 + `multiple gems, grid, match-3 board, character, explosion`

**Post each:** Remove Background → crop square → export 256 × 256 delivery

---



### 6.2 Shape overlays → `assets/images/tiles/`

White silhouette. Alchemy **OFF**. No Style Reference.

#### `tile_red_shape.png`

```text
Single white flat icon silhouette, simple sword chevron symbol, centered,
pure white #FFFFFF glyph only, transparent background, no gem, no color, no shading,
bold readable shape for colorblind accessibility overlay, mobile game UI icon
```



#### `tile_blue_shape.png`

```text
Single white flat icon silhouette, simple mana droplet symbol, centered,
pure white #FFFFFF glyph only, transparent background, no gem, no color, no shading,
bold readable shape for colorblind accessibility overlay, mobile game UI icon
```



#### `tile_green_shape.png`

```text
Single white flat icon silhouette, simple leaf cross healing symbol, centered,
pure white #FFFFFF glyph only, transparent background, no gem, no color, no shading,
bold readable shape for colorblind accessibility overlay, mobile game UI icon
```



#### `tile_yellow_shape.png`

```text
Single white flat icon silhouette, simple heater shield symbol, centered,
pure white #FFFFFF glyph only, transparent background, no gem, no color, no shading,
bold readable shape for colorblind accessibility overlay, mobile game UI icon
```



#### `tile_purple_shape.png`

```text
Single white flat icon silhouette, simple star crown ultimate symbol, centered,
pure white #FFFFFF glyph only, transparent background, no gem, no color, no shading,
bold readable shape for colorblind accessibility overlay, mobile game UI icon
```

**Negative:** §2 + `color, gradient, 3d, gem, crystal, background gray`

---



## 7. Hero battle sprites

**Settings:** 1024 × 1024, Alchemy ON, Style Ref = `style_board_hero_mage.png` @ **Mid**

**Negative:** §2 universal

**Save to:** `assets/heroes/`

### `hero_mage.png`

```text
Full-body chibi mobile game character, young arcane mage, large head short body,
hooded deep teal cloak with amber trim, pale parchment skin,
wooden staff with faint purple crystal, idle battle-ready standing pose,
facing slightly right, centered, feet near bottom,
solid flat background deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish,
same art style as reference, no environment, no UI, no health bar
```



### `hero_knight.png`

```text
Full-body chibi mobile game character, sturdy knight, large head short body,
teal-steel plate with amber trim, small shield and short sword,
calm protective idle battle pose, facing slightly right, centered, feet near bottom,
solid flat background deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish,
same art style as reference, no environment, no UI, no health bar
```

---



## 8. Enemy battle sprites

**Settings:** 1024 × 1024, Alchemy ON, Style Ref = `style_board_enemy_goblin.png` @ **Mid**

**Negative:** §2 universal

**Save to:** `assets/enemies/`

### `enemy_goblin.png`

```text
Full-body chibi mobile game enemy, goblin scout, large head short body,
green-grey skin, large pointed ears, dual small daggers, leather scraps,
wary combat pose, facing slightly left, centered, feet near bottom,
solid flat background deep teal #123A44, subtle ember accents,
thick clean outlines, soft cel shading, glossy toy finish, no gore, no UI
```



### `enemy_wolf.png`

```text
Full-body chibi mobile game enemy, dusk wolf, large head short body,
dark grey fur, amber eyes, snarling but readable, standing on four legs or reared slightly,
facing slightly left, centered, feet near bottom,
solid flat background deep teal #123A44, subtle ember accents,
thick clean outlines, soft cel shading, glossy toy finish, fantasy wolf not photo, no UI
```



### `enemy_shaman.png`

```text
Full-body chibi mobile game enemy, bog shaman goblinoid, large head short body,
moss and bone talismans, glowing green-teal staff tip, hunched mystical pose,
facing slightly right, centered, feet near bottom,
solid flat background deep teal #123A44, ember and green mist accents,
thick clean outlines, soft cel shading, glossy toy finish, no gore, no UI
```



### `enemy_brute.png`

```text
Full-body chibi mobile game enemy, stone brute ogre, large head short body,
rocky skin patches, heavy fists, slow angry idle pose,
facing forward, centered, feet near bottom,
solid flat background deep teal #123A44, subtle ember accents,
thick clean outlines, soft cel shading, glossy toy finish, heavy tank silhouette, no UI
```



### `enemy_warchief.png`

```text
Full-body chibi mobile game enemy, orc warchief Ruk, large head short body,
battle scars, crude iron jaw guard, trophy bone strap, commanding stance with axe,
facing slightly left, centered, feet near bottom,
solid flat background deep teal #123A44, stronger ember rim, mini-boss presence,
thick clean outlines, soft cel shading, glossy toy finish, no gore, no UI
```

---



## 9. Skill icons

**Settings:** 768 × 768, Alchemy ON, Style Ref = `style_board_skill_fireball.png` @ **Low–Mid**

**Negative:** §2 + `character face, full body, full scene, button, square frame`

**Save to:** `assets/images/skills/`

### Hero skills



#### `skill_fireball.png`

```text
Single square RPG skill icon, centered fireball spell, orange amber flame sphere,
thick outline, soft cel shading, soft gold highlights, transparent background, no text,
casual fantasy mobile ability icon, readable at small size
```



#### `skill_arcane_bolt.png`

```text
Single square RPG skill icon, centered purple-blue arcane bolt streak,
thick outline, soft cel shading, soft gold sparks, transparent background, no text,
casual fantasy mobile ability icon, readable at small size
```



#### `skill_basic_slash.png`

```text
Single square RPG skill icon, centered sword slash arc, silver blade trail,
amber gold motion accent, thick outline, soft cel shading, transparent background, no text,
casual fantasy mobile ability icon, readable at small size
```



#### `skill_shield_wall.png`

```text
Single square RPG skill icon, centered heraldic shield with glowing barrier,
yellow-gold shield energy #D4B03C, thick outline, soft cel shading, transparent background, no text,
casual fantasy mobile ability icon, readable at small size
```



### Enemy skills (optional P1)



#### `enemy_skill_nick.png`

```text
Single square RPG skill icon, centered small dagger nick slash, short red ember trail,
thick outline, soft cel shading, transparent background, no text, enemy ability icon
```



#### `enemy_skill_slash.png`

```text
Single square RPG skill icon, centered curved blade slash, ember orange arc,
thick outline, soft cel shading, transparent background, no text, enemy ability icon
```



#### `enemy_skill_heavy.png`

```text
Single square RPG skill icon, centered heavy spiked mace swing, thick ember motion arc,
thick outline, soft cel shading, transparent background, no text, enemy ability icon
```

---



## 10. VFX (optional P2)

**Settings:** 768 × 768, Alchemy ON, transparent background

**Save to:** `assets/images/vfx/`

### `fx_match_clear.png`

```text
Single soft particle burst, small gem fragments dissolving, circular sparkle,
warm white and pale gold sparkles, thick outline cartoon VFX, transparent background,
casual mobile puzzle effect, no character, no text, centered
```



### `fx_hit.png`

```text
Single impact hit flash, short red-orange ember slash burst, radial sparks,
thick outline cartoon VFX, transparent background, no character, centered
```

---



## 11. When output goes wrong


| Problem                           | Fix                                                                                                  |
| --------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Too realistic / adult proportions | Style Ref @ High; add prompt `large head short body, chibi`; negative already bans adult proportions |
| Neon / cyberpunk                  | Strengthen negative; lower Style Ref slightly if palette warps                                       |
| Bust / head-and-shoulders only    | Add `full-body, feet visible near bottom`                                                            |
| Two characters                    | Negative `multiple characters`; generate 1 image                                                     |
| Text / HP bar in image            | Negative already includes; regenerate                                                                |
| Busy forest background            | Add `solid flat background deep teal #123A44 only`                                                   |
| Tile looks like different game    | Re-attach `style_board_tile_red.png`; match outline weight to characters                             |
| Style drift on enemy #4           | Re-attach goblin style board                                                                         |


---



## 12. Post-processing checklist

1. **Remove Background** (tiles, icons, VFX; sprites if bg isn’t clean teal)
2. **Crop** with ~10% margin; keep feet for full-body sprites
3. **Resize** to AB1 delivery sizes (sprites 512, tiles 256, skills 128)
4. **Rename** exactly per AB1 §6
5. Place in correct `assets/` folder
6. Squint test at phone size — reject if unreadable
7. Mark approved in `assets/images/style_board/README.md`

---



## 13. Training Dusk Chibi Element (optional, Premium+)

After 5 style-board images are approved:

1. **Training & Datasets** → New Dataset
2. Upload all 5 style-board PNGs (+ good same-session rejects, max ~15)
3. Name: `MythDusk_Chibi`
4. Train on platform-recommended base for Elements
5. Strength **0.55–0.70** characters; **0.45–0.55** tiles/icons

Style Reference alone is enough for Phase 1 if training isn’t worth the slot.

---



## Quick reference — filenames


| Prompt section | Output path                  |
| -------------- | ---------------------------- |
| §5 Style board | `assets/images/style_board/` |
| §6 Tiles       | `assets/images/tiles/`       |
| §7 Heroes      | `assets/heroes/`             |
| §8 Enemies     | `assets/enemies/`            |
| §9 Skills      | `assets/images/skills/`      |
| §10 VFX        | `assets/images/vfx/`         |


