# Cursor handoff: MythDusk balance simulator

## Suggested first prompt

Read tools/balance-lab/README.md and CURSOR_HANDOFF.md, then inspect MythDusk's
actual hero unlock, progression, rewards, currency, shop, and summon code.
Map every simulator assumption to a verified source file or mark it unknown.
Preserve guaranteed level-based hero unlocks. Treat summons as an optional,
separate mechanic whose precise role must follow the game's design.
Report discrepancies and propose the smallest corrections before using the
simulator for economy decisions. Do not change the live game's economy or
publish this tool without my approval.

## What is known vs assumed

The user-established concept is heroes unlocking at levels such as 5, 25, and 50.
The simulator starts with those three thresholds plus a starter hero. Exactly
four heroes, level cap 100, summon-only roster expansion, linear leveling,
all currency rewards, pack prices, rates, budgets, and segment behaviors are
prototype assumptions, not verified facts about MythDusk.

The balanced preset uses 12 weeks; 600 starting shards; 450 weekly shards;
75 shards per level; summons at level 8; 300 shards per pull; 2% featured rate;
60-pull pity; offers at level 10, twice per month; NOK 79 for 1,800 shards.
Segment levels/week are 4.5, 6.5, 8.5, 11. Monthly budgets are NOK 0, 120,
350, 950; purchase probabilities per offer window are 0%, 18%, 36%, 62%.
Weighted spend hardcodes population shares of 60%, 25%, 10%, 5%.

## Current model

Final level = min(100, floor(1 + weeks * segment pace)).
Core heroes = starter + thresholds reached.
Earned currency = starting + weekly rewards * weeks + per-level rewards * (level - 1).
Free pulls = floor(earned currency / pull cost), if summons are unlocked.
Offer windows begin at the configured offer level; one initial window plus
floor(eligible weeks / 4.345 * monthly cadence).
Expected buys = min(windows * purchase probability, horizon budget / pack price).
Paid pulls = expected buys * pack currency / pull cost; fractional expectations
are intentional here, not individual-player transactions.
Spend = expected buys * pack price. These are scenario estimates, not net revenue.

## Priority corrections

1. Summon outcomes: featuredRate only changes an undisplayed expectedFeatured
   field. Its formula max(pulls * rate, floor(pulls / pity)) is NOT a correct
   reset-on-success pity expectation. Define pity reset, featured guarantees,
   banner carryover, duplicates, and roster eligibility first. Then implement
   an exact probability-state model or seeded simulation and display outcomes.
2. Progression feedback: summoned heroes, purchases, and core hero unlocks do
   not change progression speed. Faster spender pace is assumed, not caused
   by spending. Avoid presenting these curves as proof of purchase benefits.
3. Timing: currency is aggregated over the whole horizon; all eligible currency
   is treated as spent on pulls, without competing sinks. Offers can appear
   before summons open. Decide whether that is intended, then model events
   chronologically and avoid spending before eligibility.
4. Misleading signal: firstPaidLevel uses min(summon level, offer level).
   Show their separate timings; if both are required, eligibility uses max.
5. Comparison: only four KPI deltas compare baseline. Chart and segment table
   show current values only, despite the surrounding baseline legend. Add
   explicit baseline series/table deltas or correct the labels.
6. Saving: baseline exists only in memory and vanishes on reload. Add versioned
   JSON import/export and local persistence with clear reset behavior.
7. Validation: enforce integer thresholds and pity, sensible ordering, and a
   defined duplicate-threshold policy. Normalization currently silently sorts
   values without updating input fields. Clear invalid-input feedback is needed.
8. Metrics: expose segment weights and avoid coloring all increases as good.
   Explain the sign/unit on final-hero time deltas. Revenue excludes retention,
   churn, fees, taxes, regional pricing, and conversion calibration.
9. UI/accessibility: test mobile layout, keyboard focus and labels. Correct the
   toggle's static On text. Preset highlighting currently persists after edits.

## Useful acceptance checks

- Guaranteed heroes remain obtainable without purchases or summons.
- Changing a threshold affects acquisition timing predictably.
- Changing summon odds/pity affects visible probabilities or expected outcomes.
- No offers/purchases/pulls occur before their intended eligibility gates.
- Zero budget means zero spend; disabled summons mean zero summon purchases.
- Impossible/out-of-range values receive visible validation.
- Baseline comparison and import/export reproduce a scenario accurately.
- Probability tests cover zero pulls, certain success, and pity boundaries.
- Run the included browser checks and inspect desktop/mobile screenshots.

The included model checks cover a few invariants, not full model correctness.
Keep this as an isolated design tool until its assumptions are calibrated.
