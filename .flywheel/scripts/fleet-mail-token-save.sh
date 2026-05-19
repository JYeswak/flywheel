#!/usr/bin/env bash
# Save a fleet-mail registration token to the vault.
# Usage: fleet-mail-token-save.sh <agent-name> <token>
set -euo pipefail

NAME="${1:?agent-name required}"
TOKEN="${2:?token required}"
VAULT="$HOME/.local/state/flywheel/fleet-mail-tokens"

mkdir -p "$VAULT"
chmod 700 "$VAULT"

F="$VAULT/${NAME}.token"
printf '%s' "$TOKEN" > "$F"
chmod 600 "$F"

echo "Saved: $F"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-67-presence-hash-secret-diagnostics.md`
