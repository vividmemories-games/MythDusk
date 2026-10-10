# Weekly presentation QA

Weekly now shares Daily's illustrated bog scene, stone pedestal, antique gold
frame, serif typography, coin art, textured Play button and hearts. Shared widgets
live in `lib/shared/widgets/challenge_art.dart`; no new raster assets or dependencies
were added. Daily's golden renders remain unchanged after extraction.

Play and lives are outside the scrolling details, inside the device safe area.
The weekday objective and weekend boss presentation retain their scheduled identity.
Weekend enemies use the existing form-four art. Rewards remain 40 coins on weekdays
and 80 on weekends, granted by the existing logic. Boss enrage remains eight turns;
this screen displays the configured warning without modifying combat rules.
Completion and zero lives still disable Play. Prep selection, the Weekly battle
route, life regeneration and gated QA date overrides retain their behavior.
Removed the player-facing Firebase implementation note; retained local reset timing
and the life cost of failure.

## Evidence

- `ios-weekend-pinned-controls.png`: native iPhone 17 Pro Max simulator, October 10,
  2026, at the initial scroll position. Boss, reward, warning, Play and lives visible.
- `ios-weekday-pinned-controls.png`: native weekday fixture, October 6, 2026.
- `test/goldens/weekly-weekday.png` and `weekly-weekend.png`: 440 × 956 deterministic
  Flutter renders with Pro Max safe-area insets.
- `test/goldens/weekly-compact-controls.png`, `weekly-large-text-controls.png`, and
  `weekly-weekend-large-text.png`: 320 × 568 renders at normal or 200% text.

Small phones and larger text scroll the details while preserving visible controls.
Character illustrations and decorative art are reused from the existing catalog;
this does not change enemy identity or add bespoke boss imagery.

## Reproduce

Run `flutter run -t tool/weekly_preview.dart -d DEVICE_ID`. The fixture defaults to
October 6, 2026 and uses in-memory preferences, leaving real profiles untouched.
Add `--dart-define=WEEKLY_QA_DAY=10` for the weekend fixture.

Run `flutter analyze --no-pub` and:

```
flutter test --no-pub test/weekly_schedule_test.dart test/weekly_screen_test.dart test/weekly_visual_test.dart test/daily_contract_test.dart test/daily_screen_test.dart test/daily_visual_test.dart
```

Screen checks cover pinned controls before and after scrolling, seven-day enemy
and objective identity, form-four weekend art, zero lives and completion states.
Visual checks include weekday/weekend, compact-phone and large-text cases. Existing
schedule, combat-objective and idempotent reward tests are retained. No deployment
or gameplay changes were made.
