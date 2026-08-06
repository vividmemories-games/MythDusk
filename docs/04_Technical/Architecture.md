# Architecture

| Field | Value |
|-------|-------|
| **Status** | Active |
| **Last Updated** | 2026-08-05 |
| **Related** | [Coding Standards](Coding_Standards.md) · [PHASES](../PHASES.md) · [GAMEPLAY](../GAMEPLAY.md) |

## Stack

Flutter · Riverpod · go_router · (Firebase later)

## Layering

```text
features/*/presentation  → widgets, screens
features/*/providers     → Riverpod notifiers
features/*/domain        → pure Dart rules & models (preferred for engines)
core/                    → theme, router, env
services/                → Firebase / ads / IAP later
```

Higher layers depend on lower layers — never the reverse for **rules**.

| Layer | May | Must not |
|-------|-----|----------|
| `puzzle/domain`, battle domain helpers | Dart SDK | Flutter widgets, `BuildContext` |
| providers | domain + Riverpod | Embed match rules in widgets |
| presentation | providers, theme | Re-implement cascade / damage formulas |

## Data flow

```text
Input → provider/notifier → domain controller/engine → immutable state → UI
```

## Typed enemy effects

Enemy skill side effects use the sealed `EnemyEffect` hierarchy. The JSON
wire discriminator remains stable for future remote content, while parsing
rejects unknown types, resources, overlays, and invalid amounts.

| Wire type | Dart type | Required data |
|-----------|-----------|---------------|
| `modify_moves` | `ModifyMovesEffect` | Negative `amount` |
| `drain_resource` | `DrainResourceEffect` | Known `resourceId`, positive `amount` |
| `apply_overlay` | `ApplyOverlayEffect` | Supported `overlayId`, positive `count` |

Base enemy damage belongs only to `EnemySkill.damage`; `damage` is not an
effect type. Resolution uses an exhaustive sealed-type switch, so newly added
effect subclasses must be handled explicitly.

## Feature map (Phase 1)

| Feature | Role |
|---------|------|
| `puzzle` | Match-3 board, gravity, cascade |
| `battle` | Combat loop, skills, enemy turn, board UI |
| `heroes` | Hero / skill defs |
| `profile` | Mock coins, selected hero |
| `campaign` / `daily` / `equipment` | Stubs / placeholders |

## Routes

| Path | Screen |
|------|--------|
| `/` | Home |
| `/campaign` | Twilight Road map |
| `/battle/:nodeId` | Battle |
| `/result` | Victory / defeat |

## Firebase (later)

Own Mythora project — do not reuse Dot Clash or Labyrinth Firebase. Auth, Firestore content, Cloud Functions settlement per agent Firebase safety rules.
