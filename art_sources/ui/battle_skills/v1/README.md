# Battle skill button concepts — v1

The tall layout documented here is superseded by `../v3/README.md`: smaller action controls with the original board and character sizing. The v1 previews remain as design history.

Initial Flutter design previews for all 20 hero skills, followed by production integration on 2026-10-20. Existing illustrations come from the five skill atlases registered in `lib/core/assets/skill_artwork.dart`; no new raster assets or dependencies were added to the runtime bundle.

## Review images

- `previews/all-20-skills.png`: all five hero kits, including mastery skills.
- `previews/interaction-states.png`: Fireball ready, unavailable, pressed, and casting.
- `previews/compact-mastery-dock.png`: two three-resource mastery buttons beside an End Turn placeholder at 320 logical pixels.

The shared design uses a gold frame, skill-colored surface tint, illustrated ability icon, readable resource/AP costs, and text plus symbols for state. Pressing scales the button briefly; casting strengthens its colored highlight. Reduced-motion settings disable the transitions. Unavailable and casting states block taps. The prototype uses explicit illustrative availability; the cost amounts are from the actual skill catalog. Mastery gates and battle affordability are not overridden in the real game.

## Interactive preview

From the repository root:

```sh
flutter run -d chrome -t tool/skill_button_preview.dart
flutter run -d chrome -t tool/skill_button_preview.dart --dart-define=SKILL_STATES=true
```

The first preview shows all 20 skills; tap a ready skill to see a short casting response. The second compares four states and allows changing the selected skill. This is a local UI prototype, with no game actions or Firebase connection.

## Validation

```sh
flutter test --no-pub --dart-define=EXPORT_SKILL_PREVIEWS=true test/skill_button_preview_test.dart
flutter analyze --no-pub
git diff --check
```

Four widget checks passed: all 20 skill labels/artwork render; ready changes to casting and returns; unavailable/casting block activation; two mastery buttons fit at 320px at 100% and 200% text. Review images use the bundled DailySerif and MaterialIcons fonts. Flutter analysis and diff whitespace checks pass.

## Production integration — 2026-10-20

`lib/features/battle/presentation/battle_skill_button.dart` is now used by the battle screen for every equipped skill, keyed by stable skill ID. Affordability comes from the existing domain evaluator; each resource and AP label displays current/required values and highlights missing costs. Only the tapped control shows casting while its existing notifier callback runs. It blocks repeat activation until that callback completes and handles disposal safely. Phase labels distinguish resolving, enemy turn, victory, and defeat from insufficient costs; long-press tooltips and semantics expose complete labels. The preview now shares its accent palette with the production widget.

The stage height adapts to the viewport. A minimum scrollable content area keeps the puzzle board usable on small phones and at enlarged text sizes. The HUD wraps when necessary; at enlarged text sizes End Turn moves below the skill pair. Combat rules, costs, loadouts, progression, Firebase behavior, and production entry points are unchanged.

Refreshed Android Play Store combat captures are in `art_sources/store/google_play/v1/screenshots/01_puzzle_combat.jpg` through `03_boss_encounter.jpg`. The previous set is retained under `screenshots/archive/plain-buttons/`.

Validation:

- 46 targeted tests pass: live button costs and exactly-once charging across all 20 skills, unavailable/phase input gates, safe async disposal, compact full battles including mastery skills at 100%/200% text, plus existing puzzle, affordability, QA, turn, tutorial, and loadout checks.
- 20 additional artwork and prototype checks pass.
- Full suite: 353 pass, 7 fail in existing battle safety initialization, shop Firebase setup/layout, and the settings 1× golden. Those failures were not fixed or golden baselines updated by this UI change.
- Flutter analysis passes; Android profile build succeeds; all three refreshed JPEGs were visually inspected at 1080 × 1920 without alpha. Existing Android plugin/Kotlin compatibility warnings remain.

Next: review skill casting and scrolling on a physical phone, then review the refreshed listing artwork before upload. No production deployment was performed.
