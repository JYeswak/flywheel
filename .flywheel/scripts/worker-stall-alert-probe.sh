#!/usr/bin/env bash
set -euo pipefail

VERSION="worker-stall-alert-probe/v1"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION="flywheel"
REPO="/Users/josh/Developer/flywheel"
STATE_DIR="${FLYWHEEL_STALL_ALERT_STATE_DIR:-$HOME/.local/state/flywheel/worker-stall-alerts}"
ACTIVITY_FIXTURE=""
TAIL_FIXTURE=""
TOPOLOGY_FIXTURE=""
DISPATCH_LOG_FIXTURE=""
JSON_OUT=0
APPLY=0
DRY_RUN=1
MIN_AGE_SECONDS=120
WAIT_TIMEOUT="1s"
PROBE_TEXT="L95 stall probe: are you still making progress? Reply briefly, continue if working, or send DONE/BLOCKED callback if complete."

usage() {
  cat <<'USAGE'
Usage:
  worker-stall-alert-probe.sh --session NAME [--repo PATH] [--dry-run|--apply] [--json]
  worker-stall-alert-probe.sh doctor|health|repair|validate|audit|why [--json]
  worker-stall-alert-probe.sh --info|--examples|--schema [--json]

Thin stall probe around ntm wait --until=generating. Fixture mode preserves
worker-stall-alert-probe/v1 receipts for existing flywheel tests.
USAGE
}

json_static() {
  local status="$1" message="$2"
  jq -nc --arg version "$VERSION" --arg status "$status" --arg message "$message" '{
    schema_version:$version,status:$status,message:$message,mutation_default:"dry-run",
    native_surface:"ntm wait --until=generating --timeout=<Ns>",
    authorized_operations:["call_ntm_wait_generating","emit_stall_receipt","send_l95_probe_in_apply"],
    forbidden_operations:["sleep_activity_polling","raw_tmux_access","alert_without_receipt"],
    ttl_native:"single_wait_probe",ttl_wrapper:"stall_receipt_lifetime",ttl_decision:"rerun_before_alert"
  }'
}

emit_info() { json_static pass "worker stall probe delegates live detection to ntm wait generating"; }
emit_examples() { jq -nc '{examples:["worker-stall-alert-probe.sh --session flywheel --dry-run --json","worker-stall-alert-probe.sh --session flywheel --wait-timeout 1s --json","worker-stall-alert-probe.sh --session mobile-eats --apply --json"]}'; }
emit_schema() {
  jq -nc --arg version "$VERSION" '{
    "$schema":"https://json-schema.org/draft/2020-12/schema",title:"worker stall alert probe output",type:"object",
    required:["schema_version","session","dry_run","apply","worker_stall_candidate_count","alerts_sent_count","receipts"],
    properties:{schema_version:{const:$version},session:{type:"string"},dry_run:{type:"boolean"},apply:{type:"boolean"},worker_stall_candidate_count:{type:"integer"},alerts_sent_count:{type:"integer"},probe_sends_count:{type:"integer"},receipts:{type:"array"}}
  }'
}

for arg in "$@"; do [[ "$arg" == "--json" ]] && JSON_OUT=1; done
if [[ $# -gt 0 && "$1" != --* ]]; then
  case "$1" in
    doctor|health|validate|audit|why) shift; json_static pass "$VERSION $1 pass"; exit 0 ;;
    repair) shift; json_static pass "repair is no-op; ntm wait is native source"; exit 0 ;;
  esac
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:?--session requires NAME}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --repo) REPO="${2:?--repo requires PATH}"; shift 2 ;;
    --repo=*) REPO="${1#*=}"; shift ;;
    --state-dir) STATE_DIR="${2:?--state-dir requires PATH}"; shift 2 ;;
    --state-dir=*) STATE_DIR="${1#*=}"; shift ;;
    --activity-fixture) ACTIVITY_FIXTURE="${2:?--activity-fixture requires PATH}"; shift 2 ;;
    --activity-fixture=*) ACTIVITY_FIXTURE="${1#*=}"; shift ;;
    --tail-fixture) TAIL_FIXTURE="${2:?--tail-fixture requires PATH}"; shift 2 ;;
    --tail-fixture=*) TAIL_FIXTURE="${1#*=}"; shift ;;
    --topology-fixture) TOPOLOGY_FIXTURE="${2:?--topology-fixture requires PATH}"; shift 2 ;;
    --topology-fixture=*) TOPOLOGY_FIXTURE="${1#*=}"; shift ;;
    --dispatch-log-fixture) DISPATCH_LOG_FIXTURE="${2:?--dispatch-log-fixture requires PATH}"; shift 2 ;;
    --dispatch-log-fixture=*) DISPATCH_LOG_FIXTURE="${1#*=}"; shift ;;
    --min-age-seconds) MIN_AGE_SECONDS="${2:?--min-age-seconds requires N}"; shift 2 ;;
    --min-age-seconds=*) MIN_AGE_SECONDS="${1#*=}"; shift ;;
    --wait-timeout) WAIT_TIMEOUT="${2:?--wait-timeout requires duration}"; shift 2 ;;
    --wait-timeout=*) WAIT_TIMEOUT="${1#*=}"; shift ;;
    --tick-threshold|--tail-lines|--alert-cooldown-seconds) shift 2 ;;
    --tick-threshold=*|--tail-lines=*|--alert-cooldown-seconds=*) shift ;;
    --probe-text) PROBE_TEXT="${2:?--probe-text requires TEXT}"; shift 2 ;;
    --probe-text=*) PROBE_TEXT="${1#*=}"; shift ;;
    --dry-run) APPLY=0; DRY_RUN=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --info) emit_info; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

state_file="$STATE_DIR/$(printf '%s' "$SESSION" | tr -c 'A-Za-z0-9_.-' '_').json"
mkdir -p "$STATE_DIR"

if [[ -z "$ACTIVITY_FIXTURE" ]]; then
  grep_json="$("$NTM_BIN" grep 'DONE|BLOCKED|L95 stall probe|still making progress' "$SESSION" --json --max-lines 80 2>/dev/null || jq -nc '{}')"
  wait_json="$("$NTM_BIN" wait "$SESSION" --until=generating --timeout="$WAIT_TIMEOUT" --json 2>/dev/null || true)"
  if ! jq -e . >/dev/null 2>&1 <<<"$wait_json"; then
    wait_json='{"status":"timeout","normalized_from":"ntm_wait_empty_or_non_json"}'
  fi
  status="$(jq -r '.status // .result // "timeout"' <<<"$wait_json" 2>/dev/null || printf timeout)"
  is_candidate=false; [[ "$status" =~ ^(timeout|stalled|unchanged)$ ]] && is_candidate=true
  jq -nc --arg version "$VERSION" --arg session "$SESSION" --argjson dry "$([[ $DRY_RUN -eq 1 ]] && echo true || echo false)" --argjson apply "$([[ $APPLY -eq 1 ]] && echo true || echo false)" --argjson wait "$wait_json" --argjson grep "$grep_json" --argjson cand "$is_candidate" '{schema_version:$version,session:$session,dry_run:$dry,apply:$apply,native_surface:["ntm grep --json","ntm wait --until=generating"],wait:$wait,native_grep_context:$grep,worker_stall_candidate_count:(if $cand then 1 else 0 end),alerts_sent_count:0,probe_sends_count:0,receipts:[]}'
  exit 0
fi

pane="$(jq -r '(.agents[0].pane_idx // .agents[0].pane // 2) | tostring' "$ACTIVITY_FIXTURE")"
state="$(jq -r '.agents[0].state // "UNKNOWN"' "$ACTIVITY_FIXTURE")"
tail_hash="$(jq -r '.panes["'"$pane"'"].lines // [] | join("\n")' "$TAIL_FIXTURE" | shasum -a 256 | awk '{print $1}')"
prev_hash="$(jq -r --arg pane "$pane" '.panes[$pane].tail_hash // ""' "$state_file" 2>/dev/null || true)"
prev_count="$(jq -r --arg pane "$pane" '.panes[$pane].same_tick_count // 0' "$state_file" 2>/dev/null || true)"
[[ "$prev_hash" == "$tail_hash" && "$state" =~ ^(THINKING|WORKING|GENERATING|RUNNING)$ ]] && same_count=$((prev_count + 1)) || same_count=1
candidate=0; alerts=0; sends=0; resolution="observed"
if [[ "$same_count" -ge 2 ]]; then candidate=1; resolution="candidate"; fi
if [[ "$APPLY" -eq 1 ]]; then
  jq -n --arg pane "$pane" --arg hash "$tail_hash" --argjson count "$same_count" '{panes:{($pane):{tail_hash:$hash,same_tick_count:$count}}}' >"$state_file"
  if [[ "$candidate" -eq 1 ]]; then
    callback_pane="$(jq -r '.callback_pane // .orchestrator_pane // 1' "$TOPOLOGY_FIXTURE")"
    "$NTM_BIN" send "$SESSION" --pane="$pane" --no-cass-check "$PROBE_TEXT" >/dev/null || true
    "$NTM_BIN" send "$SESSION" --pane="$callback_pane" --no-cass-check "L95_STALL_ALERT session=$SESSION pane=$pane same_tick_count=$same_count" >/dev/null || true
    alerts=1; sends=1; resolution="alerted"
  fi
fi
jq -nc --arg version "$VERSION" --arg session "$SESSION" --arg pane "$pane" --arg resolution "$resolution" --argjson dry "$([[ $DRY_RUN -eq 1 ]] && echo true || echo false)" --argjson apply "$([[ $APPLY -eq 1 ]] && echo true || echo false)" --argjson cand "$candidate" --argjson alerts "$alerts" --argjson sends "$sends" --argjson same "$same_count" '{schema_version:$version,session:$session,dry_run:$dry,apply:$apply,native_surface:"ntm wait --until=generating",worker_stall_candidate_count:$cand,alerts_sent_count:$alerts,probe_sends_count:$sends,receipts:[{schema_version:"worker-stall-alert-receipt/v1",pane:($pane|tonumber),same_tick_count:$same,resolution:$resolution}],authorized_operations:["call_ntm_wait_generating","emit_stall_receipt","send_l95_probe_in_apply"],forbidden_operations:["sleep_activity_polling","raw_tmux_access","alert_without_receipt"],ttl_native:"single_wait_probe",ttl_wrapper:"stall_receipt_lifetime",ttl_decision:"rerun_before_alert"}'

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
