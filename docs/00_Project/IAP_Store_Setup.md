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

### Play Console prerequisite (BILLING)

Play blocks one-time products until an uploaded APK/AAB declares
`com.android.vending.BILLING` (already in `android/app/src/main/AndroidManifest.xml`).

1. Build a release AAB that includes `in_app_purchase` (current `master`).
2. Upload to **Internal testing** (or any track) and let processing finish.
3. Then **Monetize with Play → Products** unlocks “Create product”.

```bash
flutter build appbundle --release
# Upload build/app/outputs/bundle/release/app-release.aab in Play Console
```

### Create SKUs

1. **Play Console** → Monetize with Play → Products → create each ID → activate → attach to internal/closed testing track.
2. **App Store Connect** → Your app → In-App Purchases → create each ID with matching type → submit with app version as required.

## H2 — Testers

- Play: license testers and/or internal test track users.
- Apple: Sandbox Apple ID; on device use Settings → App Store → Sandbox Account.

## H3 — Verification access (Functions)

### Play (no JSON key)

Play verification uses Application Default Credentials on the Cloud Functions
runtime service account. Do **not** download a service account key.

1. Enable **Google Play Android Developer API** on GCP project `mythdusk-ec0c7`.
2. Runtime SA (pinned in `functions/index.js`):
   `mythdusk-play-iap@mythdusk-ec0c7.iam.gserviceaccount.com`
3. Play Console → **Users and permissions** → that email must be Active with
   access to view app information and financial/order data for MythDusk.
   Do not use other projects' compute SAs (e.g. Dot Clash).

### Apple (Secret Manager)

1. Enable **Secret Manager API** on `mythdusk-ec0c7`.
2. Set Firebase secrets (never commit `.p8` files):

```bash
firebase functions:secrets:set APPLE_IAP_KEY_P8 --project mythdusk-ec0c7
firebase functions:secrets:set APPLE_IAP_KEY_ID --project mythdusk-ec0c7
firebase functions:secrets:set APPLE_IAP_ISSUER_ID --project mythdusk-ec0c7
```

`APPLE_IAP_KEY_ID` must be the short Key ID only (e.g. `T76N6AHL28`), not repeated.
`validateIapReceipt` binds these secrets and verifies iOS via StoreKit API.

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
