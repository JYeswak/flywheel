#!/usr/bin/env bash
# canonical-cli-scoping-allow-large: canonical triad plus monitor, doctor, fixture, and launchd surfaces live together for one primitive.
set -Eeuo pipefail

VERSION="peer-orch-freeze-monitor.v1.0.0"
SCHEMA_VERSION="peer-orch-freeze-monitor.v1"
LEDGER_SCHEMA_VERSION="peer-orch-freeze-monitor.ledger.v1"
CONTRACT_SCHEMA_VERSION="substrate-loop-contract.v1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

STATE_DIR="${PEER_ORCH_MONITOR_STATE_DIR:-$HOME/.local/state/flywheel}"
LEDGER="${PEER_ORCH_MONITOR_LEDGER:-$STATE_DIR/peer-orch-freeze-monitor.jsonl}"
CONTRACT_LEDGER="${PEER_ORCH_MONITOR_CONTRACT_LEDGER:-$STATE_DIR/substrate-loop-contract.jsonl}"
FUCKUP_LOG="${PEER_ORCH_MONITOR_FUCKUP_LOG:-$STATE_DIR/fuckup-log.jsonl}"
TOPOLOGY="${PEER_ORCH_MONITOR_TOPOLOGY:-$STATE_DIR/session-topology.jsonl}"
JSONL_APPEND_LIB="${PEER_ORCH_MONITOR_JSONL_APPEND_LIB:-${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}}"
MK303="${PEER_ORCH_MONITOR_MK303:-$REPO_ROOT/.flywheel/scripts/codex-template-stuck-detector.sh}"
PERMIT_GATE="${PEER_ORCH_MONITOR_PERMIT:-$REPO_ROOT/.flywheel/scripts/peer-orch-respawn-permit.sh}"
NTM_BIN="${PEER_ORCH_MONITOR_NTM_BIN:-/Users/josh/.local/bin/ntm}"
RESPAWN_CMD="${PEER_ORCH_MONITOR_RESPAWN_CMD:-}"
FIXTURE_DIR="${PEER_ORCH_MONITOR_FIXTURE_DIR:-}"
PLIST_PATH="${PEER_ORCH_MONITOR_PLIST:-$REPO_ROOT/.flywheel/launchd/ai.zeststream.peer-orch-freeze-monitor.plist}"
STOP_FILE="${PEER_ORCH_MONITOR_STOP_FILE:-$STATE_DIR/STOP-peer-orch-freeze-monitor}"
FATAL_FILE="${PEER_ORCH_MONITOR_FATAL_FILE:-$STATE_DIR/FATAL-peer-orch-freeze-monitor}"
INTERVAL_SEC="${PEER_ORCH_MONITOR_INTERVAL_SEC:-300}"
WINDOW_SEC="${PEER_ORCH_MONITOR_WINDOW_SEC:-6}"
AUTO_RESPAWN="${PEER_ORCH_AUTO_RESPAWN:-0}"
ACTOR_SESSION="${PEER_ORCH_MONITOR_ACTOR_SESSION:-flywheel}"
ACTOR_PANE="${PEER_ORCH_MONITOR_ACTOR_PANE:-1}"
NOW_OVERRIDE="${PEER_ORCH_MONITOR_NOW:-}"

MODE="cycle"
APPLY=0
JSON_OUT=0
SCOPE="all"
TARGET_SESSION_FILTER=""
TARGET_PANE_FILTER=""

usage() {
  cat <<'EOF'
Usage: peer-orch-freeze-monitor.sh [command] [options]

Commands:
  cycle                 Scan peer orchestrator panes and plan or apply recovery
  doctor                Report monitor liveness and recovery metrics
  health                Alias for doctor
  repair                Ensure primitive ledgers / launchd plist surfaces exist
  validate              Validate ledger or plist shape
  audit                 Show recent monitor ledger rows
  why                   Explain why this primitive exists
  schema                Emit output schemas
  install               Write the disabled launchd plist surface
  uninstall             Remove the launchd plist surface
  quickstart            Show minimal safe invocation
  completion            Emit shell completion hints
  help                  Show this help

Options:
  --apply               Permit state writes and env-gated recovery actions
  --dry-run             Plan only; this is the default
  --json                Emit machine-readable JSON
  --scope <name>        Scope for repair/validate/audit
  --session <name>      Limit cycle to one session
  --pane <n>            Limit cycle to one pane
  --repo <path>         Override repository root
  --doctor              Equivalent to command: doctor
  --health              Equivalent to command: health
  --info                Emit primitive metadata
  --examples            Emit usage examples

Auto-respawn is disabled unless BOTH --apply and PEER_ORCH_AUTO_RESPAWN=1 are set.
EOF
}

examples() {
  cat <<'EOF'
Examples:
  .flywheel/scripts/peer-orch-freeze-monitor.sh --json
  PEER_ORCH_AUTO_RESPAWN=1 .flywheel/scripts/peer-orch-freeze-monitor.sh cycle --apply --json
  .flywheel/scripts/peer-orch-freeze-monitor.sh doctor --json
  .flywheel/scripts/peer-orch-freeze-monitor.sh install --apply --json
EOF
}

quickstart() {
  cat <<'EOF'
Safe start:
  bash -n .flywheel/scripts/peer-orch-freeze-monitor.sh
  .flywheel/scripts/peer-orch-freeze-monitor.sh doctor --json
  .flywheel/scripts/peer-orch-freeze-monitor.sh cycle --json
EOF
}

completion() {
  cat <<'EOF'
commands: cycle doctor health repair validate audit why schema install uninstall quickstart help
options: --apply --dry-run --json --scope --session --pane --repo --doctor --health --info --examples
EOF
}

info() {
  jq -n \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg primitive "peer-orch-freeze-monitor" \
    --arg mk303 "$MK303" \
    --arg permit_gate "$PERMIT_GATE" \
    --arg ledger "$LEDGER" \
    --arg topology "$TOPOLOGY" \
    '{schema_version:$schema_version,version:$version,primitive:$primitive,mk303:$mk303,permit_gate:$permit_gate,ledger:$ledger,topology:$topology,auto_respawn_default_enabled:false}'
}

emit() {
  local payload="$1"
  local rc="${2:-0}"
  if (( JSON_OUT )); then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$payload" | jq -r '
      if .summary then .summary
      elif .status then (.status|tostring)
      else .
      end'
  fi
  return "$rc"
}

now_iso() {
  if [[ -n "$NOW_OVERRIDE" ]]; then
    printf '%s\n' "$NOW_OVERRIDE"
  else
    date -u +"%Y-%m-%dT%H:%M:%SZ"
  fi
}

ensure_dirs() {
  mkdir -p "$(dirname "$LEDGER")" "$(dirname "$CONTRACT_LEDGER")" "$(dirname "$FUCKUP_LOG")" "$(dirname "$PLIST_PATH")"
}

source_append_lib() {
  if [[ -r "$JSONL_APPEND_LIB" ]]; then
    # shellcheck source=/dev/null
    source "$JSONL_APPEND_LIB"
  else
    fw_jsonl_append_validated() {
      local path="$1"
      local line="$2"
      mkdir -p "$(dirname "$path")"
      printf '%s\n' "$line" >> "$path"
    }
  fi
}

append_jsonl() {
  local path="$1"
  local row="$2"
  ensure_dirs
  source_append_lib
  fw_jsonl_append_validated "$path" "$row"
}

contract_row() {
  local ts
  ts="$(now_iso)"
  jq -n \
    --arg schema_version "$CONTRACT_SCHEMA_VERSION" \
    --arg primitive "peer-orch-freeze-monitor" \
    --arg bead "flywheel-3e5c7" \
    --arg l_rule "L117" \
    --arg ts "$ts" \
    --arg ledger "$LEDGER" \
    --arg doctor "$SCRIPT_DIR/peer-orch-freeze-monitor.sh doctor --json" \
    --arg repair "$SCRIPT_DIR/peer-orch-freeze-monitor.sh repair --scope all --apply --json" \
    '{
      schema_version:$schema_version,
      primitive:$primitive,
      bead:$bead,
      l_rule:$l_rule,
      ts:$ts,
      ledger:$ledger,
      monitor_fields:["monitor_last_fire_ts","mttr_p95_seconds","false_recovery_count_24h","permit_gate_refusals_24h","recoveries_24h","monitor_alive"],
      doctor_command:$doctor,
      self_repair_action:$repair,
      escalation_path:"fuckup-log class=peer-orch-monitor-stale then bead flywheel-3e5c7"
    }'
}

ensure_contract_row() {
  ensure_dirs
  if [[ -f "$CONTRACT_LEDGER" ]] && grep -q '"primitive":"peer-orch-freeze-monitor"' "$CONTRACT_LEDGER"; then
    return 0
  fi
  append_jsonl "$CONTRACT_LEDGER" "$(contract_row)"
}

topology_rows() {
  if [[ ! -f "$TOPOLOGY" ]]; then
    jq -n '[]'
    return 0
  fi
  jq -s -c '
    [ .[]
      | select(type=="object")
      | select((.session // "") != "")
    ]
    | sort_by(.session)
    | group_by(.session)
    | map(sort_by(.effective_at // .ts // "") | last)
    | sort_by(.session)
  ' "$TOPOLOGY"
}

targets_json() {
  topology_rows | jq -c \
    --arg session_filter "$TARGET_SESSION_FILTER" \
    --arg pane_filter "$TARGET_PANE_FILTER" '
    [ .[]
      | select((.orchestrator_pane // null) != null)
      | {
          session:(.session|tostring),
          pane:(.orchestrator_pane|tostring),
          human_pane:(.human_pane // null),
          callback_pane:(.callback_pane // null),
          effective_at:(.effective_at // .ts // null)
        }
      | select($session_filter == "" or .session == $session_filter)
      | select($pane_filter == "" or .pane == $pane_filter)
    ]'
}

fixture_path() {
  local session="$1"
  local pane="$2"
  if [[ -n "$FIXTURE_DIR" && -f "$FIXTURE_DIR/$session-$pane.json" ]]; then
    printf '%s/%s-%s.json\n' "$FIXTURE_DIR" "$session" "$pane"
  fi
}

run_mk303() {
  local session="$1"
  local pane="$2"
  local fixture="${3:-}"
  local output rc
  if [[ -n "$fixture" ]]; then
    set +e
    output="$("$MK303" --fixture "$fixture" --json 2>/dev/null)"
    rc=$?
    set -e
  else
    set +e
    output="$("$MK303" --session "$session" --pane "$pane" --window-sec "$WINDOW_SEC" --json 2>/dev/null)"
    rc=$?
    set -e
  fi
  if jq -e . >/dev/null 2>&1 <<<"$output"; then
    jq -c --argjson rc "$rc" '. + {detector_exit_code:$rc}' <<<"$output"
  else
    jq -n -c --argjson rc "$rc" --arg err "mk303 emitted non-json output" \
      '{schema_version:"codex-template-stuck-detector.error",status:"error",subclass:"detector_error",detector_exit_code:$rc,error:$err}'
  fi
}

run_permit_gate() {
  local session="$1"
  local pane="$2"
  local fixture="${3:-}"
  local mode="--dry-run"
  (( APPLY )) && mode="--apply"
  local tmp1="" tmp2="" output rc
  local -a env_args
  env_args=(
    "PEER_ORCH_RECOVERY_TOPOLOGY=$TOPOLOGY"
    "PEER_ORCH_RECOVERY_LEDGER=${PEER_ORCH_RECOVERY_LEDGER:-$STATE_DIR/peer-orch-recovery.jsonl}"
    "PEER_ORCH_RECOVERY_CONTRACT_LEDGER=$CONTRACT_LEDGER"
    "PEER_ORCH_RECOVERY_JSONL_APPEND_LIB=$JSONL_APPEND_LIB"
    "PEER_ORCH_RECOVERY_ACTOR_SESSION=$ACTOR_SESSION"
    "PEER_ORCH_RECOVERY_ACTOR_PANE=$ACTOR_PANE"
    "PEER_ORCH_RECOVERY_REASON=peer-orch-freeze-monitor $session:$pane"
  )
  if [[ -n "$fixture" ]]; then
    tmp1="$(mktemp)"
    tmp2="$(mktemp)"
    jq -r '.t0 // ""' "$fixture" > "$tmp1"
    jq -r '.t1 // ""' "$fixture" > "$tmp2"
    env_args+=(
      "PEER_ORCH_RECOVERY_SAMPLE1_FILE=$tmp1"
      "PEER_ORCH_RECOVERY_SAMPLE2_FILE=$tmp2"
      "PEER_ORCH_RECOVERY_HASH_WINDOW_SEC=0"
    )
  fi
  set +e
  output="$(env "${env_args[@]}" "$PERMIT_GATE" --target-session "$session" --target-pane "$pane" "$mode" --json 2>/dev/null)"
  rc=$?
  set -e
  [[ -n "$tmp1" ]] && rm -f "$tmp1"
  [[ -n "$tmp2" ]] && rm -f "$tmp2"
  if jq -e . >/dev/null 2>&1 <<<"$output"; then
    jq -c --argjson rc "$rc" '. + {permit_gate_exit_code:$rc}' <<<"$output"
  else
    jq -n -c --argjson rc "$rc" --arg err "permit gate emitted non-json output" \
      '{schema_version:"peer-orch-respawn-permit.error",decision:"refuse",reason:"permit_gate_error",permit_gate_exit_code:$rc,error:$err}'
  fi
}

run_respawn() {
  local session="$1"
  local pane="$2"
  if [[ -n "$RESPAWN_CMD" ]]; then
    "$RESPAWN_CMD" "$session" "$pane"
  else
    "$NTM_BIN" respawn "$session" --panes="$pane" --force
  fi
}

result_self_refuse() {
  local session="$1"
  local pane="$2"
  jq -n -c \
    --arg session "$session" \
    --arg pane "$pane" \
    '{session:$session,pane:$pane,detection_status:"skipped_self_orch",stuck:false,permit_invoked:false,permit_decision:"refuse",decision_reason:"self_orch_respawn_refused",recovery_applied:false,auto_respawn_enabled:false}'
}

result_alive() {
  local session="$1"
  local pane="$2"
  local detection="$3"
  jq -n -c \
    --arg session "$session" \
    --arg pane "$pane" \
    --argjson detection "$detection" \
    '{
      session:$session,
      pane:$pane,
      detection_status:($detection.status // "unknown"),
      detector_subclass:($detection.subclass // null),
      stuck:false,
      permit_invoked:false,
      recovery_applied:false,
      auto_respawn_enabled:false
    }'
}

result_stuck() {
  local session="$1"
  local pane="$2"
  local detection="$3"
  local fixture="$4"
  local permit
  permit="$(run_permit_gate "$session" "$pane" "$fixture")"
  local decision reason freeze_confirmed recovery_applied recovery_rc recovery_blocked mttr post_live
  decision="$(jq -r '.decision // "refuse"' <<<"$permit")"
  reason="$(jq -r '.decision_reason // .reason // "unknown"' <<<"$permit")"
  freeze_confirmed="$(jq -r 'if .freeze_confirmed == true then "true" else "false" end' <<<"$permit")"
  recovery_applied=false
  recovery_rc=null
  recovery_blocked=""
  mttr=null
  post_live=false
  if [[ "$decision" == "permit" ]]; then
    if [[ "$AUTO_RESPAWN" == "1" && "$APPLY" == "1" ]]; then
      set +e
      run_respawn "$session" "$pane"
      recovery_rc=$?
      set -e
      if [[ "$recovery_rc" == "0" ]]; then
        recovery_applied=true
        post_live=true
        mttr=0
      else
        recovery_blocked="respawn_command_failed"
      fi
    else
      recovery_blocked="auto_respawn_disabled"
    fi
  else
    recovery_blocked="permit_gate_refused"
  fi
  jq -n -c \
    --arg session "$session" \
    --arg pane "$pane" \
    --argjson detection "$detection" \
    --argjson permit "$permit" \
    --arg decision "$decision" \
    --arg reason "$reason" \
    --arg recovery_applied "$recovery_applied" \
    --argjson recovery_rc "$recovery_rc" \
    --arg recovery_blocked "$recovery_blocked" \
    --argjson mttr "$mttr" \
    --arg post_live "$post_live" \
    --arg freeze_confirmed "$freeze_confirmed" \
    --arg auto_respawn "$AUTO_RESPAWN" \
    '{
      session:$session,
      pane:$pane,
      detection_status:($detection.status // "unknown"),
      detector_subclass:($detection.subclass // null),
      stuck:true,
      permit_invoked:true,
      permit_decision:$decision,
      permit_reason:$reason,
      permit_gate:$permit,
      freeze_confirmed:($freeze_confirmed == "true"),
      auto_respawn_enabled:($auto_respawn == "1"),
      recovery_applied:($recovery_applied == "true"),
      recovery_rc:$recovery_rc,
      recovery_blocked_reason:(if $recovery_blocked == "" then null else $recovery_blocked end),
      mttr_seconds:$mttr,
      post_recovery_live:($post_live == "true")
    }'
}

cycle_command() {
  ensure_contract_row
  local ts results_tmp targets count payload
  ts="$(now_iso)"
  if [[ -e "$FATAL_FILE" ]]; then
    payload="$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --arg fatal "$FATAL_FILE" '{schema_version:$schema_version,status:"fatal",ts:$ts,fatal_file:$fatal,summary:"peer-orch-freeze-monitor fatal sentinel present"}')"
    emit "$payload" 2
    return
  fi
  if [[ -e "$STOP_FILE" ]]; then
    payload="$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --arg stop "$STOP_FILE" '{schema_version:$schema_version,status:"stopped",ts:$ts,stop_file:$stop,summary:"peer-orch-freeze-monitor stop sentinel present"}')"
    emit "$payload" 0
    return
  fi
  results_tmp="$(mktemp)"
  targets="$(targets_json)"
  count="$(jq 'length' <<<"$targets")"
  if [[ "$count" == "0" ]]; then
    jq -n -c --arg status "no_targets" --arg ts "$ts" '{session:null,pane:null,detection_status:$status,stuck:false,permit_invoked:false,recovery_applied:false,ts:$ts}' > "$results_tmp"
  else
    while IFS= read -r target; do
      local session pane fixture detection status result
      session="$(jq -r '.session' <<<"$target")"
      pane="$(jq -r '.pane' <<<"$target")"
      if [[ "$session" == "$ACTOR_SESSION" && "$pane" == "$ACTOR_PANE" ]]; then
        result="$(result_self_refuse "$session" "$pane")"
        printf '%s\n' "$result" >> "$results_tmp"
        continue
      fi
      fixture="$(fixture_path "$session" "$pane")"
      detection="$(run_mk303 "$session" "$pane" "$fixture")"
      status="$(jq -r '.status // "unknown"' <<<"$detection")"
      if [[ "$status" == "stuck" ]]; then
        result="$(result_stuck "$session" "$pane" "$detection" "$fixture")"
      else
        result="$(result_alive "$session" "$pane" "$detection")"
      fi
      printf '%s\n' "$result" >> "$results_tmp"
    done < <(jq -c '.[]' <<<"$targets")
  fi

  payload="$(jq -s \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ledger_schema_version "$LEDGER_SCHEMA_VERSION" \
    --arg ts "$ts" \
    --argjson apply "$APPLY" \
    --argjson auto_respawn "$(if [[ "$AUTO_RESPAWN" == "1" ]]; then echo true; else echo false; fi)" \
    '{
      schema_version:$schema_version,
      ledger_schema_version:$ledger_schema_version,
      primitive:"peer-orch-freeze-monitor",
      status:"ok",
      ts:$ts,
      apply:$apply,
      auto_respawn_enabled:$auto_respawn,
      target_results:.,
      targets_observed:length,
      stuck_count:([.[] | select(.stuck == true)] | length),
      permit_gate_invocations:([.[] | select(.permit_invoked == true)] | length),
      permit_gate_refusals_count:([.[] | select(.permit_invoked == true and .permit_decision != "permit")] | length),
      recoveries_count:([.[] | select(.recovery_applied == true)] | length),
      false_recovery_count:([.[] | select(.recovery_applied == true and ((.post_recovery_live != true) or (.freeze_confirmed != true)))] | length),
      summary:"peer-orch-freeze-monitor cycle completed"
    }' "$results_tmp")"
  rm -f "$results_tmp"
  if (( APPLY )); then
    append_jsonl "$LEDGER" "$payload"
  fi
  emit "$payload" 0
}

ledger_rows_array() {
  if [[ -f "$LEDGER" ]]; then
    jq -s '[.[] | select(type=="object")]' "$LEDGER"
  else
    jq -n '[]'
  fi
}

doctor_payload() {
  local ts rows
  ts="$(now_iso)"
  rows="$(ledger_rows_array)"
  jq -n \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$ts" \
    --argjson rows "$rows" \
    --arg interval "$INTERVAL_SEC" '
    def epoch($s):
      try ($s | fromdateiso8601) catch null;
    def p95:
      sort as $s
      | if ($s|length) == 0 then null
        else $s[((($s|length) * 95 / 100)|ceil) - 1]
        end;
    ($ts | fromdateiso8601) as $now_epoch
    | ($interval|tonumber) as $interval_num
    | ($rows | map(select(.primitive == "peer-orch-freeze-monitor" and (.target_results // null) != null))) as $cycles
    | ($cycles | map(.ts) | map(select(. != null)) | max // null) as $last_fire
    | (if $last_fire then epoch($last_fire) else null end) as $last_epoch
    | ($cycles
        | map(select((epoch(.ts) // 0) >= ($now_epoch - 86400)))
      ) as $recent
    | ([$recent[]?.target_results[]? | select(.recovery_applied == true) | .mttr_seconds? | select(. != null)] | p95) as $mttr_p95
    | ([$recent[]?.target_results[]? | select(.recovery_applied == true)] | length) as $recoveries_24h
    | ([$recent[]?.target_results[]? | select(.permit_invoked == true and .permit_decision != "permit")] | length) as $permit_refusals_24h
    | ([$recent[]?.target_results[]? | select(.recovery_applied == true and ((.post_recovery_live != true) or (.freeze_confirmed != true)))] | length) as $false_24h
    | (if $last_epoch == null then false else (($now_epoch - $last_epoch) <= ($interval_num * 2)) end) as $alive
    | {
        schema_version:$schema_version,
        primitive:"peer-orch-freeze-monitor",
        status:(if $false_24h > 0 then "fail" elif $alive then "pass" else "warn" end),
        ts:$ts,
        monitor_last_fire_ts:$last_fire,
        mttr_p95_seconds:$mttr_p95,
        false_recovery_count_24h:$false_24h,
        permit_gate_refusals_24h:$permit_refusals_24h,
        recoveries_24h:$recoveries_24h,
        monitor_alive:$alive,
        monitor_interval_seconds:$interval_num,
        ledger_rows:($cycles|length),
        warnings:(
          []
          + (if $last_fire == null then ["monitor_never_fired"] else [] end)
          + (if ($last_fire != null and ($alive|not)) then ["monitor_stale"] else [] end)
          + (if $false_24h > 0 then ["false_recovery_count_nonzero"] else [] end)
        ),
        summary:"peer-orch-freeze-monitor doctor complete"
      }'
}

log_stale_fuckup_if_needed() {
  local payload="$1"
  local status warnings ts
  status="$(jq -r '.status' <<<"$payload")"
  warnings="$(jq -c '.warnings' <<<"$payload")"
  ts="$(now_iso)"
  if [[ "$status" != "pass" ]]; then
    append_jsonl "$FUCKUP_LOG" "$(jq -n \
      --arg ts "$ts" \
      --arg class "peer-orch-monitor-stale" \
      --arg severity "medium" \
      --arg bead "flywheel-3e5c7" \
      --argjson warnings "$warnings" \
      '{ts:$ts,class:$class,severity:$severity,bead:$bead,source:"peer-orch-freeze-monitor",warnings:$warnings,what_happened:"peer orchestrator freeze monitor doctor reported non-pass liveness",should_become:"L117-doctrine"}')"
  fi
}

doctor_command() {
  ensure_contract_row
  local payload
  payload="$(doctor_payload)"
  if (( APPLY )); then
    log_stale_fuckup_if_needed "$payload"
  fi
  emit "$payload" 0
}

repair_command() {
  ensure_contract_row
  local ts actions
  ts="$(now_iso)"
  actions='["ensure_directories","ensure_contract_self_row"]'
  if [[ "$SCOPE" == "launchd" || "$SCOPE" == "all" ]]; then
    if (( APPLY )); then
      write_plist >/dev/null
      actions="$(jq -c '. + ["write_disabled_plist"]' <<<"$actions")"
    else
      actions="$(jq -c '. + ["would_write_disabled_plist"]' <<<"$actions")"
    fi
  fi
  emit "$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --argjson actions "$actions" --arg scope "$SCOPE" --argjson apply "$APPLY" '{schema_version:$schema_version,status:"ok",ts:$ts,scope:$scope,apply:$apply,actions:$actions,summary:"peer-orch-freeze-monitor repair complete"}')" 0
}

validate_command() {
  local ts status errors
  ts="$(now_iso)"
  errors='[]'
  status="pass"
  if [[ "$SCOPE" == "plist" || "$SCOPE" == "launchd" ]]; then
    if [[ ! -f "$PLIST_PATH" ]]; then
      status="fail"
      errors="$(jq -c '. + ["plist_missing"]' <<<"$errors")"
    elif ! grep -q '<key>Disabled</key>' "$PLIST_PATH" || ! grep -q '<true/>' "$PLIST_PATH"; then
      status="fail"
      errors="$(jq -c '. + ["plist_not_disabled_by_default"]' <<<"$errors")"
    fi
  elif [[ "$SCOPE" == "ledger" ]]; then
    if [[ -f "$LEDGER" ]] && ! jq -e . >/dev/null 2>&1 < "$LEDGER"; then
      status="fail"
      errors="$(jq -c '. + ["ledger_invalid_jsonl"]' <<<"$errors")"
    fi
  else
    "$0" validate --scope ledger --json >/dev/null
  fi
  emit "$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg scope "$SCOPE" --argjson errors "$errors" '{schema_version:$schema_version,status:$status,ts:$ts,scope:$scope,errors:$errors,summary:"peer-orch-freeze-monitor validate complete"}')" 0
}

audit_command() {
  local rows ts
  ts="$(now_iso)"
  rows="$(ledger_rows_array | jq '.[-20:]')"
  emit "$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --argjson rows "$rows" '{schema_version:$schema_version,status:"ok",ts:$ts,rows:$rows,summary:"peer-orch-freeze-monitor audit complete"}')" 0
}

why_command() {
  emit "$(jq -n --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,status:"ok",why:"L117 requires a peer orchestrator freeze monitor that reuses mk303 classification, calls L115 before recovery, exposes liveness metrics, and keeps auto-respawn disabled unless explicitly env-gated.",bead:"flywheel-3e5c7",rules:["L115","L116","L117"],summary:"peer-orch-freeze-monitor why complete"}')" 0
}

schema_command() {
  emit "$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ledger_schema_version "$LEDGER_SCHEMA_VERSION" --arg contract_schema_version "$CONTRACT_SCHEMA_VERSION" '{schema_version:$schema_version,status:"ok",schemas:{doctor:["monitor_last_fire_ts","mttr_p95_seconds","false_recovery_count_24h","permit_gate_refusals_24h","recoveries_24h","monitor_alive"],ledger_schema_version:$ledger_schema_version,contract_schema_version:$contract_schema_version},summary:"peer-orch-freeze-monitor schema complete"}')" 0
}

write_plist() {
  ensure_dirs
  cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>ai.zeststream.peer-orch-freeze-monitor</string>
  <key>Disabled</key>
  <true/>
  <key>ProgramArguments</key>
  <array>
    <string>$SCRIPT_DIR/peer-orch-freeze-monitor.sh</string>
    <string>cycle</string>
    <string>--apply</string>
    <string>--json</string>
  </array>
  <key>StartInterval</key>
  <integer>$INTERVAL_SEC</integer>
  <key>RunAtLoad</key>
  <false/>
  <key>StandardOutPath</key>
  <string>$STATE_DIR/peer-orch-freeze-monitor.out.log</string>
  <key>StandardErrorPath</key>
  <string>$STATE_DIR/peer-orch-freeze-monitor.err.log</string>
</dict>
</plist>
EOF
}

install_command() {
  local ts
  ts="$(now_iso)"
  if (( APPLY )); then
    write_plist
  fi
  emit "$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --arg plist "$PLIST_PATH" --argjson apply "$APPLY" '{schema_version:$schema_version,status:"ok",ts:$ts,apply:$apply,plist:$plist,disabled_by_default:true,launchctl_mutated:false,summary:"peer-orch-freeze-monitor install surface complete"}')" 0
}

uninstall_command() {
  local ts removed=false
  ts="$(now_iso)"
  if (( APPLY )) && [[ -f "$PLIST_PATH" ]]; then
    rm -f "$PLIST_PATH"
    removed=true
  fi
  emit "$(jq -n --arg schema_version "$SCHEMA_VERSION" --arg ts "$ts" --arg plist "$PLIST_PATH" --argjson apply "$APPLY" --arg removed "$removed" '{schema_version:$schema_version,status:"ok",ts:$ts,apply:$apply,plist:$plist,removed:($removed=="true"),launchctl_mutated:false,summary:"peer-orch-freeze-monitor uninstall surface complete"}')" 0
}

print_info_text() {
  if (( JSON_OUT )); then
    info
  else
    info | jq -r '"\(.primitive) \(.version)\nledger=\(.ledger)\nmk303=\(.mk303)\npermit_gate=\(.permit_gate)"'
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      cycle|doctor|health|repair|validate|audit|why|schema|install|uninstall|quickstart|completion|help)
        MODE="$1"
        shift
        ;;
      --doctor)
        MODE="doctor"
        shift
        ;;
      --health)
        MODE="health"
        shift
        ;;
      --apply)
        APPLY=1
        shift
        ;;
      --dry-run)
        APPLY=0
        shift
        ;;
      --json)
        JSON_OUT=1
        shift
        ;;
      --scope)
        SCOPE="${2:?missing --scope value}"
        shift 2
        ;;
      --session)
        TARGET_SESSION_FILTER="${2:?missing --session value}"
        shift 2
        ;;
      --pane)
        TARGET_PANE_FILTER="${2:?missing --pane value}"
        shift 2
        ;;
      --repo)
        REPO_ROOT="${2:?missing --repo value}"
        SCRIPT_DIR="$REPO_ROOT/.flywheel/scripts"
        shift 2
        ;;
      --info)
        MODE="info"
        shift
        ;;
      --examples)
        MODE="examples"
        shift
        ;;
      -h|--help)
        MODE="help"
        shift
        ;;
      *)
        printf 'unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  case "$MODE" in
    cycle) cycle_command ;;
    doctor|health) doctor_command ;;
    repair) repair_command ;;
    validate) validate_command ;;
    audit) audit_command ;;
    why) why_command ;;
    schema) schema_command ;;
    install) install_command ;;
    uninstall) uninstall_command ;;
    info) print_info_text ;;
    examples) examples ;;
    quickstart) quickstart ;;
    completion) completion ;;
    help) usage ;;
    *) usage >&2; exit 2 ;;
  esac
}

main "$@"
