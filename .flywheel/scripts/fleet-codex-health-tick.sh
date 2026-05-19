#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="flywheel.fleet_codex_health.v1"
TICK_SCHEMA_VERSION="${SCHEMA_VERSION}.tick"
SKILLOS_REPO="${SKILLOS_REPO:-/Users/josh/Developer/skillos}"
WATCHDOG="${FLEET_CODEX_WATCHDOG:-$SKILLOS_REPO/.flywheel/scripts/pane-watchdog.sh}"
LEDGER="${FLEET_CODEX_HEALTH_LEDGER:-/Users/josh/.local/state/flywheel/fleet-codex-health.jsonl}"
LOCK_DIR="${FLEET_CODEX_HEALTH_LOCK:-/tmp/fleet-codex-health.lock}"
SNAPSHOT_DIR="${FLEET_CODEX_SNAPSHOT_DIR:-/tmp}"
NTM="${FLEET_CODEX_NTM:-ntm}"

now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
stamp() { date -u '+%Y%m%dT%H%M%SZ'; }

classify() {
  local watchdog_state="$1" activity_state="$2"
  case "$watchdog_state:$activity_state" in
    DEAD:*) echo "queued_input_or_capture_failed" ;;
    IDLE:WORKING) echo "waiting_background_terminal_or_stale_work" ;;
    IDLE:THINKING) echo "thinking_but_idle_marker" ;;
    IDLE:*) echo "goal_banner_idle" ;;
    ALIVE:THINKING) echo "alive_thinking" ;;
    ALIVE:WORKING) echo "alive_working" ;;
    ALIVE:*) echo "alive" ;;
    ERROR:*) echo "probe_error" ;;
    *) echo "unknown" ;;
  esac
}

append_row() {
  mkdir -p "$(dirname "$LEDGER")"
  jq -c . <<<"$1" >>"$LEDGER"
}

snapshot_pane() {
  local session="$1" pane="$2" ts="$3" compact="$4"
  local path="$SNAPSHOT_DIR/${session}-pane${pane}-snapshot.${compact}.json"
  local capture
  capture="$(tmux capture-pane -t "${session}:.$pane" -p 2>&1 || true)"
  jq -n --arg schema_version "${SCHEMA_VERSION}.snapshot" --arg ts "$ts" --arg session "$session" --argjson pane "$pane" --arg capture "$capture" \
    '{schema_version:$schema_version,ts:$ts,session:$session,pane:$pane,capture:$capture}' >"$path"
  printf '%s' "$path"
}

main() {
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    jq -n --arg schema_version "$TICK_SCHEMA_VERSION" --arg ts "$(now_iso)" \
      '{schema_version:$schema_version,ts:$ts,status:"skipped",reason:"lock_held"}'
    return 0
  fi
  trap 'rmdir "$LOCK_DIR"' EXIT

  mkdir -p "$(dirname "$LEDGER")" "$SNAPSHOT_DIR"

  local ts compact sessions_json sessions count_sessions=0 count_rows=0 count_errors=0
  ts="$(now_iso)"
  compact="$(stamp)"

  if ! sessions_json="$("$NTM" list --json 2>&1)"; then
    append_row "$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --arg error "$sessions_json" \
      '{schema_version:$schema_version,ts:$ts,session:null,pane:null,agent_type:null,state:"ERROR",classifier:"ntm_list_failed",source:"fleet-codex-health-tick",evidence:null,error:$error}')"
    jq -n --arg schema_version "$TICK_SCHEMA_VERSION" --arg ts "$ts" \
      '{schema_version:$schema_version,ts:$ts,status:"error",error:"ntm_list_failed",rows:1}'
    return 1
  fi

  sessions="$(jq -r '.sessions[]? | select(.attached == true) | .name' <<<"$sessions_json")"

  while IFS= read -r session; do
    [[ -n "$session" ]] || continue
    count_sessions=$((count_sessions + 1))

    local activity_json sweep_json
    if ! activity_json="$("$NTM" activity "$session" --json 2>&1)"; then
      count_errors=$((count_errors + 1))
      append_row "$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --arg session "$session" --arg error "$activity_json" \
        '{schema_version:$schema_version,ts:$ts,session:$session,pane:null,agent_type:null,state:"ERROR",classifier:"ntm_activity_failed",source:"fleet-codex-health-tick",evidence:null,error:$error}')"
      count_rows=$((count_rows + 1))
      continue
    fi

    if ! sweep_json="$("$WATCHDOG" sweep "$session" 2>&1)"; then
      count_errors=$((count_errors + 1))
      append_row "$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --arg session "$session" --arg error "$sweep_json" \
        '{schema_version:$schema_version,ts:$ts,session:$session,pane:null,agent_type:null,state:"ERROR",classifier:"pane_watchdog_sweep_failed",source:"fleet-codex-health-tick",evidence:null,error:$error}')"
      count_rows=$((count_rows + 1))
      continue
    fi

    local codex_rows
    codex_rows="$(jq -r '
      [.agents[]? | select((.agent_type // "") == "codex")]
      | if length == 0 then "NO_CODEX\t\t\t" else .[] | [.pane, (.state // "UNKNOWN"), (.duration // ""), (.confidence // 0)] | @tsv end
    ' <<<"$activity_json")"

    while IFS=$'\t' read -r pane activity_state duration confidence; do
      if [[ "$pane" == "NO_CODEX" ]]; then
        append_row "$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --arg session "$session" \
          '{schema_version:$schema_version,ts:$ts,session:$session,pane:null,agent_type:"codex",state:"NO_CODEX",classifier:"no_codex_agents",source:"fleet-codex-health-tick",evidence:null}')"
        count_rows=$((count_rows + 1))
        continue
      fi

      local watchdog_state classifier evidence
      watchdog_state="$(jq -r --argjson pane "$pane" '.panes[]? | select(.pane == $pane) | .state // "ERROR"' <<<"$sweep_json" | head -1)"
      [[ -n "$watchdog_state" ]] || watchdog_state="ERROR"
      classifier="$(classify "$watchdog_state" "$activity_state")"
      evidence="null"
      if [[ "$watchdog_state" != "ALIVE" ]]; then
        evidence="$(snapshot_pane "$session" "$pane" "$ts" "$compact")"
      fi

      append_row "$(jq -n \
        --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --arg session "$session" --argjson pane "$pane" \
        --arg activity_state "$activity_state" --arg watchdog_state "$watchdog_state" --arg duration "$duration" \
        --argjson confidence "${confidence:-0}" --arg classifier "$classifier" --arg evidence "$evidence" \
        '{schema_version:$schema_version,ts:$ts,session:$session,pane:$pane,agent_type:"codex",state:$watchdog_state,activity_state:$activity_state,duration:$duration,confidence:$confidence,classifier:$classifier,source:"fleet-codex-health-tick",evidence:(if $evidence == "null" then null else $evidence end)}')"
      count_rows=$((count_rows + 1))
    done <<<"$codex_rows"
  done <<<"$sessions"

  jq -n --arg schema_version "$TICK_SCHEMA_VERSION" --arg ts "$ts" --arg ledger "$LEDGER" \
    --argjson sessions "$count_sessions" --argjson rows "$count_rows" --argjson errors "$count_errors" \
    '{schema_version:$schema_version,ts:$ts,status:"ok",sessions:$sessions,rows:$rows,errors:$errors,ledger:$ledger}'
}

main "$@"
