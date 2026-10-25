# Implementation audit — 25 October 2026

Source: Orcus01/Kissan_Konnect at `7afcdc84ab4d7ea7494e095a6f281df0e42f32f8`. Local work is on `rebuild/baseline-and-capture`. No AGENTS.md instructions were found in the repository or the inspected parent locations. The separate portfolio repository was not changed.

## Findings from source

- Flutter/Dart UI with Firebase Auth, Firestore, Realtime Database and Storage dependencies. Android, iOS, web and desktop scaffolding exist; this does not establish platform readiness.
- No disease inference service, model weights, ordered label map, training pipeline or evaluation evidence found. `tflite` was only a commented dependency. Output used a one-element sample list and displayed the same disease for any input; saving used different placeholder values.
- Home has a hard-coded city, current-weather request, inactive plant search/filter and placeholder guidance/news/activity text. No forecast or real news feed found.
- Capture's gallery method was unreachable; video and camera-switch controls were inactive. Asynchronous picker calls had no mounted checks or error states.
- History reads the diagnoses root and filters client-side. It retains an uncancelled listener, lacks loading/error UI, persists temporary local image paths and renders them using Image.network. No database/Storage security rules were found in source; deployed rules are unknown.
- Profile photo changes persist a device-local path; camera and gallery menu choices both use the gallery. Profile fetch assumes a document exists. Sign-up error state is held in a StatelessWidget; account lifecycle needs a focused repair.
- Chat supports messages and attachment uploads in code, but assumes a signed-in user and needs proper error handling, upload isolation, file actions and moderation decisions.
- Legacy plant detail screen imported a missing `Plants` data class. It is not connected from the current home and contains an inactive shopping concept.
- Roughly 12,000 files are tracked, including generated build/cache output. Firebase client configuration and an embedded weather key were present. No credential values are reproduced here. Client Firebase configuration is not a substitute for backend security rules.

## First changes

- Replaced sample disease/treatment output with an explicit unavailable state; removed fake-diagnosis saving.
- Built restrained capture and review screens with camera/gallery actions, busy/error states, mounted guards and photo bytes that work across mobile/browser rendering.
- Added Firebase-free `lib/preview.dart`, shared theme and six capture/weather tests, replacing the unrelated counter test.
- Removed embedded weather key and sensitive request logging; added configuration, timeout, response checks and service disposal. Fixed home clock cleanup and mounted checks.
- Restored the missing legacy display data class without adding invented plant content. Added Android Internet permission and ignore rules.

## Architecture direction

Owner chose Android first with a browser portfolio preview; original model assets are unavailable. Keep Flutter/Firebase and integrate incrementally. Do not replace the stack or imply that browser preview equals full mobile parity. Model selection/evaluation is a separate documented workstream.

## Next implementation slices

1. Resolve Android Gradle/JDK/plugin compatibility; run on an emulator and physical device. Check camera permission denial, cancellation, gallery and lifecycle behavior.
2. Repair account state, registration validation and profile editing; add loading/retry states and durable avatars.
3. Define one versioned user-scoped diagnosis schema and emulator-tested rules. Repair image upload, private queries, history details, listener cleanup and deletion together.
4. Replace placeholder home sections with working capture, current weather, curated sourced guidance, and truthful empty history. Use conventional labeled navigation.
5. Select supported crops and model/dataset provenance; implement the model plan only after reference evaluation exists.

Publication, model accuracy, production security and live backend operation are not verified by this audit.

## Validation performed

- Flutter 3.47.8 / Dart 3.13.7 installed under this chat's `work/flutter`, without changing the global command path.
- Dependency resolution completed. Lockfile changed for packages pinned by the newer Flutter SDK; no deliberate major dependency upgrades were made.
- Existing counter test failed because it expected a counter that this app does not contain. Replaced with six passing capture/review and weather tests.
- `flutter test`: six passed.
- `flutter analyze`: no errors; 178 remaining findings (seven warnings and 171 informational lints). This is not a clean-analysis claim.
- `flutter build web -t lib/preview.dart`: passed. Browser rendering inspected; screenshot saved separately.
- `flutter build web -t lib/main.dart`: passed. This confirms compilation, not authentication or backend operation. Older Firebase dependencies emit WebAssembly compatibility warnings; the JavaScript web build succeeds.
- `flutter build apk --debug`: blocked by Gradle 7.6.3 / Java 22.0.2 incompatibility. Android doctor also reports missing command-line tools and unknown license status. No APK/device validation is claimed.
- Old file_picker dependency emits desktop plugin metadata warnings. Mobile plugin upgrades remain a deliberate follow-up.
- Generated tracked files touched by local tooling were restored; a future cleanup should remove generated artifacts from tracking without losing source history.

## Local preview

The capture preview is served for this session at http://127.0.0.1:8765 . It can be restarted from the repository using `python3 -m http.server 8765 --bind 127.0.0.1 --directory build/web`. Its Firebase-free entry point is `lib/preview.dart`.
