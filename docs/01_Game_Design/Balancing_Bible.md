# Balancing Bible

| Field | Value |
|-------|-------|
| **Status** | v1.2 authoritative (combat + soft progression + weekly + V1.0 monetization knobs) |
| **Last Updated** | 2026-08-21 |
| **Authority** | Numbers & formulas (must not contradict [GAMEPLAY](../GAMEPLAY.md) rules) |
| **Related** | [Heroes](Heroes.md) · [Enemies](Enemies.md) · [Economy](Economy.md) · [Monetization](Monetization.md) · [PHASES](../PHASES.md) · `.cursor/rules/08-monetization-economy.mdc` |

## Purpose

Single place for tunable combat and soft-progression numbers. Code configs (`MatchBalanceConfig`, `PrepBalance`, `EconomyBalance`, `BossCombatBalance`, `WeeklyBalance`, `DefeatContinueBalance`, `StarterPackBalance`) must mirror this document. Product rules and later IAP phases live in [Monetization](Monetization.md). Real store SKUs wait for Firebase settlement.

## Locked design decisions (v1.1)

| Topic | Choice |
|--------|--------|
| **Scope** | Combat + soft progression (coins, lives, prep, weekly); full shop/IAP tables later |
| **Difficulty** | Board stays fair; **prep / lives / boosts** are the main friction |
| **Prep offer** | Prep picker before **every** fight (campaign + weekly); **Play with none** always allowed |
| **Prep pressure** | Trash balanced for **0 prep**; Act 3+ bosses / finales / weekend weekly expect prep |
| **Lives** | Only stamina gate (maps “energy”). Every campaign/weekly defeat spends 1 life. No second energy meter |
| **Life pool / regen** | Max **5**; **+1 every 20 minutes**; refill on player level-up when XP exists |
| **Gem lives** | Up to **3 partial refills/day** (+3 lives each), **75 gems** flat |
| **Defeat continue** | Optional; **1 ad + 1 paid** per encounter; revive **30%** max HP; never required |
| **Campaign heroes** | Guaranteed clear milestones (never gacha / never paywalled) |
| **Fight length** | Trash **3–5** player turns; act boss **6–10**; finale **10–15**; weekend weekly **8–14** (avg prep) |
| **Weekly toughness** | Weekly enemies ≥ **2×** campaign art-counterpart HP and skill damage |
| **Gems** | Lives refill + capped prep bundles (+ future boxes) + cosmetics; **no gem combat stats** |
| **Coins** | Prep shop + light hero upgrade stubs |
| **Upgrade ceiling** | Up to **~30%** total combat power from max coin upgrades |

---

## 1. Combat core

### 1.1 Match → resources / AP

Authoritative config: `lib/features/puzzle/domain/match_balance.dart` → `MatchBalanceConfig`.

| Knob | Default | Meaning |
|------|---------|---------|
| `resourcePerTile` | 1 | Resource units per matched tile of that color |
| `tilesPerAp` | 3 | AP = `max(minApPerMatch, tilesCleared ~/ tilesPerAp)` before bonuses |
| `minApPerMatch` | 1 | Non-empty match grants at least this AP |
| `maxApPerWave` | 99 | Cap AP from one resolve wave |
| `apPerRocket` | 1 | Bonus AP when a rocket is created |
| `apPerBomb` | 2 | Bonus AP when a bomb is created |
| `apPerFireball` | 3 | Bonus AP when a fireball is created |
| `apPerSeeker` | 2 | Bonus AP when a seeker is created |

Tile → resource map (unchanged from GAMEPLAY):

| Tile | Resource |
|------|----------|
| Red | Attack |
| Blue | Mana |
| Green | Healing |
| Yellow | Shield |
| Purple | Ultimate |

Matching never deals direct damage.

### 1.2 Hero baselines

Source: `lib/features/heroes/domain/hero_def.dart`.

| Hero | Moves | Max AP | Max HP | Primary skill (AP / cost → dmg) | Secondary |
|------|-------|--------|--------|----------------------------------|-----------|
| Mage | 5 | 8 | 80 | Fireball 2 AP / 4 mana + 3 healing → 24 | Arcane Bolt 1 / 2 ult + 2 healing → 12 |
| Knight | 4 | 6 | 120 | Basic Slash 1 / 2 attack + 2 shield → 14 | Shield Wall 2 / 4 shield + 3 attack → +20 shield |
| Ranger | 5 | 7 | 90 | Arrow Shot 1 / 3 attack + 2 healing → 16 | Marked Shot 2 / 4 attack + 3 ult → 26 |
| Priest | 4 | 8 | 95 | Smite 1 / 2 mana + 2 attack → 12 | Mend 2 / 4 healing + 3 shield → +22 HP |
| Ninja | 6 | 7 | 85 | Dagger Flurry 1 / 2 attack + 2 ult → 14 | Shadow Strike 2 / 3 ult + 3 mana → 28 |

### 1.3 Enemy baselines

Source: `lib/features/battle/domain/enemy_def.dart`.

Weighted mean damage = `Σ(damage × weight) / Σ(weight)`. Cap philosophy: heaviest skill ≤ ~2× weighted mean; prefer weight tables over pure RNG spikes.

| Enemy | HP | W. mean dmg | Role |
|-------|-----|-------------|------|
| Goblin Scout | 50 | ~7.1 | Early trash |
| Dusk Wolf | 60 | ~10.0 | Early trash |
| Bog Shaman | 60 | ~10.9 | Early trash |
| Mire Spawn | 60 | ~8.1 | Ch2 trash |
| Ridge Hawk | 60 | ~9.1 | Ch3 trash |
| Stone Brute | 65 | ~13.2 | Early heavy trash |
| Crypt Skeleton | 70 | ~10.7 | Mid trash |
| Forge Imp | 70 | ~10.8 | Late trash |
| Warchief Ruk | 140 | ~16.4 | Ch1 boss |
| Mirelord | 160 | ~16.8 | Ch2 boss |
| Pack Alpha | 175 | ~18.6 | Ch3 boss |
| Quarry Overseer | 190 | ~19.2 | Ch4 boss |
| Bone Seer | 180 | ~21.1 | Ch5 boss (mid spine) |
| Lake Wraith | 200 | ~21.0 | Ch6 boss |
| Gilded Fence | 210 | ~22.7 | Ch7 boss |
| Siege Captain | 220 | ~23.2 | Ch8 boss |
| Ember Smith | 240 | ~25.2 | Ch9 boss |
| Mythspire Tyrant | 260 | ~27.7 | Ch10 finale |

Weekly enemies are listed in §3.4 (derived from counterparts × 2).

### 1.4 Boss pipeline

| Rule | Value |
|------|-------|
| Forms 1–3 | HP → 0 → victory with **flee** (`bossFled`), not death copy |
| Form 4 / trash | Normal death victory |
| Enrage threshold | Default **8** player turns (`enrageAfterTurns` in level JSON) |
| Enrage damage | **1.5×** enemy skill damage (`BossCombatBalance.enrageDamageMultiplier`) |

Enrage is a soft timer pushing fights into target turn bands without unfair boards.

---

## 2. Turn-length tuning model

### 2.1 Assumptions (“normal play”, avg prep)

| Assumption | Value |
|------------|-------|
| Reference hero | Mage |
| Effective damage / player turn | **~12** early (buildup); **~15** mid with avg prep / better cascades |
| Trash prep | **0** expected — optional cushion only |
| Avg prep on bosses | +1 Move (Vanguard) and/or +15 shield (Aegis) |
| Act 3+ bosses | Assume Tonic + Aegis equipped unless upgrades are near max |
| Weekend weekly | Assume Tonic + Aegis; enemy stats already 2× counterpart |

Worksheet formula:

```text
expectedTurns ≈ enemyHp / effectiveDpsPerTurn
```

Targets:

| Encounter | Player turns |
|-----------|--------------|
| Trash | 3–5 |
| Act boss (forms 1–3) | 6–10 |
| Chapter finale (form 4) | 10–15 |

### 2.2 Representative tuning chapters

| Chapter | Role |
|---------|------|
| Ch1 Twilight Road | Onboarding; light prep pressure |
| Ch5 Candlecrypt | Mid spine; first strong “prep recommended” |
| Ch9–10 Eclipse / Mythspire | Required prep unless upgrades maxed |

Node overrides: `coinReward`, `enrageAfterTurns`, optional future `hpScale` / `minMoves`.

### 2.3 Pass-1 audit notes (2026-07-27)

Using ~12 DPS trash / ~15 DPS boss+prep:

- Goblin 50 → ~4.2 turns (OK).
- Early trash outliers (wolf/shaman/brute) lowered into 3–5 band.
- Mid trash (crypt/forge) lowered into ~5–6 with path to 3–5 as player skill rises.
- Bosses: Bone Seer / late finale HP trimmed so enrage@8 remains a backstop, not the expected clear.

---

## 3. Prep & friction

Config: `lib/features/prep/domain/prep_item.dart`.

Prep is offered on a **pre-fight loadout sheet before every battle** (campaign trash, bosses, weekly). Empty selection is always valid (“Play with none”). Do **not** raise trash HP to force prep spend.

| Knob | Value |
|------|-------|
| Max equipped | 3 |
| Vanguard | +1 Move this battle |
| Aegis | +15 starting shield |
| Second Wind | Once/day revive to **30%** max HP |
| Default min moves | 2 (after boss debuffs) |

### 3.1 Drop economy (v1.1 targets)

| Source | Drop |
|--------|------|
| Non-boss clear | **+1 Vanguard Tonic** (always, stub) |
| Act 2+ non-boss | **25%** chance +1 Aegis Flask (in addition) |
| Act 3+ non-boss | **8%** chance +1 Second Wind (in addition) |
| Boss / weekly clear | No prep drop (coins only) |

Act index is 0-based within the chapter (`actIndex` 0 = Act I).

**Sink note:** With prep offered every fight, assume ~25–40% of starts equip ≥1 item. If inventory floods mid-campaign, lower the always-Vanguard grant (e.g. to a chance) before raising shop prices.

### 3.2 Expected loadout

| Band | Expected prep |
|------|----------------|
| Campaign trash | **0** (optional 1 for comfort) |
| Ch1–2 bosses | Optional; comfort |
| Ch3–4 bosses | Strongly recommended |
| Act 3+ bosses / finales | **Tonic + Aegis** minimum for on-level heroes |
| Weekly weekday | Optional; helps vs 2× scout pressure |
| Weekly weekend | **Tonic + Aegis** recommended |

Over-leveling or max upgrades can still skip prep — intentional soft gate, not a hard lock.

### 3.3 Second Wind vs lives

- Second Wind prevents an immediate defeat mid-battle.
- If the hero dies again later in the **same attempt**, that defeat **still spends a life**.
- Second Wind does **not** refund a life.
- Must remain **once/day** (never uncapped paid revive stock).

### 3.4 Weekly (M7)

Config: `lib/features/weekly/domain/weekly_schedule.dart` → `WeeklyBalance`.

| Knob | Value |
|------|-------|
| Enemy HP / damage | **2.0×** art-counterpart (`enemyStatMultiplier`) |
| Weekday objectives | Survive **7** turns **or** clear **60** tiles |
| Weekday enemy | `weekly_scout` ← Goblin Scout × 2 |
| Weekend | One of five `weekly_boss_*`; HP fight; enrage after **8** turns |
| Weekend fight length | **8–14** player turns with avg prep |
| Coin reward | Weekday **40** / weekend **80** (stub) |
| Lives | Fail spends 1 campaign life |
| Prep | Offered every weekly start |

#### Weekly roster (base = counterpart, battle applies ×2)

| Weekly id | Counterpart | Base HP | Battle HP (×2) |
|-----------|-------------|---------|----------------|
| `weekly_boss_01` | Warchief Ruk | 140 | 280 |
| `weekly_boss_02` | Mirelord | 160 | 320 |
| `weekly_boss_03` | Pack Alpha | 175 | 350 |
| `weekly_boss_04` | Gilded Fence | 210 | 420 |
| `weekly_boss_05` | Mythspire Tyrant | 260 | 520 |
| `weekly_scout` | Goblin Scout | 50 | 100 |

Skill damage uses the same **2.0×** multiplier on counterpart skill tables.

### 3.5 Monetization path (prep inventory)

Allowed later (not priced until IAP): coin/gem **prep packs**, loot **boxes** that grant Vanguard/Aegis/Second Wind. Battle-pass prep track stays **off** until retention is validated. All refill inventory only — never raw combat power. Server must validate grants (Firebase phase).

### 3.6 Defeat continue (optional resurrection)

Config: `lib/features/profile/domain/economy_balance.dart` → `DefeatContinueBalance`.

Optional on the defeat result screen. Does **not** replace lives or Second Wind. Free Retry (subject to lives) remains. Continue is never mandatory.

| Knob | Value |
|------|-------|
| Rewarded-ad continues / encounter | **1** |
| Paid continues / encounter | **1** |
| Max continues / encounter | **2** |
| Paid continue cost | **500 coins** |
| Revive strength | **30%** max HP (same as Second Wind) |

Encounter token (`activeEncounterId`) persists across Retry/Continue for that node until victory or the player leaves the result screen. Caps do not reset on Retry.

- Ad continue is a QA/dev stub until an ads SDK ships; prod hides the ad button and leaves the paid slot.
- Continue arms a one-shot revive for the next attempt of the same encounter; it does **not** consume the daily Second Wind prep stock.
- Failed attempts still spend a life when the result is applied (existing lives rule). Continue does not refund that life.

Starter pack (local QA claim until IAP):

| Knob | Value |
|------|-------|
| Id | `starter_pack_001` |
| Coins | **400** |
| Gems | **40** |
| Cosmetic | `overlay_dusk_sash` (visual only) |
| Repeat | One-time entitlement |

---

## 4. Lives & gem refills

Config: `lib/features/profile/domain/economy_balance.dart` → `EconomyBalance`.

Lives are the only stamina / “energy” gate. They mainly slow repeated farming; they should not frequently interrupt first-time campaign progress. Practice / selected activities may stay life-free later. Failed attempts consume **1** life (not a second energy tax). Regeneration stays generous.

| Knob | Value |
|------|-------|
| Starting / max lives | 5 |
| Regen | +1 life every **20 minutes** while below max |
| Defeat | −1 life (clamp 0) |
| Start gate | Cannot start a campaign node or weekly at **0 lives** |
| Gem partial refill | **75 gems** → **+3 lives** (clamp max) |
| Daily gem refill cap | **3** purchases per `yyyy-MM-dd` |
| Full gem refill | Not in V1.0 |
| Level-up refill | Grant lives to max when player XP/levels exist (not yet) |
| Optional ad refill | Phase 3; counts toward a **3–5/day** rewarded-ad pool |

Persist: `lastLifeRegenAt`, `gemLifeRefillDay`, `gemLifeRefillCount` on mock profile (later Firestore `users`).

### 4.1 Monetization never-buy list

Gems / IAP must **not** purchase:

- Combat stat power (damage, HP, AP, Moves beyond capped prep)
- Uncapped revives / uncapped Second Wind stock
- Extra battle Moves as a paid product
- Premium-only combat mechanics
- Mandatory paid continues
- Guaranteed win / skip boss
- Campaign heroes or hero duplicates required for viability
- Client-trusted reward amounts (server validates in Firebase phase)

Allowed gem / IAP sinks: capped life refills, capped prep bundles/boxes, cosmetics, one-time starter pack, later 30-day value pack. Battle pass stays disabled until Phase 4.

---

## 5. Coins & upgrades

### 5.1 Coin income (level JSON)

| Band | Trash `coinReward` | Boss `coinReward` |
|------|--------------------|-------------------|
| Ch1 | ~30–58 | ~70–100 |
| Mid (Ch5) | ~45–75 | ~95–130 |
| Late (Ch9–10) | ~57–96 | ~115–150 |

Expected campaign pace band: roughly **400–700 coins/hour** of active play (subject to playtest).

### 5.2 Prep shop (coin sinks — stub prices)

| Item | Coin price | Notes |
|------|------------|-------|
| Vanguard Tonic | 40 | Common |
| Aegis Flask | 60 | Uncommon |
| Second Wind | 150 | Rare; still once/day use |

### 5.3 Upgrade stubs (~30% ceiling)

| Stat line | Per tier | Max tiers | Max bonus |
|-----------|----------|-----------|-----------|
| HP | +5% | 6 | +30% |
| Skill damage | +5% | 6 | +30% |
| Skill shield | +5% | 6 | +30% |

| Tier | Coin cost (cumulative sink) |
|------|------------------------------|
| 1 | 100 |
| 2 | 150 |
| 3 | 225 |
| 4 | 325 |
| 5 | 450 |
| 6 | 600 |

Applied once when building `BattleState.initial` (scaled `HeroDef`), not in widgets. Profile field: `upgradeLevelsByHero` map (`heroId` → `{hp,damage,shield}` → 0–6). Legacy account-global `upgradeLevels` migrate onto every currently unlocked hero; newly unlocked heroes start at 0.

**Dynamic difficulty:** Stages do **not** scale by equipped hero power. Mage remains the on-level reference. Stronger personalities are intended power fantasy on easier nodes — do not auto-buff enemies 10–15% for upgraded heroes.

---

## 6. Config delivery

| Phase | Delivery |
|-------|----------|
| Now | Dart `MatchBalanceConfig`, `PrepBalance`, `EconomyBalance`, `BossCombatBalance`, `WeeklyBalance` |
| Later | `assets/balance/remote_balance.json` or Firestore `remote_balance` |

Future remote document shape:

```json
{
  "id": "remote_balance_v1",
  "schemaVersion": 1,
  "contentVersion": 1,
  "isEnabled": true,
  "match": { "tilesPerAp": 3, "resourcePerTile": 1 },
  "economy": {
    "maxLives": 5,
    "lifeRegenMinutes": 20,
    "gemLifeRefillCost": 75,
    "gemLifeRefillAmount": 3,
    "gemLifeRefillsPerDay": 3,
    "defeatContinueCoinCost": 500,
    "defeatContinueAdPerEncounter": 1,
    "defeatContinuePaidPerEncounter": 1,
    "starterPackEnabled": true,
    "battlePassEnabled": false
  },
  "upgrades": { "pctPerTier": 0.05, "maxTiers": 6 },
  "createdAt": "...",
  "updatedAt": "..."
}
```

---

## 7. Playtest checklist

1. Trash clears in 3–5 player turns for on-level hero **with 0 prep**.
2. Act bosses clear in 6–10 turns before or near enrage with recommended prep.
3. Finales 10–15 turns with prep; enrage is a backstop.
4. Act 3+ boss defeat rate with **0 prep** is clearly higher than with Tonic+Aegis.
5. Prep sheet appears on trash and weekly; empty loadout can always start.
6. Weekend weekly feels clearly harder than its campaign counterpart (~2× HP/damage).
7. F2P can recover lives via regen without obligatory gem spend; gem refill stays under 3/day.
8. Max **per-hero** personality upgrades feel helpful (~30%) but do not delete prep pressure entirely; switching heroes does not carry the same tiers.
9. Prep inventory neither floods uselessly nor forces gem buys by mid-Ch2.
10. Defeat continue is skippable; fair content is clearable without it. Caps stay 1 ad + 1 paid per encounter.
11. Starter pack and cosmetics never grant combat stats.

Record material formula changes in [Decisions](../00_Project/Decisions.md).
