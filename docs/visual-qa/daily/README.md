# Daily contract visual QA

The Daily screen now composes reusable raster artwork with live Flutter text,
controls, enemy portraits and provider-driven contract content. Gameplay,
rewards, life regeneration, preparation, QA gating and the battle route retain
their existing behavior. Contract details scroll on small phones and with large text. Play and lives are
pinned below the scroll area, inside the safe area. The stage is shorter so the
objective and all three medals also fit the Pro Max at normal text size.

## Persistent controls follow-up

The owner reported that Play and lives required scrolling even on iPhone 17 Pro Max.
The action area is now fixed, with lives beside the hearts, a shorter enemy stage,
and slightly tighter objective spacing. No art, contract rules or reward logic changed.
`ios-daily-pinned-controls-2026-10-06.png` is the current native screenshot at the
initial scroll position, using the same Leech Wisp contract as the owner’s screenshot.
All three medals, Play and lives are visible. Small phones and 200% text retain
scrollable details while both controls remain visible before and after scrolling.

## Evidence and reproduction

Approved reference: `/Users/apoorv/Documents/Personal Projects/Mythora/assets/generated/daily-contract-redesign-v1.png`.

- Previous layout `ios-daily-2026-10-05.png`: native iPhone 17 Pro Max simulator, top of the page.
- Previous layout `ios-daily-controls-2026-10-05.png`: same native fixture, scrolled to the controls.
- `comparison.png`: reference alongside the actual complete Flutter render.
- `test/goldens/daily-contract-2026-10-05.png`: deterministic 393 × 852 Flutter render.
- `test/goldens/daily-compact-controls.png`: 320 × 568 controls render.
- `test/goldens/daily-large-text-controls.png`: 320 × 568, 200% text controls render.

Run `flutter run -t tool/daily_preview.dart -d DEVICE_ID` for the isolated October 5,
2026 fixture. Add `--dart-define=DAILY_QA_SCROLL_BOTTOM=true` for the bottom view. Add `--dart-define=DAILY_QA_DAY=6` to reproduce Leech Wisp.
The preview uses in-memory preferences; it does not read or overwrite real profiles.
Regenerate renders with `flutter test test/daily_visual_test.dart --update-goldens`.
Golden tests intentionally load the bundled serif font and Material icons.

Visual iterations corrected oversized panel ornaments overlapping the objective,
a native nine-slice frame sizing difference, missing test-render font glyphs,
and excess spacing. Final panel uses a thin textured frame stretched to the live
content height; corners remain small. Native screenshots were inspected separately
from the golden render.

## Remaining fidelity differences

The existing scheduled enemy artwork is reused, including the current Hexer
portrait. Its pose, face and lighting differ from the concept. The background and
ornaments match its atmosphere but are separate generated artwork, not exact
extractions. The coin, heart and medal details differ. The panel border is thinner
and the reward is an inline row rather than a separate outlined plaque. Blurbs may
wrap on narrow phones. Smaller viewports and larger text can require scrolling through details, while
Play and lives remain visible. No screenshot is used as a flattened interface.

## Shipped artwork and provenance

All final raster files live in `assets/images/daily/`:
`bog_stage.webp`, `panel_frame.webp`, `button.webp`, `spiral.webp`,
`lightning.webp`, `hourglass.webp`, `coin.webp`, `objective.webp`, `heart.webp`.
Generated with the built-in imagegen tool, then cropped into separate assets and
encoded as WebP for package size. Alpha is retained on the decorative assets.
Libre Baskerville is bundled under its included SIL Open Font License in
`assets/fonts/OFL.txt`; it is scoped to the Daily and Weekly challenge presentation.

Prompt set used:

1. **Bog stage** — “Use case: stylized-concept. Generate a reusable TEXT-FREE environment asset for a Flutter fantasy RPG. Reference image is STYLE and COMPOSITION reference only. Create portrait 1024x1536 atmospheric teal bog: twisted hanging branches at top edges, misty ruined stone pillars with faint antique gold runes, fireflies, reflective water. A broad mossy dark stone pedestal at center-bottom, its top at 76 percent height, empty space above for separately composited enemy. Thin magical antique gold circular rune halo centered at 53 percent height. Upper 20 percent subdued dark teal negative space. NO character, NO text, NO interface, NO panels, NO button. Rich illustrated game art matching reference atmosphere. Output a single background.”
2. **Decorative sheet** — “Use case: stylized-concept. Game UI decorative asset sheet, transparent background, exactly 8 isolated elements arranged in 2 columns and 4 rows evenly spaced, each inside its own equal 512 square region, with generous clear padding. Row1: left ornate antique gold cornered dark teal rectangular panel frame, right wide antique hammered gold blank button with bevels and clipped corners. Row2: left round silver medal with luminous purple spiral, right round antique gold medal with cyan lightning bolt. Row3: left round antique gold medal with amber hourglass, right gold crown coin. Row4: left dark stone square objective medallion with four cyan diamond tiles, right ruby red heart with gold rim. All rendered highly detailed painterly fantasy RPG UI, deep teal dark interiors, gold etching. NO TEXT NO LETTERS. Consistent frontal flat perspective. Elements must not overlap. Each occupies centered 80% of its cell.”
3. **Alpha correction** — “Edit target: this decorative asset sheet. Remove ALL brown backdrop and shadows outside the eight objects. Preserve eight objects, exact size positions colors artwork and internal dark teal surfaces. Output truly transparent alpha outside each object, not a painted background or checkerboard. No other changes.”
4. **Final panel** — “Use case: stylized-concept. A SINGLE blank fantasy mobile RPG panel, portrait 1024x1536. The entire image is the panel. Uniform very dark near-black teal textured interior. Extremely thin antique gold double border precisely inset 12 pixels from image edges. Small delicate angled gold filigree corners only 45 pixels wide. No protruding shapes, no gems, no large ornaments, no center diamonds. Frame must leave central 94 percent width and height empty for live Flutter text. Style elegant understated antique gold etching matching a misty bog RPG. NO TEXT NO SYMBOLS NO ICONS. Flat frontal rectangular UI texture. Full bleed panel, no outside background.”

## Checks

Run `flutter analyze --no-pub` and
`flutter test --no-pub test/daily_contract_test.dart test/daily_screen_test.dart test/daily_visual_test.dart`.
Screen tests cover compact text scales, scrolling to Play and the last medal,
seven-day enemy/objective identity, completed reward state and zero-lives gating.
The Pro Max render includes top/bottom safe-area insets and asserts that all three
medals, Play and lives are visible without any scrolling.
Existing domain tests cover stable scheduling, medal evaluation and idempotent
Daily rewards. No Firebase, authentication, economy or production deployment changes.
