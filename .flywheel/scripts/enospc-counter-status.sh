#!/usr/bin/env bash
set -u -o pipefail

STATE_DIR="${ENOSPC_STATE_DIR:-$HOME/.local/state/flywheel}"
COUNTER="${ENOSPC_COUNTER:-$STATE_DIR/enospc-counter.jsonl}"
WINDOW_SEC="${ENOSPC_WINDOW_SEC:-300}"

now_iso() {
  if [[ -n "${ENOSPC_NOW:-}" ]]; then
    printf '%s' "$ENOSPC_NOW"
  else
    date -u '+%Y-%m-%dT%H:%M:%SZ'
  fi
}

if [[ ! -s "$COUNTER" ]]; then
  jq -c -n \
    --arg schema_version "skillos.enospc.v1" \
    --arg ts "$(now_iso)" \
    --arg counter_path "$COUNTER" \
    --argjson window_sec "$WINDOW_SEC" \
    '{schema_version:$schema_version,ts:$ts,counter_path:$counter_path,window_sec:$window_sec,sources:[]}'
  exit 0
fi

now_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$(now_iso)" '+%s' 2>/dev/null || date -u '+%s')"
jq -s -c \
  --arg schema_version "skillos.enospc.v1" \
  --arg ts "$(now_iso)" \
  --arg counter_path "$COUNTER" \
  --argjson window_sec "$WINDOW_SEC" \
  --argjson cutoff "$((now_epoch - WINDOW_SEC))" '
    {
      schema_version:$schema_version,
      ts:$ts,
      counter_path:$counter_path,
      window_sec:$window_sec,
      sources: (
        [.[] | select((.ts | fromdateiso8601? // 0) >= $cutoff)]
        | group_by(.source)
        | map({
            source: .[0].source,
            strike_count: length,
            latest_ts: (map(.ts) | max),
            latest_disk_pressure_pct: (map(.disk_pressure_pct) | last)
          })
      )
    }
  ' "$COUNTER" 2>/dev/null || jq -c -n \
    --arg schema_version "skillos.enospc.v1" \
    --arg ts "$(now_iso)" \
    --arg counter_path "$COUNTER" \
    --argjson window_sec "$WINDOW_SEC" \
    '{schema_version:$schema_version,ts:$ts,counter_path:$counter_path,window_sec:$window_sec,sources:[],status:"degraded"}'
