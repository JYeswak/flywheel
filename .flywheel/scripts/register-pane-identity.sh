#!/usr/bin/env bash
# Register a local agent-mail identity assignment for a specific pane.
# Usage: register-pane-identity.sh <session> <pane> <identity-or-auto>
#
# Phase 1 intentionally records local assignments only. MCP register_agent
# wiring is a follow-up so each session can own its auth flow.

set -euo pipefail

SESSION="${1:?session required}"
PANE="${2:?pane required}"
IDENTITY="${3:-auto}"

PROJECT="${FLYWHEEL_PROJECT:-/Users/josh/Developer/flywheel}"
TOPOLOGY="${FLYWHEEL_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
TOKENS="${FLYWHEEL_IDENTITY_TOKENS:-$HOME/.local/state/flywheel/identity-tokens.jsonl}"

[[ "$PANE" =~ ^[0-9]+$ ]] || { echo "ERR: pane must be numeric: $PANE" >&2; exit 64; }

mkdir -p "$(dirname "$TOPOLOGY")" "$(dirname "$TOKENS")"
touch "$TOKENS"
chmod 600 "$TOKENS"

json_quote() {
    local s="${1//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\n'/\\n}"
    printf '"%s"' "$s"
}

lookup_assignment() {
    if [[ ! -s "$TOKENS" ]]; then
        return 0
    fi
    if command -v jq >/dev/null 2>&1; then
        jq -sr --arg s "$SESSION" --arg p "$PANE" \
            'map(select(.session == $s and (.pane | tostring) == $p)) | sort_by(.ts) | last | .identity // ""' \
            "$TOKENS" 2>/dev/null || true
    else
        grep -F "\"session\":\"$SESSION\"" "$TOKENS" 2>/dev/null \
            | grep -F "\"pane\":$PANE" \
            | tail -1 \
            | sed -n 's/.*"identity":"\([^"]*\)".*/\1/p'
    fi
}

identity_in_use() {
    local candidate="$1"
    if [[ ! -s "$TOKENS" ]]; then
        return 1
    fi
    if command -v jq >/dev/null 2>&1; then
        jq -e --arg id "$candidate" 'select(.identity == $id)' "$TOKENS" >/dev/null 2>&1
    else
        grep -F "\"identity\":\"$candidate\"" "$TOKENS" >/dev/null 2>&1
    fi
}

existing="$(lookup_assignment)"
if [[ -n "$existing" ]]; then
    echo "Existing: $SESSION pane $PANE -> $existing"
    echo "Project: $PROJECT"
    echo "Token storage: $TOKENS"
    exit 0
fi

if [[ "$IDENTITY" == "auto" ]]; then
    COLORS=("Crimson" "Azure" "Olive" "Slate" "Coral" "Indigo" "Amber" "Teal")
    ANIMALS=("Falcon" "Otter" "Heron" "Lynx" "Marlin" "Raven" "Stoat" "Vireo")
    for _ in $(seq 1 128); do
        C="${COLORS[$((RANDOM % ${#COLORS[@]}))]}"
        A="${ANIMALS[$((RANDOM % ${#ANIMALS[@]}))]}"
        candidate="${C}${A}"
        if ! identity_in_use "$candidate"; then
            IDENTITY="$candidate"
            break
        fi
    done
    [[ "$IDENTITY" != "auto" ]] || { echo "ERR: could not generate unused local identity" >&2; exit 70; }
elif identity_in_use "$IDENTITY"; then
    echo "ERR: identity already assigned locally: $IDENTITY" >&2
    exit 65
fi

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
row="$(printf '{"ts":%s,"session":%s,"pane":%s,"identity":%s,"project":%s,"token":null,"registered_via":"local-stub"}' \
    "$(json_quote "$NOW")" \
    "$(json_quote "$SESSION")" \
    "$PANE" \
    "$(json_quote "$IDENTITY")" \
    "$(json_quote "$PROJECT")")"

printf '%s\n' "$row" >> "$TOKENS"
chmod 600 "$TOKENS"

echo "Registered: $SESSION pane $PANE -> $IDENTITY"
echo "Project: $PROJECT"
echo "Token storage: $TOKENS"
echo "Topology storage: $TOPOLOGY (not modified in Phase 1)"
echo ""
echo "NEXT STEP (manual until MCP is wired): from a session with MCP agent-mail, run:"
echo "  mcp__mcp-agent-mail__register_agent project_key=$PROJECT agent_name=$IDENTITY"
echo "Then update topology rows to include the pane->identity mapping."

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-100-contention-shaped-state-owner.md`
