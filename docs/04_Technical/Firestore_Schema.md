# Firestore Schema (planned)

Status: **design only — nothing deployed.** The app currently persists
`PlayerProfile` locally via SharedPreferences (`mythdusk_profile_v2` key,
`schemaVersion: 3`). This doc pins the Firestore shape so the local model
migrates cleanly when Firebase is wired.

## Principles

- Client never writes authoritative rewards (coins, gems, unlocks) directly;
  those move through Cloud Functions once online.
- Every content/config doc carries `schemaVersion`, `contentVersion`,
  `isEnabled`, `createdAt`, `updatedAt`.
- Local `PlayerProfile.toJson()` is the source of truth for field names, so
  the eventual sync layer is a straight mapping.

## `users/{uid}`

Mirrors `PlayerProfile`:

```jsonc
{
  "schemaVersion": 3,
  "displayName": "Wanderer",
  "coins": 500,              // server-validated writes only
  "gems": 50,                // server-validated writes only
  "lives": 5,
  "selectedHeroId": "mage",
  "completedNodeIds": ["node_01"],
  "prepInventory": { "vanguard_tonic": 2, "aegis_flask": 1, "second_wind": 1 },
  "secondWindUsedDay": "2026-07-21",
  "createdAt": "<serverTimestamp>",
  "updatedAt": "<serverTimestamp>"
}
```

Security: owner read; owner may write cosmetic/selection fields
(`displayName`, `selectedHeroId`). Economy fields (`coins`, `gems`, `lives`,
`prepInventory`, `completedNodeIds`) are written by Cloud Functions after
validating a submitted battle run.

## `battle_runs/{runId}`

Client-submitted result, validated server-side before rewards are granted:

```jsonc
{
  "schemaVersion": 1,
  "uid": "<auth uid>",
  "nodeId": "node_01",
  "heroId": "mage",
  "won": true,
  "turnsTaken": 6,
  "equippedPrep": ["vanguard_tonic"],
  "clientVersion": "0.4.0",
  "submittedAt": "<serverTimestamp>",
  "processed": false          // set true by the reward function (idempotency)
}
```

Security: owner create only (no update/delete). Reward grant is idempotent —
the function checks `processed` before paying out.

## Content collections (read-only for clients)

`heroes`, `skills`, `enemies`, `bosses`, `campaigns`, `economy_config`,
`remote_balance` — all carry the standard versioning envelope. Current
in-repo sources that will seed them:

| Collection       | Current source                                   |
| ---------------- | ------------------------------------------------ |
| `campaigns`      | `assets/levels/twilight_road.json`               |
| `heroes`/`skills`| `HeroCatalog` (`lib/features/heroes/domain`)     |
| `enemies`/`bosses`| `EnemyCatalog` (`lib/features/battle/domain`)   |
| `remote_balance` | `MatchBalanceConfig` (`lib/features/puzzle/domain/match_balance.dart`), `PrepBalance` |

Security: public authenticated read where `isEnabled == true`; writes only
via admin tooling / trusted service accounts.
