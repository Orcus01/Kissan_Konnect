#!/usr/bin/env bash
set -euo pipefail
TASK_APP_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export KISSAN_FIREBASE_PROJECT_ID=kissan-konnect-personal-261026
export KISSAN_FIREBASE_CONFIG="$TASK_APP_ROOT/firebase.personal.json"
if [[ ! -f "$KISSAN_FIREBASE_CONFIG" ]]; then
  echo 'Personal Firebase client settings are missing. Follow docs/FIREBASE_SETUP.md.' >&2
  exit 1
fi
unset KISSAN_AUTH_EMULATOR
exec "$TASK_APP_ROOT/scripts/run_local.sh"
