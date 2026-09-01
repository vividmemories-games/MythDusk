# Heroes

| Field | Value |
|-------|-------|
| **Status** | Phase 1 stubs |
| **Last Updated** | 2026-07-10 |
| **Authority** | Identity & roster notes; numbers → [Balancing Bible](Balancing_Bible.md) |
| **Code** | `lib/features/heroes/domain/hero_def.dart` |
| **Related** | [GAMEPLAY](../GAMEPLAY.md) |

## Rules (from GAMEPLAY)

- Skills cost **resources + AP**
- Phase 1: **1 hero** in battle
- Primary resources define fantasy, not exclusive access

## Design roster (GAMEPLAY)

| Hero | Moves | Max AP | Role | Primary resources |
|------|------:|-------:|------|-------------------|
| Knight | 4 | 6 | Tank | attack, shield |
| Mage | 5 | 8 | Spell damage | mana, ultimate |
| Rogue | 6 | 4 | Fast damage | attack, ultimate |
| Priest | 5 | 6 | Support / heal | healing, mana |

## Implemented in code (Phase 1)

Skills use **dual/triple resource costs** (off-color secondary softened vs equal 4+4 where noted).

| Id | Name | Moves | Max AP | Max HP | Skills (highlights) |
|----|------|------:|-------:|-------:|---------------------|
| `mage` | Mage | 5 | 8 | 80 | Fireball (4 mana + 3 healing + 2 AP → 24 dmg), Arcane Bolt (2 ult + 2 healing + 1 AP → 12) |
| `knight` | Knight | 4 | 6 | 120 | Basic Slash (2 attack + 2 shield + 1 AP → 14), Shield Wall (4 shield + 3 attack + 2 AP → +20 shield) |
| `ranger` | Ranger | 5 | 7 | 90 | Arrow Shot (3 attack + 2 healing + 1 AP → 16), Marked Shot (4 attack + 3 ult + 2 AP → 26) |
| `priest` | Priest | 4 | 8 | 95 | Smite (2 mana + 2 attack + 1 AP → 12), Mend (4 healing + 3 shield + 2 AP → +22 HP) |
| `ninja` | Ninja | 6 | 7 | 85 | Dagger Flurry (2 attack + 2 ult + 1 AP → 14), Shadow Strike (3 ult + 3 mana + 2 AP → 28) |

Source of truth: `lib/features/heroes/domain/hero_def.dart`.

## Content pipeline note

Prefer stable string IDs (`mage`, `fireball`). Later: JSON / Firestore editors per [PHASES](../PHASES.md) Phase 2.
