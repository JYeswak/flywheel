#!/usr/bin/env bash
# Load a fleet-mail registration token from the vault.
# Usage: fleet-mail-token-load.sh <agent-name>
# Prints the token; empty if not found.
set -euo pipefail

NAME="${1:?agent-name required}"
F="$HOME/.local/state/flywheel/fleet-mail-tokens/${NAME}.token"

if [ -f "$F" ]; then
    cat "$F"
else
    echo ""
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-67-presence-hash-secret-diagnostics.md`
