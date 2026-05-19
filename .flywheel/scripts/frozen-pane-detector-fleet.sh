#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial → passing per bead flywheel-1hshd.31)
# doctor-mode-tier: scaffolded
# shellcheck disable=SC2034,SC2221,SC2222
# Fleet launchd wrapper for frozen-pane-detector.sh. Conservative by design:
# scheduled cycles observe and record; recovery requires explicit --apply and
# healthy live-truth gates.
set -euo pipefail

VERSION="2026-05-04.2"
SCHEMA_VERSION="frozen-pane-detector-fleet.v1"
LABEL="${FROZEN_FLEET_LABEL:-ai.zeststream.frozen-pane-detector-fleet}"
REPO_ROOT="${FROZEN_FLEET_REPO_ROOT:-/Users/josh/Developer/flywheel}"
DETECTOR="${FROZEN_FLEET_DETECTOR:-$REPO_ROOT/.flywheel/scripts/frozen-pane-detector.sh}"
PLIST="${FROZEN_FLEET_PLIST:-$HOME/Library/LaunchAgents/${LABEL}.plist}"
DOMAIN="${FROZEN_FLEET_DOMAIN:-gui/$(id -u)}"
TARGET="${DOMAIN}/${LABEL}"
STATE_DIR="${FROZEN_FLEET_STATE_DIR:-$HOME/.local/state/flywheel/frozen-pane-detector-fleet}"
EVENTS="${FROZEN_FLEET_EVENTS:-$STATE_DIR/events.jsonl}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
JSONL_APPEND_AVAILABLE=0
BUDGET_FILE="${FROZEN_FLEET_BUDGET_FILE:-$STATE_DIR/budgets.json}"
FATAL_FILE="${FROZEN_FLEET_FATAL_FILE:-$STATE_DIR/FATAL}"
STOP_FILE="${FROZEN_FLEET_STOP_FILE:-$HOME/.flywheel/STOP-frozen-pane-detector-fleet}"
GLOBAL_STOP_FILE="${FROZEN_FLEET_GLOBAL_STOP_FILE:-$HOME/.flywheel/STOP-ALL}"
STDOUT_PATH="${FROZEN_FLEET_STDOUT_PATH:-$HOME/.local/logs/frozen-pane-detector-fleet.out.log}"
STDERR_PATH="${FROZEN_FLEET_STDERR_PATH:-$HOME/.local/logs/frozen-pane-detector-fleet.err.log}"
CADENCE_SECONDS="${FROZEN_FLEET_CADENCE_SECONDS:-30}"
GLOBAL_BUDGET_PER_HOUR="${FROZEN_FLEET_GLOBAL_BUDGET_PER_HOUR:-4}"
PER_PANE_BUDGET_PER_HOUR="${FROZEN_FLEET_PER_PANE_BUDGET_PER_HOUR:-1}"
MODE="doctor"
JSON_OUT=0
DRY_RUN=1
APPLY=0
SESSION="all"
PANE=""
IDEMPOTENCY_KEY=""

if [[ -f "$JSONL_APPEND_LIB" ]]; then
  # shellcheck disable=SC1090,SC1091
  if source "$JSONL_APPEND_LIB" && declare -F fw_jsonl_append_validated >/dev/null; then
    JSONL_APPEND_AVAILABLE=1
  fi
fi

usage() {
  cat <<'USAGE'
Usage:
  frozen-pane-detector-fleet.sh --doctor [--json]
  frozen-pane-detector-fleet.sh health [--json]
  frozen-pane-detector-fleet.sh install --dry-run|--apply [--json]
  frozen-pane-detector-fleet.sh uninstall --dry-run|--apply [--json]
  frozen-pane-detector-fleet.sh cycle [--session all|NAME] [--pane N] [--apply] [--json]
  frozen-pane-detector-fleet.sh repair --scope install --dry-run|--apply [--json]
  frozen-pane-detector-fleet.sh validate plist|budgets|cycle [--json]
  frozen-pane-detector-fleet.sh audit [--json]
  frozen-pane-detector-fleet.sh why <gate|budget|truth|launchd>
  frozen-pane-detector-fleet.sh --info|--examples|quickstart|schema|completion zsh

Scheduled launchd cycles are disabled by default and run observation-only.
USAGE
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
say() { printf '%s\n' "$*"; }
json_escape() { jq -Rn --arg v "$1" '$v'; }

ensure_dirs() {
  mkdir -p "$STATE_DIR" "$(dirname "$STDOUT_PATH")" "$(dirname "$STDERR_PATH")" "$(dirname "$PLIST")"
}

emit_json() {
  printf '%s\n' "$1"
}

append_jsonl_best_effort() {
  local path="$1" row="$2" label="$3" rc
  if [[ "$JSONL_APPEND_AVAILABLE" -ne 1 ]] || ! declare -F fw_jsonl_append_validated >/dev/null; then
    printf 'WARN: %s append skipped; JSONL primitive unavailable: %s\n' "$label" "$JSONL_APPEND_LIB" >&2
    return 0
  fi
  if fw_jsonl_append_validated "$path" "$row"; then
    return 0
  else
    rc=$?
    printf 'WARN: %s append failed rc=%s path=%s\n' "$label" "$rc" "$path" >&2
    return 0
  fi
}

event_append() {
  local payload="$1"
  ensure_dirs
  append_jsonl_best_effort "$EVENTS" "$payload" "frozen-pane fleet event"
}

plist_payload() {
  jq -n \
    --arg label "$LABEL" \
    --arg script "$REPO_ROOT/.flywheel/scripts/frozen-pane-detector-fleet.sh" \
    --arg stdout "$STDOUT_PATH" \
    --arg stderr "$STDERR_PATH" \
    --argjson cadence "$CADENCE_SECONDS" \
    '{
      Label:$label,
      ProgramArguments:["/bin/bash",$script,"cycle","--json"],
      StartInterval:$cadence,
      RunAtLoad:false,
      Disabled:true,
      StandardOutPath:$stdout,
      StandardErrorPath:$stderr
    }'
}

write_plist() {
  local tmp
  ensure_dirs
  tmp="${PLIST}.$$"
  python3 - "$tmp" "$LABEL" "$REPO_ROOT/.flywheel/scripts/frozen-pane-detector-fleet.sh" "$STDOUT_PATH" "$STDERR_PATH" "$CADENCE_SECONDS" <<'PY'
import plistlib
import sys

payload = {
    "Label": sys.argv[2],
    "ProgramArguments": ["/bin/bash", sys.argv[3], "cycle", "--json"],
    "StartInterval": int(sys.argv[6]),
    "RunAtLoad": False,
    "Disabled": True,
    "StandardOutPath": sys.argv[4],
    "StandardErrorPath": sys.argv[5],
}
with open(sys.argv[1], "wb") as fh:
    plistlib.dump(payload, fh, sort_keys=False)
PY
  plutil -lint "$tmp" >/dev/null
  mv "$tmp" "$PLIST"
}

plist_field() {
  local field="$1"
  [[ -f "$PLIST" ]] || return 1
  plutil -extract "$field" raw "$PLIST" 2>/dev/null
}

launchd_loaded() {
  launchctl print "$TARGET" >/dev/null 2>&1
}

doctor_json() {
  local installed loaded disabled cadence stdout stderr status warnings errors detector_ok
  installed=false
  loaded=false
  disabled=null
  cadence=null
  stdout=""
  stderr=""
  status="PASS"
  warnings="[]"
  errors="[]"
  detector_ok=false

  [[ -x "$DETECTOR" ]] && detector_ok=true
  if [[ -f "$PLIST" ]]; then
    installed=true
    disabled="$(plist_field Disabled || printf 'missing')"
    cadence="$(plist_field StartInterval || printf 'missing')"
    stdout="$(plist_field StandardOutPath || true)"
    stderr="$(plist_field StandardErrorPath || true)"
  else
    warnings="$(jq -nc '[{code:"daemon_absent",message:"fleet LaunchAgent is not installed; disabled-by-default install is available"}]')"
    status="WARN"
  fi
  if launchd_loaded; then
    loaded=true
  fi
  if [[ "$installed" == true && "$disabled" != "1" && "$disabled" != "true" ]]; then
    status="FAIL"
    errors="$(jq -nc '[{code:"daemon_not_disabled",message:"LaunchAgent must be disabled by default"}]')"
  fi
  if [[ "$installed" == true && "$cadence" != "$CADENCE_SECONDS" ]]; then
    status="FAIL"
    errors="$(printf '%s\n' "$errors" | jq --arg cadence "$cadence" '. + [{code:"cadence_mismatch",message:("StartInterval="+$cadence)}]')"
  fi
  if [[ "$detector_ok" != true ]]; then
    status="FAIL"
    errors="$(printf '%s\n' "$errors" | jq '. + [{code:"detector_missing",message:"base frozen-pane-detector.sh is missing or not executable"}]')"
  fi
  jq -n \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg label "$LABEL" \
    --arg target "$TARGET" \
    --arg plist "$PLIST" \
    --arg status "$status" \
    --arg checked_at "$(now_iso)" \
    --arg stdout "$STDOUT_PATH" \
    --arg stderr "$STDERR_PATH" \
    --arg stop_file "$STOP_FILE" \
    --arg global_stop_file "$GLOBAL_STOP_FILE" \
    --arg fatal_file "$FATAL_FILE" \
    --arg budget_file "$BUDGET_FILE" \
    --arg events "$EVENTS" \
    --argjson daemon_installed "$installed" \
    --argjson daemon_loaded "$loaded" \
    --argjson detector_ok "$detector_ok" \
    --argjson cadence "$CADENCE_SECONDS" \
    --argjson global_budget "$GLOBAL_BUDGET_PER_HOUR" \
    --argjson per_pane_budget "$PER_PANE_BUDGET_PER_HOUR" \
    --argjson warnings "$warnings" \
    --argjson errors "$errors" \
    '{
      schema_version:$schema_version,
      version:$version,
      mode:"doctor",
      success:($status != "FAIL"),
      status:$status,
      checked_at:$checked_at,
      label:$label,
      target:$target,
      plist:$plist,
      daemon_installed:$daemon_installed,
      daemon_loaded:$daemon_loaded,
      disabled_by_default:true,
      cadence_seconds:$cadence,
      stdout_path:$stdout,
      stderr_path:$stderr,
      detector_ok:$detector_ok,
      stop_files:[$stop_file,$global_stop_file],
      fatal_state_file:$fatal_file,
      budget_file:$budget_file,
      events:$events,
      recovery_budget:{global_per_hour:$global_budget,per_pane_per_hour:$per_pane_budget},
      degraded_truth_auto_recovery_blocked:true,
      warnings:$warnings,
      errors:$errors
    }'
}

install_json() {
  local actions
  actions="$(jq -n --arg plist "$PLIST" --arg stdout "$STDOUT_PATH" --arg stderr "$STDERR_PATH" --argjson cadence "$CADENCE_SECONDS" \
    '[{action:"write_disabled_launchagent",path:$plist},{action:"ensure_log_paths",stdout:$stdout,stderr:$stderr},{action:"set_cadence",seconds:$cadence}]')"
  if [[ "$APPLY" == "1" ]]; then
    write_plist
    event_append "$(jq -nc --arg ts "$(now_iso)" --arg action "install" --arg plist "$PLIST" '{ts:$ts,action:$action,plist:$plist,disabled_by_default:true}')"
    jq -n --arg schema_version "$SCHEMA_VERSION" --arg mode "install" --arg plist "$PLIST" --argjson actions "$actions" \
      '{schema_version:$schema_version,mode:$mode,success:true,applied:true,plist:$plist,actual_actions:$actions,loaded:false,disabled_by_default:true}'
  else
    jq -n --arg schema_version "$SCHEMA_VERSION" --arg mode "install" --arg plist "$PLIST" --argjson actions "$actions" \
      '{schema_version:$schema_version,mode:$mode,success:true,dry_run:true,plist:$plist,planned_actions:$actions,loaded:false,disabled_by_default:true}'
  fi
}

uninstall_json() {
  local actions
  actions="$(jq -n --arg target "$TARGET" --arg plist "$PLIST" '[{action:"bootout_if_loaded",target:$target},{action:"remove_plist",path:$plist}]')"
  if [[ "$APPLY" == "1" ]]; then
    if launchd_loaded; then launchctl bootout "$TARGET"; fi
    rm -f "$PLIST"
    event_append "$(jq -nc --arg ts "$(now_iso)" --arg action "uninstall" --arg plist "$PLIST" '{ts:$ts,action:$action,plist:$plist}')"
    jq -n --arg schema_version "$SCHEMA_VERSION" --argjson actions "$actions" '{schema_version:$schema_version,mode:"uninstall",success:true,applied:true,actual_actions:$actions}'
  else
    jq -n --arg schema_version "$SCHEMA_VERSION" --argjson actions "$actions" '{schema_version:$schema_version,mode:"uninstall",success:true,dry_run:true,planned_actions:$actions}'
  fi
}

recent_recoveries_json() {
  local since
  since="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)"
  [[ -f "$EVENTS" ]] || { printf '[]\n'; return; }
  jq -s --arg since "$since" '[.[] | select(.ts >= $since and .recovery_applied == true)]' "$EVENTS" 2>/dev/null || printf '[]\n'
}

budget_state_json() {
  local recoveries global_count pane_count budget_ok
  recoveries="$(recent_recoveries_json)"
  global_count="$(printf '%s\n' "$recoveries" | jq 'length')"
  if [[ -n "$PANE" ]]; then
    pane_count="$(printf '%s\n' "$recoveries" | jq --arg session "$SESSION" --arg pane "$PANE" '[.[] | select(.session == $session and .pane == $pane)] | length')"
  else
    pane_count=0
  fi
  budget_ok=true
  if [[ "$global_count" -ge "$GLOBAL_BUDGET_PER_HOUR" ]]; then budget_ok=false; fi
  if [[ -n "$PANE" && "$pane_count" -ge "$PER_PANE_BUDGET_PER_HOUR" ]]; then budget_ok=false; fi
  jq -n \
    --argjson global_count "$global_count" \
    --argjson pane_count "$pane_count" \
    --argjson global_limit "$GLOBAL_BUDGET_PER_HOUR" \
    --argjson pane_limit "$PER_PANE_BUDGET_PER_HOUR" \
    --argjson ok "$budget_ok" \
    '{ok:$ok,global:{used_last_hour:$global_count,limit_per_hour:$global_limit},pane:{used_last_hour:$pane_count,limit_per_hour:$pane_limit}}'
}

detector_payload() {
  if [[ -n "${FROZEN_FLEET_DETECTOR_FIXTURE:-}" ]]; then
    cat "$FROZEN_FLEET_DETECTOR_FIXTURE"
    return
  fi
  if [[ -x "$DETECTOR" ]]; then
    "$DETECTOR" --session="$SESSION" --auto-recover --dry-run --json 2>/dev/null || true
  fi
}

truth_is_degraded() {
  jq -e '(.success != true) or (.source_health.status? != "healthy") or ((.l60_signals_present? // {}) | length == 0)' >/dev/null
}

cycle_json() {
  local budget payload degraded=false reason="ok" recovery_applied=false detector_status="missing"
  ensure_dirs
  budget="$(budget_state_json)"
  if [[ -f "$GLOBAL_STOP_FILE" || -f "$STOP_FILE" ]]; then
    reason="stopped"
  elif [[ -f "$FATAL_FILE" ]]; then
    reason="fatal"
  elif ! printf '%s\n' "$budget" | jq -e '.ok == true' >/dev/null; then
    reason="budget_exhausted"
  else
    payload="$(detector_payload)"
    if [[ -z "$payload" ]]; then
      reason="degraded_truth"
      degraded=true
    elif printf '%s\n' "$payload" | truth_is_degraded; then
      reason="degraded_truth"
      degraded=true
      detector_status="$(printf '%s\n' "$payload" | jq -r '.source_health.status? // "degraded"' 2>/dev/null || printf 'invalid')"
    else
      detector_status="healthy"
      if [[ "$APPLY" == "1" ]]; then
        recovery_applied=false
        reason="apply_blocked_by_design"
      fi
    fi
  fi
  local output
  output="$(jq -n \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$(now_iso)" \
    --arg session "$SESSION" \
    --arg pane "$PANE" \
    --arg reason "$reason" \
    --arg detector_status "$detector_status" \
    --argjson dry_run "$DRY_RUN" \
    --argjson apply "$APPLY" \
    --argjson budget "$budget" \
    --argjson degraded "$degraded" \
    --argjson recovery_applied "$recovery_applied" \
    '{
      schema_version:$schema_version,
      mode:"cycle",
      success:($reason != "fatal"),
      ts:$ts,
      session:$session,
      pane:(if $pane == "" then null else $pane end),
      dry_run:$dry_run,
      apply_requested:$apply,
      decision:$reason,
      detector_status:$detector_status,
      budget:$budget,
      recovery_applied:$recovery_applied,
      degraded_truth_auto_recovery_blocked:$degraded,
      stopped:($reason == "stopped"),
      fatal:($reason == "fatal")
    }')"
  event_append "$output"
  printf '%s\n' "$output"
}

validate_json() {
  local thing="${1:-cycle}"
  case "$thing" in
    plist)
      if [[ -f "$PLIST" ]] && plutil -lint "$PLIST" >/dev/null; then
        jq -n --arg schema_version "$SCHEMA_VERSION" --arg thing "$thing" '{schema_version:$schema_version,mode:"validate",thing:$thing,success:true}'
      else
        jq -n --arg schema_version "$SCHEMA_VERSION" --arg thing "$thing" '{schema_version:$schema_version,mode:"validate",thing:$thing,success:false,error:"plist_missing_or_invalid"}'
      fi
      ;;
    budgets)
      budget_state_json | jq --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,mode:"validate",thing:"budgets",success:.ok,budget:.}'
      ;;
    cycle)
      cycle_json | jq --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,mode:"validate",thing:"cycle",success:true,cycle:.}'
      ;;
    *) jq -n --arg schema_version "$SCHEMA_VERSION" --arg thing "$thing" '{schema_version:$schema_version,mode:"validate",thing:$thing,success:false,error:"unknown_validation_target"}'; return 2 ;;
  esac
}

audit_json() {
  ensure_dirs
  if [[ -f "$EVENTS" ]]; then
    jq -s --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,mode:"audit",success:true,events:(.[-20:] // [])}' "$EVENTS"
  else
    jq -n --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,mode:"audit",success:true,events:[]}'
  fi
}

info_json() {
  # AG3.1 (bead flywheel-1hshd.31) requires .name + .version + .capabilities.
  # Augmented to add .name + .capabilities while preserving every native field
  # (.version, .commands, .label, .detector, .plist, .state_dir) — the
  # regression test asserts `.commands | index("doctor") and index("repair")
  # and ...` which remains satisfied.
  jq -n \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg label "$LABEL" \
    --arg detector "$DETECTOR" \
    --arg plist "$PLIST" \
    --arg state_dir "$STATE_DIR" \
    '{schema_version:$schema_version,mode:"info",success:true,name:"frozen-pane-detector-fleet.sh",version:$version,capabilities:["fleet-launchd-wrapper","disabled-by-default-install","l60-l67-degraded-truth-block","global-and-per-pane-budget","stop-and-fatal-file-honor","reversible-uninstall"],mutates_state:true,mutation_paths:["plist-write-on-install","event-jsonl-append","budget-state-update"],label:$label,detector:$detector,plist:$plist,state_dir:$state_dir,commands:["doctor","health","install","uninstall","cycle","repair","validate","audit","why","schema","quickstart","completion"]}'
}

schema_json() {
  # AG3.2 (bead flywheel-1hshd.31) requires .input_schema + .output_schema.
  # Augmented to add canonical JSON-Schema envelopes while preserving native
  # .title + .required for back-compat.
  jq -n --arg schema_version "$SCHEMA_VERSION" '{
    schema_version:$schema_version,
    title:"Frozen pane detector fleet wrapper output",
    required:["schema_version","mode","success"],
    input_schema:{
      type:"object",
      properties:{
        session:{type:"string"},
        pane:{type:["string","integer"]},
        apply:{type:"boolean"},
        dry_run:{type:"boolean"},
        json:{type:"boolean"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","mode","success"],
      properties:{
        schema_version:{const:"frozen-pane-detector-fleet.v1"},
        mode:{enum:["doctor","health","install","uninstall","cycle","repair","validate","audit","why","info","schema","examples","quickstart","completion"]},
        success:{type:"boolean"},
        status:{enum:["PASS","WARN","FAIL"]},
        daemon_installed:{type:"boolean"},
        daemon_loaded:{type:"boolean"},
        cadence_seconds:{type:"integer"},
        warnings:{type:"array"},
        errors:{type:"array"}
      }
    }
  }'
}

examples() {
  # AG3.3 (bead flywheel-1hshd.31) requires --examples --json | jq -e
  # '.examples | length > 0'. When --json was passed (JSON_OUT==1) emit
  # canonical envelope; otherwise preserve native text mode for back-compat
  # with the regression test (`"$SCRIPT" --examples >/dev/null` checks rc only).
  if [[ "${JSON_OUT:-0}" == "1" ]]; then
    jq -n --arg sv "$SCHEMA_VERSION" '{
      schema_version:$sv,
      mode:"examples",
      success:true,
      examples:[
        {name:"doctor probe",invocation:"frozen-pane-detector-fleet.sh --doctor --json",purpose:"check fleet daemon installed + disabled-by-default contract"},
        {name:"install dry-run",invocation:"frozen-pane-detector-fleet.sh install --dry-run --json",purpose:"preview LaunchAgent write without mutating"},
        {name:"install apply",invocation:"frozen-pane-detector-fleet.sh install --apply --json",purpose:"write disabled-by-default LaunchAgent (load/kickstart is a separate human decision)"},
        {name:"cycle all sessions",invocation:"frozen-pane-detector-fleet.sh cycle --session all --json",purpose:"observe detector state across the fleet (degraded truth blocks recovery by design)"},
        {name:"validate budgets",invocation:"frozen-pane-detector-fleet.sh validate budgets --json",purpose:"check global + per-pane hourly recovery budgets"}
      ]
    }'
    return 0
  fi
  cat <<'EXAMPLES'
frozen-pane-detector-fleet.sh --doctor --json
frozen-pane-detector-fleet.sh install --dry-run --json
frozen-pane-detector-fleet.sh install --apply --json
frozen-pane-detector-fleet.sh cycle --session all --json
frozen-pane-detector-fleet.sh validate budgets --json
EXAMPLES
}

quickstart() {
  cat <<'QUICKSTART'
Install writes a disabled LaunchAgent only. Load/kickstart is intentionally a
separate human/orchestrator decision. Scheduled cycles observe detector state,
honor STOP and FATAL files, and never auto-recover degraded truth.
QUICKSTART
}

why_text() {
  case "${1:-gate}" in
    gate|truth) say "L60/L67 require live, non-degraded truth before recovery; this wrapper blocks recovery on degraded detector output." ;;
    budget) say "Global and per-pane hourly budgets prevent recovery storms across the fleet." ;;
    launchd) say "The LaunchAgent is disabled by default so install is reversible and does not silently mutate pane state." ;;
    *) say "Known topics: gate, truth, budget, launchd" ;;
  esac
}

completion() {
  cat <<'ZSH'
#compdef frozen-pane-detector-fleet.sh
_arguments '1:command:(doctor health install uninstall cycle repair validate audit why schema quickstart completion)'
ZSH
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --doctor|doctor) MODE="doctor"; shift ;;
    health) MODE="health"; shift ;;
    install) MODE="install"; shift ;;
    uninstall) MODE="uninstall"; shift ;;
    cycle) MODE="cycle"; shift ;;
    repair) MODE="repair"; shift ;;
    validate) MODE="validate"; shift ;;
    audit) MODE="audit"; shift ;;
    why) MODE="why"; shift ;;
    schema) MODE="schema"; shift ;;
    quickstart) MODE="quickstart"; shift ;;
    completion) MODE="completion"; shift ;;
    --info) MODE="info"; shift ;;
    --examples|examples) MODE="examples"; shift ;;
    # flywheel-ecujm: --schema flag delegates to schema_json (the `schema`
    # subcommand) so the introspection triad+1 (--help/--info/--schema/
    # --examples) is uniformly accessible as flags per
    # agent-ergonomics-cli-max R001.
    --schema) MODE="schema"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --session) SESSION="${2:?--session needs value}"; shift 2 ;;
    --session=*) SESSION="${1#--session=}"; shift ;;
    --pane) PANE="${2:?--pane needs value}"; shift 2 ;;
    --pane=*) PANE="${1#--pane=}"; shift ;;
    --scope) shift 2 ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:?--idempotency-key needs value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    zsh|plist|budgets|cycle|gate|budget|truth|launchd) break ;;
    *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

# AG3.4 (bead flywheel-1hshd.31) requires `doctor --json | jq -e '.checks'`.
# Augment doctor output to add a .checks array (canonical named-probe
# shape) while preserving every native field (.status, .daemon_installed,
# .cadence_seconds, .warnings, .errors) — the regression test asserts
# `.status == "WARN" and .daemon_installed == false and warnings code` +
# `.status == "PASS" and .cadence_seconds == 30` which remain satisfied.
augmented_doctor_json() {
  local raw bash_s=fail jq_s=fail launchctl_s=warn plutil_s=warn detector_s=warn plist_dir_s=fail
  command -v bash >/dev/null 2>&1 && bash_s=pass
  command -v jq >/dev/null 2>&1 && jq_s=pass
  command -v launchctl >/dev/null 2>&1 && launchctl_s=pass
  command -v plutil >/dev/null 2>&1 && plutil_s=pass
  [[ -x "${DETECTOR:-}" ]] && detector_s=pass
  local _plist_dir; _plist_dir="$(dirname "${PLIST:-/}")"
  [[ -d "$_plist_dir" && -w "$_plist_dir" ]] && plist_dir_s=pass
  raw="$(doctor_json)"
  printf '%s\n' "$raw" | jq -c \
    --arg bash_s "$bash_s" --arg jq_s "$jq_s" --arg lc_s "$launchctl_s" \
    --arg pu_s "$plutil_s" --arg det_s "$detector_s" --arg pd_s "$plist_dir_s" \
    --arg det "${DETECTOR:-}" --arg pd "$_plist_dir" \
    '. + {checks:[
      {name:"bash_available",status:$bash_s},
      {name:"jq_available",status:$jq_s},
      {name:"launchctl_available",status:$lc_s,detail:"load-bearing — used to probe LaunchAgent loaded state"},
      {name:"plutil_available",status:$pu_s,detail:"load-bearing — used to read plist fields"},
      {name:"detector_executable",status:$det_s,path:$det,detail:"load-bearing — base frozen-pane-detector.sh"},
      {name:"plist_dir_writable",status:$pd_s,path:$pd}
    ]}'
}

case "$MODE" in
  doctor|health) emit_json "$(augmented_doctor_json)" ;;
  install) emit_json "$(install_json)" ;;
  uninstall) emit_json "$(uninstall_json)" ;;
  cycle) emit_json "$(cycle_json)" ;;
  repair) emit_json "$(install_json)" ;;
  validate) emit_json "$(validate_json "${1:-cycle}")" ;;
  audit) emit_json "$(audit_json)" ;;
  why) why_text "${1:-gate}" ;;
  info) emit_json "$(info_json)" ;;
  schema) schema_json ;;
  examples) examples ;;
  quickstart) quickstart ;;
  completion) completion ;;
  *) usage; exit 2 ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
