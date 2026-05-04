#!/usr/bin/env bash
# Idempotent init for the josh-requests JSONL substrate.
set -euo pipefail

STATE_DIR="${JOSH_REQUESTS_STATE_DIR:-$HOME/.local/state/flywheel}"
JSONL="$STATE_DIR/josh-requests.jsonl"

mkdir -p "$STATE_DIR"
if [[ ! -e "$JSONL" ]]; then
  : >"$JSONL"
fi
chmod 600 "$JSONL"
