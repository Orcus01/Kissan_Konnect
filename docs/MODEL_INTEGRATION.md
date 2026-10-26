# App ↔ independent ML service

The model implementation now lives in [Orcus01/Kissan_Konnect_ML](https://github.com/Orcus01/Kissan_Konnect_ML), a separate private repository. The app does not import model code or require ONNX Runtime/NumPy. The two repositories communicate through a versioned HTTP contract.

```text
Flutter browser / Android
         │ /api/*
         ▼
App gateway :8765             Kissan_Konnect repository
  ├─ notebook → local SQLite
  ├─ weather → Open-Meteo
  └─ inference HTTP client
         │ /v1/model, /v1/predict
         ▼
ML service :8767              Kissan_Konnect_ML repository
  └─ verified model assets → preprocessing → ONNX Runtime CPU
```

## Ownership

| Application repository | ML repository |
| --- | --- |
| Flutter screens and navigation | Model download and SHA-256 manifest |
| Image selection and result presentation | Image validation and preprocessing |
| Local notebook, photos and notes | Ordered labels and inference |
| City weather | Model response contract and model tests |
| HTTP client and response validation | Stateless `/v1/*` API and readiness |

Application-owned thumbnail encoding is separate from inference preprocessing. No shared Python path, copied weights or submodule is needed at runtime. The demo photo remains an attributed Flutter asset so the app can demonstrate screening.

## Start both

Run `./scripts/run_local.sh` from the application repository. The launcher checks `ml-service.lock.json`, uses a sibling `Kissan_Konnect_ML` checkout (or `KISSAN_ML_DIR`), and clones the pinned revision if that checkout does not exist. Private repository access requires your normal GitHub authentication; no token is embedded in scripts or Flutter. An existing checkout at another revision is preserved and the launcher explains the mismatch.

The launcher creates separate environments, installs each repository's requirements, verifies the model, builds Flutter web, starts the ML service, checks API readiness, then starts the app gateway. It stops the pair if either process exits. Ctrl-C stops both.

Options: `KISSAN_VENV`, `KISSAN_ML_VENV`, `KISSAN_ML_DIR`, `KISSAN_PORT`, `KISSAN_ML_PORT`, and `FLUTTER_BIN`.

For independently running services:

```sh
# In the ML repository
./scripts/run_service.sh

# In the app repository, after dependency installation and a Flutter web build
KISSAN_ML_URL=http://127.0.0.1:8767 .venv/bin/python -m server.app
```

The app gateway is the browser's same-origin backend. Flutter never needs direct cross-origin access to the model port. Android debug continues through `adb reverse tcp:8765 tcp:8765`; inference runs on the local service, not on Android hardware. The previously identified Android toolchain blocker is unchanged.

## Contract and recovery

`GET /v1/model` reports API version, readiness, model version, source, license declaration, supported classes and limitations. `POST /v1/predict?crop=Potato` accepts raw JPEG/PNG/WebP bytes. The response includes API major version 1, model request ID, timestamp, selected crop, status, top three scored labels, processing time and model provenance. Every response must set `verified_diagnosis` to false.

The app validates the response schema, score ranges, selected crop and API version before presenting or saving it. Image validation errors stay actionable. A stopped service, incompatible response or different crop produces a recoverable error instead of an invented result. Notebook records keep both the app record ID and upstream model request ID.

## Model provenance and evidence

The active model is Kissan Leaf v1: a newly trained 38-class head on a frozen ImageNet MobileNetV3 Small backbone, using Kaggle PlantVillage v3 colour images. The pinned separate ML repository contains the model card, full evaluation, training pipeline, grouped split manifest and checksummed private release. Held-out lab accuracy is 98.64% on 8,208 images; this does not measure field performance. Dataset license is CC BY-NC-SA 4.0.

Scores are calibrated within the held-out lab distribution and are not general diagnostic probabilities. There is no reliable non-leaf/unknown-input detector. The two demonstration fixtures were excluded from training, but remain from the same dataset family.

## Data and deployment boundary

The ML service does not save images or predictions. The app retains unsaved reviews in bounded memory and writes a re-encoded EXIF-free photo, notes and result to its local SQLite notebook only on explicit save. That notebook remains in this app repository's ignored `server/data` directory and is not migrated to the model repository or synchronized to Firestore.

Both services bind to loopback and reject unexpected Host/Origin values. Remote ML URLs must use HTTPS. Public hosting still needs authentication, user isolation, retention controls and a separate deployment design.

## Accounts and assistant

The gateway validates ID tokens from the explicitly configured personal Firebase project. Scans, photos, pending predictions and chat history are scoped by Firebase UID. No Firebase service-account key is shipped to Flutter. The model API remains stateless and loopback-only. The chat endpoint forwards question and crop context to the separate ML repository, where curated university-extension guidance is retrieved; the gateway stores only the owning account’s history. See FIREBASE_SETUP.md.
