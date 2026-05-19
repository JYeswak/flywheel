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

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
