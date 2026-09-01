# Firebase (emulator-first)

| Field | Value |
|-------|-------|
| **Status** | Active in-repo; **no production deploy** without chat approval |
| **Related** | [Firestore_Schema](Firestore_Schema.md) · [Firebase_Console_Checklist](../00_Project/Firebase_Console_Checklist.md) |

## What is in the repo

- `firebase.json`, `.firebaserc` (`mythdusk-emulator` placeholder)
- `firestore.rules`, `firestore.indexes.json`
- `functions/index.js` — `ensureUser`, `tickLives`, `refillLivesWithGems`,
  `submitBattleRun`, `validateIapReceipt`
- FlutterFire packages; `lib/firebase/firebase_bootstrap.dart`
- Guest → link Apple/Google; live 1v1 challenge; Remote Config / Crashlytics /
  Analytics / App Check init (skipped if Firebase is down)

## Run emulators

```bash
cd functions && npm install && cd ..
npx -y firebase-tools@latest emulators:start
flutter run --dart-define=FLAVOR=dev
```

Do **not** run `firebase deploy` unless the project owner approves it.

## After console setup

Replace `.firebaserc` default with the real Project ID. Run
`flutterfire configure --project <PROJECT_ID>` to overwrite
`lib/firebase/firebase_options.dart`. Commit `GoogleService-Info.plist` and
`google-services.json`. Never commit `.p8` keys.

I've set up prototype Security Rules to keep the data in Firestore safe. They
are designed to be secure because unauthenticated access is denied, economy
fields are Function-only, battle runs cannot be updated by the client, and
content collections are read-only. However, you should review and verify them
before broadly sharing the app. If you'd like, I can help you harden these
rules.
