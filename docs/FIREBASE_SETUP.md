# Dedicated personal Firebase accounts

Use a Firebase project that you control for **Kissan Konnect only**. Do not reuse Seats and Spaces or another client project. The current implementation refuses project ID `seatsandspaces`, and does not load historical `firebase_options.dart` as a fallback. No live project has been selected automatically.

## Live setup

1. In your dedicated Firebase project, register web and Android apps. Enable Authentication → Email/Password. Authorize your deployed web domain; add localhost explicitly if needed for local development.
2. Save a local, ignored build configuration file (for example `firebase.personal.json`) with these keys, using your own project’s client settings:

```json
{
  "KISSAN_FIREBASE_PROJECT_ID": "YOUR_PERSONAL_PROJECT_ID",
  "KISSAN_FIREBASE_API_KEY": "YOUR_FIREBASE_WEB_API_KEY",
  "KISSAN_FIREBASE_APP_ID": "YOUR_PLATFORM_FIREBASE_APP_ID",
  "KISSAN_FIREBASE_SENDER_ID": "YOUR_MESSAGING_SENDER_ID",
  "KISSAN_FIREBASE_AUTH_DOMAIN": "YOUR_PERSONAL_PROJECT_ID.firebaseapp.com"
}
```

3. Set the gateway’s `KISSAN_FIREBASE_PROJECT_ID` to exactly the same project, then start:

```sh
export KISSAN_FIREBASE_PROJECT_ID=YOUR_PERSONAL_PROJECT_ID
export KISSAN_FIREBASE_CONFIG=/absolute/path/firebase.personal.json
./scripts/run_local.sh
```

For Android, use that platform’s Firebase app ID and `flutter run --dart-define-from-file=/absolute/path/android.personal.json`. The native build toolchain limitations documented in README still apply. No working APK is claimed.

Firebase client configuration identifies the project and is not an Admin SDK credential. Never put a service-account private key into Flutter, Git, or a build configuration file. The gateway verifies signed Firebase ID tokens with Google public certificates and validates project audience, issuer, subject and expiry. It does not check revocation per request; a previously issued token/session can remain valid until token expiry, at most one hour. Server-side Firebase Admin revocation checks are future production hardening.

Browser photo access uses an opaque HttpOnly SameSite=Strict cookie expiring with the verified ID token. Firebase SDK persistence/refresh is responsible for client sign-in; the app refreshes the gateway image session when the token changes. Native API and photo requests use Firebase bearer tokens. SQLite stores Firebase UIDs and profile display names, not passwords. Storage is namespaced by project ID so switching personal projects does not reuse their notebooks or sessions. Existing anonymous notebook rows are not assigned to new accounts.

## Local emulator verification

The current preview uses project `demo-kissan-konnect`, a loopback Authentication emulator on port 9099, and an isolated notebook directory. These are test accounts, not accounts in a live personal or client project. Emulator sessions deliberately use in-memory browser persistence: sign in again after reloading the page. Live web accounts use Firebase local persistence. Password-reset links stay in emulator output; no real email is sent.

The gateway accepts unsigned emulator tokens only when **both** `KISSAN_AUTH_EMULATOR=1` and a `demo-` project ID are set. Never enable that mode for a live project or public service. The normal verifier always checks Google signatures. The app enables emulator use only with a `demo-` project and explicit `KISSAN_AUTH_EMULATOR_HOST` build setting.

Backend tests use synthetic identities and temporary databases; the browser signup/inference/chat checks use the local emulator. Live email/password provider behavior and email delivery remain unverified until the dedicated project is configured. Account creation and password reset in the app contact only the explicitly selected Firebase project.
