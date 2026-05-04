#!/usr/bin/env bash
#
# Starts a local Anvil (Foundry) instance for integration testing.
#
# Usage:
#   bash tool/anvil/start.sh
#   bash tool/anvil/start.sh --block-time 5  # mine a block every 5 seconds
#   ANVIL_PORT=8546 bash tool/anvil/start.sh --silent
#
# Environment variables:
#   ANVIL_BIN   — path to anvil binary (default: auto-detect from PATH or ~/.foundry)
#   ANVIL_PORT  — listen port (default: 8545)

set -euo pipefail

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

echo "Starting Anvil on port $ANVIL_PORT (PID: $$)"
echo "  Binary: $ANVIL_BIN"
echo "  RPC URL: http://127.0.0.1:$ANVIL_PORT"

exec "$ANVIL_BIN" \
  --port "$ANVIL_PORT" \
  --chain-id 31337 \
  "$@"
