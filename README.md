# Kissan Konnect

An Android-first Flutter plant-health project with a working local browser workspace and a newly trained Kaggle classifier and Firebase email/password accounts. The separate portfolio repository is unchanged.

## Working features

- **Leaf screening:** select from 14 supported crops; use camera/gallery or a clearly labelled dataset sample; run an actual local ONNX classifier with 38 trained classes.
- **Traceable results:** top three model scores, crop-mismatch and ambiguous-match states, version/source details, and a copyable screening report. Results are unverified suggestions, not confirmed diagnoses.
- **Field notebook:** explicitly save a photo/result/notes, search the latest 200 records, edit notes, reload durable images, and delete records. SQLite records belong to the local service and are isolated by verified Firebase UID.
- **Crop guide:** searchable observation guidance with university-extension references for early/late blight and bacterial spot. No generated pesticide instructions.
- **Weather:** city search with location choices, modelled current conditions and a five-day forecast from Open-Meteo. No API key or device-location permission needed; weather requires internet.
- **Firebase accounts:** sign up, sign in, sign out and request a password reset; notebook and conversation data are isolated per account.
- **Plant assistant:** sourced, curated care guidance for nine plants with context-aware follow-ups and private conversation history. This is a retrieval assistant, not a generative LLM.
- **Model report:** actual lab evaluation, data provenance, supported classes and limitations.
- **Responsive workspace:** desktop navigation rail and phone bottom navigation, useful empty/error states, and explicit model status.

## Two connected repositories

- **Application:** [Orcus01/Kissan_Konnect](https://github.com/Orcus01/Kissan_Konnect) — Flutter, app gateway, notebook and weather.
- **Machine learning:** [Orcus01/Kissan_Konnect_ML](https://github.com/Orcus01/Kissan_Konnect_ML) — private repository containing model acquisition, preprocessing, ONNX inference, versioned API and model tests.

Flutter calls the app gateway on port 8765. The gateway calls the independent ML API on port 8767 using HTTP, validates API version 1 and the result schema, then presents/saves the result. `ml-service.lock.json` pins the expected ML Git revision. There is no runtime Python import across repositories.

## Start the app and model together

Requires Flutter and Python 3.12 (or `uv`, which can provision Python). For the configured personal project, run `./scripts/run_personal.sh`. Tested with Flutter 3.47.8 / Dart 3.13.7.

```sh
./scripts/run_local.sh
```

This checks or clones the pinned sibling ML repository using your GitHub access, creates separate Python environments, installs each repository's dependencies, verifies the model, builds Flutter web and starts both loopback-only services with readiness checks and coordinated shutdown. Open [the local workspace](http://127.0.0.1:8765). Stop with Ctrl-C. You can set `FLUTTER_BIN`, `KISSAN_VENV`, `KISSAN_ML_DIR`, `KISSAN_ML_VENV`, `KISSAN_PORT` or `KISSAN_ML_PORT` if needed. An existing model checkout is never reset; a different revision requires deliberately updating the lock or selecting a matching checkout.

To start only the app gateway after building and starting the separate ML service:

```sh
KISSAN_ML_URL=http://127.0.0.1:8767 .venv/bin/python -m server.app
```

`lib/main.dart` and `lib/preview.dart` open the same authenticated workspace. The dedicated personal Firebase project `kissan-konnect-personal-261026` is configured locally. Use `./scripts/run_personal.sh`; see [Firebase setup](docs/FIREBASE_SETUP.md) for fresh-checkout configuration. With no configuration, the sign-in screen explains that setup is required; no historical project is selected automatically. A plain static file server cannot run the complete workspace; use the app gateway and the ML service.

## Android development

Flutter remains the mobile stack. The model currently runs on the local Python service, **not on the Android device itself**. Connect the device/emulator to the service through USB debugging:

```sh
adb reverse tcp:8765 tcp:8765
flutter run -t lib/main.dart
```

The debug manifest permits cleartext only for loopback; no production cleartext configuration was added. `KISSAN_SERVICE_URL` is available for a future HTTPS service. The existing native build is still blocked by Gradle 7.6.3 versus the installed Java 22 toolchain, with Android command-line tools missing. No working APK or physical-device camera run is claimed. The local browser implementation is runnable now; native migration is a separate remaining slice.

## Checks

```sh
flutter test
.venv/bin/python -m pytest server/tests -q
flutter build web -t lib/main.dart --no-wasm-dry-run
```

The app Python tests use temporary notebooks and an HTTP-boundary mock, without ONNX Runtime or weight files. Real inference tests live in the ML repository. Model smoke fixtures come from the PlantVillage dataset family and do not establish independent field accuracy. See [model integration and limitations](docs/MODEL_INTEGRATION.md).

## Model attribution

Kissan Leaf v1 was trained on the colour portion of [Kaggle PlantVillage v3](https://www.kaggle.com/datasets/abdallahalidev/plantvillage-dataset): 54,282 retained images, 38 classes and 14 crops. The MobileNetV3 Small ImageNet backbone is frozen and its classifier head is newly trained. Held-out lab test accuracy is **98.64%**, macro F1 **97.98%**, on 8,208 images. These are not field accuracy estimates. Validation-only temperature scaling is folded into ONNX. Dataset license: **CC BY-NC-SA 4.0**.

The separate ML repository owns acquisition, training, split audit, complete evaluation, versioned weights and the curated assistant. Binary weights and notebook data are not committed. Model assets come from a private checksummed GitHub release; authenticate `gh` with repository access. Known demo fixture images are excluded from this training run. No original paper results or production readiness are claimed.

## Project separation

Kissan Konnect is a personal project. Firebase configuration must explicitly identify its dedicated project; `seatsandspaces` is blocked in the current auth path. There is no fallback to historical Firebase options. Client accounts, data and repositories are not reused. The former embedded weather key was removed from source; its owner still needs to rotate it because Git history retains it.

Generated build/cache files are already tracked upstream. New ignore rules prevent additions; existing tracked artifact cleanup is a separate follow-up. See the [initial audit](docs/BASELINE_AUDIT.md) for the original implementation findings.

## Research context

The owner supplied “Kissan Konnect: AI-Powered Plant Disease Control System”, IEEE SSITCON 2024, DOI [10.1109/SSITCON62437.2024.10796969](https://doi.org/10.1109/SSITCON62437.2024.10796969). This rebuild does not reproduce that paper's model or results.
