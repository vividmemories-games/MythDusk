# Home and pre-battle implementation

Approved references: Home courtyard v2 and pre-battle bog v3 under `assets/generated/`.

## Result

- Home uses a moonlit courtyard, an engraved stone hero dais, serif headings, live campaign progress, and the gold Continue Journey action. Home Prep is removed. A full-width illustrated Arena tile opens the existing `/challenge` route; the bottom 1v1 shortcut remains. Daily, Weekly, unlocked Expedition, More, settings, lives, hero cycling, cosmetics, and unlock celebrations retain their existing flows.
- Pre-battle presents the enemy without a box, its single name and briefing text at the right, and a compact board-rule/reward summary. The duplicate encounter banner and board preview are removed. The hero loadout and optional aid cards reuse the challenge panel artwork. All 20 skills have illustrated art resolved by skill ID; the selected hero's equipped skills appear in their saved order, including mastery unlocks. Unknown skills or failed artwork loads use an effect-based fallback. Bog creatures reuse the challenge scenery; other enemies use their chapter background.
- The Battle action stays outside the scrolling content and inside the safe area. Compact screens can scroll; enlarged text stacks aid cards. At normal Pro Max text size all Home mode entries and all three preparation cards fit without scrolling.
- Art is decorative. Text, semantics, navigation, inventory, selection state, skill costs, enemy intent, and rewards remain live Flutter/provider data. No Firebase, economy, battle-engine, or production-deployment changes were made.

## Native captures

Captured on the iPhone 17 Pro Max simulator (1320 × 2868), using `tool/hub_preview.dart` and isolated in-memory profile storage:

- [Home](home-pro-max.png)
- [Pre-battle](briefing-pro-max.png)
- [Mage with Frost Ward and Meteor Shard equipped](briefing-mage-alternate-pro-max.png)
- [All 20 skill icons rendered through the shared widget](../../../test/goldens/skill-artwork-roster.png)

Fixture commands:

```sh
flutter run --no-pub -t tool/hub_preview.dart -d 68684F2A-AF0A-4A88-B373-5E7448DBDC67
flutter run --no-pub -t tool/hub_preview.dart --dart-define=BRIEFING_QA=true -d 68684F2A-AF0A-4A88-B373-5E7448DBDC67
flutter run --no-pub -t tool/hub_preview.dart --dart-define=BRIEFING_QA=true --dart-define=QA_HERO=mage --dart-define=QA_SKILLS=frost_ward,meteor_shard -d 68684F2A-AF0A-4A88-B373-5E7448DBDC67
```

The fixture uses example profile values and stub destinations; production screens use the existing app router. Native captures verify platform typography. Six deterministic Flutter goldens cover both screens at 440 × 956 with safe insets, 360 × 640, and 320 × 568 at 200% text. Body text in goldens uses Flutter's deterministic test font.

## Validation

- Formatting and diff whitespace checks pass.
- Flutter analysis passes.
- Full `flutter test --no-pub` suite passes: 303 tests. This includes the six screen goldens and the complete skill-icon grid, plus catalog coverage, live hero/loadout updates, alternate equipped pairs for all five heroes, mastery icons, and missing-art fallbacks.
- Widget checks cover both Arena entries, campaign/Daily/Weekly routes, briefing back and loadout navigation, inventory spending only on Battle, deselection, unavailable aids, the daily Second Wind limit, and the pinned action while scrolling at 200% text. The existing critical campaign journey and combat/prep/loadout checks remain covered.
- Existing native-build warnings remain for Firebase Auth/Google Sign-In UIScene adoption and sign_in_with_apple Swift Package Manager support.
- The asset budget check flags the pre-existing `assets/images/backgrounds/bg_splash_dusk.png` (2.4 MiB against a 2 MiB per-file limit). All new assets are below that limit. Home uses three optimized WebP files; abilities use five transparent atlases under `assets/images/skills/`. The original two-icon Knight reference is archived outside the shipped bundle.

Runtime asset paths and full generation prompts are recorded in [artwork notes](../../../assets/generated/home-briefing-runtime-assets.md). Assets were generated with the built-in imagegen tool and optimized to WebP; generated full-screen concepts are not bundled as UI.

The complete skill artwork registry and generation prompts are recorded in [skill artwork notes](../../../assets/generated/skill-artwork-notes.md). New skill art is added by stable ID in `SkillArtwork.bySkillId`; it does not depend on a fixed hero, default pair, or catalog ordering. `SkillArt` is reusable by other screens.

Next review: try Home → campaign → pre-battle and Home → 1v1 on a physical phone, including the preferred text size.

## Realm browser and quick campaign resume

Continue Journey opens the first unfinished playable node in the furthest unlocked chapter. Both act and node gates are checked by `CampaignChapter.nextPlayableNode`; completing a chapter advances to the next unlocked chapter. A fully cleared campaign opens the realm browser for replay selection. World Map opens the browser independently of lives, while the existing Continue Journey lives check is retained. Briefing still controls aid selection and battle launch.

The realm browser features the selected chapter, uses existing chapter scenery for every card, and shows locked realms with explicit previous-realm requirements. Chapter Medals starts collapsed; existing progress and claim behavior is retained inside it. No new raster assets, dependencies, backend changes, or deployments were required.

Native iPhone 17 Pro Max capture: `realms-pro-max.png`. Reproduce with `flutter run -t tool/hub_preview.dart --dart-define=REALMS_QA=true`; this is a deterministic mock-profile fixture. Goldens cover normal and 200% text on compact screens; Home goldens also include the World Map link.

Validation: All 312 tests passed, including six resume tests and realm interaction/golden checks. Flutter analysis and diff whitespace checks passed. Simulator build retains the existing FirebaseAuth/GoogleSignIn lifecycle and sign_in_with_apple Swift Package Manager warnings.

## Heroes, Shop, and Profile

The three collection/economy screens now share `MythHubShell`: a moonlit backdrop, serif titles, gold divider, safe-area layout, and back navigation that returns Home for direct route entry. `RelicPanel` and `HeroPedestal` reuse existing art and the open engraved border; no new artwork or dependencies were added.

Heroes retains its swipe/chevron carousel and unlock gates. Skills appear before cosmetics and use the same skill-ID artwork registry as the briefing; equipped, unequipped, and mastery-locked states remain visible. Mastery skill rewards display their readable names. Cosmetics, mastery claims, and training actions are preserved.

Shop puts coin-priced battle supplies first, followed by existing offers. The coin price is explicit and purchase accessibility labels name the item and cost. Technical SKU/config copy is removed, and the disabled battle pass card is hidden. Existing coin prices, inventory grants, QA-only pack controls, production store availability, and analytics are unchanged.

Profile retains selected-hero cosmetics, path rank, economy/lives, chapter progress, aid inventory, training summary, and existing Heroes/Shop/Settings routes, now in the same visual style.

Native iPhone 17 Pro Max screenshots: `heroes-pro-max.png`, `shop-pro-max.png`, `profile-pro-max.png`. Reproduce with `flutter run -t tool/hub_preview.dart --dart-define=QA_SCREEN=heroes` (or `shop` / `profile`). These fixture runs use mocked profile storage.

Validation: all 322 tests pass; Flutter analysis and diff whitespace checks pass. Six new golden/layout checks cover the three screens on Pro Max and compact phones at 200% text. Four action tests verify exact coin/inventory changes, insufficient funds, ability swapping, mastery locks, and locked hero browsing. Existing profile navigation tests also pass. Native builds retain the previously documented plugin warnings; no production deployment or backend/IAP logic changes were made.
