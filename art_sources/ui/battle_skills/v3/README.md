# Compact buttons with original battle sizing

2026-10-20 correction: only shrink the action controls. The board's original 0.89 scale and 18px bottom spacing are restored exactly. Character stage sizing, compact-screen board height, scrolling rules, and the combat-status row are restored to the pre-v2 implementation. The original board source has no diff against the repository baseline.

Retained changes: slim illustrated skill buttons with visible required costs, full current/required information on long press, existing casting/disabled semantics, and the compact End Turn touch target. No skill costs or combat mechanics change.

Validation: 11 button/layout/board-effects tests pass, including exact original stage-height checks at normal/enlarged text, all-20-skill cost/activation checks, and long-press behavior. Flutter analysis is clean; Android profile build succeeds. Combat screenshots 01–03 and the listing overview are refreshed with the corrected layout. Existing full-suite shop/settings failures from the previous run remain documented in v2; the full suite was not rerun for this correction.

The v2 board/character resizing experiment is rejected and retained only as history. Next: review the smaller controls on a phone without changing the established battle geometry.
