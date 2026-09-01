# MythDusk — Gameplay Design (v0.1)

| Field | Value |
|-------|-------|
| **Status** | Active — combat authority |
| **Last Updated** | 2026-07-10 |
| **Related** | [Vision](00_Project/Vision.md) · [PHASES](PHASES.md) · [Decisions](00_Project/Decisions.md) · [Heroes](01_Game_Design/Heroes.md) · [Enemies](01_Game_Design/Enemies.md) · [Balancing Bible](01_Game_Design/Balancing_Bible.md) |

Product name: **MythDusk**  
Source design: `MythDusk_Gameplay_Design_v0.1.md` (formerly Mythora / Relicbound)

## Genre

- Turn-based puzzle RPG
- Hero collection
- PvE adventure
- Live-service capable (phased)

## Core philosophy

The puzzle board **does not deal direct damage**.

The board generates **resources** that power hero skills. Combat revolves around:

- Limited **Moves**
- Resource management
- **Action Points (AP)**
- Hero skills
- (Later) team composition

Every turn should be a tactical decision, not “match the biggest combo.”

---

## Battle loop

```text
Battle Starts
      │
      ▼
Player Turn Begins
      │
      ▼
Moves Refreshed
      │
      ▼
Solve Puzzle Board
      │
      ▼
Generate Resources
      │
      ▼
Earn AP
      │
      ▼
Use Hero Skills
      │
      ▼
Moves Reach Zero
      │
      ▼
Enemy Turn
      │
      ▼
Status Effects Resolve
      │
      ▼
Next Player Turn
```

---

## Moves

- Every tile swap consumes **1 Move**
- Moves refresh at the start of every turn
- Moves **cannot** be carried over
- Effective moves per turn (locked 2026-07-20):

```text
movesThisTurn = hero.movesPerTurn + prep + levelModifiers − bossDebuffs
```

- Default **minimum = 2**; **nightmare bosses** may allow **minimum = 1**
- Meta prep example: Vanguard Tonic → **+1 Move** for that battle (see [Content Architecture](01_Game_Design/Content_Architecture.md))

Placeholder per-hero moves (Phase 1 stubs):

| Hero   | Moves |
|--------|------:|
| Knight | 4     |
| Mage   | 5     |
| Rogue  | 6     |
| Priest | 5     |

---

## Puzzle board

### Phase 1 board size

- First levels: **6×6 square**
- Later: asymmetric / irregular masks, disconnected regions, moving parts (Royal Match–style)

### Board complexity rollout (locked 2026-07-20)

| Mechanic | Start |
|----------|-------|
| Masked / blocked cells, layered obstacles | Mid-campaign (Ch2+) via templates |
| Moving parts (row/col shove, sliding segments) | **Chapter 3 — Howling Ridge** |

Do not unique-author geometry per level — use `maskId` / `obstacleLayout` / `moverId` in level JSON.

### Tile → resource mapping

| Tile   | Generates         |
|--------|-------------------|
| Red    | Attack Energy     |
| Blue   | Mana              |
| Green  | Healing           |
| Yellow | Shield            |
| Purple | Ultimate Energy   |

Matching tiles **never** deals damage directly. Matches fill resource meters.

Example: Match 4 Red → `+4 Attack Energy`

---

## Resources

Resources persist for the whole battle. Heroes specialize:

| Hero   | Primary resources |
|--------|-------------------|
| Knight | Red + Yellow      |
| Mage   | Blue + Purple     |
| Priest | Green + Blue      |
| Rogue  | Red + Purple      |

---

## Action Points (AP)

- Earned during battle (not refreshed each turn)
- Accumulates until spent
- Each hero has a max AP capacity

Placeholder generation (open for balancing):

- Every match = +1 AP
- 4-match = +2 AP
- Cascades may award bonus AP

---

## Hero skills

Every skill costs **both resources and AP**. Skills use **dual** (or triple) resource costs — never a single mono color in the live catalog.

Examples (source: `lib/features/heroes/domain/hero_def.dart`):

| Skill | Cost |
|-------|------|
| Fireball | 4 Mana + 3 Healing + 2 AP |
| Arcane Bolt | 2 Ultimate + 2 Healing + 1 AP |
| Basic Slash | 2 Attack + 2 Shield + 1 AP |
| Shield Wall | 4 Shield + 3 Attack + 2 AP |
| Marked Shot | 4 Attack + 3 Ultimate + 2 AP |
| Mend | 4 Healing + 3 Shield + 2 AP |

---

## Example turn

```text
Start Turn — Moves = 5, AP = 2
Match Red  — Moves = 4, Attack Energy +3, AP +1
Match Blue — Moves = 3, Mana +4, AP +1
Cast Fireball — spend 4 Mana + 3 Healing + 2 AP
… until Moves = 0
Enemy Turn
```

---

## Enemy turn

Enemies may attack, buff, debuff, summon, apply status, or trigger boss mechanics.

Phase 1 stub: weighted skill table (see [Enemies](01_Game_Design/Enemies.md)). Numbers are placeholders for the Balancing Bible.

---

## Hero identity (Phase 1: single hero in battle)

| Hero   | Moves | Max AP | Role            |
|--------|------:|-------:|-----------------|
| Knight | 4     | 6      | Tank            |
| Mage   | 5     | 8      | Spell damage    |
| Rogue  | 6     | 4      | Fast damage     |
| Priest | 5     | 6      | Support / heal  |

**Locked:** battle uses **1 hero** for now. Parties / teams = Phase 3–4.

---

## Equipment

Equipment changes **rules**, not only raw stats.

Examples:

- Swift Boots → +1 Move
- Ruby Ring → +25% Attack Energy from Red matches
- Wizard Staff → Blue matches generate double Mana
- Lucky Charm → 15% chance to refund AP cost

---

## Boss mechanics

Bosses change rules / board, not only HP.

Examples:

- Ice Dragon → Lose 1 Move at start of every turn
- Spider Queen → Adds poison tiles
- Stone Golem → Immune until armor broken
- Necromancer → Summons skeletons every 3 turns
- Vampire Lord → Heals for 40% of damage dealt

### Enrage (locked 2026-07-20)

Optional per-level flag: after **8 player turns**, boss **enrages** (higher damage / tougher skill weights). Not an instant lose. Multipliers → Balancing Bible.

### Campaign win / lose (locked 2026-07-20)

- Default: **HP** — hero ≤ 0 → defeat; enemy ≤ 0 (or boss flee/death at chapter beats) → victory
- **No** global “N chances then lose” in campaign
- Weekly / special nodes may use survive-N-turns or clear-N-tiles objectives

---

## Match-3 mechanics to adopt (Royal Match–inspired)

Copy **mechanics**, not the full live-ops event calendar.

### Shape catalog → power-ups

| Formation | Power-up |
|-----------|----------|
| Line H/V of 3 | None (clear only) |
| Line **H of 4** | **Vertical rocket** (clears column) |
| Line **V of 4** | **Horizontal rocket** (clears row) |
| Line H/V of **5** | **Fireball** |
| **2×2 square** | **Bomb** (3×3) |
| Mix of five **T / plus** | **Bomb** |
| Mix of five **L** | **Seeker** (8 random tiles) |

New specials appear on the **swap destination**. Power-ups are **not color-matched** — activate by **tap** or by **swapping with any adjacent tile**. Special↔special swaps **merge** (see Decisions / engine).

**Fireball:** tap → clear a random color on the board; swap with a normal tile → clear that tile’s color. Power-ups among the cleared tiles **chain**.

**Bomb + V/H rocket:** both merges clear the same fat cross (3 full rows + 3 full columns centered on the merge).

- Cascades + gravity
- Later: more obstacles, irregular boards
- Layered / special obstacles with clear rules

**Defer:** weekly tournaments, streak gift ladders, renovation meta, seasonal event sprawl.

**MVP retention:** campaign + daily dungeon only.

---

## Design principles

1. Puzzle generates resources, not damage.
2. Moves are the player's turn budget.
3. Resources + AP power abilities.
4. Heroes feel unique through mechanics, not just stats.
5. Bosses change gameplay rules.
6. Systems create replayability; art stays manageable for a solo developer.

## Open design question

AP generation formula is intentionally soft until playtesting. Architecture above is fixed.
