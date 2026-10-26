#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_VENV="${KISSAN_VENV:-$TASK_ROOT/.venv}"
TASK_ML_DIR="${KISSAN_ML_DIR:-$TASK_ROOT/../Kissan_Konnect_ML}"
TASK_ML_VENV="${KISSAN_ML_VENV:-$TASK_ML_DIR/.venv}"
TASK_FLUTTER="${FLUTTER_BIN:-flutter}"
if ! command -v "$TASK_FLUTTER" >/dev/null 2>&1; then
  if [[ -x "$TASK_ROOT/../work/flutter/bin/flutter" ]]; then
    TASK_FLUTTER="$TASK_ROOT/../work/flutter/bin/flutter"
  else
    echo 'Flutter was not found. Install Flutter or set FLUTTER_BIN to its executable.' >&2
    exit 1
  fi
fi
create_environment() {
  local task_environment="$1"
  if [[ ! -x "$task_environment/bin/python" ]]; then
    if command -v uv >/dev/null 2>&1; then
      uv venv --python 3.12 "$task_environment"
    else
      python3.12 -m venv "$task_environment"
    fi
  fi
}
install_requirements() {
  local task_environment="$1"
  local task_requirements="$2"
  if command -v uv >/dev/null 2>&1; then
    uv pip install --python "$task_environment/bin/python" -r "$task_requirements"
  else
    "$task_environment/bin/python" -m pip install -r "$task_requirements"
  fi
}
create_environment "$TASK_VENV"
"$TASK_VENV/bin/python" scripts/prepare_ml_checkout.py "$TASK_ML_DIR"
create_environment "$TASK_ML_VENV"
install_requirements "$TASK_VENV" server/requirements.txt
install_requirements "$TASK_ML_VENV" "$TASK_ML_DIR/requirements.txt"
"$TASK_ML_VENV/bin/python" "$TASK_ML_DIR/scripts/fetch_model.py"
"$TASK_FLUTTER" pub get
TASK_FIREBASE_ARGS=()
if [[ -n "${KISSAN_FIREBASE_CONFIG:-}" ]]; then
  TASK_FIREBASE_ARGS+=("--dart-define-from-file=$KISSAN_FIREBASE_CONFIG")
fi
"$TASK_FLUTTER" build web -t lib/main.dart --no-wasm-dry-run "${TASK_FIREBASE_ARGS[@]}"
exec "$TASK_VENV/bin/python" scripts/run_services.py \
  --ml-dir "$TASK_ML_DIR" --ml-python "$TASK_ML_VENV/bin/python" \
  --port "${KISSAN_PORT:-8765}" --ml-port "${KISSAN_ML_PORT:-8767}"
