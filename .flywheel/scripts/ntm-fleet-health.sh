#!/usr/bin/env bash
# Fleet-wide ntm health daemon wrapper.
# Discovers sessions, runs health check + auto-restart-stuck per session.
# Writes JSONL to ~/.local/state/flywheel/ntm-fleet-health.jsonl.

set -euo pipefail

NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
OUT_FILE="${NTM_FLEET_HEALTH_OUT:-$HOME/.local/state/flywheel/ntm-fleet-health.jsonl}"
LOCK_FILE="${NTM_FLEET_HEALTH_LOCK:-$HOME/.local/state/flywheel/ntm-fleet-health.lock}"
TOPOLOGY_FILE="${NTM_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
THRESHOLD="${NTM_HEALTH_THRESHOLD:-10m}"

mkdir -p "$(dirname "$OUT_FILE")"

if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE" || exit 1
  flock -n 9 || { echo "another instance running"; exit 0; }
else
  if ! mkdir "$LOCK_FILE" 2>/dev/null; then
    echo "another instance running"
    exit 0
  fi
  trap 'rmdir "$LOCK_FILE" 2>/dev/null || true' EXIT INT TERM
fi

NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

json_wrap() {
  local raw="$1"
  local rc="$2"
  if printf '%s' "$raw" | jq -ce . >/dev/null 2>&1; then
    printf '%s' "$raw" | jq -c .
  else
    jq -cn --arg raw "$raw" --argjson exit_code "$rc" \
      '{success:false, parse_error:true, exit_code:$exit_code, raw:$raw}'
  fi
}

set +e
LIST_OUT=$("$NTM_BIN" list --json 2>&1)
LIST_RC=$?
set -e

if [[ "$LIST_RC" -ne 0 ]]; then
  LIST_JSON=$(json_wrap "$LIST_OUT" "$LIST_RC")
  jq -cn --arg ts "$NOW" --arg event "session_discovery_failed" --argjson list "$LIST_JSON" \
    '{ts:$ts, event:$event, list:$list}' >>"$OUT_FILE"
  exit 0
fi

SESSIONS=$(printf '%s' "$LIST_OUT" | jq -r '
  if type == "array" then
    .[]? | (.name // .session // empty)
  elif type == "object" and (.sessions? | type == "array") then
    .sessions[]? | (.name // .session // empty)
  elif type == "object" then
    .name // .session // empty
  else
    empty
  end
' 2>/dev/null || true)

if [[ -z "$SESSIONS" ]]; then
  jq -cn --arg ts "$NOW" --arg event "no_sessions_discovered" \
    '{ts:$ts, event:$event}' >>"$OUT_FILE"
  exit 0
fi

while IFS= read -r SESSION; do
  [[ -z "$SESSION" ]] && continue

  TOPO="null"
  if [[ -r "$TOPOLOGY_FILE" ]]; then
    TOPO=$(jq -sc --arg s "$SESSION" \
      'map(select(.session == $s)) | sort_by(.effective_at // "") | last // null' \
      "$TOPOLOGY_FILE" 2>/dev/null || printf 'null')
  fi

  set +e
  HEALTH_OUT=$("$NTM_BIN" health "$SESSION" --json --auto-restart-stuck --threshold "$THRESHOLD" 2>&1)
  HEALTH_RC=$?
  set -e
  HEALTH=$(json_wrap "$HEALTH_OUT" "$HEALTH_RC")

  jq -cn \
    --arg ts "$NOW" \
    --arg session "$SESSION" \
    --arg threshold "$THRESHOLD" \
    --argjson topology "$TOPO" \
    --argjson health "$HEALTH" \
    '{ts:$ts, session:$session, threshold:$threshold, topology:$topology, health:$health}' \
    >>"$OUT_FILE"
done <<<"$SESSIONS"

TMP=$(mktemp "${OUT_FILE}.tmp.XXXXXX")
tail -1000 "$OUT_FILE" >"$TMP" && mv "$TMP" "$OUT_FILE"
