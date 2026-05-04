#!/usr/bin/env bash
#
# Starts a local Anvil instance, runs a Flutter integration test, then stops Anvil.
#
# Usage:
#   # Run the swap anvil test
#   bash tool/anvil/run_test.sh integration_test/swap_anvil_test.dart
#
#   # Run from any directory
#   bash /path/to/zero/tool/anvil/run_test.sh integration_test/swap_anvil_test.dart
#
# Environment variables:
#   ANVIL_BIN     — path to anvil binary (default: auto-detect)
#   ANVIL_PORT    — listen port (default: 8545)
#   ANVIL_RPC_URL — RPC URL (default: http://127.0.0.1:$ANVIL_PORT)
#                    On Android emulator use http://10.0.2.2:8545
#
# Examples:
#   # Default: start Anvil, run test, clean up
#   bash tool/anvil/run_test.sh integration_test/swap_anvil_test.dart
#
#   # Android emulator: the app connects to host via 10.0.2.2
#   ANVIL_RPC_URL=http://10.0.2.2:8545 \
#     bash tool/anvil/run_test.sh integration_test/swap_anvil_test.dart

set -euo pipefail

# Resolve project root (zero/ directory) regardless of where we're called from.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Locate anvil binary.
ANVIL_BIN="${ANVIL_BIN:-}"
if [ -z "$ANVIL_BIN" ]; then
  if command -v anvil &>/dev/null; then
    ANVIL_BIN="$(command -v anvil)"
  elif [ -x "$HOME/.foundry/bin/anvil" ]; then
    ANVIL_BIN="$HOME/.foundry/bin/anvil"
  else
    echo "Error: 'anvil' not found. Install Foundry or set ANVIL_BIN." >&2
    exit 1
  fi
fi

ANVIL_PORT="${ANVIL_PORT:-8545}"
ANVIL_RPC_URL="${ANVIL_RPC_URL:-http://127.0.0.1:$ANVIL_PORT}"

# Host-side probe URL — always use localhost since the process runs on the host.
# $ANVIL_RPC_URL may be set to e.g. http://10.0.2.2:8545 for Android emulator
# and is only reachable from inside the emulator, not from this host-side script.
ANVIL_PROBE_URL="http://127.0.0.1:$ANVIL_PORT"

# Pick test file: first argument or default.
TEST_FILE="${1:-integration_test/swap_anvil_test.dart}"

echo "Starting Anvil on port $ANVIL_PORT ..."
"$ANVIL_BIN" --port "$ANVIL_PORT" --silent &
ANVIL_PID=$!

cleanup() {
  echo "Stopping Anvil (PID $ANVIL_PID) ..."
  kill "$ANVIL_PID" 2>/dev/null || true
  wait "$ANVIL_PID" 2>/dev/null || true
  echo "Anvil stopped."
}
trap cleanup EXIT

# Wait for Anvil to be ready (probe via host-side URL).
echo "Waiting for Anvil to be ready ..."
for i in $(seq 1 30); do
  if curl -sf -X POST -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
    "$ANVIL_PROBE_URL" >/dev/null 2>&1; then
    echo "Anvil ready after ${i}s"
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "Error: Anvil did not start within 30s" >&2
    exit 1
  fi
  sleep 1
done

cd "$PROJECT_ROOT"
echo "Running test: $TEST_FILE"
echo "RPC URL: $ANVIL_RPC_URL"
env \
  -u http_proxy -u https_proxy \
  flutter test \
    --dart-define=ANVIL_RPC_URL="$ANVIL_RPC_URL" \
    "$TEST_FILE"
EXIT_CODE=$?
exit "$EXIT_CODE"
