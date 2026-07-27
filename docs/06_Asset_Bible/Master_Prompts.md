# Master Prompts — Leonardo (Mythora)


| Field            | Value                                                                                                      |
| ---------------- | ---------------------------------------------------------------------------------------------------------- |
| **Status**       | Active — checklist tracker                                                                                 |
| **Last Updated** | 2026-07-22                                                                                                 |
| **Plan**         | [Content Architecture](../01_Game_Design/Content_Architecture.md)                                          |
| **Style**        | [AB1 Production Standards](AB1_Production_Standards.md) · [AB1 Leonardo Pack](AB1_Leonardo_Prompt_Pack.md) |
| **Decisions**    | [2026-07-20 campaign](../00_Project/Decisions.md) · [2026-07-22 act maps](../00_Project/Decisions.md)     |


One **prompt per artwork**. Mark **Created** when the file exists at **Path**. Prompt Enhance **OFF**. Style Reference = `style_board_hero_mage.png` or `hero_mage.png` @ **Mid** (characters/icons).

Generate in priority order: **P0 → P1 → P2 → P3 → P4**.

---



## Launch checklist summary


| Priority | Meaning                   | Done / Total |
| -------- | ------------------------- | ------------ |
| **P0**   | Ship now / M1 board juice | 12 / 12      |
| **P1**   | M2–M3 prep + home + HUD   | 8 / 8        |
| **P2**   | M4–M6 Ch1 vertical slice  | 9 / 9        |
| **P3**   | First hero unlock polish  | 0 / 1        |
| **P4**   | Post-launch Ch2–10        | 90 / 90       |




### Directory layout


| Kind                | Directory                           |
| ------------------- | ----------------------------------- |
| Heroes              | `assets/heroes/`                    |
| Trash enemies       | `assets/enemies/`                   |
| Chapter bosses      | `assets/enemies/bosses/`            |
| Tiles               | `assets/images/tiles/`              |
| Board power-ups     | `assets/images/powerups/`           |
| Meta prep icons     | `assets/images/prep/`               |
| HUD icons           | `assets/images/icons/`              |
| Battle stage BGs    | `assets/images/backgrounds/battle/` |
| Home BG             | `assets/images/backgrounds/`        |
| Campaign act maps   | `assets/images/maps/`               |
| VFX                 | `assets/images/vfx/`                |
| Style board         | `assets/images/style_board/`        |


---



## 0. Shared settings


| Asset class             | Size        | Notes                                         |
| ----------------------- | ----------- | --------------------------------------------- |
| Characters / bosses     | 1024 × 1024 | Full-body chibi; solid `#123A44` or Remove BG |
| Icons (power-up / prep) | 768 × 768   | Transparent                                   |
| Battle backgrounds      | 1024 × 1536 | Soft empty lower third                        |
| Map act portraits       | 1024 × 1536 | **4 per chapter** (a1–a4); empty path for five pins |
| Home bg                 | 1024 × 1536 | No UI chrome                                  |
| VFX                     | 768 × 768   | Transparent                                   |




### Universal negative (characters / icons / VFX)

```text
text, words, letters, numbers, watermark, logo, signature, username, frame, border, UI, caption,
health bar, HP bar, level badge, star rating,
blurry, low quality, jpeg artifacts, noisy, pixelated, oversaturated, neon colors, cyan glow, magenta glow,
photorealistic, photograph, 3d render, octane, unreal engine, plastic skin,
realistic face, detailed skin texture, subsurface scattering, hyper detailed, cinematic lighting,
adult proportions, realistic anatomy, fashion model, oil painting portrait, bust only,
disney, pixar, cartoon network, manga panel,
multiple characters, crowd, duplicate face, extra limbs, deformed hands, bad anatomy,
busy background, detailed environment, bright white background, harsh spotlight, lens flare,
modern clothing, sci-fi, cyberpunk, guns, robots, gore
```



### Environment negative (battle BG / map / home)

```text
text, words, letters, numbers, watermark, logo, UI, HUD, health bar,
photorealistic, photograph, 3d render, octane, neon colors, cyan glow, magenta glow,
adult realistic people, crowd of characters, readable faces in foreground,
modern city, cars, sci-fi, cyberpunk, gore, blood splatter
```

---



## P0 — Board power-ups (M1)



### `powerup_rocket_v.png` — **P0**

- [x] Created

- **Path:** `assets/images/powerups/powerup_rocket_v.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Board specials
- **Negative:** universal character/icon

```text
Single glossy match-3 power-up icon, vertical rocket special, teal and amber accents, pointing up,
thick clean outline, soft cel shading, toy highlight, centered, transparent background, no text, casual dusk puzzle RPG
```



### `powerup_rocket_h.png` — **P0**

- [x] Created

- **Path:** `assets/images/powerups/powerup_rocket_h.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Board specials
- **Negative:** universal character/icon

```text
Single glossy match-3 power-up icon, horizontal rocket special, teal and amber accents, pointing right,
thick clean outline, soft cel shading, toy highlight, centered, transparent background, no text, casual dusk puzzle RPG
```



### `powerup_bomb.png` — **P0**

- [x] Created

- **Path:** `assets/images/powerups/powerup_bomb.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Board specials
- **Negative:** universal character/icon

```text
Single glossy match-3 power-up icon, round bomb special with short fuse spark, ember and soft gold accents,
thick clean outline, soft cel shading, toy highlight, centered, transparent background, no text, casual dusk puzzle RPG
```



### `powerup_fireball.png` — **P0**

- [x] Created

- **Path:** `assets/images/powerups/powerup_fireball.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Board specials
- **Negative:** universal character/icon

```text
Single glossy match-3 power-up icon, compact fireball sphere, orange amber flames with soft purple spark core,
thick clean outline, soft cel shading, toy highlight, centered, transparent background, no text, casual dusk puzzle RPG
```



### `powerup_seeker.png` — **P0**

- [x] Created

- **Path:** `assets/images/powerups/powerup_seeker.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Board specials
- **Negative:** universal character/icon

```text
Single glossy match-3 power-up icon, seeker special, stylized targeting reticle gem with teal glow arrow,
thick clean outline, soft cel shading, toy highlight, centered, transparent background, no text, casual dusk puzzle RPG
```

---



## P0 — Board VFX (M1)



### `fx_match_clear.png` — **P0**

- [x] Created

- **Path:** `assets/images/vfx/fx_match_clear.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Create/destroy juice
- **Negative:** universal character/icon

```text
Single soft particle burst VFX, gem fragments dissolving, circular sparkle, warm white and pale gold,
thick outline cartoon effect, transparent background, centered, no character, no text
```



### `fx_special_create.png` — **P0**

- [x] Created

- **Path:** `assets/images/vfx/fx_special_create.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Create/destroy juice
- **Negative:** universal character/icon

```text
Single power-up spawn pop VFX, bright ring burst with amber sparks, transparent background, centered,
cartoon mobile puzzle effect, no character, no text
```

---



## P0 — Tiles (shipped)



### `tile_red.png` — **P0**

- [x] Created

- **Path:** `assets/images/tiles/tile_red.png`
- **Size:** square PNG · transparent
- **Notes:** Red attack energy gem — already wired
- **Negative:** universal character/icon

```text
(Keep existing asset; regenerate only if style drifts. See AB1 tile prompts.)
```



### `tile_blue.png` — **P0**

- [x] Created

- **Path:** `assets/images/tiles/tile_blue.png`
- **Size:** square PNG · transparent
- **Notes:** Blue mana droplet — already wired
- **Negative:** universal character/icon

```text
(Keep existing asset; regenerate only if style drifts. See AB1 tile prompts.)
```



### `tile_green.png` — **P0**

- [x] Created

- **Path:** `assets/images/tiles/tile_green.png`
- **Size:** square PNG · transparent
- **Notes:** Green healing leaf — already wired
- **Negative:** universal character/icon

```text
(Keep existing asset; regenerate only if style drifts. See AB1 tile prompts.)
```



### `tile_yellow.png` — **P0**

- [x] Created

- **Path:** `assets/images/tiles/tile_yellow.png`
- **Size:** square PNG · transparent
- **Notes:** Yellow shield gem — already wired
- **Negative:** universal character/icon

```text
(Keep existing asset; regenerate only if style drifts. See AB1 tile prompts.)
```



### `tile_purple.png` — **P0**

- [x] Created

- **Path:** `assets/images/tiles/tile_purple.png`
- **Size:** square PNG · transparent
- **Notes:** Purple ultimate star gem — already wired
- **Negative:** universal character/icon

```text
(Keep existing asset; regenerate only if style drifts. See AB1 tile prompts.)
```

---



## P1 — Meta prep (M2)



### `prep_vanguard_tonic.png` — **P1**

- [x] Created

- **Path:** `assets/images/prep/prep_vanguard_tonic.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Pre-boss inventory
- **Negative:** universal character/icon

```text
Single square RPG inventory icon, Vanguard Tonic, small potion flask with teal liquid and amber cork,
thick clean outline, soft cel shading, glossy toy finish, centered, transparent background, no text, dusk fantasy mobile game
```



### `prep_aegis_flask.png` — **P1**

- [x] Created

- **Path:** `assets/images/prep/prep_aegis_flask.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Pre-boss inventory
- **Negative:** universal character/icon

```text
Single square RPG inventory icon, Aegis Flask, small potion flask with golden shield emblem on glass, yellow shield liquid,
thick clean outline, soft cel shading, glossy toy finish, centered, transparent background, no text, dusk fantasy mobile game
```



### `prep_second_wind.png` — **P1**

- [x] Created

- **Path:** `assets/images/prep/prep_second_wind.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Pre-boss inventory
- **Negative:** universal character/icon

```text
Single square RPG inventory icon, Second Wind, small heart-feather charm vial with soft parchment glow,
thick clean outline, soft cel shading, glossy toy finish, centered, transparent background, no text, dusk fantasy mobile game
```

---



## P1 — Home (M3)



### `bg_home_dusk.png` — **P1**

- [x] Created

- **Path:** `assets/images/backgrounds/bg_home_dusk.png`
- **Size:** 1024 × 1536
- **Notes:** Home hub; gradient OK until art lands
- **Negative:** environment

```text
Mobile game home screen background, vertical portrait, dusk adventure atmosphere, deep teal ink sky, soft amber rim light,
subtle distant mythic silhouette, empty center for UI, painterly 2D casual fantasy, no characters in foreground, no text, no UI chrome
```

---



## P1 — Stage characters (shipped)



### `hero_mage.png` — **P1**

- [x] Created

- **Path:** `assets/heroes/hero_mage.png`
- **Size:** 1024 × 1024
- **Notes:** Starter hero — shipped
- **Negative:** universal character/icon

```text
Full-body chibi mobile game hero, young arcane mage, large head short body,
hooded deep teal cloak with amber trim, pale parchment skin, wooden staff with purple crystal,
idle battle-ready pose, facing slightly right, centered, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish,
no UI, no health bar
```



### `enemy_goblin.png` — **P1**

- [x] Created

- **Path:** `assets/enemies/enemy_goblin.png`
- **Size:** 1024 × 1024
- **Notes:** Ch1 trash — shipped
- **Negative:** universal character/icon

```text
Full-body chibi enemy, goblin scout, large head short body, green-grey skin, large pointed ears,
dual small daggers, leather scraps, wary combat pose, facing slightly left, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish, no gore, no UI
```

---



## P1 — Battle HUD icons



### `icon_moves.png` — **P1**

- [x] Created

- **Path:** `assets/images/icons/icon_moves.png`
- **Size:** 256 × 256 · transparent
- **Notes:** Moves chip on battle HUD
- **Negative:** universal character/icon

```text
Single mobile game HUD icon, Moves, stylized leather boot footprint soft gold accents,
thick clean outline, soft cel shading, glossy toy finish, centered, transparent background, no text
```



### `icon_ap.png` — **P1**

- [x] Created

- **Path:** `assets/images/icons/icon_ap.png`
- **Size:** 256 × 256 · transparent
- **Notes:** AP chip on battle HUD; resources reuse tile_*.png
- **Negative:** universal character/icon

```text
Single mobile game HUD icon, Action Points, glowing amber lightning crystal orb,
thick clean outline, soft cel shading, glossy toy finish, centered, transparent background, no text
```

---



## P2 — Ch1 map & battle BG (M4–M6)



### `map_ch_twilight_road_a1.png` … `_a4.png` — **P2**

- [x] Created

- **Path:** `assets/images/maps/map_ch_twilight_road_a1.png` (…`_a4.png`)
- **Size:** 1024 × 1536 each (one Leonardo-friendly / generator portrait per act)
- **Notes:** Ch1 split into 4 acts × 5 nodes; each act darker/denser than the last. Not one mega-strip.
- **Negative:** environment

```text
Tall portrait mobile campaign map, winding dusk dirt path through teal woods,
empty path for five level markers, Act N darker and denser than previous,
painterly fantasy, no text, no UI, no characters
```

### `map_ch_twilight_road.png` (legacy single strip) — **deprecated**

- [ ] Removed — replaced by act maps a1–a4

### `bg_battle_twilight_road.png` — **P2**

- [x] Created

- **Path:** `assets/images/backgrounds/battle/bg_battle_twilight_road.png`
- **Size:** 1024 × 1536
- **Notes:** Empty lower third for fighters
- **Negative:** environment

```text
Mobile game battle stage background, vertical portrait, dusk forest path, deep teal ink sky, amber sunset rim light,
soft silhouettes of pines, empty clear lower third for characters, painterly 2D casual fantasy, no people, no UI
```

---



## P2 — Ch1 boss forms (M6)



### `boss_warchief_ruk_f1.png` — **P2**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_warchief_ruk_f1.png`
- **Size:** 1024 × 1024
- **Notes:** Boss sighting form f1
- **Negative:** universal character/icon

```text
Full-body chibi boss form 1, young orc warchief Ruk, large head short body, light leather, small axe, cocky grin, weaker scout look,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Twilight Road dusk fantasy, no gore, no UI
```



### `boss_warchief_ruk_f2.png` — **P2**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_warchief_ruk_f2.png`
- **Size:** 1024 × 1024
- **Notes:** Boss sighting form f2
- **Negative:** universal character/icon

```text
Full-body chibi boss form 2, orc warchief Ruk, large head short body, iron jaw guard, better axe and scrap armor, elite battle stance,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, dusk fantasy, no gore, no UI
```



### `boss_warchief_ruk_f3.png` — **P2**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_warchief_ruk_f3.png`
- **Size:** 1024 × 1024
- **Notes:** Boss sighting form f3
- **Negative:** universal character/icon

```text
Full-body chibi boss form 3, orc warchief Ruk, large head short body, heavier armor, trophy bones, oversized intimidating scale, menacing pose,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, dusk fantasy, no gore, no UI
```



### `boss_warchief_ruk_f4.png` — **P2**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_warchief_ruk_f4.png`
- **Size:** 1024 × 1024
- **Notes:** Boss sighting form f4
- **Negative:** universal character/icon

```text
Full-body chibi boss form 4, orc warchief Ruk final form, large head short body, crowned warlord armor, glowing ember axe, ultimate finale pose,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, chapter finale boss, no gore, no UI
```

---



## P2 — Ch1 VFX (M6)



### `fx_hit.png` — **P2**

- [x] Created

- **Path:** `assets/images/vfx/fx_hit.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Combat hit
- **Negative:** universal character/icon

```text
Single impact hit flash VFX, short ember slash burst, radial sparks, transparent background, centered,
cartoon mobile game effect, no character, no text
```



### `fx_boss_flee.png` — **P2**

- [x] Created

- **Path:** `assets/images/vfx/fx_boss_flee.png`
- **Size:** 768 × 768 · transparent
- **Notes:** Boss flees beat
- **Negative:** universal character/icon

```text
Single boss flee puff VFX, swirl of teal mist and dust cloud, transparent background, centered,
cartoon mobile game effect, no character, no text
```

---



## P2 — Ch1 trash (optional)



### `enemy_wolf.png` — **P2**

- [x] Created

- **Path:** `assets/enemies/enemy_wolf.png`
- **Size:** 1024 × 1024
- **Notes:** Ch1–3 trash variety
- **Negative:** universal character/icon

```text
Full-body chibi enemy, dusk wolf, large head short body, dark grey fur, amber eyes,
snarling but readable, standing pose facing slightly left, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish,
fantasy wolf not photo, no gore, no UI
```

---



## P3 — First hero unlock



### `hero_knight.png` — **P3**

- [ ] Created

- **Path:** `assets/heroes/hero_knight.png`
- **Size:** 1024 × 1024
- **Notes:** ~Level 50 unlock
- **Negative:** universal character/icon

```text
Full-body chibi mobile game hero, sturdy knight, large head short body,
teal-steel plate armor with amber gold trim, small heater shield and short sword,
calm protective idle pose, facing slightly right, centered, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish,
no UI, no health bar
```

---



## P4 — Later heroes



### `hero_ranger.png` — **P4**

- [x] Created

- **Path:** `assets/heroes/hero_ranger.png`
- **Size:** 1024 × 1024
- **Notes:** Unlock later in arc
- **Negative:** universal character/icon

```text
Full-body chibi mobile game hero, forest ranger archer, large head short body,
moss-green hooded cloak, leather bracers, wooden bow and quiver,
alert idle pose, facing slightly right, centered, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish,
dusk adventure, no UI, no health bar
```



### `hero_priest.png` — **P4**

- [x] Created

- **Path:** `assets/heroes/hero_priest.png`
- **Size:** 1024 × 1024
- **Notes:** Unlock later in arc
- **Negative:** universal character/icon

```text
Full-body chibi mobile game hero, gentle priest healer, large head short body,
parchment-white and soft gold robes, small holy staff with amber crystal,
serene idle pose, facing slightly right, centered, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish,
no UI, no health bar
```



### `hero_ninja.png` — **P4**

- [x] Created

- **Path:** `assets/heroes/hero_ninja.png`
- **Size:** 1024 × 1024
- **Notes:** Unlock later in arc
- **Negative:** universal character/icon

```text
Full-body chibi mobile game hero, dusk ninja, large head short body,
ink-dark wraps with teal sash, twin daggers, masked lower face, amber eye accent,
ready crouch-idle pose, facing slightly right, centered, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish,
no UI, no health bar
```

---



## P4 — Remaining trash enemies



### `enemy_shaman.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/enemy_shaman.png`
- **Size:** 1024 × 1024
- **Notes:** Later chapters
- **Negative:** universal character/icon

```text
Full-body chibi enemy, bog shaman goblinoid, large head short body, moss and bone talismans,
staff with glowing teal tip, hunched mystical pose, facing slightly right, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish, no gore, no UI
```



### `enemy_brute.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/enemy_brute.png`
- **Size:** 1024 × 1024
- **Notes:** Later chapters
- **Negative:** universal character/icon

```text
Full-body chibi enemy, stone brute ogre, large head short body, rocky skin patches, heavy fists,
slow angry idle pose facing forward, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish, no gore, no UI
```



### `enemy_mire_spawn.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/enemy_mire_spawn.png`
- **Size:** 1024 × 1024
- **Notes:** Later chapters
- **Negative:** universal character/icon

```text
Full-body chibi enemy, swamp mire spawn, large head short body, slimy teal-green body, reed frills,
dripping but cute not gross, facing slightly left, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish, Mistfen marshes, no gore, no UI
```



### `enemy_ridge_hawk.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/enemy_ridge_hawk.png`
- **Size:** 1024 × 1024
- **Notes:** Later chapters
- **Negative:** universal character/icon

```text
Full-body chibi enemy, ridge wind hawk, large head short body, grey-brown feathers, sharp amber eyes,
wings half-spread idle, facing slightly left, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish, Howling Ridge, no gore, no UI
```



### `enemy_crypt_skel.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/enemy_crypt_skel.png`
- **Size:** 1024 × 1024
- **Notes:** Later chapters
- **Negative:** universal character/icon

```text
Full-body chibi enemy, candlecrypt skeleton minion, large head short body, parchment bone, tiny purple candle glow in ribs,
clumsy combat pose facing slightly left, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish, cute undead not horror, no gore, no UI
```



### `enemy_forge_imp.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/enemy_forge_imp.png`
- **Size:** 1024 × 1024
- **Notes:** Later chapters
- **Negative:** universal character/icon

```text
Full-body chibi enemy, eclipse forge imp, large head short body, ember-orange skin, tiny horns, coal tongs weapon,
mischievous pose facing slightly left, feet near bottom,
solid flat background deep teal #123A44, thick clean outlines, soft cel shading, glossy toy finish, no gore, no UI
```

---



## P4 — Bosses Ch2–10 (Mistfen Marshes)



### `boss_mirelord_f1.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_mirelord_f1.png`
- **Size:** 1024 × 1024
- **Notes:** Mistfen Marshes form 1
- **Negative:** universal character/icon

```text
Full-body chibi boss form 1, swamp mirelord toad-king, large head short body, mossy skin reed crown,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mistfen Marshes, no gore, no UI
```



### `boss_mirelord_f2.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_mirelord_f2.png`
- **Size:** 1024 × 1024
- **Notes:** Mistfen Marshes form 2
- **Negative:** universal character/icon

```text
Full-body chibi boss form 2, swamp mirelord toad-king, large head short body, moss armor teal spores,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mistfen Marshes, no gore, no UI
```



### `boss_mirelord_f3.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_mirelord_f3.png`
- **Size:** 1024 × 1024
- **Notes:** Mistfen Marshes form 3
- **Negative:** universal character/icon

```text
Full-body chibi boss form 3, swamp mirelord toad-king, large head short body, oversized vine cloak,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mistfen Marshes, no gore, no UI
```



### `boss_mirelord_f4.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_mirelord_f4.png`
- **Size:** 1024 × 1024
- **Notes:** Mistfen Marshes form 4
- **Negative:** universal character/icon

```text
Full-body chibi boss form 4, swamp mirelord toad-king, large head short body, coral reed crown swamp lantern staff,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mistfen Marshes, no gore, no UI
```

---



## P4 — Bosses Ch2–10 (Howling Ridge)



### `boss_pack_alpha_f1.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_pack_alpha_f1.png`
- **Size:** 1024 × 1024
- **Notes:** Howling Ridge form 1
- **Negative:** universal character/icon

```text
Full-body chibi boss form 1, dusk wolf pack alpha, large head short body, lean grey fur,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Howling Ridge, no gore, no UI
```



### `boss_pack_alpha_f2.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_pack_alpha_f2.png`
- **Size:** 1024 × 1024
- **Notes:** Howling Ridge form 2
- **Negative:** universal character/icon

```text
Full-body chibi boss form 2, dusk wolf pack alpha, large head short body, wind-mark paint elite,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Howling Ridge, no gore, no UI
```



### `boss_pack_alpha_f3.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_pack_alpha_f3.png`
- **Size:** 1024 × 1024
- **Notes:** Howling Ridge form 3
- **Negative:** universal character/icon

```text
Full-body chibi boss form 3, dusk wolf pack alpha, large head short body, oversized storm-grey mane,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Howling Ridge, no gore, no UI
```



### `boss_pack_alpha_f4.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_pack_alpha_f4.png`
- **Size:** 1024 × 1024
- **Notes:** Howling Ridge form 4
- **Negative:** universal character/icon

```text
Full-body chibi boss form 4, dusk wolf pack alpha, large head short body, amber storm eyes wind-totem collar,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Howling Ridge, no gore, no UI
```

---



## P4 — Bosses Ch2–10 (Ashen Quarries)



### `boss_quarry_overseer_f1.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_quarry_overseer_f1.png`
- **Size:** 1024 × 1024
- **Notes:** Ashen Quarries form 1
- **Negative:** universal character/icon

```text
Full-body chibi boss form 1, quarry overseer golem, large head short body, cracked stone small pickaxe,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Ashen Quarries, no gore, no UI
```



### `boss_quarry_overseer_f2.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_quarry_overseer_f2.png`
- **Size:** 1024 × 1024
- **Notes:** Ashen Quarries form 2
- **Negative:** universal character/icon

```text
Full-body chibi boss form 2, quarry overseer golem, large head short body, ore veins heavier pickaxe,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Ashen Quarries, no gore, no UI
```



### `boss_quarry_overseer_f3.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_quarry_overseer_f3.png`
- **Size:** 1024 × 1024
- **Notes:** Ashen Quarries form 3
- **Negative:** universal character/icon

```text
Full-body chibi boss form 3, quarry overseer golem, large head short body, oversized rocky ember cracks,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Ashen Quarries, no gore, no UI
```



### `boss_quarry_overseer_f4.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_quarry_overseer_f4.png`
- **Size:** 1024 × 1024
- **Notes:** Ashen Quarries form 4
- **Negative:** universal character/icon

```text
Full-body chibi boss form 4, quarry overseer golem, large head short body, molten ore heart crystal ore crown,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Ashen Quarries, no gore, no UI
```

---



## P4 — Bosses Ch2–10 (Candlecrypt)



### `boss_bone_seer_f1.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_bone_seer_f1.png`
- **Size:** 1024 × 1024
- **Notes:** Candlecrypt form 1
- **Negative:** universal character/icon

```text
Full-body chibi boss form 1, bone seer, large head short body, thin robe single purple candle,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Candlecrypt, no gore, no UI
```



### `boss_bone_seer_f2.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_bone_seer_f2.png`
- **Size:** 1024 × 1024
- **Notes:** Candlecrypt form 2
- **Negative:** universal character/icon

```text
Full-body chibi boss form 2, bone seer, large head short body, candle crown elite mystic,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Candlecrypt, no gore, no UI
```



### `boss_bone_seer_f3.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_bone_seer_f3.png`
- **Size:** 1024 × 1024
- **Notes:** Candlecrypt form 3
- **Negative:** universal character/icon

```text
Full-body chibi boss form 3, bone seer, large head short body, oversized floating candle orbs,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Candlecrypt, no gore, no UI
```



### `boss_bone_seer_f4.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_bone_seer_f4.png`
- **Size:** 1024 × 1024
- **Notes:** Candlecrypt form 4
- **Negative:** universal character/icon

```text
Full-body chibi boss form 4, bone seer, large head short body, purple flame halo ornate bone staff,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Candlecrypt, no gore, no UI
```

---



## P4 — Bosses Ch2–10 (Mirror Lake)



### `boss_lake_wraith_f1.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_lake_wraith_f1.png`
- **Size:** 1024 × 1024
- **Notes:** Mirror Lake form 1
- **Negative:** universal character/icon

```text
Full-body chibi boss form 1, lake wraith, large head short body, translucent teal veil mirror shard,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mirror Lake, no gore, no UI
```



### `boss_lake_wraith_f2.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_lake_wraith_f2.png`
- **Size:** 1024 × 1024
- **Notes:** Mirror Lake form 2
- **Negative:** universal character/icon

```text
Full-body chibi boss form 2, lake wraith, large head short body, mirror armor shards elite,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mirror Lake, no gore, no UI
```



### `boss_lake_wraith_f3.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_lake_wraith_f3.png`
- **Size:** 1024 × 1024
- **Notes:** Mirror Lake form 3
- **Negative:** universal character/icon

```text
Full-body chibi boss form 3, lake wraith, large head short body, oversized glass cloak,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mirror Lake, no gore, no UI
```



### `boss_lake_wraith_f4.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_lake_wraith_f4.png`
- **Size:** 1024 × 1024
- **Notes:** Mirror Lake form 4
- **Negative:** universal character/icon

```text
Full-body chibi boss form 4, lake wraith, large head short body, fractured mirror crown deep teal glow,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mirror Lake, no gore, no UI
```

---



## P4 — Bosses Ch2–10 (Thornmarket)



### `boss_gilded_fence_f1.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_gilded_fence_f1.png`
- **Size:** 1024 × 1024
- **Notes:** Thornmarket form 1
- **Negative:** universal character/icon

```text
Full-body chibi boss form 1, corrupt market fence, large head short body, ragged trader coat coin pouch,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Thornmarket, no gore, no UI
```



### `boss_gilded_fence_f2.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_gilded_fence_f2.png`
- **Size:** 1024 × 1024
- **Notes:** Thornmarket form 2
- **Negative:** universal character/icon

```text
Full-body chibi boss form 2, corrupt market fence, large head short body, gold trim weighted scales,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Thornmarket, no gore, no UI
```



### `boss_gilded_fence_f3.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_gilded_fence_f3.png`
- **Size:** 1024 × 1024
- **Notes:** Thornmarket form 3
- **Negative:** universal character/icon

```text
Full-body chibi boss form 3, corrupt market fence, large head short body, oversized thorn-coin cape,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Thornmarket, no gore, no UI
```



### `boss_gilded_fence_f4.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_gilded_fence_f4.png`
- **Size:** 1024 × 1024
- **Notes:** Thornmarket form 4
- **Negative:** universal character/icon

```text
Full-body chibi boss form 4, corrupt market fence, large head short body, gilded mask amber coin staff,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Thornmarket, no gore, no UI
```

---



## P4 — Bosses Ch2–10 (Skybridge Siege)



### `boss_siege_captain_f1.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_siege_captain_f1.png`
- **Size:** 1024 × 1024
- **Notes:** Skybridge Siege form 1
- **Negative:** universal character/icon

```text
Full-body chibi boss form 1, skybridge siege captain, large head short body, light armor small banner spear,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Skybridge Siege, no gore, no UI
```



### `boss_siege_captain_f2.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_siege_captain_f2.png`
- **Size:** 1024 × 1024
- **Notes:** Skybridge Siege form 2
- **Negative:** universal character/icon

```text
Full-body chibi boss form 2, skybridge siege captain, large head short body, plated armor torn war banner,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Skybridge Siege, no gore, no UI
```



### `boss_siege_captain_f3.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_siege_captain_f3.png`
- **Size:** 1024 × 1024
- **Notes:** Skybridge Siege form 3
- **Negative:** universal character/icon

```text
Full-body chibi boss form 3, skybridge siege captain, large head short body, oversized bridge-chain cloak,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Skybridge Siege, no gore, no UI
```



### `boss_siege_captain_f4.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_siege_captain_f4.png`
- **Size:** 1024 × 1024
- **Notes:** Skybridge Siege form 4
- **Negative:** universal character/icon

```text
Full-body chibi boss form 4, skybridge siege captain, large head short body, storm-cape glowing banner spear,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Skybridge Siege, no gore, no UI
```

---



## P4 — Bosses Ch2–10 (Eclipse Forge)



### `boss_ember_smith_f1.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_ember_smith_f1.png`
- **Size:** 1024 × 1024
- **Notes:** Eclipse Forge form 1
- **Negative:** universal character/icon

```text
Full-body chibi boss form 1, ember smith, large head short body, soot apron small hammer,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Eclipse Forge, no gore, no UI
```



### `boss_ember_smith_f2.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_ember_smith_f2.png`
- **Size:** 1024 × 1024
- **Notes:** Eclipse Forge form 2
- **Negative:** universal character/icon

```text
Full-body chibi boss form 2, ember smith, large head short body, heat-proof plates bigger hammer,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Eclipse Forge, no gore, no UI
```



### `boss_ember_smith_f3.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_ember_smith_f3.png`
- **Size:** 1024 × 1024
- **Notes:** Eclipse Forge form 3
- **Negative:** universal character/icon

```text
Full-body chibi boss form 3, ember smith, large head short body, oversized magma armor cracks,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Eclipse Forge, no gore, no UI
```



### `boss_ember_smith_f4.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_ember_smith_f4.png`
- **Size:** 1024 × 1024
- **Notes:** Eclipse Forge form 4
- **Negative:** universal character/icon

```text
Full-body chibi boss form 4, ember smith, large head short body, molten crown dual forging hammers,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Eclipse Forge, no gore, no UI
```

---



## P4 — Bosses Ch2–10 (Mythspire Gate)



### `boss_mythspire_tyrant_f1.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_mythspire_tyrant_f1.png`
- **Size:** 1024 × 1024
- **Notes:** Mythspire Gate form 1
- **Negative:** universal character/icon

```text
Full-body chibi boss form 1, mythspire tyrant, large head short body, cracked dark armor broken crown,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mythspire Gate, no gore, no UI
```



### `boss_mythspire_tyrant_f2.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_mythspire_tyrant_f2.png`
- **Size:** 1024 × 1024
- **Notes:** Mythspire Gate form 2
- **Negative:** universal character/icon

```text
Full-body chibi boss form 2, mythspire tyrant, large head short body, dark plate amber-purple runes,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mythspire Gate, no gore, no UI
```



### `boss_mythspire_tyrant_f3.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_mythspire_tyrant_f3.png`
- **Size:** 1024 × 1024
- **Notes:** Mythspire Gate form 3
- **Negative:** universal character/icon

```text
Full-body chibi boss form 3, mythspire tyrant, large head short body, oversized dusk-star cloak,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mythspire Gate, no gore, no UI
```



### `boss_mythspire_tyrant_f4.png` — **P4**

- [x] Created

- **Path:** `assets/enemies/bosses/boss_mythspire_tyrant_f4.png`
- **Size:** 1024 × 1024
- **Notes:** Mythspire Gate form 4
- **Negative:** universal character/icon

```text
Full-body chibi boss form 4, mythspire tyrant, large head short body, full dusk crown legendary amber-purple blade,
facing slightly left, feet near bottom, solid flat deep teal #123A44,
thick clean outlines, soft cel shading, glossy toy finish, Mythspire Gate, no gore, no UI
```

---



## P4 — Battle BGs Ch2–10



### `bg_battle_mistfen_marshes.png` — **P4**

- [x] Created

- **Path:** `assets/images/backgrounds/battle/bg_battle_mistfen_marshes.png`
- **Size:** 1024 × 1536
- **Notes:** Mistfen Marshes
- **Negative:** environment

```text
Mobile game battle stage background, vertical portrait, foggy swamp marshes at dusk, teal mist, reed silhouettes,
empty clear lower third for characters, painterly 2D casual fantasy, Mistfen Marshes mood, no people, no UI
```



### `bg_battle_howling_ridge.png` — **P4**

- [x] Created

- **Path:** `assets/images/backgrounds/battle/bg_battle_howling_ridge.png`
- **Size:** 1024 × 1536
- **Notes:** Howling Ridge
- **Negative:** environment

```text
Mobile game battle stage background, vertical portrait, windy cliff ridge at dusk, streaked clouds, rocky ledges,
empty clear lower third for characters, painterly 2D casual fantasy, Howling Ridge mood, no people, no UI
```



### `bg_battle_ashen_quarries.png` — **P4**

- [x] Created

- **Path:** `assets/images/backgrounds/battle/bg_battle_ashen_quarries.png`
- **Size:** 1024 × 1536
- **Notes:** Ashen Quarries
- **Negative:** environment

```text
Mobile game battle stage background, vertical portrait, ember quarry pits, ash dust, warm ember accents on teal dusk,
empty clear lower third for characters, painterly 2D casual fantasy, Ashen Quarries mood, no people, no UI
```



### `bg_battle_candlecrypt.png` — **P4**

- [x] Created

- **Path:** `assets/images/backgrounds/battle/bg_battle_candlecrypt.png`
- **Size:** 1024 × 1536
- **Notes:** Candlecrypt
- **Negative:** environment

```text
Mobile game battle stage background, vertical portrait, candlelit catacomb hall, soft purple candle glows, stone arches distant,
empty clear lower third for characters, painterly 2D casual fantasy, Candlecrypt mood, no people, no UI
```



### `bg_battle_mirror_lake.png` — **P4**

- [x] Created

- **Path:** `assets/images/backgrounds/battle/bg_battle_mirror_lake.png`
- **Size:** 1024 × 1536
- **Notes:** Mirror Lake
- **Negative:** environment

```text
Mobile game battle stage background, vertical portrait, still mirror lake ruins at dusk, reflective water, soft teal haze,
empty clear lower third for characters, painterly 2D casual fantasy, Mirror Lake mood, no people, no UI
```



### `bg_battle_thornmarket.png` — **P4**

- [x] Created

- **Path:** `assets/images/backgrounds/battle/bg_battle_thornmarket.png`
- **Size:** 1024 × 1536
- **Notes:** Thornmarket
- **Negative:** environment

```text
Mobile game battle stage background, vertical portrait, night fantasy bazaar stalls silhouettes, amber lanterns, teal shadows,
empty clear lower third for characters, painterly 2D casual fantasy, Thornmarket mood, no people, no UI
```



### `bg_battle_skybridge_siege.png` — **P4**

- [x] Created

- **Path:** `assets/images/backgrounds/battle/bg_battle_skybridge_siege.png`
- **Size:** 1024 × 1536
- **Notes:** Skybridge Siege
- **Negative:** environment

```text
Mobile game battle stage background, vertical portrait, broken skybridge spans over abyss, dusk wind, distant towers,
empty clear lower third for characters, painterly 2D casual fantasy, Skybridge Siege mood, no people, no UI
```



### `bg_battle_eclipse_forge.png` — **P4**

- [x] Created

- **Path:** `assets/images/backgrounds/battle/bg_battle_eclipse_forge.png`
- **Size:** 1024 × 1536
- **Notes:** Eclipse Forge
- **Negative:** environment

```text
Mobile game battle stage background, vertical portrait, magma forge cavern, ember glow vs deep teal shadows, anvil silhouettes,
empty clear lower third for characters, painterly 2D casual fantasy, Eclipse Forge mood, no people, no UI
```



### `bg_battle_mythspire_gate.png` — **P4**

- [x] Created

- **Path:** `assets/images/backgrounds/battle/bg_battle_mythspire_gate.png`
- **Size:** 1024 × 1536
- **Notes:** Mythspire Gate
- **Negative:** environment

```text
Mobile game battle stage background, vertical portrait, mythic fortress gate at dusk, towering doors, amber rim light, ink sky,
empty clear lower third for characters, painterly 2D casual fantasy, Mythspire Gate mood, no people, no UI
```

---



## P4 — Act maps Ch2–10 (4 per chapter)



Each chapter mirrors Ch1: **`map_ch_{slug}_a1.png` … `_a4.png`** — one 1024×1536 portrait per act (5 nodes). Act N is darker/denser than Act N−1. Legacy single-strip files without `_aN` are **deprecated** (do not generate).

**Inventory:** 9 chapters × 4 acts = **36** map arts (Ch1’s 4 already under P2 → **40** campaign maps total).

**Path-only act maps (final layout approach):**
- Paint a **natural walkable path** only (stone road, boardwalk, cliff switchback, etc.) that zig-zags bottom → top.
- **Do not** paint circular stone/dirt pads, gold rings, empty discs, or numbered markers.
- Pin positions are placed in-app (QA pin editor) onto the path — art must leave a clear walkable ribbon, not pre-baked pad slots.
- **Never** draw UI polylines, dashed connectors, or diagram lines on the path.
- No characters, no UI chrome, no text, no watermarks.

Composition reference for older pad experiments: `assets/images/style_board/map_pin_pad_template.png` (optional; not required for path-only gens).

Legacy locked pad percentages (only if compositing pads via `scripts/stamp_map_pads.py`):

| Pad | mapX | mapY |
|-----|------|------|
| 1 (bottom) | 0.48 | 0.88 |
| 2 | 0.58 | 0.72 |
| 3 | 0.42 | 0.56 |
| 4 | 0.56 | 0.38 |
| 5 (top / boss) | 0.50 | 0.28 |



### `map_ch_mistfen_marshes_a1.png` … `_a4.png` — **P4**

- [x] Created

- **Path:** `assets/images/maps/map_ch_mistfen_marshes_a1.png` (…`_a4.png`)
- **Size:** 1024 × 1536 each
- **Notes:** Mistfen Marshes; 4 acts × 5 nodes; denser fog per act; **locked pad layout**
- **Negative:** environment

```text
Tall portrait mobile campaign map, foggy teal swamp boardwalk,
ONE continuous walkable path zig-zag bottom to top (path only),
NO circular pads, NO round platforms, NO discs, NO gold rings,
Act N denser fog than previous, painterly fantasy, Mistfen Marshes,
no text, no UI, no characters
```



### `map_ch_howling_ridge_a1.png` … `_a4.png` — **P4**

- [x] Created

- **Path:** `assets/images/maps/map_ch_howling_ridge_a1.png` (…`_a4.png`)
- **Size:** 1024 × 1536 each
- **Notes:** Howling Ridge; wind/cliff densifies per act
- **Negative:** environment

```text
Tall portrait mobile campaign map, winding cliff switchback path, windy dusk ridges,
empty path for five level markers, Act N darker windier than previous,
painterly fantasy, Howling Ridge, no text, no UI, no characters
```



### `map_ch_ashen_quarries_a1.png` … `_a4.png` — **P4**

- [x] Created

- **Path:** `assets/images/maps/map_ch_ashen_quarries_a1.png` (…`_a4.png`)
- **Size:** 1024 × 1536 each
- **Notes:** Ashen Quarries; ember/ash densifies per act
- **Negative:** environment

```text
Tall portrait mobile campaign map, winding quarry switchbacks, ash and ember accents,
empty path for five level markers, Act N denser embers than previous,
painterly fantasy, Ashen Quarries, no text, no UI, no characters
```



### `map_ch_candlecrypt_a1.png` … `_a4.png` — **P4**

- [x] Created

- **Path:** `assets/images/maps/map_ch_candlecrypt_a1.png` (…`_a4.png`)
- **Size:** 1024 × 1536 each
- **Notes:** Candlecrypt; candle/purple glow densifies per act
- **Negative:** environment

```text
Tall portrait mobile campaign map, winding candlelit crypt corridor path,
empty path for five level markers, Act N darker more candles than previous,
painterly fantasy, Candlecrypt, no text, no UI, no characters
```



### `map_ch_mirror_lake_a1.png` … `_a4.png` — **P4**

- [x] Created

- **Path:** `assets/images/maps/map_ch_mirror_lake_a1.png` (…`_a4.png`)
- **Size:** 1024 × 1536 each
- **Notes:** Mirror Lake; reflection/ruin densifies per act
- **Negative:** environment

```text
Tall portrait mobile campaign map, winding lakeside ruin path, reflective teal water,
empty path for five level markers, Act N denser ruins than previous,
painterly fantasy, Mirror Lake, no text, no UI, no characters
```



### `map_ch_thornmarket_a1.png` … `_a4.png` — **P4**

- [x] Created

- **Path:** `assets/images/maps/map_ch_thornmarket_a1.png` (…`_a4.png`)
- **Size:** 1024 × 1536 each
- **Notes:** Thornmarket; lantern bazaar densifies per act
- **Negative:** environment

```text
Tall portrait mobile campaign map, winding night market alley path, amber lantern bokeh,
empty path for five level markers, Act N denser stalls than previous,
painterly fantasy, Thornmarket, no text, no UI, no characters
```



### `map_ch_skybridge_siege_a1.png` … `_a4.png` — **P4**

- [x] Created

- **Path:** `assets/images/maps/map_ch_skybridge_siege_a1.png` (…`_a4.png`)
- **Size:** 1024 × 1536 each
- **Notes:** Skybridge Siege; broken spans densify per act
- **Negative:** environment

```text
Tall portrait mobile campaign map, winding broken bridge path over abyss,
empty path for five level markers, Act N more fractured spans than previous,
painterly fantasy, Skybridge Siege, no text, no UI, no characters
```



### `map_ch_eclipse_forge_a1.png` … `_a4.png` — **P4**

- [x] Created

- **Path:** `assets/images/maps/map_ch_eclipse_forge_a1.png` (…`_a4.png`)
- **Size:** 1024 × 1536 each
- **Notes:** Eclipse Forge; ember veins densify per act
- **Negative:** environment

```text
Tall portrait mobile campaign map, winding forge cavern path, ember veins in rock,
empty path for five level markers, Act N hotter denser forge glow than previous,
painterly fantasy, Eclipse Forge, no text, no UI, no characters
```



### `map_ch_mythspire_gate_a1.png` … `_a4.png` — **P4**

- [x] Created

- **Path:** `assets/images/maps/map_ch_mythspire_gate_a1.png` (…`_a4.png`)
- **Size:** 1024 × 1536 each
- **Notes:** Mythspire Gate; approach densifies toward the gate
- **Negative:** environment

```text
Tall portrait mobile campaign map, winding fortress approach path to giant dusk gate,
empty path for five level markers, Act N closer more imposing gate than previous,
painterly fantasy, Mythspire Gate, no text, no UI, no characters
```

---



## Reference — style board



### `style_seed_battle_mage.png` — **P0**

- [x] Created

- **Path:** `assets/images/style_board/style_seed_battle_mage.png`
- **Size:** 1024 × 1024
- **Notes:** Bootstrap style seed
- **Negative:** universal character/icon

```text
(Style reference asset — see AB1 Leonardo Prompt Pack §5 if regenerating.)
```



### `style_board_tile_red.png` — **P0**

- [x] Created

- **Path:** `assets/images/style_board/style_board_tile_red.png`
- **Size:** 1024 × 1024
- **Notes:** Tile style ref
- **Negative:** universal character/icon

```text
(Style reference asset — see AB1 Leonardo Prompt Pack §5 if regenerating.)
```



### `style_board_skill_fireball.png` — **P0**

- [x] Created

- **Path:** `assets/images/style_board/style_board_skill_fireball.png`
- **Size:** 1024 × 1024
- **Notes:** Skill style ref
- **Negative:** universal character/icon

```text
(Style reference asset — see AB1 Leonardo Prompt Pack §5 if regenerating.)
```



### `style_board_hero_mage.png` — **P0**

- [ ] Created

- **Path:** `assets/images/style_board/style_board_hero_mage.png`
- **Size:** 1024 × 1024
- **Notes:** Preferred Style Ref — recreate from hero_mage if missing
- **Negative:** universal character/icon

```text
(Style reference asset — see AB1 Leonardo Prompt Pack §5 if regenerating.)
```



### `style_board_enemy_goblin.png` — **P0**

- [ ] Created

- **Path:** `assets/images/style_board/style_board_enemy_goblin.png`
- **Size:** 1024 × 1024
- **Notes:** Enemy Style Ref — recreate from enemy_goblin if missing
- **Negative:** universal character/icon

```text
(Style reference asset — see AB1 Leonardo Prompt Pack §5 if regenerating.)
```

---

