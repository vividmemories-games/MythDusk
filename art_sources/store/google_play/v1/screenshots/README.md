# Google Play screenshots

Five English phone screenshot exports at 1080 × 1920, JPEG without alpha. Upload in numeric order. PNG capture masters, including the headline, are retained in `sources/`. The overview in `../previews/phone_screenshots.jpg` is for review only.

Combat screenshots 01–03 were refreshed on 2026-10-20 with the integrated illustrated skill buttons, live current/required costs, and responsive battle layout. The previous set is retained in `archive/plain-buttons/`. Screenshots 04–05 are unchanged. The overview reflects the refreshed set.

| File | Heading | Suggested alt text |
| --- | --- | --- |
| `01_puzzle_combat.jpg` | Match gems. Fuel your skills. | Knight battles a Goblin Scout above a gem board, resource meters, and hero skills. |
| `02_hero_skills.jpg` | Your hero. Your strategy. | Mage faces a Bog Shaman with vine-covered gem tiles and resource costs for Fireball and Arcane Bolt. |
| `03_boss_encounter.jpg` | Face powerful bosses. | Knight confronts Warchief Ruk in a boss encounter with a shaped puzzle board. |
| `04_heroes.jpg` | Find your favorite hero. | Knight hero selection shows equipped abilities, alternative skills, and a locked mastery skill. |
| `05_campaign.jpg` | Explore the dusk realms. | Realm browser shows Twilight Road progress and further realms unlocked through campaign completion. |

## Capture method

Created on 2026-10-19 from actual Flutter screens rendered on the Android 15 emulator in profile mode (debug QA tools hidden), with native fonts and assets. `tool/store_preview.dart` uses isolated in-memory SharedPreferences, actual campaign definitions, actual board catalogs, and real battle actions. It does not initialize the Dart Firebase backend or change production code. Android's existing native Firebase plugins may still initialize automatically.

The screenshot canvas is 540 × 960 logical pixels, rendered at 2×. The top headline occupies 112 logical pixels (11.7%); the remaining 88.3% shows the actual screen. Safe-area padding is removed for the store composition; no device frames or system status bars are included. Battle captures follow two valid swaps through the normal notifier API, with animations allowed to settle. Boards and cascade outcomes vary between runs. Profile progress and currencies are sample values.

For a fresh disposable Android emulator, run:

```sh
flutter run --profile --no-pub -t tool/store_preview.dart -d emulator-5554
```

Use a disposable emulator: Flutter may uninstall an existing app if its signing key differs, deleting that emulator app's local data. This occurred during the first capture build; no physical device or Firestore data was changed.

In another terminal from the repository root:

```sh
"$HOME/Library/Android/sdk/platform-tools/adb" -s emulator-5554 forward tcp:18765 tcp:8765
sh tool/capture_store_screenshots.sh
```

The fixture serves captures on device loopback only. `?raw=1` omits the headline for additional full-screen captures. Stop the fixture after capture and remove the forwarding rule.

## Validation and limits

- Visually inspected all five PNG masters; verified all JPEG exports are 1080 × 1920 with no alpha, each below 1 MB.
- `flutter analyze --no-pub` passes; `git diff --check` passes.
- On refresh: 46 targeted gameplay/live-button tests and 20 artwork/prototype tests pass. The full suite has 353 passing and 7 failing tests in battle safety initialization, shop Firebase setup/layout, and the settings golden. See `art_sources/ui/battle_skills/v1/README.md` for integration details. These failures were not fixed by the screenshot refresh.
- Existing native build warnings: Kotlin Gradle Plugin compatibility warnings from Firebase/sign-in plugins and deprecated Android API use.
- Play Console acceptance, promotional cropping, localization, and tablet-specific screenshots remain unverified. These are the first phone screenshot set for owner review.
