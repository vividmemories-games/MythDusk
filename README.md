# MythDusk

Turn-based **puzzle RPG** for iOS & Android.

Match tiles to generate **resources**, spend **AP** on hero skills, survive enemy turns.

## Docs

Start at [docs/README.md](docs/README.md).

| Doc | Role |
|-----|------|
| [docs/GAMEPLAY.md](docs/GAMEPLAY.md) | Combat / puzzle authority |
| [docs/PHASES.md](docs/PHASES.md) | Phase plan + locked product table |
| [docs/00_Project/Vision.md](docs/00_Project/Vision.md) | Product intent |
| [docs/00_Project/Decisions.md](docs/00_Project/Decisions.md) | Living decisions log |

Validate doc links:

```bash
dart run tool/check_docs.dart
```

## Stack

Flutter · Riverpod · go_router · (Firebase in a later phase)

## Run

```bash
flutter pub get
flutter run
# or: fvm flutter run
```

## Phase 1 focus

Home → **Twilight Road** (5 nodes) → battle with cascades + rockets/bombs → victory rewards → unlock next. Local persisted profile.


Agent rules: `AGENTS.md` and `.cursor/rules/` (product name **MythDusk**; former working titles Mythora / Relicbound).
