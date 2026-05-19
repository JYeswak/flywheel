#!/usr/bin/env bash
# adversarial-orch-self-audit-probe.sh — closes flywheel-1rmp.10 (value-gap
# `adversarial-orchestrator-self-audit`).
#
# The smallest recurring measurement that makes the value gap visible: scan
# recent orchestrator dispatch packets + callbacks for adversarial signals
# the orchestrator might be cutting corners on. Four-axis snapshot:
#
#   1. punt_phrase_count       — L70 forbidden phrases in recent dispatch packets
#   2. mission_drift_count     — dispatches with mission_fitness=drift
#   3. unaddressed_skill_routes — skill auto-routes catalog matched but
#                                  not addressed (yes|no|n/a missing)
#   4. recent_closed_beads_without_evidence — beads closed today with no
#                                  .flywheel/evidence/<bead-id>/ dir
#
# Step 4o anti-pattern preserved: probe is READ-ONLY. No br/ntm/gh/git/
# agent-mail mutating verbs in source. No auto-dispatch from findings.
# Output is structured JSON only. The orchestrator decides what to do with
# the findings; this probe just measures.
#
# Canonical-cli-scoping triad: --doctor / --health / --info / --schema /
# --json with stable exit codes.
set -euo pipefail

SCHEMA_VERSION="adversarial-orch-self-audit-probe.v1"
DEFAULT_DISPATCH_LOG="/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl"
DEFAULT_TMP_DISPATCH_DIR="/tmp"
DEFAULT_EVIDENCE_DIR="/Users/josh/Developer/flywheel/.flywheel/evidence"
DEFAULT_BEADS_BIN="$(command -v br 2>/dev/null || echo /Users/josh/.cargo/bin/br)"

DISPATCH_LOG="$DEFAULT_DISPATCH_LOG"
TMP_DISPATCH_DIR="$DEFAULT_TMP_DISPATCH_DIR"
EVIDENCE_DIR="$DEFAULT_EVIDENCE_DIR"
BR_BIN="$DEFAULT_BEADS_BIN"
LOOKBACK_HOURS=24
JSON_OUT=0
MODE=run

# L70 forbidden punt-phrase catalog (lowercased; trailing context-stripped).
PUNT_PHRASES=(
  "should i"
  "should we"
  "want me to"
  "do you want me to"
  "would you like me to"
  "shall i"
  "let me know if"
  "let me know when"
  "if you want me to"
  "if you'd like"
  "when you're ready"
  "say the word"
  "want to proceed"
  "confirm and i'll"
  "the next move is yours"
  "standing by"
)

usage() {
  cat <<'USAGE'
usage: adversarial-orch-self-audit-probe.sh [--lookback-hours N] [--json]
       adversarial-orch-self-audit-probe.sh --doctor|--health|--info|--schema [--json]

Multi-axis adversarial self-audit of orchestrator behavior. Four axes:

  1. punt_phrase_count: L70 forbidden phrases in recent /tmp/dispatch_*.md packets
  2. mission_drift_count: dispatches with mission_fitness=drift in dispatch-log
  3. unaddressed_skill_routes_count: callbacks where catalog skill missing yes|no|n/a
     (heuristic — packets list `skill_auto_routes_addressed=...` field)
  4. recent_closed_beads_without_evidence: closed beads (last 24h) with no
     .flywheel/evidence/<bead-id>/ directory present

Default --lookback-hours 24. Emits findings as JSON; never auto-dispatches.

Exit codes:
  0  measurement emitted
  1  no input data in window
  2  config error
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg dlog "$DISPATCH_LOG" --arg evid "$EVIDENCE_DIR" --arg brb "$BR_BIN" \
    '{schema_version:$schema, success:true, mode:"doctor",
      dispatch_log:$dlog, evidence_dir:$evid, br_bin:$brb,
      reads_only:true, auto_dispatch:false,
      surfaces:["tick receipt consumer","dashboard tile","doctor signal candidate"],
      step_4o_compliance:"preserved",
      out_of_scope:["auto-dispatch","Joshua-blocker creation","Pushover notification"]}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      axes:[
        "punt_phrase_count: L70 forbidden phrases in recent dispatch packets",
        "mission_drift_count: dispatches with mission_fitness=drift",
        "unaddressed_skill_routes_count: skill catalog matched but not addressed",
        "recent_closed_beads_without_evidence: closed beads missing evidence dir"
      ],
      doctrine:"orchestrator behavior should pass the same adversarial audits we run on plans",
      reads_only:true,
      step_4o_compliance:"preserved"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        lookback_hours:{type:"integer"},
        punt_phrase_count:{type:"integer"},
        punt_phrase_samples:{type:"array"},
        mission_drift_count:{type:"integer"},
        unaddressed_skill_routes_count:{type:"integer"},
        recent_closed_beads_without_evidence:{type:"integer"},
        recent_closed_beads_sampled:{type:"integer"},
        adversarial_signal:{type:"boolean"},
        adversarial_axes_triggered:{type:"array"}}}'
}


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: partial → passing (filled-in per bead flywheel-1hshd.1)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# Partial-baseline coexistence (wave-4 vs wave-2 missing-baseline):
# the existing bash script already has --info / --schema / --doctor /
# --health / --help / --json as dash-flag canonical surfaces. Bash
# scaffold ADDS the missing gaps:
#   - --examples (NEW dash flag — python+bash both rejected today)
#   - doctor / health / repair / validate / audit / why / quickstart /
#     help <topic> / completion (NEW no-dash subcommand family)
# The existing dash-flag forms (--info/--schema/--doctor/--health/-h/--help)
# fall through to the original argparse loop UNCHANGED.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="adversarial-orch-self-audit-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/adversarial-orch-self-audit-probe-runs.jsonl}"

scaffold_emit_examples() {
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{
      schema_version: $sv,
      command: "examples",
      examples: [
        "adversarial-orch-self-audit-probe.sh --json",
        "adversarial-orch-self-audit-probe.sh --lookback-hours 12 --json",
        "adversarial-orch-self-audit-probe.sh --info --json",
        "adversarial-orch-self-audit-probe.sh --schema --json",
        "adversarial-orch-self-audit-probe.sh --doctor --json",
        "adversarial-orch-self-audit-probe.sh doctor --json",
        "adversarial-orch-self-audit-probe.sh validate --dispatch-log"
      ]
    }'
}

scaffold_emit_quickstart() {
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{schema_version:$sv,command:"quickstart",steps:[
      {step:1,action:"probe canonical doctor",command:"adversarial-orch-self-audit-probe.sh doctor --json"},
      {step:2,action:"check recent dispatches",command:"adversarial-orch-self-audit-probe.sh --json --lookback-hours 24"},
      {step:3,action:"validate dispatch-log shape",command:"adversarial-orch-self-audit-probe.sh validate --dispatch-log"}
    ]}'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default mode emits 4-axis adversarial signal JSON (punt_phrase_count, mission_drift_count, unaddressed_skill_routes_count, recent_closed_beads_without_evidence). Read-only by step_4o doctrine.\n' ;;
    doctor)   printf 'topic: doctor — read-only canonical substrate probe. Also accessible via legacy --doctor flag.\n' ;;
    health)   printf 'topic: health — read-only canonical health snapshot. Also accessible via legacy --health flag.\n' ;;
    repair)   printf 'topic: repair — scopes: audit-log-rotate (>5MB → mv .ts), dispatch-log-prime (read-only — probes dispatch-log row count).\n' ;;
    validate) printf 'topic: validate — subjects: --row-json JSON, --schema, --config, --dispatch-log (probes dispatch-log row schema), --evidence-dir (counts evidence directories).\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh>\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "adversarial-orch-self-audit-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--examples,--info,--schema,--doctor,--health,--lookback-hours,--dispatch-log,--tmp-dispatch-dir,--evidence-dir,--br-bin" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "adversarial-orch-self-audit-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

scaffold_cmd_doctor() {
  # Canonical doctor — substrate probes (different from legacy --doctor surface).
  local script_root; script_root="$_SCAFFOLD_REPO_ROOT"
  local checks="" overall="pass"

  if command -v jq >/dev/null 2>&1; then
    checks+="$(jq -nc --arg p "$(command -v jq)" '{name:"jq_on_path",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc '{name:"jq_on_path",status:"fail"}')"$'\n'
    overall="fail"
  fi

  local dl_present=false dl_rows=0
  if [[ -r "$DISPATCH_LOG" ]]; then
    dl_present=true
    dl_rows="$(wc -l < "$DISPATCH_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
  fi
  local dl_status="pass"; [[ "$dl_present" != true ]] && dl_status="warn"
  checks+="$(jq -nc --arg p "$DISPATCH_LOG" --arg s "$dl_status" --argjson present "$dl_present" --argjson rows "${dl_rows:-0}" \
    '{name:"dispatch_log_readable",status:$s,value:$p,present:$present,row_count:$rows}')"$'\n'

  local ev_present=false ev_count=0
  if [[ -d "$EVIDENCE_DIR" ]]; then
    ev_present=true
    ev_count="$(find "$EVIDENCE_DIR" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  fi
  local ev_status="pass"; [[ "$ev_present" != true ]] && ev_status="warn"
  checks+="$(jq -nc --arg p "$EVIDENCE_DIR" --arg s "$ev_status" --argjson present "$ev_present" --argjson count "${ev_count:-0}" \
    '{name:"evidence_dir_readable",status:$s,value:$p,present:$present,subdir_count:$count}')"$'\n'

  if [[ -x "$BR_BIN" ]]; then
    checks+="$(jq -nc --arg p "$BR_BIN" '{name:"br_bin_executable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$BR_BIN" '{name:"br_bin_executable",status:"warn",value:$p,detail:"br used for closed-bead enumeration"}')"$'\n'
  fi

  local tmp_present=false
  [[ -d "$TMP_DISPATCH_DIR" ]] && tmp_present=true
  local tmp_status="pass"; [[ "$tmp_present" != true ]] && tmp_status="warn"
  checks+="$(jq -nc --arg p "$TMP_DISPATCH_DIR" --arg s "$tmp_status" --argjson present "$tmp_present" \
    '{name:"tmp_dispatch_dir_present",status:$s,value:$p,present:$present}')"$'\n'

  if [[ -d "$script_root" ]]; then
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"pass",value:$p}')"$'\n'
  else
    checks+="$(jq -nc --arg p "$script_root" '{name:"flywheel_root_resolvable",status:"fail",value:$p}')"$'\n'
    overall="fail"
  fi

  local ts; ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$checks" | jq -sc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$overall" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$status,checks:.}'
}

scaffold_cmd_health() {
  local ts; ts="$(cli_iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local log="$SCAFFOLD_AUDIT_LOG"
  local last_row="null" stale_seconds=-1 status="warn"
  local dl_rows=0 ev_count=0
  if [[ -r "$log" ]]; then
    local row_raw; row_raw="$(tail -n 1 "$log" 2>/dev/null || true)"
    if [[ -n "$row_raw" ]] && printf '%s' "$row_raw" | jq -e '.' >/dev/null 2>&1; then
      last_row="$row_raw"
      local last_ts; last_ts="$(printf '%s' "$row_raw" | jq -r '.ts // empty' 2>/dev/null || true)"
      if [[ -n "$last_ts" ]]; then
        local last_epoch now_epoch
        last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo 0)"
        now_epoch="$(date -u +%s)"
        if [[ "$last_epoch" -gt 0 ]]; then
          stale_seconds=$((now_epoch - last_epoch))
          if [[ "$stale_seconds" -le 604800 ]]; then status="pass"; fi
        fi
      fi
    fi
  fi
  [[ -r "$DISPATCH_LOG" ]] && dl_rows="$(wc -l < "$DISPATCH_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
  [[ -d "$EVIDENCE_DIR" ]] && ev_count="$(find "$EVIDENCE_DIR" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$log" \
    --arg status "$status" --argjson stale "$stale_seconds" --argjson row "$last_row" \
    --argjson dlr "${dl_rows:-0}" --argjson evc "${ev_count:-0}" \
    --arg dl "$DISPATCH_LOG" --arg ev "$EVIDENCE_DIR" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,stale_seconds:$stale,last_row:$row,dispatch_log:$dl,dispatch_log_rows:$dlr,evidence_dir:$ev,evidence_subdir_count:$evc}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
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
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  case "$scope" in
    audit-log-rotate)
      local log="$SCAFFOLD_AUDIT_LOG"
      local size_bytes=0 rotated=false
      [[ -r "$log" ]] && size_bytes="$(stat -f '%z' "$log" 2>/dev/null || echo 0)"
      if [[ "$mode" == "apply" && "$size_bytes" -gt 5242880 ]]; then
        local rotated_path="${log}.$(date -u +%Y%m%dT%H%M%SZ)"
        if mv "$log" "$rotated_path" 2>/dev/null; then
          : > "$log" 2>/dev/null || true
          rotated=true
        fi
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg log "$log" --argjson sz "$size_bytes" --argjson r "$rotated" \
        '{schema_version:$sv,command:"repair",status:"pass",mode:$mode,scope:$scope,idempotency_key:$idem,audit_log:$log,size_bytes:$sz,rotation_threshold:5242880,rotated:$r}'
      ;;
    dispatch-log-prime)
      local present=false rows=0 size_bytes=0
      if [[ -r "$DISPATCH_LOG" ]]; then
        present=true
        rows="$(wc -l < "$DISPATCH_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
        size_bytes="$(stat -f '%z' "$DISPATCH_LOG" 2>/dev/null || echo 0)"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" \
        --arg idem "$idem_key" --arg dl "$DISPATCH_LOG" --arg s "$status" \
        --argjson present "$present" --argjson rows "${rows:-0}" --argjson sz "${size_bytes:-0}" \
        '{schema_version:$sv,command:"repair",status:$s,mode:$mode,scope:$scope,idempotency_key:$idem,dispatch_log:$dl,present:$present,row_count:$rows,size_bytes:$sz,note:"read-only probe"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        '{schema_version:$sv,command:"repair",status:"unknown_scope",mode:$mode,scope:$scope,idempotency_key:$idem,known_scopes:["audit-log-rotate","dispatch-log-prime"]}'
      ;;
  esac
}

scaffold_cmd_validate() {
  local subject="" row_json=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      --row-json) subject="row"; row_json="${2:-}"; shift 2 ;;
      --row-json=*) subject="row"; row_json="${1#--row-json=}"; shift ;;
      --schema) subject="schema"; shift ;;
      --config) subject="config"; shift ;;
      --dispatch-log) subject="dispatch-log"; shift ;;
      --evidence-dir) subject="evidence-dir"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown validate arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  case "$subject" in
    row)
      local valid=true missing=""
      if [[ -z "$row_json" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"--row-json required"}'
        return 0
      fi
      if ! printf '%s' "$row_json" | jq -e '.' >/dev/null 2>&1; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",subject:"row",status:"fail",valid:false,reason:"invalid_json"}'
        return 0
      fi
      # Probe output row schema (4-axis adversarial signal).
      for f in schema_version lookback_hours punt_phrase_count mission_drift_count; do
        if ! printf '%s' "$row_json" | jq -e --arg k "$f" 'has($k)' >/dev/null 2>&1; then
          valid=false; missing="${missing}${f},"
        fi
      done
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson v "$valid" --arg m "${missing%,}" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $v then "pass" else "fail" end),valid:$v,missing:$m}'
      ;;
    schema)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",subject:"schema",status:"pass",surfaces:["doctor","health","repair","validate","audit","why","audit-row"]}'
      ;;
    config)
      local jq_ok=false dl_ok=false ev_ok=false br_ok=false root_ok=false
      command -v jq >/dev/null 2>&1 && jq_ok=true
      [[ -r "$DISPATCH_LOG" ]] && dl_ok=true
      [[ -d "$EVIDENCE_DIR" ]] && ev_ok=true
      [[ -x "$BR_BIN" ]] && br_ok=true
      [[ -d "$_SCAFFOLD_REPO_ROOT" ]] && root_ok=true
      local overall=pass
      [[ "$jq_ok" != true || "$root_ok" != true ]] && overall=fail
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$overall" \
        --argjson jqq "$jq_ok" --argjson dl "$dl_ok" --argjson ev "$ev_ok" --argjson br "$br_ok" --argjson rt "$root_ok" \
        --arg root "$_SCAFFOLD_REPO_ROOT" --arg dl_p "$DISPATCH_LOG" --arg ev_p "$EVIDENCE_DIR" --arg br_p "$BR_BIN" \
        '{schema_version:$sv,command:"validate",subject:"config",status:$s,jq_present:$jqq,dispatch_log_present:$dl,evidence_dir_present:$ev,br_bin_present:$br,flywheel_root_present:$rt,flywheel_root:$root,dispatch_log:$dl_p,evidence_dir:$ev_p,br_bin:$br_p}'
      ;;
    dispatch-log)
      local present=false rows=0 last_row=null last_row_valid=false
      if [[ -r "$DISPATCH_LOG" ]]; then
        present=true
        rows="$(wc -l < "$DISPATCH_LOG" 2>/dev/null | tr -d ' ' || echo 0)"
        local raw; raw="$(tail -n 1 "$DISPATCH_LOG" 2>/dev/null || true)"
        if [[ -n "$raw" ]] && printf '%s' "$raw" | jq -e '.' >/dev/null 2>&1; then
          last_row="$raw"
          if printf '%s' "$raw" | jq -e 'has("ts")' >/dev/null 2>&1; then
            last_row_valid=true
          fi
        fi
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      [[ "$present" == true && "$rows" -gt 0 && "$last_row_valid" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg dl "$DISPATCH_LOG" \
        --argjson present "$present" --argjson rows "${rows:-0}" \
        --argjson lr "$last_row" --argjson lrv "$last_row_valid" \
        '{schema_version:$sv,command:"validate",subject:"dispatch-log",status:$s,dispatch_log:$dl,present:$present,row_count:$rows,last_row:$lr,last_row_valid:$lrv}'
      ;;
    evidence-dir)
      local present=false subdir_count=0
      if [[ -d "$EVIDENCE_DIR" ]]; then
        present=true
        subdir_count="$(find "$EVIDENCE_DIR" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
      fi
      local status="pass"
      [[ "$present" != true ]] && status="warn"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$status" --arg ev "$EVIDENCE_DIR" \
        --argjson present "$present" --argjson c "${subdir_count:-0}" \
        '{schema_version:$sv,command:"validate",subject:"evidence-dir",status:$s,evidence_dir:$ev,present:$present,subdir_count:$c}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"pass",subjects:["row","schema","config","dispatch-log","evidence-dir"],usage:"validate --row-json JSON or --schema or --config or --dispatch-log or --evidence-dir"}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg s "$subject" \
        '{schema_version:$sv,command:"validate",subject:$s,status:"unknown_subject",known:["row","schema","config","dispatch-log","evidence-dir"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  local limit=50
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit) limit="${2:-50}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      *) shift ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null 2>&1; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
  else
    local rows="[]" count=0
    if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
      rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" | jq -sc '. // []' 2>/dev/null || echo '[]')"
      count="$(printf '%s' "$rows" | jq 'length' 2>/dev/null || echo 0)"
    fi
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson rows "$rows" --argjson count "$count" \
      '{schema_version:$sv,command:"audit",audit_log:$log,row_count:$count,rows:$rows}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local matches="[]" status="not_found"
  local any_source_present=false
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    any_source_present=true
    local raw
    raw="$(grep -F "$id" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then
      matches="$(printf '%s' "$raw" | jq -sc '.' 2>/dev/null || echo '[]')"
    fi
  fi
  if [[ "$any_source_present" != true ]]; then
    status="unavailable"
  else
    local n; n="$(printf '%s' "$matches" | jq 'length' 2>/dev/null || echo 0)"
    n="${n//[^0-9]/}"; [[ -z "$n" ]] && n=0
    [[ "$n" -gt 0 ]] && status="found"
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg s "$status" \
    --arg log "$SCAFFOLD_AUDIT_LOG" --argjson m "$matches" \
    '{schema_version:$sv,command:"why",id:$id,status:$s,audit_log:$log,matches:$m,total_matches:($m|length)}'
}

scaffold_main() {
  if [[ $# -eq 0 ]]; then
    usage; exit 0
  fi
  case "$1" in
    --examples)   shift; scaffold_emit_examples "$@"; exit 0 ;;
    doctor)       shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)       shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)       shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)     shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)        shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)          shift; scaffold_cmd_why "$@"; exit $? ;;
    quickstart)   shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    completion)   shift; scaffold_emit_completion "${1:-bash}"; exit $? ;;
    *)
      printf 'ERR: unknown canonical subcommand: %s\n' "$1" >&2
      exit 64 ;;
  esac
}

# Early-dispatch intercept: NEW canonical subcommands + --examples only.
# Existing dash-flag forms (--info/--schema/--doctor/--health/-h/--help/--json
# /--lookback-hours/etc.) fall through to the original argparse loop UNCHANGED.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --examples) return 0 ;;
    help)
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lookback-hours) LOOKBACK_HOURS="${2:?--lookback-hours requires N}"; shift 2;;
    --dispatch-log) DISPATCH_LOG="${2:?--dispatch-log requires PATH}"; shift 2;;
    --tmp-dispatch-dir) TMP_DISPATCH_DIR="${2:?--tmp-dispatch-dir requires PATH}"; shift 2;;
    --evidence-dir) EVIDENCE_DIR="${2:?--evidence-dir requires PATH}"; shift 2;;
    --br-bin) BR_BIN="${2:?--br-bin requires PATH}"; shift 2;;
    --json) JSON_OUT=1; shift;;
    --doctor|--health) MODE=doctor; shift;;
    --info) MODE=info; shift;;
    --schema) MODE=schema; shift;;
    -h|--help) usage; exit 0;;
    *) echo "ERR: unknown arg $1" >&2; usage >&2; exit 2;;
  esac
done

case "$MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

# --- Axis 1: punt_phrase_count ---
# Scan recent /tmp/dispatch_*.md packets (filed within lookback window) for
# the L70 forbidden phrase catalog (case-insensitive). The orchestrator
# should never name these phrases in its own dispatch packets.
PUNT_PATTERN="$(printf '%s\n' "${PUNT_PHRASES[@]}" | paste -sd '|' -)"
PUNT_COUNT=0
PUNT_SAMPLES_TMP="$(mktemp "${TMPDIR:-/tmp}/punt-samples.XXXXXX")"
trap 'rm -f "$PUNT_SAMPLES_TMP"' EXIT
: >"$PUNT_SAMPLES_TMP"

# find packets within lookback (mtime < N hours ago).
while IFS= read -r packet; do
  [[ -f "$packet" ]] || continue
  matches="$(grep -ciE "$PUNT_PATTERN" "$packet" 2>/dev/null || echo 0)"
  if [[ "$matches" -gt 0 ]]; then
    PUNT_COUNT=$((PUNT_COUNT + matches))
    [[ "$(wc -l <"$PUNT_SAMPLES_TMP" | tr -d ' ')" -lt 5 ]] && \
      printf '{"file":"%s","matches":%s}\n' "$packet" "$matches" >>"$PUNT_SAMPLES_TMP"
  fi
done < <(find "$TMP_DISPATCH_DIR" -maxdepth 1 -name 'dispatch_*.md' -type f \
           -mmin -$((LOOKBACK_HOURS * 60)) 2>/dev/null)
PUNT_SAMPLES_JSON="$(jq -s '.' "$PUNT_SAMPLES_TMP" 2>/dev/null || echo '[]')"

# --- Axis 2: mission_drift_count ---
# Count dispatch_sent rows in dispatch-log within lookback window where
# mission_fitness_class=drift, OR scan packet bodies for that field.
NOW_EPOCH="$(date -u +%s)"
CUTOFF_EPOCH=$((NOW_EPOCH - LOOKBACK_HOURS * 3600))
set +e
DRIFT_COUNT="$(tail -n 5000 "$DISPATCH_LOG" 2>/dev/null \
  | jq -R -c --argjson cutoff "$CUTOFF_EPOCH" '
      fromjson?
      | select(type == "object" and .event == "dispatch_sent" and (.ts // null) != null)
      | (.ts | sub("Z$"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime) as $epoch
      | select($epoch >= $cutoff)
      | select((.mission_fitness_class // "") == "drift")' 2>/dev/null \
  | wc -l | tr -d ' ')"
set -e
DRIFT_COUNT="${DRIFT_COUNT:-0}"

# --- Axis 3: unaddressed_skill_routes_count ---
# Heuristic — recent dispatch packets with `skill_auto_routes_addressed=`
# field where some catalog skill is missing yes|no|n/a. A correct addressed
# field has the pattern `skill=yes|no|n/a` for every catalog skill.
UNADDRESSED_COUNT=0
while IFS= read -r packet; do
  [[ -f "$packet" ]] || continue
  matched="$(grep -m1 -E '^skill_auto_routes_matched=' "$packet" 2>/dev/null | head -1)"
  addressed="$(grep -m1 -E '^skill_auto_routes_addressed=' "$packet" 2>/dev/null | head -1)"
  [[ -z "$matched" || -z "$addressed" ]] && continue
  m_list="${matched#skill_auto_routes_matched=}"
  a_list="${addressed#skill_auto_routes_addressed=}"
  ok=true
  IFS=',' read -r -a matched_arr <<<"$m_list"
  for s in "${matched_arr[@]}"; do
    s="$(printf '%s' "$s" | tr -d ' \r\n')"
    [[ -n "$s" ]] || continue
    if ! grep -qE "(^|,)${s}=(yes|no|n/a)(,|$)" <<<"$a_list"; then
      ok=false
      break
    fi
  done
  [[ "$ok" == "false" ]] && UNADDRESSED_COUNT=$((UNADDRESSED_COUNT + 1))
done < <(find "$TMP_DISPATCH_DIR" -maxdepth 1 -name 'dispatch_*.md' -type f \
           -mmin -$((LOOKBACK_HOURS * 60)) 2>/dev/null)

# --- Axis 4: recent_closed_beads_without_evidence ---
# Sample last 30 closed beads from `br list --json --status closed`; for each,
# check whether `.flywheel/evidence/<bead-id>/` exists. Beads without evidence
# are suspicious closures.
CLOSED_TMP="$(mktemp "${TMPDIR:-/tmp}/closed-sample.XXXXXX")"
trap 'rm -f "$PUNT_SAMPLES_TMP" "$CLOSED_TMP"' EXIT
: >"$CLOSED_TMP"
set +e
"$BR_BIN" list --json --status closed --limit 30 2>/dev/null \
  | jq -r '.issues[]?.id // empty' 2>/dev/null \
  > "$CLOSED_TMP"
set -e
CLOSED_SAMPLED="$(wc -l <"$CLOSED_TMP" | tr -d ' ')"
NO_EVIDENCE_COUNT=0
while IFS= read -r bead_id; do
  [[ -n "$bead_id" ]] || continue
  if [[ ! -d "$EVIDENCE_DIR/$bead_id" ]]; then
    NO_EVIDENCE_COUNT=$((NO_EVIDENCE_COUNT + 1))
  fi
done <"$CLOSED_TMP"

# --- Aggregate ---
AXES_TRIGGERED=()
[[ "$PUNT_COUNT" -gt 0 ]]                 && AXES_TRIGGERED+=("punt_phrase_in_dispatch_packet")
[[ "$DRIFT_COUNT" -gt 0 ]]                && AXES_TRIGGERED+=("mission_drift_dispatch")
[[ "$UNADDRESSED_COUNT" -gt 0 ]]          && AXES_TRIGGERED+=("skill_routes_not_addressed")
[[ "$NO_EVIDENCE_COUNT" -gt 5 ]]          && AXES_TRIGGERED+=("closed_beads_missing_evidence_above_5")

ADVERSARIAL_SIGNAL=false
[[ "${#AXES_TRIGGERED[@]}" -gt 0 ]] && ADVERSARIAL_SIGNAL=true

AXES_JSON="$(printf '%s\n' "${AXES_TRIGGERED[@]:-}" | jq -R -s 'split("\n") | map(select(length > 0))')"

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson lookback "$LOOKBACK_HOURS" \
  --argjson punt "$PUNT_COUNT" \
  --argjson punt_samples "$PUNT_SAMPLES_JSON" \
  --argjson drift "$DRIFT_COUNT" \
  --argjson unaddressed "$UNADDRESSED_COUNT" \
  --argjson no_evidence "$NO_EVIDENCE_COUNT" \
  --argjson sampled "$CLOSED_SAMPLED" \
  --argjson signal "$ADVERSARIAL_SIGNAL" \
  --argjson axes "$AXES_JSON" \
  '{schema_version:$schema, ts:$ts, success:true, mode:"run",
    lookback_hours:$lookback,
    punt_phrase_count:$punt,
    punt_phrase_samples:$punt_samples,
    mission_drift_count:$drift,
    unaddressed_skill_routes_count:$unaddressed,
    recent_closed_beads_without_evidence:$no_evidence,
    recent_closed_beads_sampled:$sampled,
    adversarial_signal:$signal,
    adversarial_axes_triggered:$axes,
    reads_only:true, auto_dispatch:false,
    step_4o_compliance:"preserved"}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"adversarial-orch-audit lookback=\(.lookback_hours)h punt=\(.punt_phrase_count) drift=\(.mission_drift_count) unaddressed_skills=\(.unaddressed_skill_routes_count) closed_no_evidence=\(.recent_closed_beads_without_evidence)/\(.recent_closed_beads_sampled) signal=\(.adversarial_signal) axes=\(.adversarial_axes_triggered | join(\",\"))"' <<<"$PAYLOAD"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
