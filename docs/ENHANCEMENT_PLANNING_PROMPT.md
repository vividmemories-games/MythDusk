# MythDusk — Functionality & Usability Planning Brief
You are working on **MythDusk**, a Flutter + Riverpod + go_router, turn-based
puzzle RPG. Read `AGENTS.md` and the relevant repository files before proposing
anything.

## Task

Create a practical, phased implementation plan to improve MythDusk's
functionality, usability, accessibility, and campaign variety.

**Do not implement changes yet.** First inspect the current working tree,
validate the observations below, and then produce a small, reviewable plan.
Preserve all unrelated and uncommitted work.

## Product rules that must remain unchanged

- Matching tiles generates resources and AP; it never directly damages enemies.
- Skills cause damage, healing, shields, buffs, and debuffs.
- Every successful puzzle action spends one Move.
- Moves refresh each player turn and do not carry over by default.
- AP persists until spent.
- Battles use one hero for now.
- Core gameplay logic should remain pure Dart and testable without widgets or
  Firebase.
- Prefer reusable, data-driven systems over bespoke art or handcrafted levels.
- Do not add Firebase, deploy anything, add a major dependency, or change the
  core combat model without explicit approval.

## Verified current state

- The puzzle/combat foundation is strong and primarily pure Dart.
- Cascades, power-ups, overlays, hazards, board movers, enemy intent, boss
  forms, prep items, lives, upgrades, local persistence, and weekly objectives
  exist.
- The campaign contains 200 nodes across 10 chapters.
- Campaign content is stored in local JSON.
- Documentation validation passes.
- All 103 current tests pass.
- `flutter analyze` currently reports only four minor warnings in test files.
- Existing tests are almost entirely domain tests; widget, accessibility,
  navigation, and integration coverage is missing.

## Main problems to solve

### 1. First-session onboarding

The core rule—matches generate resources rather than damage—is unusual and is
not taught strongly enough.

Plan a guided introduction across the first few battles that progressively
teaches:

1. Swapping and matching.
2. Tile colors generating resources.
3. Matches generating AP.
4. Skills requiring both resources and AP.
5. Moves controlling when the enemy acts.
6. Reading enemy intent.
7. Creating and activating power-ups.

Prefer contextual callouts, highlights, and a small number of guided actions
over large text dialogs.

### 2. Battle decision feedback

Improve the player's ability to understand what is happening and make tactical
choices.

Consider:

- Skill progress such as `Mana 5/8 · AP 1/2`.
- Clearly showing which cost is missing when a skill is unavailable.
- Resource/AP feedback traveling from cleared tiles toward the HUD.
- A clear "skill ready" cue.
- Enemy-intent damage after shield absorption.
- An end-turn consequence preview.
- Better invalid-swap feedback.
- Long-press skill explanations.
- Clearer status-effect and board-mechanic explanations.

Do not move combat calculations into widgets.

### 3. Pre-battle node briefing

Normal campaign pins currently launch battle immediately, while bosses only
show the prep picker.

Plan a reusable node briefing surface that can show:

- Enemy and likely actions.
- Board rules and hazards.
- Rewards.
- Selected hero and relevant skills/resources.
- Recommended strategy or prep.
- Boss prep selection.
- A deliberate Battle button.

### 4. Distinctive, data-driven enemies

`EnemySkill` currently contains little more than ID, name, damage, and weight.
Most enemies therefore behave like different HP/damage tables.

Plan an extensible enemy-effect model supporting a deliberately small initial
set such as:

- Damage.
- Apply a status effect.
- Add or spread a board overlay.
- Drain or suppress a resource.
- Temporarily reduce Moves.
- Gain armor/shield.
- Heal.
- Modify tile spawn weights.

Use this to define one representative normal enemy and one boss vertical slice
before converting the full catalog. Enemy intents must accurately describe the
action that will execute.

### 5. Real campaign variation

The 200-node structure exists, but levels within a chapter mostly inherit the
same chapter-wide board configuration. Node-level board overrides are rarely
used, and only a few reusable templates exist.

Plan a scalable content progression:

- Introduce each chapter mechanic gently.
- Reinforce it with enemy combinations.
- Add per-node template, spawn-weight, hazard, mover, and objective variations.
- Combine mechanics near act finales.
- Give bosses rule-changing mechanics, not only more HP and damage.

Pay particular attention to planned-but-thin identities:

- Mirror Lake: reflection or mirror behavior.
- Thornmarket: match/resource tax.
- Eclipse Forge: burn or fire hazards.
- Mythspire Gate: controlled combinations of learned mechanics.

Do not create 200 bespoke implementations. Define reusable configuration
patterns and apply them through JSON.

### 6. Player-facing progression

The profile layer already supports hero upgrades and buying prep items, but
these systems have little or no proper UI.

Plan:

- A Heroes screen with stats, skills, upgrade tiers, comparisons, and unlock
  progress.
- A small Shop screen exposing existing prep-item purchases.
- A Profile/progress screen.
- A later Daily Missions surface using existing battle events.

Review hero unlock pacing. The second playable hero currently unlocks after 50
campaign clears, which may be too late for demonstrating gameplay variety.
Recommend a better curve without invalidating existing profiles.

### 7. Production usability and accessibility

Include a cleanup pass for:

- Hide QA-only controls behind debug mode.
- Confirm restart and exit during an active battle.
- Save and resume an in-progress battle where practical.
- Make the lives countdown update while Home remains open.
- Implement or remove placeholder sound/haptic switches.
- Add color-blind differentiation beyond color alone.
- Support reduced motion and larger text.
- Add semantic labels and accessible tap targets.
- Verify small-phone layouts.
- Avoid side effects during widget `build`.

### 8. Known data/flow inconsistency

Campaign node `prepDrops` values are parsed from JSON, but victory settlement
currently generates drops through `PrepDrops.forNonBossClear` instead of
honoring the node configuration. Decide which source is authoritative, remove
dead configuration, and test the chosen behavior.

Also review fallback lookups that silently return the first/default hero,
enemy, chapter, or node for unknown IDs. Content errors should be caught by
validation rather than silently launching unrelated content.

## Engineering quality work

Include proportionate work for:

- A content validator covering unique IDs, cross-references, supported effect
  types, asset paths, board templates, and reward configuration.
- Widget tests for the critical user journey.
- Accessibility tests where Flutter supports them.
- Navigation tests for Home → chapter → briefing → battle → result.
- Unit tests for all new pure-Dart rules.
- Splitting oversized files only where it directly supports the planned work;
  avoid an architecture rewrite.

## Required plan output

Return:

1. A short assessment of the current architecture and the observations you
   verified.
2. A prioritized roadmap divided into:
   - **P0: first-session clarity and safety**
   - **P1: combat and campaign depth**
   - **P2: progression and retention**
3. For every work item:
   - User outcome.
   - Exact files/modules likely affected.
   - Domain/data/UI changes.
   - Dependencies and migration concerns.
   - Tests and acceptance criteria.
   - Estimated size: S, M, L, or XL.
4. A recommended first implementation slice that is small enough for one
   reviewable pull request.
5. Risks, open decisions, and anything that requires owner approval.
6. A proposed order of commits for the first slice.

## Preferred first slice

Unless repository inspection reveals a blocker, prioritize:

1. Guided first-battle tutorial state and presentation.
2. Reusable pre-battle node briefing.
3. Clear skill/resource readiness feedback.
4. One distinctive enemy effect plus one boss mechanic.
5. Widget/navigation tests for the resulting path.

Keep the plan solo-developer friendly. Favor incremental changes that reuse the
existing engine and data pipeline.
