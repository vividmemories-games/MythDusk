# AGENTS.md

# MythDusk AI Agent Instructions

This file is the source of truth for AI coding agents working on **MythDusk**, a Flutter + Firebase turn-based Puzzle RPG.

Agents must treat these instructions as binding unless the human project owner explicitly overrides them.

---

## 1. Project Summary

**Product name:** MythDusk  
**Former working titles:** Mythora, Relicbound  
**Genre:** Turn-based Puzzle RPG  
**Platform:** iOS and Android  
**Frontend:** Flutter  
**Backend:** Firebase  
**Development style:** Solo-developer friendly, data-driven, system-heavy, low-art-dependency.

MythDusk is designed around a combat loop where the puzzle board generates tactical resources instead of dealing direct damage.

The game should scale through:
- Heroes
- Skills
- Equipment
- Enemies
- Boss mechanics
- Campaign nodes
- Daily challenges
- Weekly events
- Balance configs

The game must **not** depend on expensive handcrafted maps, cinematic environments, or large art pipelines.

---

## 2. Non-Negotiable Product Principles

1. **Systems over art**
   - Prefer reusable UI, reusable battle screens, data-driven configs, procedural variation, and scalable mechanics.
   - Do not introduce features that require large amounts of bespoke artwork or handcrafted environment design.

2. **Puzzle generates resources, not damage**
   - Matching tiles fills resources.
   - Damage, healing, shields, buffs, and debuffs are caused by hero skills or enemy actions.

3. **Moves limit puzzle actions**
   - Every tile swap consumes one Move.
   - Moves refresh each player turn.
   - Moves do not carry over by default.

4. **AP limits skill usage**
   - AP is earned through successful puzzle play.
   - AP does not fully refresh each turn by default.
   - Skills require both resources and AP.

5. **Firebase content must be data-driven**
   - Heroes, skills, equipment, enemies, bosses, events, quests, economy values, and balance knobs should be configurable remotely where safe.

6. **Production safety first**
   - Never deploy to production, delete user data, reset Firestore, change billing-sensitive backend behavior, or modify security rules without explicit human approval.

7. **Solo-developer maintainability**
   - Prefer small files, readable architecture, simple state models, testable pure logic, and minimal dependency sprawl.

---

## 3. Core Combat Rules

### 3.1 Battle Flow

```text
Battle Starts
      |
      v
Player Turn Begins
      |
      v
Moves Refresh
      |
      v
Player Swaps Tiles
      |
      v
Matches Generate Resources
      |
      v
Matches Generate AP
      |
      v
Player Uses Hero Skills
      |
      v
Moves Reach Zero or Player Ends Turn
      |
      v
Enemy Turn
      |
      v
Status Effects Resolve
      |
      v
Next Player Turn
```

### 3.2 Tile Colors

| Tile | Resource |
|------|----------|
| Red | Attack Energy |
| Blue | Mana |
| Green | Healing Energy |
| Yellow | Shield Energy |
| Purple | Ultimate Energy |

### 3.3 Matching

- Matching tiles does **not** directly damage enemies.
- A valid match generates resources based on tile color and match size.
- A valid match generates AP according to the current AP rules.
- Cascades may generate additional resources and AP if enabled by balance config.

### 3.4 Moves

- Each tile swap costs 1 Move.
- Moves refresh at the start of each player turn.
- Moves do not carry over unless a future mechanic explicitly enables it.
- Hero, equipment, buffs, debuffs, and boss mechanics may modify Moves.

### 3.5 AP

- AP is a combat resource for skill usage.
- AP has a current value and max capacity.
- AP is earned through puzzle play.
- AP persists across turns until spent.
- AP should not be granted freely every turn unless a specific passive/buff says so.

### 3.6 Skills

Every skill should define:
- Resource costs
- AP cost
- Targeting rules
- Cooldown, if any
- Effects
- Status interactions
- Animation cue
- Balance tags

Example:

```json
{
  "id": "skill_fireball_001",
  "name": "Fireball",
  "resourceCosts": { "mana": 8 },
  "apCost": 2,
  "targeting": "single_enemy",
  "effects": [
    { "type": "damage", "scaling": "magic", "base": 24 }
  ]
}
```

---

## 4. Architecture Rules

### 4.1 Recommended Layers

Use clear separation between:

```text
lib/
  app/
  core/
  features/
    battle/
      domain/
      data/
      presentation/
    heroes/
    inventory/
    campaign/
    daily_challenges/
    shop/
    profile/
  shared/
  firebase/
```

### 4.2 Domain First

Core game rules should be pure Dart where possible.

Good:
- `BattleState`
- `BoardState`
- `HeroState`
- `EnemyState`
- `SkillDefinition`
- `MatchResolver`
- `TurnResolver`
- `DamageCalculator`

Avoid:
- Putting combat logic directly inside widgets.
- Calling Firebase inside domain classes.
- Mixing UI animation state with battle rule state.

### 4.3 Pure Logic First

Battle resolution must be testable without Flutter widgets and without Firebase.

A valid battle engine should run in unit tests.

---

## 5. Flutter Rules

1. Prefer simple, readable widgets.
2. Keep screens thin.
3. Keep business logic out of widgets.
4. Use immutable models where practical.
5. Use explicit state transitions.
6. Avoid global mutable state.
7. Avoid animation-first architecture; gameplay correctness comes first.
8. Make UI work on small phones before tablets.
9. Avoid hardcoded dimensions where responsive layout is needed.
10. Keep the battle screen performant at 60 FPS.

If state management is not already chosen, propose options before implementing. Do not introduce a major state management package without approval.

---

## 6. Firebase Rules

### 6.1 Client Must Not Be Trusted

The client may submit player actions and results, but server-side validation must own:

- Reward grants
- Score submissions
- Purchases
- Leaderboard updates
- Economy changes
- Event rewards
- Anti-cheat checks

### 6.2 Firestore Design

Prefer stable, versioned, query-friendly collections.

Suggested top-level collections:

```text
users
heroes
skills
equipment
enemies
bosses
campaigns
daily_challenges
events
leaderboards
matches
battle_runs
inventory
shop_offers
economy_config
remote_balance
```

### 6.3 Data Versioning

All remotely configurable gameplay definitions should include:

```text
schemaVersion
contentVersion
isEnabled
createdAt
updatedAt
```

### 6.4 Security

Never create Firestore rules that allow:
- Unauthenticated writes to gameplay data.
- Client writes to authoritative reward fields.
- Client writes to another user's inventory/profile.
- Public mutation of balance configs.
- Direct client updates to validated leaderboards.

### 6.5 Cost Awareness

Avoid chatty real-time listeners.

Use:
- Firestore for durable state.
- Realtime Database only for presence/live multiplayer if introduced later.
- Cloud Functions for trusted writes.
- Remote Config for lightweight tuning knobs.

---

## 7. Testing Requirements

Minimum expected tests for gameplay changes:

1. Unit tests for pure combat logic.
2. Unit tests for match resolution.
3. Unit tests for resource generation.
4. Unit tests for AP generation.
5. Unit tests for skill costs and execution.
6. Edge-case tests for invalid moves, zero moves, insufficient resources, max AP, death states, and status effects.

Minimum expected tests for Firebase/backend changes:

1. Emulator-based tests where possible.
2. Security rule tests for allowed and denied access.
3. Cloud Function validation tests.
4. Idempotency tests for rewards and purchases.

Do not mark work as complete if core gameplay logic is untested.

---

## 8. Commands

Before running commands, inspect the repository.

Common commands may include:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
firebase emulators:start
firebase deploy --only firestore:rules
firebase deploy --only functions
```

Do not deploy anything without explicit human approval.

---

## 9. Code Style

1. Prefer clarity over cleverness.
2. Keep functions small.
3. Use descriptive names.
4. Avoid magic numbers; use balance/config objects.
5. Use enums/sealed types for gameplay states where appropriate.
6. Add comments only for non-obvious logic.
7. Do not introduce speculative abstractions.
8. Do not rewrite working systems unless requested.

---

## 10. Content Pipeline Philosophy

The game should eventually support an internal admin dashboard for:

- Hero editor
- Skill editor
- Enemy editor
- Boss editor
- Equipment editor
- Campaign editor
- Daily challenge scheduler
- Shop/event manager
- Balance tuning dashboard
- Player support tools

When adding content systems, design them so this admin dashboard can exist later.

---

## 11. Monetization Rules

Monetization must not break game balance.

Allowed monetization directions:
- Cosmetic skins
- Remove ads
- Rewarded revive
- Rewarded bonus chest
- Battle pass / season pass
- Starter bundles
- Convenience boosts with strict limits

Avoid:
- Pay-to-win PvP
- Infinite paid revives
- Manipulative dark patterns
- Reward grants without server validation

---

## 12. AI Agent Workflow

When asked to implement a feature:

1. Inspect existing files first.
2. Summarize relevant architecture.
3. Propose a short implementation plan.
4. Make small, reviewable changes.
5. Add or update tests.
6. Run format/analyze/tests when possible.
7. Summarize what changed and any risks.

When uncertain:
- Prefer asking one concise question.
- If blocked, make the safest minimal assumption and document it.
- Do not invent unavailable APIs or files.

---

## 13. Forbidden Actions Without Explicit Approval

Do not:

- Deploy production Firebase changes.
- Delete or overwrite user data.
- Change billing-sensitive Firebase usage patterns.
- Add a large dependency.
- Change the core combat model.
- Change authentication providers.
- Modify store/IAP behavior.
- Disable App Check/security protections.
- Commit secrets.
- Store API keys in client code beyond platform-required public config.
- Replace architecture wholesale.
- Add real-time PvP unless specifically requested.

---

## 14. Definition of Done

A task is complete only when:

- The implementation matches the design principles.
- Core logic is tested.
- Flutter analysis passes or known issues are documented.
- No production deployment was performed without approval.
- Firebase writes are safe and validated.
- The change remains maintainable for a solo developer.
- The final response includes:
  - What changed
  - Tests run
  - Risks/limitations
  - Suggested next step
