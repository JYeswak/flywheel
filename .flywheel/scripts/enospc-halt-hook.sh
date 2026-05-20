#!/usr/bin/env bash
set -u -o pipefail

STATE_DIR="${ENOSPC_STATE_DIR:-$HOME/.local/state/flywheel}"
COUNTER="${ENOSPC_COUNTER:-$STATE_DIR/enospc-counter.jsonl}"
HALTS="${ENOSPC_HALTS:-$STATE_DIR/enospc-halt-events.jsonl}"
FOUNDER_EVENTS="${ENOSPC_FOUNDER_EVENTS:-$STATE_DIR/founder-page-events.jsonl}"
WINDOW_SEC="${ENOSPC_WINDOW_SEC:-300}"
THRESHOLD="${ENOSPC_THRESHOLD:-3}"
DATA_VOLUME="${ENOSPC_DATA_VOLUME:-/System/Volumes/Data}"
REPO="${SKILLOS_REPO:-/Users/josh/Developer/skillos}"

now_iso() {
  if [[ -n "${ENOSPC_NOW:-}" ]]; then
    printf '%s' "$ENOSPC_NOW"
  else
    date -u '+%Y-%m-%dT%H:%M:%SZ'
  fi
}

disk_pressure_pct() {
  if [[ -n "${ENOSPC_DISK_PRESSURE_PCT:-}" ]]; then
    printf '%s' "$ENOSPC_DISK_PRESSURE_PCT"
    return 0
  fi
  df -P "$DATA_VOLUME" 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}'
}

json_get() {
  local payload="$1" filter="$2" fallback="${3:-}"
  jq -r "$filter // \"$fallback\"" <<<"$payload" 2>/dev/null
}

source_key() {
  local payload="$1" session cwd repo
  if [[ -n "${ENOSPC_SOURCE:-}" ]]; then
    printf '%s' "$ENOSPC_SOURCE"
    return 0
  fi
  session="$(json_get "$payload" '.session_id' '')"
  if [[ -n "$session" && "$session" != "null" ]]; then
    printf '%s' "$session"
    return 0
  fi
  cwd="$(json_get "$payload" '.cwd' "$PWD")"
  repo="$(basename "$cwd" 2>/dev/null || printf 'unknown')"
  printf 'shell-wrapper:%s' "$repo"
}

command_snippet() {
  local payload="$1" command
  command="$(json_get "$payload" '.tool_input.command' 'unknown')"
  printf '%s' "$command" | tr '\n' ' ' | cut -c1-160
}

stderr_text() {
  local payload="$1"
  jq -r '.tool_response.stderr // .tool_output.stderr // ""' <<<"$payload" 2>/dev/null
}

matches_enospc() {
  grep -Eqi 'No space left on device|write error: ENOSPC|(^|[^A-Za-z])ENOSPC([^A-Za-z]|$)|errno[=: ]+28'
}

append_counter_row() {
  local ts="$1" source="$2" snippet="$3" errno="$4" disk="$5" matched="$6"
  mkdir -p "$(dirname "$COUNTER")" 2>/dev/null || return 1
  jq -c -n \
    --arg ts "$ts" \
    --arg source "$source" \
    --arg command_snippet "$snippet" \
    --arg matched_pattern "$matched" \
    --argjson errno "$errno" \
    --argjson disk_pressure_pct "$disk" \
    '{ts:$ts,source:$source,command_snippet:$command_snippet,errno:$errno,disk_pressure_pct:$disk_pressure_pct,matched_pattern:$matched_pattern}' \
    >> "$COUNTER"
}

strike_count_for() {
  local source="$1" now_epoch
  [[ -s "$COUNTER" ]] || { printf '0'; return 0; }
  now_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$(now_iso)" '+%s' 2>/dev/null || date -u '+%s')"
  jq -s -r \
    --arg source "$source" \
    --argjson cutoff "$((now_epoch - WINDOW_SEC))" '
      [.[]
       | select(.source == $source)
       | select((.ts | fromdateiso8601? // 0) >= $cutoff)]
      | length
    ' "$COUNTER" 2>/dev/null || printf '0'
}

append_halt_event() {
  local ts="$1" source="$2" strikes="$3" disk="$4" matched="$5"
  mkdir -p "$(dirname "$HALTS")" 2>/dev/null || return 1
  jq -c -n \
    --arg schema_version "skillos.enospc_halt_event.v1" \
    --arg ts "$ts" \
    --arg source "$source" \
    --arg event "source-halt" \
    --arg counter_path "$COUNTER" \
    --arg action "halt_dispatch_and_escalate" \
    --arg matched "$matched" \
    --argjson strike_count "$strikes" \
    --argjson window_sec "$WINDOW_SEC" \
    --argjson disk_pressure_pct "$disk" \
    '{
      schema_version:$schema_version,
      ts:$ts,
      source:$source,
      event:$event,
      strike_count:$strike_count,
      window_sec:$window_sec,
      disk_pressure_pct:$disk_pressure_pct,
      counter_path:$counter_path,
      matched_patterns:[$matched],
      action:$action
    }' >> "$HALTS"
}

append_founder_event() {
  local ts="$1" source="$2" strikes="$3" disk="$4"
  mkdir -p "$(dirname "$FOUNDER_EVENTS")" 2>/dev/null || return 1
  jq -c -n \
    --arg schema_version "skillos.founder_page_event.v1" \
    --arg ts "$ts" \
    --arg repo "$REPO" \
    --arg source "$source" \
    --arg operator_action "free disk or run approved emergency reap, then wait cooldown" \
    --argjson strike_count "$strikes" \
    --argjson disk_pressure_pct "$disk" \
    '{
      schema_version:$schema_version,
      ts:$ts,
      class:"storage.enospc_halt",
      severity:"high",
      repo:$repo,
      source:$source,
      summary:"ENOSPC halt fired after \($strike_count) strikes in 5 minutes; disk pressure \($disk_pressure_pct)",
      operator_action:$operator_action
    }' >> "$FOUNDER_EVENTS"
}

main() {
  local payload tool stderr disk disk_json errno matched ts source snippet strikes
  payload="$(cat 2>/dev/null || true)"
  [[ -n "$payload" ]] || return 0
  jq -e . >/dev/null 2>&1 <<<"$payload" || return 0

  tool="$(json_get "$payload" '.tool_name' '')"
  [[ "$tool" == "Bash" ]] || return 0

  stderr="$(stderr_text "$payload")"
  disk="$(disk_pressure_pct)"
  if printf '%s\n' "$stderr" | matches_enospc; then
    errno=28
    matched="stderr-enospc"
  elif [[ "${disk:-}" =~ ^[0-9]+$ ]] && (( disk >= 99 )); then
    errno=null
    matched="preemptive-df-probe"
  else
    return 0
  fi

  if [[ "${disk:-}" =~ ^[0-9]+$ ]]; then
    disk_json="$disk"
  else
    disk_json=null
  fi

  ts="$(now_iso)"
  source="$(source_key "$payload")"
  snippet="$(command_snippet "$payload")"
  [[ "$matched" == "preemptive-df-probe" ]] && snippet="preemptive-df-probe"

  append_counter_row "$ts" "$source" "$snippet" "$errno" "$disk_json" "$matched" || return 0
  strikes="$(strike_count_for "$source")"
  [[ "$strikes" =~ ^[0-9]+$ ]] || strikes=0

  if (( strikes >= THRESHOLD )); then
    append_halt_event "$ts" "$source" "$strikes" "$disk_json" "$matched" || true
    append_founder_event "$ts" "$source" "$strikes" "$disk_json" || true
    printf '%s\n' 'ENOSPC 3-strike halt fired' >&2
    return 2
  fi

  return 0
}

main "$@"
rc=$?
if [[ "$rc" -eq 2 ]]; then
  exit 2
fi
exit 0
