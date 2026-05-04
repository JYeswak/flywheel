#!/usr/bin/env bash
# Verify each topology row's fleet_mail_identity has a corresponding token file.
# Read-only.
set -euo pipefail

TOPOLOGY="$HOME/.local/state/flywheel/session-topology.jsonl"
VAULT="$HOME/.local/state/flywheel/fleet-mail-tokens"

if [ ! -f "$TOPOLOGY" ]; then
    echo "WARN: no session-topology.jsonl"
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "WARN: jq not found; cannot inspect session-topology.jsonl"
    exit 0
fi

# Get unique fleet_mail_identity values from latest-per-session rows.
IDENTITIES=$(
    jq -sr 'group_by(.session) | map(max_by(.effective_at)) | .[].fleet_mail_identity // empty | select(. != null)' "$TOPOLOGY" 2>/dev/null \
        | sort -u
)

if [ -z "$IDENTITIES" ]; then
    echo "INFO: no topology rows declare fleet_mail_identity yet (waiting on bd-register-session-fleet-mail-flag)"
    exit 0
fi

MISSING=0
for NAME in $IDENTITIES; do
    F="$VAULT/${NAME}.token"
    if [ -f "$F" ]; then
        echo "OK: $NAME -> $F"
    else
        echo "MISSING: $NAME (no token at $F)"
        MISSING=$((MISSING + 1))
    fi
done

if [ "$MISSING" -gt 0 ]; then
    echo "FAIL: $MISSING missing token(s)"
    exit 1
fi

echo "PASS: all fleet_mail_identity values have tokens"
exit 0
