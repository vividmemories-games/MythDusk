# IAP store setup (Human — W3)

Agent cannot create store products or upload secrets. Complete H1–H5 before sandbox purchases grant in production Functions.

**App ID:** `com.vividmemories.mythdusk`  
**Firebase project:** `mythdusk-ec0c7`

## Product IDs (exact)

| Product ID | Play type | App Store type | Grant |
|---|---|---|---|
| `mythdusk_starter_pack` | Managed product (non-consumable) | Non-Consumable | 400 coins, 40 gems, Dusk Sash |
| `mythdusk_value_30d` | Managed product | Non-Renewing Subscription | 200 gems + entitlement |
| `mythdusk_gems_small` | Managed product (consumable) | Consumable | 80 gems |
| `mythdusk_gems_medium` | Managed product (consumable) | Consumable | 250 gems |
| `mythdusk_prep_box` | Managed product (consumable) | Consumable | prep inventory |

## H1 — Create products

1. **Play Console** → Monetize with Play → Products → create each ID → activate → attach to internal/closed testing track.
2. **App Store Connect** → Your app → In-App Purchases → create each ID with matching type → submit with app version as required.

## H2 — Testers

- Play: license testers and/or internal test track users.
- Apple: Sandbox Apple ID; on device use Settings → App Store → Sandbox Account.

## H3 — Verification secrets (Functions)

Set Firebase secrets (never commit files):

```bash
# Play: JSON key for a service account with Android Publisher access
firebase functions:secrets:set PLAY_SERVICE_ACCOUNT_JSON

# App Store Connect API key (.p8 contents, Key ID, Issuer ID)
firebase functions:secrets:set APPLE_IAP_KEY_P8
firebase functions:secrets:set APPLE_IAP_KEY_ID
firebase functions:secrets:set APPLE_IAP_ISSUER_ID
```

Service account needs permission to call Android Publisher API for the Play app.  
Apple key needs App Store Connect API access for In-App Purchase / StoreKit.

## H4 — Deploy Functions

After secrets exist, approve in chat:

```bash
firebase deploy --only functions
```

(or Agent MCP deploy with your approval)

## H5 — Sandbox test

1. Fresh cloud account without starter entitlement.
2. Shop → Buy starter → pay in sandbox → coins/gems/cosmetic once.
3. Buy again / Restore → no double grant.
4. Settings → Restore purchases.
5. Optional: buy `mythdusk_gems_small`.
6. Release build: no “Claim (QA)”; debug build may still show QA claim.

## Debug QA path

Debug builds can call `validateIapReceipt` with `qaToken: qa-mythdusk-ec0c7` (emulator or matching project id) without store proof. Release builds use real store verification only.
