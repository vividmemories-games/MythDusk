# Architecture

| Field | Value |
|-------|-------|
| **Status** | Active |
| **Last Updated** | 2026-08-06 |
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

## Content resolution and route safety

Runtime catalog lookups are strict: `HeroCatalog.byId`, `EnemyCatalog.byId`,
`CampaignIndex.byId`, `CampaignChapter.nodeById`, and `actById` throw for an
unknown identifier. Presentation code uses the matching nullable `tryById`
methods when it needs to render a player-safe `ContentErrorScreen`.

Persisted profile migration is the one intentional recovery boundary: a saved
hero ID that no longer exists is normalized to the starter Mage while loading
the profile. Shipped campaign cross-references remain enforced by
`tool/validate_content.dart`.

Campaign battles are not constructed until the chapter, overlay catalog, board
template catalog, node, enemy, template, and hazard overlay have all resolved.
This prevents an async load or malformed deep link from silently starting a
Goblin fight on a generic board. Victory settlement revalidates the completed
node before granting its reward.

Debug/dev battle builds expose a QA enemy-skill picker. It feeds a selected
catalog skill through the normal enemy-turn pipeline; it is never displayed in
production builds.

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
| `/chapters` | Chapter selection |
| `/campaign` | Selected chapter act map |
| `/briefing/:nodeId` | Validated pre-battle briefing |
| `/battle/:nodeId` | Battle |
| `/result` | Victory / defeat |

## Firebase (later)

Own MythDusk project — do not reuse Dot Clash or Labyrinth Firebase. Auth, Firestore content, Cloud Functions settlement per agent Firebase safety rules.
