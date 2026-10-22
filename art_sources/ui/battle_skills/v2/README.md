# Compact battle controls — v2

Rejected sizing experiment: the owner requested restoring original board and character sizes. That correction is implemented and documented in `../v3/README.md`. Only the smaller action controls are retained. Images below are historical, not the current layout.

2026-10-20 revision following owner feedback that the illustrated cards occupied too much screen space. This supersedes the v1 tall button layout.

## Result

- Slim illustrated skill buttons have a 52px minimum height, with icon/name and a short strip of required resource/AP costs. No divider or separate readiness/status row. All 20 skills remain supported.
- Ready state uses the gold frame and skill color; unavailable state dims the art and highlights unmet costs. Casting and pressed feedback remain. Full current/required values and the blocking reason are available by long press and through semantics, including on disabled skills.
- Normal buttons are checked at 116px width and must remain at or below 64px height. Text enlargement may wrap costs; touch targets remain at least 48px.
- The character stage is secondary (112px at normal text size, 160px at enlarged text). The board uses 97% of available width with a 6px bottom gap. Normal battle layouts prioritize the board without forcing scrolling; enlarged text keeps the scroll fallback and moves End Turn below the skill pair.
- Removed the duplicate combat-log row above the dock. Moves, AP, resources, enemy intent, and phase remain in the existing HUD/stage. No battle mechanics or costs changed.

## Review

- `previews/compact-battle.png`: Android-rendered Knight battle in the store composition.
- `previews/before-after.jpg`: tall layout on the left, compact layout on the right. Gameplay states differ because captures use real random boards and puzzle actions.
- Refreshed combat exports: `art_sources/store/google_play/v1/screenshots/01_puzzle_combat.jpg` through `03_boss_encounter.jpg`.
- Previous tall captures are retained under `screenshots/archive/tall-buttons/`.

## Verification

42 targeted tests pass across live skill buttons, puzzle resolution, skill affordability, turn handoff, and board effects. Coverage includes all 20 skills, height bounds, exactly-once charges, disabled/phase gating, asynchronous disposal, long-press costs without activation, and complete compact/mastery layouts at 100% and 200% text. On the 390×844 normal-text test, the board's allocated area exceeds half the screen height.

Flutter analysis passes. Android profile build succeeds; native capture and before/after comparison visually inspected. Full suite: 356 passed, 5 failed in existing shop Firebase/layout checks and the settings golden. These failures were not fixed or baselines updated in this layout revision. Existing Android plugin compatibility warnings remain.

Next: review on a physical phone, especially long skill names and comfortable tile swipes. No production deployment or backend changes.
