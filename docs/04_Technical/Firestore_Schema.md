# Firestore Schema

Status: **emulator-ready — nothing deployed to production.** Local play still
uses SharedPreferences (`mythdusk_profile_v2`, `schemaVersion: 14`). Cloud
sync is owned by Cloud Functions after Firebase console setup.

See [Firebase.md](Firebase.md) for emulators and
[Firebase_Console_Checklist](../00_Project/Firebase_Console_Checklist.md) for
human console steps.

## Principles

- Client never writes authoritative rewards (coins, gems, lives, unlocks,
  prep, entitlements).
- Link conflicts **never** `max()` coins/gems — keep guest or switch to the
  existing cloud profile.
- Every content/config doc carries `schemaVersion`, `contentVersion`,
  `isEnabled`, `createdAt`, `updatedAt`.
- Field split lives in `lib/features/profile/domain/profile_field_policy.dart`
  and `firestore.rules`.

## `users/{uid}` (schema 14)

Mirrors `PlayerProfile`. **Client may update:** `displayName`,
`selectedHeroId`, equipped skills/cosmetics, settings, tutorial flags.

**Functions only:** `coins`, `gems`, `lives`, regen/refill counters, upgrades,
`completedNodeIds`, `prepInventory`, medals, expedition, mastery, claimed
cosmetics/packs, encounter continue fields.

Create is Functions `ensureUser` (not client create).

## `battle_runs/{runId}`

Client creates `{processed:false}` then calls `submitBattleRun`. Duplicate
calls return the original grant. Defeat spends a life (not PvP).

## `challenges/{id}` / `matches/{id}`

Live 1v1 only. Invite TTL 60s. Both players must be online. Frozen loadouts.
`actionLog` replay through `PvpDuelEngine`. Heartbeat 5s / forfeit 20s.
No async/offline mailbox.

## `iap_receipts/{id}`

Functions `validateIapReceipt` only. Product grants come from the server
table, never from the client payload.

## Content collections

`heroes`, `skills`, `enemies`, `bosses`, `campaigns`, `economy_config`,
`remote_balance` — authenticated read where `isEnabled == true`; no client
writes.
