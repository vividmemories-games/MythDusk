# Animations

| Field | Value |
|-------|-------|
| **Status** | Active (P0.7 battle juice) |
| **Last Updated** | 2026-07-31 |
| **Code** | `BattleController` durations · `AnimatedPuzzleBoard` · `BattleStage` |
| **Related** | [Theme](Theme.md) · `.cursor/rules/06-ui-ux-polish.mdc` |

## Temperament

- Satisfying but **short** — battle stays readable
- Cascade motion leads; HUD motion stays minimal
- Prefer ease-out curves; avoid elastic bounce on core HUD
- Character idle/attack sheets deferred to **AB2** (chibi stage sprites are still PNGs in AB1)
- Sell rule changes (wind shove, hazard spawn) with motion, not only log lines

## Phase 1 duration roles

| Role | Duration | Code constant / note |
|------|----------|----------------------|
| Swap settle | ~100ms | Brief pause after swap before clear |
| Match destroy | 240ms | `BattleController.clearDuration` |
| Gravity fall | 280ms | `fallDuration` |
| Spawn drop-in | 300ms | `spawnDuration` |
| Combat FX (hit flash/shake) | 360ms | `combatFxDuration` |
| Skill cast cue | 400ms | `castFxDuration` (lunge + gold flash) |
| Wind shove / lane gust | 520ms | `windFxDuration` |
| Hazard spawn pulse | 380ms | `hazardFxDuration` |
| Enemy telegraph | 480ms | `enemyTelegraph` (threat badge pulse) |
| Selection chrome | 120ms | Tile border `AnimatedContainer` |

## Combat juice cues (`CombatFx`)

| Flag | Presentation |
|------|----------------|
| `heroCast` | Gold tint, cast puff, short lunge toward enemy |
| `enemyHit` | Hit FX overlay + flash/shake on enemy |
| `heroHit` | Hit FX + shake on hero |
| `wind` | Lane streak, gust wash, tile nudge, HUD **Wind!** |
| `hazard` | Overlay pulse on spawned cells, HUD **Hazard!** |

## Reduced motion

When `MediaQuery.disableAnimationsOf(context)` is true:

- Skip multi-step cascade delays where safe; snap to final board
- Skip wind nudge / cast lunge / telegraph scale
- Prefer fade over shake
- Keep state changes comprehensible without motion

## Out of scope for now

Hero/enemy sprite animation sheets, particle VFX libraries, ceremonial victory sequences — polish after art pass (AB2).
