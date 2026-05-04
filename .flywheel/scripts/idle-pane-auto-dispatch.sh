#!/usr/bin/env bash
set -euo pipefail

VERSION="idle-pane-auto-dispatch/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
PROBE="${FLYWHEEL_IDLE_STATE_PROBE:-$ROOT/.flywheel/scripts/idle-state-probe.sh}"
STALE_PING="${FLYWHEEL_STALE_ERROR_AUTO_PING:-$ROOT/.flywheel/scripts/stale-error-auto-ping.sh}"
STALL_ALERT="${FLYWHEEL_WORKER_STALL_ALERT_PROBE:-$ROOT/.flywheel/scripts/worker-stall-alert-probe.sh}"
TOPOLOGY="${FLYWHEEL_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
LOOP_STATE_DIR="${FLYWHEEL_LOOP_STATE_DIR:-$HOME/.flywheel/loops}"
SESSION="flywheel"
REPO=""
JSON_OUT=0
APPLY=0
DRY_RUN=1
FORCE=0
NOW_EPOCH="${FLYWHEEL_IDLE_WATCHER_NOW_EPOCH:-$(date +%s)}"
PANE_COOLDOWN_SECONDS=180
BEAD_DEDUPE_SECONDS=600
STATE_DIR=""

usage() {
  cat <<'USAGE'
Usage:
  idle-pane-auto-dispatch.sh --session NAME [--repo PATH] [--dry-run|--apply] [--json]
  idle-pane-auto-dispatch.sh --info [--json]
  idle-pane-auto-dispatch.sh --examples [--json]
  idle-pane-auto-dispatch.sh --schema [--json]
  idle-pane-auto-dispatch.sh --help

Promotes a single ready bead into one live idle worker pane. Default is dry-run.
The dispatch gate requires idle_state_class=="dispatching",
capture_provenance=="live", and state=="WAITING".
USAGE
}

session_repo() {
  case "$1" in
    flywheel) printf '%s\n' "/Users/josh/Developer/flywheel" ;;
    alpsinsurance|alps) printf '%s\n' "/Users/josh/Developer/alpsinsurance" ;;
    skillos) printf '%s\n' "/Users/josh/Developer/skillos" ;;
    mobile-eats) printf '%s\n' "/Users/josh/Developer/mobile-eats" ;;
    vrtx) printf '%s\n' "/Users/josh/Developer/vrtx" ;;
    *) printf '%s\n' "" ;;
  esac
}

safe_name() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_'
}

json_bool() {
  if [[ "$1" -eq 1 ]]; then printf 'true'; else printf 'false'; fi
}

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg version "$VERSION" --arg ntm "$NTM_BIN" --arg probe "$PROBE" '{
      schema_version:$version,
      command:"idle-pane-auto-dispatch.sh",
      mutation_default:"dry-run",
      ntm:$ntm,
      idle_state_probe:$probe,
      canonical_flags:["--help","--info","--examples","--schema","--dry-run","--apply","--json","--session","--repo"],
      required_gate:["idle_state_class==\"dispatching\"","capture_provenance==\"live\"","state==\"WAITING\""],
      receipt:"dispatch-delivery-receipt/v1",
      leverage_points:["#2 information flows","#4 self-organization","#6 rules"]
    }'
  else
    printf '%s\n' "$VERSION"
    printf 'mutation_default=dry-run\n'
    printf 'required_gate=idle_state_class=="dispatching",capture_provenance=="live",state=="WAITING"\n'
  fi
}

emit_examples() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc '{
      examples:[
        "idle-pane-auto-dispatch.sh --session flywheel --dry-run --json",
        "idle-pane-auto-dispatch.sh --session skillos --repo /Users/josh/Developer/skillos --apply --json",
        "idle-pane-auto-dispatch.sh --schema --json"
      ]
    }'
  else
    printf '%s\n' \
      "idle-pane-auto-dispatch.sh --session flywheel --dry-run --json" \
      "idle-pane-auto-dispatch.sh --session skillos --repo /Users/josh/Developer/skillos --apply --json" \
      "idle-pane-auto-dispatch.sh --schema --json"
  fi
}

emit_schema() {
  jq -nc --arg version "$VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",
    title:"idle-pane-auto-dispatch result",
    type:"object",
    required:["schema_version","session","repo","dry_run","apply","status","probe","delivery_receipt"],
    properties:{
      schema_version:{const:$version},
      session:{type:"string"},
      repo:{type:"string"},
      dry_run:{type:"boolean"},
      apply:{type:"boolean"},
      status:{type:"string"},
      candidate:{type:["object","null"]},
      dispatch_file:{type:["string","null"]},
      delivery_receipt:{type:"object"},
      stale_error_auto_ping:{type:"object"},
      worker_stall_alerts:{type:"object"}
    }
  }'
}

latest_topology_json() {
  if [[ ! -s "$TOPOLOGY" ]]; then
    jq -nc --arg session "$SESSION" '{session:$session,worker_panes:[],orchestrator_pane:null,callback_pane:null,human_pane:null,source:"missing"}'
    return 0
  fi
  jq -sc --arg session "$SESSION" '
    map(select(.session == $session))
    | sort_by(.effective_at // "")
    | last // {session:$session}
    | {
        session:($session),
        worker_panes:(.worker_panes // []),
        worker_kinds:(.worker_kinds // {}),
        orchestrator_pane:(.orchestrator_pane // null),
        callback_pane:(.callback_pane // .orchestrator_pane // null),
        human_pane:(.human_pane // null),
        effective_at:(.effective_at // null),
        source:"session-topology"
      }
  ' "$TOPOLOGY" 2>/dev/null || jq -nc --arg session "$SESSION" '{session:$session,worker_panes:[],orchestrator_pane:null,callback_pane:null,human_pane:null,source:"invalid"}'
}

worker_panes_csv() {
  jq -r '
    if ((.worker_panes // []) | length) > 0 then
      (.worker_panes | map(tostring) | join(","))
    else "2,3,4" end
  ' <<<"$1"
}

stale_error_auto_ping_json() {
  local topology="$1" panes mode output
  if [[ ! -x "$STALE_PING" ]]; then
    jq -nc --arg path "$STALE_PING" '{schema_version:"stale-error-auto-ping.v1",status:"missing",path:$path,stale_error_candidate_count:0,send_count:0}'
    return 0
  fi
  panes="$(worker_panes_csv "$topology")"
  if [[ "$APPLY" -eq 1 ]]; then mode="--apply"; else mode="--dry-run"; fi
  output="$("$STALE_PING" --session "$SESSION" --panes "$panes" "$mode" --json 2>/dev/null || true)"
  if jq -e . >/dev/null 2>&1 <<<"$output"; then
    jq -c . <<<"$output"
  else
    jq -nc '{schema_version:"stale-error-auto-ping.v1",status:"invalid_json",stale_error_candidate_count:0,send_count:0}'
  fi
}

worker_stall_alert_json() {
  local mode output
  if [[ ! -x "$STALL_ALERT" ]]; then
    jq -nc --arg path "$STALL_ALERT" '{schema_version:"worker-stall-alert-probe/v1",status:"missing",path:$path,worker_stall_candidate_count:0,alerts_sent_count:0,receipts:[]}'
    return 0
  fi
  if [[ "$APPLY" -eq 1 ]]; then mode="--apply"; else mode="--dry-run"; fi
  output="$("$STALL_ALERT" --session "$SESSION" --repo "$REPO" --state-dir "$STATE_DIR/stalls" "$mode" --json 2>/dev/null || true)"
  if jq -e . >/dev/null 2>&1 <<<"$output"; then
    jq -c . <<<"$output"
  else
    jq -nc '{schema_version:"worker-stall-alert-probe/v1",status:"invalid_json",worker_stall_candidate_count:0,alerts_sent_count:0,receipts:[]}'
  fi
}

probe_json() {
  "$PROBE" \
    --session "$SESSION" \
    --repo "$REPO" \
    --json \
    --now-epoch "$NOW_EPOCH" \
    --pane-last-fired "$STATE_DIR/pane-last-fired" \
    --bead-fired "$STATE_DIR/bead-fired"
}

select_candidate_json() {
  local probe="$1" topology="$2"
  jq -c --argjson topology "$topology" '
    def forbidden:
      [$topology.orchestrator_pane, $topology.callback_pane, $topology.human_pane]
      | map(select(. != null) | tostring);
    def worker_allowed($pane):
      if (($topology.worker_panes // []) | length) == 0 then true
      else (($topology.worker_panes // []) | map(tostring) | index(($pane | tostring))) != null end;
    [
      (.idle_state_class // [])[]
      | select(.idle_state_class == "dispatching")
      | select(.capture_provenance == "live")
      | select(.state == "WAITING")
      | select(.dispatch_candidate != null)
      | select(worker_allowed(.pane))
      | select((.pane | tostring) as $p | (forbidden | index($p)) == null)
    ]
    | sort_by([(.dispatch_priority // 99), (.pane // 99)])
    | .[0] // null
  ' <<<"$probe"
}

write_dispatch_file() {
  local task_id="$1" bead="$2" pane="$3" priority="$4" callback_pane="$5" file="$6"
  umask 077
  {
    printf 'Read this dispatch and execute it as /flywheel:worker-tick parity.\n\n'
    printf 'task_id=%s\n' "$task_id"
    printf 'session=%s\n' "$SESSION"
    printf 'repo=%s\n' "$REPO"
    printf 'target_pane=%s\n' "$pane"
    printf 'bead_id=%s\n' "$bead"
    printf 'priority=%s\n' "$priority"
    printf 'callback_to=%s:%s\n\n' "$SESSION" "$callback_pane"
    printf 'MANDATORY PRE-FLIGHT:\n'
    printf '1. Resolve your Agent Mail identity from the durable registry; no raw tokens in pane text.\n'
    printf '2. Run socraticode survey before edits and report socraticode_queries/indexed_chunks_observed.\n'
    printf '3. Reserve files through Agent Mail before edits and release them on DONE/BLOCKED.\n'
    printf '4. Use br show %s, inspect acceptance criteria, and do only the bounded bead work.\n\n' "$bead"
    printf 'CALLBACK CONTRACT:\n'
    printf 'DONE %s output=/tmp/%s-output.md bead_id=%s socraticode_queries=N indexed_chunks_observed=N files_reserved=... files_released=... beads_updated=... no_bead_reason=... fuckups_logged=...\n' "$task_id" "$task_id" "$bead"
    printf 'If BLOCKED, include probe ledger, skills_consulted, fuckups_logged, and the exact non-Joshua next action.\n'
  } >"$file"
}

append_cooldowns() {
  local pane="$1" bead="$2"
  mkdir -p "$STATE_DIR"
  printf '%s:%s\n' "$pane" "$NOW_EPOCH" >>"$STATE_DIR/pane-last-fired"
  printf '%s:%s\n' "$bead" "$NOW_EPOCH" >>"$STATE_DIR/bead-fired"
}

append_dispatch_log() {
  local row="$1"
  mkdir -p "$REPO/.flywheel"
  printf '%s\n' "$row" >>"$REPO/.flywheel/dispatch-log.jsonl"
}

delivery_receipt_json() {
  local pane="$1" task_id="$2" dispatch_file="$3" send_rc="$4" send_stdout="$5" send_stderr="$6"
  local tail_json activity_json pane_state prompt_visible work_started prompt_submitted source_health
  tail_json="$("$NTM_BIN" --robot-tail="$SESSION" --panes="$pane" --lines=80 2>/dev/null || printf '{"success":false,"panes":[]}')"
  activity_json="$("$NTM_BIN" "--robot-activity=$SESSION" --activity-type=codex,claude 2>/dev/null || printf '{"agents":[]}')"
  prompt_visible="$(jq -r --arg task "$task_id" --arg file "$dispatch_file" '
    [(.panes // [])[] | (.text // .content // .capture // .output // "" | tostring)]
    | any(test($task) or test($file))
  ' <<<"$tail_json" 2>/dev/null || printf false)"
  pane_state="$(jq -r --arg pane "$pane" '
    [(.agents // [])[] | select(((.pane_idx // .pane) | tostring) == $pane) | .state][0] // "UNKNOWN"
  ' <<<"$activity_json" 2>/dev/null || printf UNKNOWN)"
  source_health="$(jq -c '.source_health // {}' <<<"$tail_json" 2>/dev/null || printf '{}')"
  if [[ "$prompt_visible" == "true" ]]; then prompt_submitted=true; else prompt_submitted=false; fi
  if [[ "$pane_state" != "WAITING" && "$pane_state" != "UNKNOWN" ]]; then work_started=true; else work_started=false; fi
  jq -nc \
    --arg schema_version "dispatch-delivery-receipt/v1" \
    --arg session "$SESSION" \
    --argjson pane "$pane" \
    --arg task_id "$task_id" \
    --arg dispatch_file "$dispatch_file" \
    --arg pane_state "$pane_state" \
    --arg send_stdout "$send_stdout" \
    --arg send_stderr "$send_stderr" \
    --argjson send_rc "$send_rc" \
    --argjson transport_accepted "$([[ "$send_rc" -eq 0 ]] && printf true || printf false)" \
    --argjson prompt_visible_in_target "$prompt_visible" \
    --argjson prompt_submitted "$prompt_submitted" \
    --argjson work_started "$work_started" \
    --argjson source_health "$source_health" \
    '{
      schema_version:$schema_version,
      session:$session,
      pane:$pane,
      task_id:$task_id,
      dispatch_file:$dispatch_file,
      transport_accepted:$transport_accepted,
      prompt_visible_in_target:$prompt_visible_in_target,
      prompt_submitted:$prompt_submitted,
      work_started:$work_started,
      pane_state_after_send:$pane_state,
      ntm_send_exit_code:$send_rc,
      ntm_send_stdout:$send_stdout,
      ntm_send_stderr:$send_stderr,
      source_health:$source_health
    }'
}

run_dispatch() {
  local topology stale stalls probe candidate candidate_count dry_bool apply_bool status reason
  local pane bead priority callback_pane task_id dispatch_file send_out send_err send_rc delivery log_row

  REPO="${REPO:-$(session_repo "$SESSION")}"
  [[ -n "$REPO" ]] || { printf 'ERR: unknown session repo for %s; pass --repo\n' "$SESSION" >&2; exit 64; }
  [[ -x "$PROBE" ]] || { printf 'ERR: idle-state probe missing or not executable: %s\n' "$PROBE" >&2; exit 66; }
  STATE_DIR="${STATE_DIR:-$HOME/.local/state/flywheel/idle-pane-auto-dispatch/$(safe_name "$SESSION")}"
  mkdir -p "$STATE_DIR"

  topology="$(latest_topology_json)"
  stale="$(stale_error_auto_ping_json "$topology")"
  stalls="$(worker_stall_alert_json)"
  probe="$(probe_json)"
  candidate="$(select_candidate_json "$probe" "$topology")"
  candidate_count="$(jq -r --argjson topology "$topology" '
    def forbidden:
      [$topology.orchestrator_pane, $topology.callback_pane, $topology.human_pane]
      | map(select(. != null) | tostring);
    def worker_allowed($pane):
      if (($topology.worker_panes // []) | length) == 0 then true
      else (($topology.worker_panes // []) | map(tostring) | index(($pane | tostring))) != null end;
    [(.idle_state_class // [])[]
      | select(.idle_state_class == "dispatching")
      | select(.capture_provenance == "live")
      | select(.state == "WAITING")
      | select(.dispatch_candidate != null)
      | select(worker_allowed(.pane))
      | select((.pane | tostring) as $p | (forbidden | index($p)) == null)
    ] | length
  ' <<<"$probe")"

  dry_bool="$(json_bool "$DRY_RUN")"
  apply_bool="$(json_bool "$APPLY")"
  if [[ "$candidate" == "null" ]]; then
    status="no_candidate"
    reason="no topology-allowed live WAITING pane with idle_state_class dispatching"
    jq -nc \
      --arg schema_version "$VERSION" \
      --arg session "$SESSION" \
      --arg repo "$REPO" \
      --arg status "$status" \
      --arg reason "$reason" \
      --argjson dry_run "$dry_bool" \
      --argjson apply "$apply_bool" \
      --argjson topology "$topology" \
      --argjson stale_error_auto_ping "$stale" \
      --argjson worker_stall_alerts "$stalls" \
      --argjson probe "$probe" \
      --argjson candidate_count "$candidate_count" \
      '{schema_version:$schema_version,session:$session,repo:$repo,dry_run:$dry_run,apply:$apply,status:$status,reason:$reason,topology:$topology,stale_error_auto_ping:$stale_error_auto_ping,worker_stall_alerts:$worker_stall_alerts,probe:$probe,candidate_count:$candidate_count,candidate:null,dispatch_file:null,delivery_receipt:{schema_version:"dispatch-delivery-receipt/v1",transport_accepted:false,prompt_visible_in_target:false,prompt_submitted:false,work_started:false,skipped:true}}'
    return 0
  fi

  pane="$(jq -r '.pane' <<<"$candidate")"
  bead="$(jq -r '.dispatch_candidate' <<<"$candidate")"
  priority="$(jq -r '.dispatch_priority // "null"' <<<"$candidate")"
  callback_pane="$(jq -r '.callback_pane // .orchestrator_pane // 1' <<<"$topology")"
  task_id="$(safe_name "${SESSION}_idle_${bead}_p${pane}_$(date -u +%Y%m%dT%H%M%SZ)")"
  dispatch_file="/tmp/dispatch_${task_id}.md"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    jq -nc \
      --arg schema_version "$VERSION" \
      --arg session "$SESSION" \
      --arg repo "$REPO" \
      --arg status "dry_run_candidate" \
      --arg dispatch_file "$dispatch_file" \
      --argjson dry_run "$dry_bool" \
      --argjson apply "$apply_bool" \
      --argjson topology "$topology" \
      --argjson stale_error_auto_ping "$stale" \
      --argjson worker_stall_alerts "$stalls" \
      --argjson probe "$probe" \
      --argjson candidate "$candidate" \
      --argjson candidate_count "$candidate_count" \
      '{schema_version:$schema_version,session:$session,repo:$repo,dry_run:$dry_run,apply:$apply,status:$status,topology:$topology,stale_error_auto_ping:$stale_error_auto_ping,worker_stall_alerts:$worker_stall_alerts,probe:$probe,candidate_count:$candidate_count,candidate:$candidate,dispatch_file:$dispatch_file,delivery_receipt:{schema_version:"dispatch-delivery-receipt/v1",transport_accepted:false,prompt_visible_in_target:false,prompt_submitted:false,work_started:false,dry_run:true}}'
    return 0
  fi

  write_dispatch_file "$task_id" "$bead" "$pane" "$priority" "$callback_pane" "$dispatch_file"
  if command -v br >/dev/null 2>&1 && [[ -d "$REPO/.beads" ]]; then
    (cd "$REPO" && br update "$bead" --status in_progress >/dev/null 2>&1) || true
  fi

  send_out="$(mktemp "${TMPDIR:-/tmp}/idle-dispatch-send-out.XXXXXX")"
  send_err="$(mktemp "${TMPDIR:-/tmp}/idle-dispatch-send-err.XXXXXX")"
  send_rc=0
  "$NTM_BIN" send "$SESSION" --pane="$pane" --file "$dispatch_file" --no-cass-check >"$send_out" 2>"$send_err" || send_rc=$?
  sleep 2
  delivery="$(delivery_receipt_json "$pane" "$task_id" "$dispatch_file" "$send_rc" "$(tr '\n' ' ' <"$send_out")" "$(tr '\n' ' ' <"$send_err")")"
  rm -f "$send_out" "$send_err"

  append_cooldowns "$pane" "$bead"
  log_row="$(jq -nc \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg event "idle_pane_auto_dispatch" \
    --arg task_id "$task_id" \
    --arg bead_id "$bead" \
    --arg dispatch_file "$dispatch_file" \
    --arg target_session "$SESSION" \
    --argjson target_pane "$pane" \
    --argjson delivery "$delivery" \
    '{ts:$ts,event:$event,task_id:$task_id,bead_id:$bead_id,dispatch_file:$dispatch_file,target_session:$target_session,target_pane:$target_pane,callback_received_at:null,status:(if $delivery.transport_accepted then "dispatched" else "send_failed" end),delivery_receipt:$delivery}')"
  append_dispatch_log "$log_row"

  jq -nc \
    --arg schema_version "$VERSION" \
    --arg session "$SESSION" \
    --arg repo "$REPO" \
    --arg status "$(jq -r 'if .transport_accepted then "dispatched" else "send_failed" end' <<<"$delivery")" \
    --arg task_id "$task_id" \
    --arg dispatch_file "$dispatch_file" \
    --argjson dry_run "$dry_bool" \
    --argjson apply "$apply_bool" \
    --argjson topology "$topology" \
    --argjson stale_error_auto_ping "$stale" \
    --argjson worker_stall_alerts "$stalls" \
    --argjson probe "$probe" \
    --argjson candidate "$candidate" \
    --argjson candidate_count "$candidate_count" \
    --argjson delivery "$delivery" \
    '{schema_version:$schema_version,session:$session,repo:$repo,dry_run:$dry_run,apply:$apply,status:$status,task_id:$task_id,topology:$topology,stale_error_auto_ping:$stale_error_auto_ping,worker_stall_alerts:$worker_stall_alerts,probe:$probe,candidate_count:$candidate_count,candidate:$candidate,dispatch_file:$dispatch_file,delivery_receipt:$delivery}'
}

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_OUT=1
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:?--session requires NAME}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --repo) REPO="${2:?--repo requires PATH}"; shift 2 ;;
    --repo=*) REPO="${1#*=}"; shift ;;
    --state-dir) STATE_DIR="${2:?--state-dir requires PATH}"; shift 2 ;;
    --state-dir=*) STATE_DIR="${1#*=}"; shift ;;
    --probe) PROBE="${2:?--probe requires PATH}"; shift 2 ;;
    --probe=*) PROBE="${1#*=}"; shift ;;
    --ntm-bin) NTM_BIN="${2:?--ntm-bin requires PATH}"; shift 2 ;;
    --ntm-bin=*) NTM_BIN="${1#*=}"; shift ;;
    --dry-run) APPLY=0; DRY_RUN=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --json) JSON_OUT=1; shift ;;
    --force) FORCE=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --info) emit_info; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

run_dispatch
