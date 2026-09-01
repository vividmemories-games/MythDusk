# Firebase console checklist (human)

Agent cannot create the production Firebase project, Apple keys, or
SHA fingerprints. Finish A–I, then send the agent: Project ID, confirmation
that `GoogleService-Info.plist` and `google-services.json` are in the repo,
Google Web client ID, and that Anonymous + Google (+ Apple) are enabled.

**Do not** `firebase deploy` unless you explicitly approve it in chat.

IDs: iOS/Android `com.vividmemories.mythdusk`. Display name MythDusk.
New Firebase project only (not Dot Clash).

| Step | What | Status |
|------|------|--------|
| A | [Firebase Console](https://console.firebase.google.com/) → Add project (e.g. `mythdusk`). Copy **Project ID**. Optional new GA4. Stay on Spark until Blaze is needed for Cloud Functions. Emulators work without Blaze. | Human |
| B | iOS app, bundle `com.vividmemories.mythdusk`. Download `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`. | Human |
| C | Android app, package `com.vividmemories.mythdusk`. Download `google-services.json` → `android/app/google-services.json`. Add **SHA-1 and SHA-256** (debug: `keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore`, password `android`). | Human |
| D | Auth: enable **Anonymous**, **Google** (copy Web client ID), **Apple** (after E). | Human |
| E | Apple Developer: App ID enable Sign in with Apple; Xcode capability; Services ID e.g. `com.vividmemories.mythdusk.signin`; create Sign in with Apple key, download `.p8` once (**never commit `.p8`**). | Human |
| F | Google Cloud OAuth consent screen; Android OAuth client must include SHA-1. | Human |
| G | Optional cloud Firestore (or emulators only). Do not deploy Functions. Crashlytics/App Check after apps exist. | Human |
| H | `npm install -g firebase-tools` → `firebase login`. Optional `flutterfire configure --project <PROJECT_ID>`. **Do not** `firebase deploy` unless approved. | Human |
| I | Send the agent: Project ID; plist/json in place; Google Web client ID; Anonymous+Google on; Apple on; Android SHA-1 added. | Human |

After I, replace the emulator placeholder in `.firebaserc` with the real
Project ID. `lib/firebase/firebase_options.dart` is a Dart-only emulator
stub until `flutterfire configure` overwrites it with real keys.
