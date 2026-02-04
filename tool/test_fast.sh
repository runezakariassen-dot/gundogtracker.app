#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_flutter_preflight.sh"

if ! flutter_preflight_check; then
  echo "Aborting: Flutter SDK is not writable."
  exit 1
fi

cd "$SCRIPT_DIR/.."

flutter test -r expanded --concurrency=1 --exclude-tags slow
