#!/usr/bin/env bash
# Look up the local agent-mail identity for a session+pane.
# Usage: lookup-pane-identity.sh <session> <pane>
# Prints just the identity name, or empty string if not found.

set -euo pipefail

SESSION="${1:?session required}"
PANE="${2:?pane required}"
TOKENS="${FLYWHEEL_IDENTITY_TOKENS:-$HOME/.local/state/flywheel/identity-tokens.jsonl}"

[[ "$PANE" =~ ^[0-9]+$ ]] || { echo ""; exit 0; }
[[ -f "$TOKENS" ]] || { echo ""; exit 0; }

if command -v jq >/dev/null 2>&1; then
    jq -sr --arg s "$SESSION" --arg p "$PANE" \
        'map(select(.session == $s and (.pane | tostring) == $p)) | sort_by(.ts) | last | .identity // ""' \
        "$TOKENS" 2>/dev/null || echo ""
else
    grep -F "\"session\":\"$SESSION\"" "$TOKENS" 2>/dev/null \
        | grep -F "\"pane\":$PANE" \
        | tail -1 \
        | sed -n 's/.*"identity":"\([^"]*\)".*/\1/p' \
        || echo ""
fi
