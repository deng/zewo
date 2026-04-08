#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

TARGETS=("$@")
if [ "${#TARGETS[@]}" -eq 0 ]; then
  TARGETS=("integration_test")
fi

run_flutter_test() {
  local log_file="$1"
  set +e
  env \
    -u all_proxy \
    -u ALL_PROXY \
    -u http_proxy \
    -u https_proxy \
    -u HTTP_PROXY \
    -u HTTPS_PROXY \
    -u no_proxy \
    -u NO_PROXY \
    flutter test "${TARGETS[@]}" 2>&1 | tee "$log_file"
  local rc=${PIPESTATUS[0]}
  set -e
  return "$rc"
}

attempt=1
max_attempts=2

while true; do
  log_file="$(mktemp "${TMPDIR:-/tmp}/flutter-integration-test.XXXXXX.log")"
  if run_flutter_test "$log_file"; then
    rm -f "$log_file"
    exit 0
  fi

  if [ "$attempt" -ge "$max_attempts" ] || \
     ! grep -q "No tests ran\." "$log_file"; then
    rm -f "$log_file"
    exit 1
  fi

  echo "Detected stale Flutter integration runner output ('No tests ran.'); retrying once..." >&2
  rm -f "$log_file"
  attempt=$((attempt + 1))
done
