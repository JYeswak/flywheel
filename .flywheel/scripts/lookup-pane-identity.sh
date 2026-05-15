#!/usr/bin/env bash
# Look up the Agent Mail identity for a session+pane.
# Usage: lookup-pane-identity.sh <session> <pane>
# Prints just the identity name, or empty string if not found.

set -euo pipefail

SESSION="${1:?session required}"
PANE="${2:?pane required}"
AGENT_MAIL_DIR="${FLYWHEEL_AGENT_MAIL_STATE_DIR:-$HOME/.local/state/flywheel/agent-mail}"
TOKENS="${FLYWHEEL_IDENTITY_TOKENS:-$HOME/.local/state/flywheel/identity-tokens.jsonl}"

[[ "$PANE" =~ ^[0-9]+$ ]] || { echo ""; exit 0; }

REGISTRY_ROW="$AGENT_MAIL_DIR/sessions/${SESSION}:${PANE}.json"
if [[ -r "$REGISTRY_ROW" ]] && command -v jq >/dev/null 2>&1; then
    identity="$(
        jq -r '
            if (.status == "active" or .status == "needs_registration" or .status == "needs_token")
            then (.identity_name // "")
            else ""
            end
        ' "$REGISTRY_ROW" 2>/dev/null || true
    )"
    if [[ -n "$identity" && "$identity" != "null" ]]; then
        printf '%s\n' "$identity"
        exit 0
    fi
fi

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
