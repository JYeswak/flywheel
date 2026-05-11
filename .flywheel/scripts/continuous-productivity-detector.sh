#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.19)
# doctor-mode-tier: scaffolded
#
# IDEMPOTENT-BY-CONSTRUCTION: this surface is read-only (read_only=true,
# peer_repo_writes=false). Default invocation classifies peer-orchestrator
# productivity state and emits planned actions but does not mutate state.
# --idempotency-key flag is accepted (parses + flows through) but not
# strictly required since the python core has no mutation path.
set -euo pipefail

# ====== BEGIN canonical-cli scaffold (bead flywheel-1hshd.19) ======
# SURGICAL DASH-FLAG SCAFFOLD variant (sister 5ke66.17 / 1hshd.{15,17}).
# Native python3 heredoc owns argparse for --info, --examples, --json,
# --quiet, --session, threshold flags, fixture flags. Two regression suites
# assert specific shapes:
#   - .flywheel/tests/test_continuous_productivity_detector.sh:
#     `--info --json` must have .read_only==true, .peer_repo_writes==false,
#     .canonical_cli contains "--quiet", .joshua_notify_allowlist contains
#     "substrate-corrupt"
#   - same suite: `--examples --json` must have .examples|length>=3
#
# Bash scaffold intercepts BEFORE python heredoc fires:
#   - --schema (NEW; not in python argparse — would error)
#   - NEW verbs: doctor, health, repair, validate, audit, why, quickstart
#   - help <topic> (python argparse has --help, not `help <topic>`)
#
# All other invocations (including --info, --examples, default classifier)
# fall through to python verbatim. Native python info() is augmented
# in-place to add .version + .capabilities (AG3.1) while preserving
# .read_only / .peer_repo_writes / .canonical_cli / .joshua_notify_allowlist
# (regression contract).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi
SCAFFOLD_SCHEMA_VERSION="continuous-productivity-detector/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-${CPD_AUDIT_LOG:-$HOME/.local/state/flywheel/continuous-productivity-detector-runs.jsonl}}"

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"doctor",fields:{ts:"ISO8601",status:"pass|warn|fail",checks:"array of {name,status,detail?,path?}"}}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"health",fields:{ts:"ISO8601",status:"pass|warn|fail",audit_log:"path",last_run_ts:"ISO8601 or null",age_seconds:"int|null",recent_runs:"int (last 20)",total_runs:"int",stale_threshold_seconds:"int"}}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["audit_log_dir","topology_path"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{audit_log:"SCAFFOLD_AUDIT_LOG",topology:"CPD_TOPOLOGY"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["session-name","threshold-seconds","allowlist-class"],contract:{rejects_with_rc1:"on schema violation",threshold_seconds_min:1,threshold_seconds_max:86400,allowlist_classes:["substrate-corrupt","security","phi","paradigm","destructive"]}}'
      ;;
    report|default|*)
      local input_schema output_schema
      input_schema='{"type":"object","properties":{"topology":{"type":"string"},"loops_dir":{"type":"string"},"activity_dir":{"type":"string"},"ready_dir":{"type":"string"},"doctor_dir":{"type":"string"},"session":{"type":"string"},"threshold_seconds":{"type":"integer"},"now_epoch":{"type":"number"}}}'
      output_schema='{"type":"object","required":["schema_version","checked_at","threshold_seconds","sessions_checked","action_required_count","sessions"],"properties":{"schema_version":{"const":"continuous-productivity-detector/v1"},"checked_at":{"type":"string"},"threshold_seconds":{"type":"integer"},"sessions_checked":{"type":"integer"},"idle_with_work_available_count":{"type":"integer"},"josh_notify_allowlisted_count":{"type":"integer"},"action_required_count":{"type":"integer"},"sessions":{"type":"array"},"parse_errors":{"type":"array"},"probe_errors":{"type":"array"}}}'
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --argjson in "$input_schema" --argjson out "$output_schema" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","report"],input_schema:$in,output_schema:$out,note:"Default surface = report. Native python emits report shape from default invocation; scaffold owns NEW verbs."}'
      ;;
  esac
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe substrate",command:"continuous-productivity-detector.sh doctor --json"}'
)"$'\n'"$(jq -nc '{step:2,action:"detect across all peers",command:"continuous-productivity-detector.sh --json"}'
)"$'\n'"$(jq -nc '{step:3,action:"single-session probe",command:"continuous-productivity-detector.sh --session skillos --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,validate,audit"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run|detect)  printf 'topic: detect (default) — read $CPD_TOPOLOGY + $CPD_LOOPS_DIR; for each peer-orch session, probe ntm activity + ready beads + doctor doc; classify productivity_state ∈ {productive, idle_with_work_available, josh_notify_allowlisted}; emit planned_actions; rc 0=no-escalation, 1=escalation-emitted, 2=parse-error, 3=probe-error\n' ;;
    doctor)      printf 'topic: doctor — substrate probes: bash, jq, python3, ntm, topology_readable, loops_dir_present, audit_log_dir_writable\n' ;;
    health)      printf 'topic: health — tail $SCAFFOLD_AUDIT_LOG; report last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >24h stale\n' ;;
    repair)      printf 'topic: repair --scope <audit_log_dir|topology_path> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: audit_log_dir (mkdir -p), topology_path (REPORT-ONLY — verifies $CPD_TOPOLOGY readable; topology rows owned by topology-tick-refresh.sh)\n' ;;
    validate)    printf 'topic: validate <subject> [VALUE] — subjects: session-name (non-empty), threshold-seconds (integer in [1, 86400]; matches CPD_THRESHOLD_SECONDS env), allowlist-class (must be one of substrate-corrupt|security|phi|paradigm|destructive); rc=1 on schema violation\n' ;;
    audit)       printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail; default limit=20\n' ;;
    why)         printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/session/productivity_state; states: found / not_found / unavailable\n' ;;
    *)           printf 'topics: detect | doctor | health | repair | validate | audit | why | quickstart (SURGICAL DASH-FLAG SCAFFOLD: --schema + new verbs route to bash scaffold; --info/--examples/default classifier route to python with augmented info envelope)\n' ;;
  esac
}

scaffold_cmd_doctor() {
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local topology="${CPD_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
  local loops_dir="${CPD_LOOPS_DIR:-$HOME/.flywheel/loops}"
  local ntm_bin="${CPD_NTM:-/Users/josh/.local/bin/ntm}"
  local bash_s=fail jq_s=fail py_s=fail ntm_s=warn topo_s=warn loops_s=warn audit_s=fail
  command -v bash >/dev/null 2>&1 && bash_s=pass
  command -v jq >/dev/null 2>&1 && jq_s=pass
  command -v python3 >/dev/null 2>&1 && py_s=pass
  [[ -x "$ntm_bin" ]] && ntm_s=pass
  [[ -r "$topology" ]] && topo_s=pass
  [[ -d "$loops_dir" ]] && loops_s=pass
  [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]] && audit_s=pass
  local overall=pass
  for st in "$bash_s" "$jq_s" "$py_s"; do [[ "$st" == fail ]] && overall=fail; done
  if [[ "$overall" == pass ]]; then
    for st in "$ntm_s" "$topo_s" "$loops_s" "$audit_s"; do
      [[ "$st" == warn || "$st" == fail ]] && overall=warn
    done
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg bash_s "$bash_s" --arg jq_s "$jq_s" --arg py_s "$py_s" --arg ntm_s "$ntm_s" \
    --arg topo_s "$topo_s" --arg loops_s "$loops_s" --arg audit_s "$audit_s" \
    --arg ntm "$ntm_bin" --arg topo "$topology" --arg loops "$loops_dir" --arg audit "$audit_log_dir" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_s},
        {name:"jq_available",status:$jq_s},
        {name:"python3_available",status:$py_s,detail:"load-bearing — script body is python3 heredoc"},
        {name:"ntm_executable",status:$ntm_s,path:$ntm,detail:"used for live --robot-activity probes"},
        {name:"topology_readable",status:$topo_s,path:$topo},
        {name:"loops_dir_present",status:$loops_s,path:$loops},
        {name:"audit_log_dir_writable",status:$audit_s,path:$audit}
      ]}'
}

scaffold_cmd_health() {
  local audit_log="$SCAFFOLD_AUDIT_LOG"
  local ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${CPD_HEALTH_STALE_THRESHOLD_SECONDS:-86400}"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$audit_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$audit_log" --argjson stale "$stale_threshold" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",audit_log:$log,reason:"audit_log_missing",last_run_ts:null,age_seconds:null,recent_runs:0,total_runs:0,stale_threshold_seconds:$stale}'
    return 0
  fi
  total_runs="$(wc -l < "$audit_log" 2>/dev/null | tr -d ' ' || echo 0)"
  recent_runs="$(tail -20 "$audit_log" 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  last_run_ts="$(tail -1 "$audit_log" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
  if [[ -n "$last_run_ts" ]]; then
    local now last_epoch
    now="$(date -u +%s)"
    last_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$last_run_ts" +%s 2>/dev/null \
                  || date -u -d "$last_run_ts" +%s 2>/dev/null || echo 0)"
    age_seconds=$((now - last_epoch))
    [[ "$age_seconds" -gt "$stale_threshold" ]] && status="warn"
  else
    age_seconds=null; status="warn"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" \
    --arg log "$audit_log" --arg last_run_ts "$last_run_ts" \
    --argjson age "${age_seconds:-null}" --argjson total "$total_runs" --argjson recent "$recent_runs" \
    --argjson stale "$stale_threshold" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,
      last_run_ts:(if $last_run_ts == "" then null else $last_run_ts end),
      age_seconds:$age,recent_runs:$recent,total_runs:$total,stale_threshold_seconds:$stale}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --scope=*) scope="${1#--scope=}"; shift ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key",exit_code:3}'
      exit 3
    fi
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    audit_log_dir)
      local target; target="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      local existed="true"; [[ ! -d "$target" ]] && existed="false"
      [[ "$mode" == "apply" ]] && mkdir -p "$target"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    topology_path)
      # REPORT-ONLY scope — topology rows are owned by topology-tick-refresh.sh.
      local target="${CPD_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
      local existed="false" readable="false"
      [[ -f "$target" ]] && existed="true"
      [[ -r "$target" ]] && readable="true"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" \
        --arg existed "$existed" --arg readable "$readable" \
        '{schema_version:$sv,command:"repair",status:"report",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed:($existed == "true"),readable:($readable == "true"),note:"REPORT-ONLY — topology rows owned by topology-tick-refresh.sh, not this surface"}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|topology_path>\n' >&2; return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","topology_path"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    session-name)
      if [[ -n "$arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg s "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"ok",value:$s}'
        return 0
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" \
        '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"reject",reason:"empty_session_name"}'
      return 1 ;;
    threshold-seconds)
      [[ -z "$arg" ]] && { printf 'ERR: validate threshold-seconds requires VALUE\n' >&2; return 64; }
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 1 && arg <= 86400 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"threshold-seconds",ts:$ts,status:"ok",value:$v}'
        return 0
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
        '{schema_version:$sv,command:"validate",subject:"threshold-seconds",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[1, 86400]",default:300}'
      return 1 ;;
    allowlist-class)
      [[ -z "$arg" ]] && { printf 'ERR: validate allowlist-class requires VALUE\n' >&2; return 64; }
      case "$arg" in
        substrate-corrupt|security|phi|paradigm|destructive)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg c "$arg" \
            '{schema_version:$sv,command:"validate",subject:"allowlist-class",ts:$ts,status:"ok",value:$c}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg c "$arg" \
            '{schema_version:$sv,command:"validate",subject:"allowlist-class",ts:$ts,status:"reject",value:$c,reason:"unknown_class",valid_classes:["substrate-corrupt","security","phi","paradigm","destructive"]}'
          return 1 ;;
      esac ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["session-name","threshold-seconds","allowlist-class"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["session-name","threshold-seconds","allowlist-class"]}'
      return 64 ;;
  esac
}

scaffold_cmd_audit() {
  local limit=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      --limit) limit="${2:-20}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown audit arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
    return 0
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"empty",audit_log:$log,rows:[]}'
    return 0
  fi
  local rows; rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -s . 2>/dev/null || echo '[]')"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
    --argjson rows "$rows" --argjson limit "$limit" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:"ok",audit_log:$log,limit:$limit,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  [[ -z "$id" ]] && { printf 'ERR: why requires <id>\n' >&2; return 64; }
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",reason:"audit_log_missing",audit_log:$log}'
    return 0
  fi
  local match
  match="$(jq -c --arg id "$id" 'select(.ts == $id or (.session // "") == $id or (.productivity_state // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","session","productivity_state"]}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson row "$match" \
    '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log:$log,row:$row}'
}

scaffold_main() {
  case "$1" in
    --schema)
      shift
      local surface="${1:-default}"
      [[ "$surface" == "--json" ]] && surface="default"
      scaffold_emit_schema "$surface"; exit 0 ;;
    quickstart) shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    doctor)     shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)     shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)     shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)   shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)      shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)        shift; scaffold_cmd_why "$@"; exit $? ;;
    help)       shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    *)
      printf 'ERR: scaffold_main called with non-canonical arg: %s\n' "$1" >&2; exit 64 ;;
  esac
}

# SURGICAL DASH-FLAG match — intercept ONLY --schema + new verbs +
# `help <topic>`. Native --info / --examples / --json / --quiet / --session /
# default classifier all fall through to python (regression-test contract
# preserved by augmenting native python info() in-place below).
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    --schema) return 0 ;;
    quickstart|doctor|health|repair|validate|audit|why) return 0 ;;
    help)
      case "${2:-}" in detect|run|doctor|health|repair|validate|audit|why|quickstart|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

# IDEMPOTENT-BY-CONSTRUCTION: read-only surface (peer_repo_writes=false in
# native --info envelope). --idempotency-key flag accepted by scaffold for
# `repair --apply` only; default classifier path has no mutation.

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======

python3 - "$@" <<'PY'
import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
SCHEMA = "continuous-productivity-detector/v1"
MEMORY = "/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_flywheel_owns_continuous_productivity_no_downtime_unless_josh_blocker.md"
DEFAULT_TOPOLOGY = Path.home() / ".local/state/flywheel/session-topology.jsonl"
DEFAULT_LOOPS = Path.home() / ".flywheel/loops"
DEFAULT_NTM = "/Users/josh/.local/bin/ntm"
ALLOWLIST = {
    "substrate-corrupt": ("substrate-corrupt", "substrate corruption", "substrate_corrupt", "corrupt-substrate"),
    "security": ("security", "secret exposure", "credential leak", "access token"),
    "phi": ("phi", "hipaa", "protected health"),
    "paradigm": ("paradigm", "mental model", "founder decision"),
    "destructive": ("destructive", "delete production", "drop database", "destroy"),
}
def parse_args():
    p = argparse.ArgumentParser(description="Detect peer orchestrator idle-with-work productivity breaches.")
    p.add_argument("--info", action="store_true")
    p.add_argument("--examples", action="store_true")
    p.add_argument("--json", action="store_true")
    p.add_argument("--quiet", action="store_true")
    p.add_argument("--session")
    p.add_argument("--include-self", action="store_true")
    p.add_argument("--threshold-seconds", type=int, default=int(os.environ.get("CPD_THRESHOLD_SECONDS", "300")))
    p.add_argument("--now-epoch", type=float, default=float(os.environ.get("CPD_NOW_EPOCH", time.time())))
    p.add_argument("--topology", default=os.environ.get("CPD_TOPOLOGY", str(DEFAULT_TOPOLOGY)))
    p.add_argument("--loops-dir", default=os.environ.get("CPD_LOOPS_DIR", str(DEFAULT_LOOPS)))
    p.add_argument("--activity-dir", default=os.environ.get("CPD_ACTIVITY_DIR"))
    p.add_argument("--ready-dir", default=os.environ.get("CPD_READY_DIR"))
    p.add_argument("--doctor-dir", default=os.environ.get("CPD_DOCTOR_DIR"))
    p.add_argument("--ntm", default=os.environ.get("CPD_NTM", DEFAULT_NTM))
    p.add_argument("--activity-timeout", type=int, default=int(os.environ.get("CPD_ACTIVITY_TIMEOUT", "5")))
    return p.parse_args()
def info():
    # AG3.1 (bead flywheel-1hshd.19) requires .name + .version + .capabilities.
    # Pre-existing regression contract requires .read_only==True,
    # .peer_repo_writes==False, .canonical_cli contains "--quiet",
    # .joshua_notify_allowlist contains "substrate-corrupt" — all preserved.
    return {
        "schema_version": SCHEMA,
        "name": "continuous-productivity-detector.sh",
        "version": "scaffolded-v1",
        "capabilities": [
            "peer-orch-idle-with-work-detector",
            "5min-default-threshold",
            "joshua-notify-allowlist-5-classes",
            "fixture-or-live-input",
            "read-only-no-peer-repo-writes",
            "xpane-escalation-message-builder",
        ],
        "purpose": "Detect peer orchestrators idle past threshold while workers wait and findings exist.",
        "canonical_cli": ["--info", "--help", "--examples", "--json", "--quiet"],
        "exit_codes": {"0": "no-escalation-needed", "1": "escalation-emitted", "2": "malformed-state", "3": "probe-error"},
        "read_only": True,
        "peer_repo_writes": False,
        "mutates_state": False,
        "joshua_notify_allowlist": sorted(ALLOWLIST),
        "memory": MEMORY,
    }
def examples():
    return {
        "examples": [
            "continuous-productivity-detector.sh --json",
            "continuous-productivity-detector.sh --session skillos --json",
            "CPD_ACTIVITY_DIR=/tmp/activity continuous-productivity-detector.sh --topology /tmp/topology.jsonl --json",
        ]
    }
def load_json(path, default, errors):
    try:
        with Path(path).open(encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return default
    except Exception as exc:
        errors.append(f"json:{path}:{exc}")
        return default
def load_jsonl(path, errors):
    rows = []
    try:
        with Path(path).open(encoding="utf-8") as f:
            for line_no, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                    row["__line"] = line_no
                    rows.append(row)
                except Exception as exc:
                    errors.append(f"jsonl:{path}:{line_no}:{exc}")
    except FileNotFoundError:
        return rows
    return rows
def latest_by_session(rows):
    latest = {}
    for row in rows:
        session = row.get("session")
        if not session:
            continue
        prev = latest.get(session)
        if prev is None or str(row.get("effective_at", "")) >= str(prev.get("effective_at", "")):
            latest[session] = row
    return latest
def loops(loops_dir, errors):
    out = {}
    path = Path(loops_dir)
    if not path.exists():
        return out
    for item in sorted(path.glob("*.json")):
        row = load_json(item, {}, errors)
        if row.get("active") is False:
            continue
        session = row.get("session") or item.stem
        out[session] = row
    return out
def fixture_json(dir_path, session, default, errors):
    if not dir_path:
        return None
    return load_json(Path(dir_path) / f"{session}.json", default, errors)
def run_json(cmd, default, timeout, probe_errors):
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.PIPE, text=True, timeout=timeout)
        return json.loads(out)
    except Exception as exc:
        probe_errors.append(f"probe:{' '.join(cmd)}:{exc}")
        return default
def activity(session, args, probe_errors, parse_errors):
    fixture = fixture_json(args.activity_dir, session, {"agents": []}, parse_errors)
    if fixture is not None:
        return fixture
    return run_json([args.ntm, f"--robot-activity={session}", "--activity-type=codex,claude"], {"agents": []}, args.activity_timeout, probe_errors)
def ready_rows(session, repo, args, parse_errors):
    fixture = fixture_json(args.ready_dir, session, [], parse_errors)
    if fixture is not None:
        return fixture if isinstance(fixture, list) else fixture.get("ready", [])
    if not repo or not Path(repo).is_dir():
        return []
    try:
        out = subprocess.check_output(["bash", "-lc", f"cd {json.dumps(repo)} && br ready --json"], stderr=subprocess.DEVNULL, text=True, timeout=5)
        return json.loads(out)
    except Exception:
        return []
def doctor(session, args, parse_errors):
    fixture = fixture_json(args.doctor_dir, session, {}, parse_errors)
    return fixture if fixture is not None else {}
def intish(value, default=0):
    try:
        return int(value)
    except Exception:
        return default
def age_seconds(agent, now_epoch):
    for key in ("state_since_epoch", "waiting_since_epoch"):
        value = agent.get(key)
        if isinstance(value, (int, float)):
            return max(0, int(now_epoch - value))
    for key in ("state_since", "state_since_iso"):
        raw = agent.get(key)
        if isinstance(raw, str):
            try:
                dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
                if dt.tzinfo is None:
                    dt = dt.replace(tzinfo=timezone.utc)
                return max(0, int(now_epoch - dt.timestamp()))
            except Exception:
                pass
    return intish(agent.get("idle_seconds") or agent.get("wait_seconds") or 0)
def source_rows(doc, ready):
    sources = []
    if isinstance(ready, list) and ready:
        sources.append({"source": "unprocessed ready beads", "count": len(ready), "examples": labels(ready)})
    errors = doc.get("errors") if isinstance(doc.get("errors"), list) else []
    if errors:
        sources.append({"source": "doctor errors[]", "count": len(errors), "examples": labels(errors)})
    triage = doc.get("fuckup_triage") if isinstance(doc.get("fuckup_triage"), dict) else {}
    candidates = triage.get("candidates") or triage.get("promotion_ready") or []
    if isinstance(candidates, list) and candidates:
        sources.append({"source": "fuckup_triage candidates", "count": len(candidates), "examples": labels(candidates)})
    closed = intish(doc.get("closed_bead_audit_pending_count") or doc.get("audit_findings_count") or 0)
    if closed:
        sources.append({"source": "audit findings pending", "count": closed, "examples": ["closed-bead/audit findings"]})
    incidents = intish(doc.get("incidents_unprocessed_count") or 0)
    if incidents:
        sources.append({"source": "INCIDENTS.md unprocessed events", "count": incidents, "examples": ["incident promotion backlog"]})
    return sources
def labels(rows):
    out = []
    for row in rows[:3]:
        if isinstance(row, dict):
            out.append(str(row.get("id") or row.get("code") or row.get("trauma_class") or row.get("title") or row)[:100])
        else:
            out.append(str(row)[:100])
    return out
def allowlisted_class(doc):
    text = json.dumps(doc, sort_keys=True).lower()
    for klass, needles in ALLOWLIST.items():
        if any(needle in text for needle in needles):
            return klass
    return None
def escalation_message(session, pane, sources):
    instructions = []
    for idx, src in enumerate(sources[:3], 1):
        example = ", ".join(src["examples"]) or src["source"]
        instructions.append(f"{idx}. File or dispatch a bead from {src['source']}: {example}.")
    while len(instructions) < 3:
        instructions.append(f"{len(instructions)+1}. Confirm the next findings source is empty or convert it to a bead.")
    return "\n".join([
        f"PRODUCTIVITY_ESCALATION session={session} target_pane={pane}",
        "peer-orch idle >5m + workers WAITING + findings non-empty",
        "Flywheel owns continuous productivity; this is an xpane escalation, not a Joshua notification.",
        *instructions[:3],
        f"evidence_memory={MEMORY}",
    ])
def classify(session, topo, loop, act, ready, doc, args):
    orch_pane = intish(topo.get("orchestrator_pane") or loop.get("orchestrator_pane") or 1, 1)
    worker_panes = {intish(p) for p in (topo.get("worker_panes") or loop.get("worker_panes") or []) if intish(p)}
    agents = act.get("agents") if isinstance(act.get("agents"), list) else []
    orch = next((a for a in agents if intish(a.get("pane_idx") or a.get("pane")) == orch_pane), {})
    workers = [a for a in agents if intish(a.get("pane_idx") or a.get("pane")) in worker_panes] if worker_panes else [a for a in agents if intish(a.get("pane_idx") or a.get("pane")) >= 2]
    orch_state = str(orch.get("state") or "UNKNOWN").upper()
    orch_age = age_seconds(orch, args.now_epoch) if orch else 0
    waiting_workers = [w for w in workers if str(w.get("state", "")).upper() == "WAITING"]
    active_workers = [w for w in workers if str(w.get("state", "")).upper() in {"THINKING", "WORKING", "GENERATING"}]
    sources = source_rows(doc, ready)
    notify_class = allowlisted_class(doc)
    idle_trip = orch_state == "WAITING" and orch_age >= args.threshold_seconds
    actions = []
    state = "productive"
    if notify_class:
        state = "josh_notify_allowlisted"
        actions.append({"type": "josh_notify", "session": session, "target": "joshua", "allowlist_class": notify_class})
    elif idle_trip and waiting_workers and sources:
        state = "idle_with_work_available"
        actions.append({"type": "xpane_productivity_escalation", "session": session, "target_pane": orch_pane, "message": escalation_message(session, orch_pane, sources)})
    return {
        "session": session,
        "repo": loop.get("repo") or topo.get("repo") or topo.get("project_key") or "",
        "orchestrator_pane": orch_pane,
        "worker_panes": sorted(worker_panes),
        "orchestrator_state": orch_state,
        "orchestrator_idle_age_seconds": orch_age,
        "workers_waiting": len(waiting_workers),
        "workers_active": len(active_workers),
        "findings_count": sum(s["count"] for s in sources),
        "findings_sources": sources,
        "productivity_state": state,
        "planned_actions": actions,
    }
def make_report(args):
    parse_errors = []
    probe_errors = []
    topo_latest = latest_by_session(load_jsonl(args.topology, parse_errors))
    loop_rows = loops(args.loops_dir, parse_errors)
    sessions = sorted(set(topo_latest) | set(loop_rows))
    if args.session:
        sessions = [s for s in sessions if s == args.session]
    if not args.include_self:
        sessions = [s for s in sessions if s != "flywheel"]
    rows = []
    for session in sessions:
        topo = topo_latest.get(session, {})
        loop = loop_rows.get(session, {})
        repo = loop.get("repo") or topo.get("repo") or topo.get("project_key") or ""
        act = activity(session, args, probe_errors, parse_errors)
        ready = ready_rows(session, repo, args, parse_errors)
        doc = doctor(session, args, parse_errors)
        rows.append(classify(session, topo, loop, act, ready, doc, args))
    action_count = sum(len(r["planned_actions"]) for r in rows)
    return {
        "success": not parse_errors and not probe_errors,
        "schema_version": SCHEMA,
        "checked_at": datetime.fromtimestamp(args.now_epoch, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "threshold_seconds": args.threshold_seconds,
        "memory": MEMORY,
        "sessions_checked": len(rows),
        "idle_with_work_available_count": sum(1 for r in rows if r["productivity_state"] == "idle_with_work_available"),
        "josh_notify_allowlisted_count": sum(1 for r in rows if r["productivity_state"] == "josh_notify_allowlisted"),
        "action_required_count": action_count,
        "sessions": rows,
        "parse_errors": parse_errors,
        "probe_errors": probe_errors,
    }
def main():
    args = parse_args()
    if args.info:
        print(json.dumps(info(), sort_keys=True) if args.json else "\n".join(f"{k}: {v}" for k, v in info().items()))
        return 0
    if args.examples:
        print(json.dumps(examples(), sort_keys=True) if args.json else "\n".join(examples()["examples"]))
        return 0
    report = make_report(args)
    if args.json or not args.quiet:
        print(json.dumps(report, sort_keys=True) if args.json else f"action_required={report['action_required_count']} sessions={report['sessions_checked']}")
    if report["parse_errors"]:
        return 2
    if report["probe_errors"] and report["sessions_checked"] == 0:
        return 3
    return 1 if report["action_required_count"] else 0
if __name__ == "__main__":
    raise SystemExit(main())
PY
