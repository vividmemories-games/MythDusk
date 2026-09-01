# MythDusk Documentation

**Source of truth** for product intent, combat rules, balance stubs, design language, and engineering contracts.

Adapted from Labyrinth Legends’ documentation discipline — **not** its maze content.

## Authority (conflict resolution)

When documents disagree, the **higher document wins**:

```text
Vision
  → GAMEPLAY.md (combat / puzzle rules)
  → Balancing Bible (numbers — Phase 2)
  → Economy / Progression / Heroes / Enemies
  → Design System (Theme, Animations)
  → Asset Bible (when art production starts)
  → Technical (Architecture, Coding Standards)
  → Implementation
```

Lower docs may **extend** higher ones; they must not redefine them. Record exceptions in [00_Project/Decisions.md](00_Project/Decisions.md).

## Quick start

| I need to… | Read |
|------------|------|
| Understand the game | [Vision](00_Project/Vision.md), [GAMEPLAY](GAMEPLAY.md) |
| See phase plan | [PHASES](PHASES.md) |
| Check a locked choice | [Decisions](00_Project/Decisions.md) |
| Balance / content (Phase 2) | [Balancing Bible](01_Game_Design/Balancing_Bible.md) |
| Economy / monetization | [Economy](01_Game_Design/Economy.md), [Monetization](01_Game_Design/Monetization.md), [Progression](01_Game_Design/Progression.md) |
| Heroes / enemies | [Heroes](01_Game_Design/Heroes.md), [Enemies](01_Game_Design/Enemies.md) |
| Campaign / 200-level plan | [Content Architecture](01_Game_Design/Content_Architecture.md) |
| Colors / motion | [Theme](02_Design_System/Theme.md), [Animations](02_Design_System/Animations.md) |
| Write code | [Coding Standards](04_Technical/Coding_Standards.md), [Architecture](04_Technical/Architecture.md) |
| Firebase / Auth / PvP | [Firebase](04_Technical/Firebase.md), [Firestore Schema](04_Technical/Firestore_Schema.md), [Console checklist](00_Project/Firebase_Console_Checklist.md) |
| Produce art | [Asset Bible](06_Asset_Bible/README.md), [AB1 Standards](06_Asset_Bible/AB1_Production_Standards.md), [Leonardo Prompt Pack](06_Asset_Bible/AB1_Leonardo_Prompt_Pack.md), [Master Prompts](06_Asset_Bible/Master_Prompts.md) |

## Structure

```text
docs/
├── README.md                 # this file
├── GAMEPLAY.md               # combat authority
├── PHASES.md                 # phase plan + locked product table
├── 00_Project/               # Vision, Decisions
├── 01_Game_Design/           # balance, economy, heroes, enemies, content architecture
├── 02_Design_System/         # dusk theme + motion
├── 04_Technical/             # architecture, coding standards, Firebase
└── 06_Asset_Bible/           # AB1 + Master Prompts
    ├── README.md
    ├── AB1_Production_Standards.md
    ├── AB1_Leonardo_Prompt_Pack.md
    └── Master_Prompts.md
```

## Document standards

Prefer short docs with:

- Purpose / scope
- Status (`Draft` / `Active` / `Phase 2 stub`)
- Links to authority docs
- Tables over prose where possible

Avoid duplicating GAMEPLAY rules in every file — link instead.

## Validate docs

```bash
dart run tool/check_docs.dart
```

Checks relative markdown links and a few code/doc consistency assertions.

## What we did **not** copy from Labyrinth Legends

Maze path rules, level JSON schema, LLDL stone-citadel language, GP workshop series, and the large `99_Reviews` archive. Steal process; rewrite content for MythDusk.
