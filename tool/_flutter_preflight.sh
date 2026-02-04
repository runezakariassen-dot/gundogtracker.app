#!/usr/bin/env bash
set -euo pipefail

flutter_preflight_check() {
  local flutter_bin
  flutter_bin=$(command -v flutter 2>/dev/null || true)
  if [[ -z "$flutter_bin" ]]; then
    echo "❌ Flutter binary not found in PATH. Install Flutter and add it to PATH."
    return 1
  fi

  local sdk_dir cache_dir stamp_dir
  sdk_dir=$(cd "$(dirname "$flutter_bin")/.." && pwd)
  echo "FLUTTER_SDK_DIR=$sdk_dir"
  cache_dir="$sdk_dir/bin/cache"
  stamp_dir="$cache_dir/engine.stamp"

  echo "Flutter binary: $flutter_bin"
  echo "Flutter SDK root: $sdk_dir"
  echo
  echo "flutter --version output:"
  if ! "$flutter_bin" --version; then
    echo "⚠ flutter --version failed to finish; permissions may be denied."
  fi
  echo
  echo "Path info:"
  ls -ld "$sdk_dir" "$sdk_dir/bin" "$cache_dir"
  if [[ -e "$stamp_dir" ]]; then
    ls -l "$stamp_dir"
  else
    echo "-> engine.stamp does not exist yet."
  fi

  local missing=0
  local paths=("$sdk_dir" "$sdk_dir/bin" "$cache_dir")
  for path in "${paths[@]}"; do
    if [[ ! -w "$path" ]]; then
      echo "✖ Not writable: $path"
      missing=1
    else
      echo "✔ Writable: $path"
    fi
  done
  if [[ -e "$stamp_dir" ]]; then
    if [[ ! -w "$stamp_dir" ]]; then
      echo "✖ Not writable: $stamp_dir"
      missing=1
    else
      echo "✔ Writable: $stamp_dir"
    fi
  fi

  if [[ $missing -ne 0 ]]; then
    cat <<EOF
Fix suggestions:
 1) chmod -R u+w "$cache_dir"
 2) xattr -dr com.apple.provenance "$cache_dir" || true
 3) xattr -dr com.apple.quarantine "$cache_dir" || true
 4) Re-run ./tool/test_fast.sh after fixing the SDK permissions.
EOF
    return 1
  fi

  return 0
}
