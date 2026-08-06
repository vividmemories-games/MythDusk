# Coding Standards

| Field | Value |
|-------|-------|
| **Status** | Active |
| **Last Updated** | 2026-07-10 |
| **Related** | [Architecture](Architecture.md) · `AGENTS.md` · `.cursor/rules/01-flutter-architecture.mdc` |

Adapted from Labyrinth Legends coding standards — MythDusk feature layout and combat domain.

## Philosophy

1. Solo-dev + AI maintainable
2. Pure Dart for puzzle/combat rules
3. Small, reviewable diffs
4. Tests for engine changes

## Project structure

```text
lib/
  main.dart / app.dart
  core/                 # router, theme
  features/
    puzzle/domain/      # pure match-3
    battle/             # domain + providers + presentation
    heroes/
    profile/
    campaign/ equipment/ daily/   # stubs
  services/ shared/
test/
  puzzle_engine_test.dart
docs/
```

Feature folders prefer `domain/` · `providers/` · `presentation/` (and `data/` when persistence appears).

## Pure Dart engines

- No `package:flutter` in puzzle/battle **domain** rule files
- Deterministic helpers where practical (`Random` injected for tests)
- Unit-test match detection, gravity, cascade, swap validation

## State

- Riverpod for UI/session state
- Immutable `BattleState` / board copies
- Lock input while `BattlePhase.resolving` / enemy turn

## Naming

- Types: `BattleState`, `PuzzleEngine`, `HeroDef`
- Files: `snake_case.dart`
- Stable content IDs: `mage`, `goblin`, `fireball`

## Testing

| Change | Expectation |
|--------|-------------|
| Puzzle engine | Unit tests required |
| Battle formulas | Prefer domain tests |
| UI chrome | Manual / widget tests as needed |

```bash
flutter test
flutter analyze
dart run tool/check_docs.dart
```

## Anti-patterns

- Match damage on the board (violates GAMEPLAY)
- Hardcoding Dot Clash neon tokens
- Inventing Firebase write paths on the client for currency
- Changing combat rules without updating [GAMEPLAY](../GAMEPLAY.md) / [Decisions](../00_Project/Decisions.md)

## Definition of done

- [ ] Behavior matches GAMEPLAY / Decisions
- [ ] Engine tests updated when rules change
- [ ] `flutter analyze` clean for touched areas
- [ ] Docs updated if material
