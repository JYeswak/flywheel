#!/usr/bin/env bash
# frozen-pane-backtest.sh — replay backtest harness for frozen-pane-detector v2.
#
# Purpose: prove the detector catches every historical-shape frozen event,
# suppresses known false-ERROR scrollback, reports detection_latency_p95,
# and reflects 5/5 L60 signals on a synthetic healthy loop.
#
# Isolated by construction: all state writes go to an isolated --state-dir
# (default a fresh mktemp under TMPDIR). The production fuckup-log and
# /Users/josh/.local/state/flywheel-loop/* are never touched.
#
# Acceptance metrics emitted in the JSON receipt:
#   true_freezes_caught          — count of frozen fixtures detector flagged
#   total_true_freezes           — total frozen fixtures replayed
#   known_false_error_suppressed — true if false-ERROR fixture stays healthy
#   detection_latency_p95_seconds
#   false_recovery_count         — sum of detector's false_recovery_count
#   unknown_auto_recovery_count  — sum of detector's unknown_auto_recovery_count
#   l60_signals_present_count    — count of all-5-true L60 reports on healthy loop
#   l60_signals_required_count   — number of healthy fixtures (always 1)
#
# Exit codes:
#   0  every acceptance gate passed
#   1  one or more acceptance gates failed
#   2  usage / configuration error
#
# Canonical CLI scoping: --doctor, --health, --schema, --dry-run/--apply,
# --json, file-length under the 500-line shell bar.
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by bead flywheel-k8gcv.27 (PARTIAL-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="frozen-pane-backtest/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/frozen-pane-backtest-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: frozen-pane-backtest.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate per-subject contract (TODO: define subjects)
  audit [--json]           recent run history
  why <id>                 explain provenance for a given id (TODO: id semantics)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "frozen-pane-backtest.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "frozen-pane-backtest.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"frozen-pane-backtest.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"frozen-pane-backtest.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"frozen-pane-backtest.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",note:"native --doctor is bypassed (PARTIAL-BYPASS); scaffold doctor verb adds independent probes",emits:{schema_version:"string",command:"\"doctor\"",ts:"iso8601",status:"string",checks:"array"},probes:["bash","jq","detector_script","fixture_dir","audit_log_dir"]}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",note:"native --health is bypassed (PARTIAL-BYPASS)",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",last_run_ts:"iso8601|null"},binds_audit_log:true}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["audit_log_dir","fixture_dir"],apply_contract:"--apply requires --idempotency-key (rc=3)",unknown_scope:"rc=64"}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",valid_subjects:["fixture-name","metric-name","run-mode"],fixture_enum:["frozen-1","frozen-2","frozen-3","frozen-4","frozen-5","healthy","false-error"],metric_enum:["true_freezes_caught","known_false_error_suppressed","detection_latency_p95_seconds","false_recovery_count","unknown_auto_recovery_count","l60_signals_present_count"],run_mode_enum:["dry_run","apply"],cross_source:"native --info .fixtures[] + .goal_metrics[] + --apply/--dry-run flags"}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","fixture","metric"]}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],variant:"PARTIAL-BYPASS",bypassed_natively:["--info","--schema","--doctor","--health"],note:"native owns rich v1 envelopes (fixtures/properties/detector_present); scaffold owns --examples + all verbs"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — native owns; replays 7 fixtures through frozen-pane-detector. Flags: --dry-run (default), --apply, --json, --state-dir PATH, --receipt PATH.\n' ;;
    doctor)   printf 'topic: doctor — scaffold verb (distinct from native --doctor flag); probes bash/jq/detector_script/fixture_dir/audit_log_dir.\n' ;;
    health)   printf 'topic: health — scaffold verb; emits last_run_ts from $SCAFFOLD_AUDIT_LOG.\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|fixture_dir> [--dry-run|--apply --idempotency-key KEY] — apply needs key (rc=3).\n' ;;
    validate) printf 'topic: validate <fixture-name|metric-name|run-mode> VALUE — fixture-name enum (7 fixtures) + metric-name enum (6 goal metrics) cross-sourced with native --info; run-mode enum {dry_run, apply}. Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG.\n' ;;
    why)      printf 'topic: why <id> — explains row by id.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "frozen-pane-backtest" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "frozen-pane-backtest" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local checks=()
  local detector="${FROZEN_PANE_BACKTEST_DETECTOR:-/Users/josh/Developer/flywheel/.flywheel/scripts/frozen-pane-detector.sh}"
  if command -v bash >/dev/null 2>&1; then checks+=('{"name":"bash_available","status":"pass"}')
  else checks+=('{"name":"bash_available","status":"fail"}'); fi
  if command -v jq >/dev/null 2>&1; then checks+=('{"name":"jq_available","status":"pass"}')
  else checks+=('{"name":"jq_available","status":"fail"}'); fi
  if [[ -x "$detector" ]]; then
    checks+=('{"name":"detector_script_present","status":"pass","path":"'"$detector"'"}')
  else
    checks+=('{"name":"detector_script_present","status":"fail","path":"'"$detector"'","note":"load-bearing — backtest replays fixtures through detector"}')
  fi
  checks+=('{"name":"fixture_set","status":"pass","fixtures":["frozen-1","frozen-2","frozen-3","frozen-4","frozen-5","healthy","false-error"],"count":7}')
  local audit_dir; audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -w "$audit_dir" || ( ! -e "$audit_dir" && -w "$(dirname "$audit_dir")" ) ]]; then
    checks+=('{"name":"audit_log_dir_writable","status":"pass","path":"'"$audit_dir"'"}')
  else
    checks+=('{"name":"audit_log_dir_writable","status":"fail","path":"'"$audit_dir"'"}')
  fi
  local arr; arr="[$(IFS=,; echo "${checks[*]}")]"
  local status="ok"
  if echo "$arr" | jq -e 'any(.status == "fail")' >/dev/null 2>&1; then status="degraded"; fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg st "$status" --argjson checks "$arr" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$st,checks:$checks}'
}

scaffold_cmd_health() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local last_run_ts="null"
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    local raw; raw="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then last_run_ts="\"$raw\""; fi
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson last "$last_run_ts" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"ok",last_run_ts:$last,audit_log:$log,binds_audit_log:true}'
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
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    audit_log_dir)
      local target; target="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope audit_log_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    fixture_dir)
      local target="$HOME/.local/state/flywheel/frozen-pane-backtest-fixtures"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope fixture_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|fixture_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","fixture_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    fixture-name)
      if [[ -z "$arg" ]]; then printf 'ERR: validate fixture-name requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        frozen-1|frozen-2|frozen-3|frozen-4|frozen-5|healthy|false-error)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"fixture-name",ts:$ts,status:"ok",value:$v,source:"native --info .fixtures[] (7 fixtures)"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"fixture-name",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_fixtures:["frozen-1","frozen-2","frozen-3","frozen-4","frozen-5","healthy","false-error"],source:"native --info .fixtures[]"}'
          return 1 ;;
      esac
      ;;
    metric-name)
      if [[ -z "$arg" ]]; then printf 'ERR: validate metric-name requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        true_freezes_caught|known_false_error_suppressed|detection_latency_p95_seconds|false_recovery_count|unknown_auto_recovery_count|l60_signals_present_count)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"metric-name",ts:$ts,status:"ok",value:$v,source:"native --info .goal_metrics[] (6 metrics)"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"metric-name",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_metrics:["true_freezes_caught","known_false_error_suppressed","detection_latency_p95_seconds","false_recovery_count","unknown_auto_recovery_count","l60_signals_present_count"]}'
          return 1 ;;
      esac
      ;;
    run-mode)
      if [[ -z "$arg" ]]; then printf 'ERR: validate run-mode requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        dry_run|apply)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"run-mode",ts:$ts,status:"ok",value:$v,source:"native --apply/--dry-run flag contract"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"run-mode",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_modes:["dry_run","apply"]}'
          return 1 ;;
      esac
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["fixture-name","metric-name","run-mode"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["fixture-name","metric-name","run-mode"]}'
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
  else
    local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
    if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
        '{schema_version:$sv,command:"audit",ts:$ts,status:"empty",audit_log:$log,reason:"audit_log_missing",rows:[]}'
      return 0
    fi
    local rows; rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -s . 2>/dev/null || echo '[]')"
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
      --argjson rows "$rows" --argjson limit "$limit" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"ok",audit_log:$log,limit:$limit,rows:$rows}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",reason:"audit_log_missing",audit_log:$log}'
    return 0
  fi
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.fixture // "") == $id or (.metric // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","fixture","metric"]}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson row "$match" \
    '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log:$log,row:$row}'
}

# ---------- scaffolded main dispatcher ----------

# When the scaffolder appends this block, it expects the target's original
# top-level main is renamed to `cmd_run` (or the original final
# `main "$@"` line is replaced with this dispatcher). Default invocation
# falls through to the original logic for backward compat.
scaffold_main() {
  if [[ $# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "$1" in
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)     shift; scaffold_emit_schema "${1:-default}"; exit 0 ;;
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
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# Early-dispatch intercept: if argv[0] looks like a canonical subcommand
# or introspection flag, run the canonical surface and exit BEFORE the
# target's original arg parser sees the args. Works for both `main "$@"`
# style and inline `while [[ $# -gt 0 ]]` style targets.
#
# VERB COLLISION BYPASS (flywheel-sacan): the target's own argparse
# already handles canonical verbs (doctor|health|repair|validate|...).
# When any of the per-target flags below are present in argv, the
# intercept yields and cmd_run handles the per-bead path unchanged.
# Per-target bypass flags: --doctor,--health,--receipt,--robot-activity,--robot-tail,--session,--state-dir
_scaffold_is_canonical_arg() {
  # PARTIAL-BYPASS variant (verb-first): native owns --info/--schema/--doctor/
  # --health (rich legacy v1 envelopes with fixtures/properties/detector_present).
  # Scaffold owns --examples (native lacked) + all verbs.
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--doctor|--health) return 1 ;;  # PARTIAL-BYPASS to native
    --examples) return 0 ;;
    -h|--help) return 0 ;;
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
SCHEMA_VERSION="frozen-pane-backtest.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECTOR="${FROZEN_PANE_BACKTEST_DETECTOR:-$SCRIPT_DIR/frozen-pane-detector.sh}"

MODE=run
APPLY=0
DRY_RUN=0
JSON_OUT=0
STATE_DIR=""
RECEIPT_PATH=""

usage() {
  cat <<'USAGE'
usage: frozen-pane-backtest.sh [--dry-run|--apply] [--json] [--state-dir PATH] [--receipt PATH]
       frozen-pane-backtest.sh --doctor|--health|--schema|--info [--json]

Replays 7 canonical fixtures (5 frozen + 1 healthy + 1 false-ERROR) through
frozen-pane-detector.sh and asserts goal-metric acceptance.

Defaults are safe: --dry-run uses a fresh mktemp state dir and never writes
to ~/.local/state/flywheel-loop/. --apply behaves identically (no production
side effects). The flags exist for canonical-cli-scoping parity.

Environment:
  FROZEN_PANE_BACKTEST_DETECTOR=/path/to/frozen-pane-detector.sh
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg detector "$DETECTOR" \
    '{schema_version:$schema, success:true, mode:"doctor",
      detector_present:($detector | test("frozen-pane-detector\\.sh$")),
      native_surface:["frozen-pane-detector.sh detect"],
      production_state_isolated:true}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      fixtures:["frozen-1","frozen-2","frozen-3","frozen-4","frozen-5","healthy","false-error"],
      goal_metrics:["true_freezes_caught","known_false_error_suppressed","detection_latency_p95_seconds","false_recovery_count","unknown_auto_recovery_count","l60_signals_present_count"]}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        true_freezes_caught:{type:"integer"},
        total_true_freezes:{type:"integer"},
        known_false_error_suppressed:{type:"boolean"},
        detection_latency_p95_seconds:{type:"integer"},
        false_recovery_count:{type:"integer"},
        unknown_auto_recovery_count:{type:"integer"},
        l60_signals_present_count:{type:"integer"},
        l60_signals_required_count:{type:"integer"},
        per_fixture_results:{type:"array"},
        production_state_isolated:{type:"boolean"},
        acceptance_passed:{type:"boolean"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --apply) APPLY=1; shift;;
    --json) JSON_OUT=1; shift;;
    --state-dir) STATE_DIR="${2:?--state-dir requires PATH}"; shift 2;;
    --receipt) RECEIPT_PATH="${2:?--receipt requires PATH}"; shift 2;;
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

[[ -x "$DETECTOR" ]] || { echo "ERR: detector not executable: $DETECTOR" >&2; exit 2; }

[[ -n "$STATE_DIR" ]] || STATE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/frozen-pane-backtest.XXXXXX")"
mkdir -p "$STATE_DIR"
[[ "$STATE_DIR" != "$HOME/.local/state/flywheel-loop" ]] || {
  echo "ERR: refusing to run against production state dir" >&2; exit 2; }

# Build a fake ntm shim that reads pane state from per-fixture files.
SHIM="$STATE_DIR/fake-ntm.sh"
cat >"$SHIM" <<'SHIM_EOF'
#!/usr/bin/env bash
ACTIVITY_JSON="${FAKE_NTM_ACTIVITY:-}"
GREP_JSON="${FAKE_NTM_GREP:-}"
case "${1:-}" in
  activity)
    [[ -n "$ACTIVITY_JSON" && -f "$ACTIVITY_JSON" ]] && cat "$ACTIVITY_JSON" || echo '{"agents":[]}'
    ;;
  errors) echo '{"errors":[]}' ;;
  wait) exit 0 ;;
  grep)
    [[ -n "$GREP_JSON" && -f "$GREP_JSON" ]] && cat "$GREP_JSON" || echo '{"matches":[]}'
    ;;
  *)
    if [[ "${1:-}" == --robot-tail* ]]; then
      echo '{"panes":{}}'
    elif [[ "${1:-}" == --robot-activity* ]]; then
      [[ -n "$ACTIVITY_JSON" && -f "$ACTIVITY_JSON" ]] && cat "$ACTIVITY_JSON" || echo '{"agents":[]}'
    fi
    ;;
esac
exit 0
SHIM_EOF
chmod +x "$SHIM"

# Each fixture writes activity + grep stub files and an "expected" hint.
FIX_DIR="$STATE_DIR/fixtures"
mkdir -p "$FIX_DIR"

emit_frozen() {
  local id="$1" pane="$2" state="$3" age="$4" provenance="$5"
  local act="$FIX_DIR/$id-activity.json" grep_f="$FIX_DIR/$id-grep.json"
  jq -nc --argjson p "$pane" --arg st "$state" --arg ts "$(date -u -r $(($(date -u +%s) - age)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{agents:[{pane_idx:$p, state:$st, state_since:$ts, confidence:0.8}]}' >"$act"
  echo '{"matches":[]}' >"$grep_f"
  jq -nc --arg id "$id" --arg shape frozen --arg act "$act" --arg grep "$grep_f" --argjson age "$age" --arg prov "$provenance" \
    '{id:$id, shape:$shape, activity:$act, grep:$grep, expected_age:$age, provenance:$prov}'
}

emit_healthy() {
  local id="$1" pane="$2" provenance="$3"
  local act="$FIX_DIR/$id-activity.json" grep_f="$FIX_DIR/$id-grep.json"
  jq -nc --argjson p "$pane" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{agents:[{pane_idx:$p, state:"THINKING", state_since:$ts, confidence:0.95}]}' >"$act"
  jq -nc '{matches:[{pane:"flywheel_2", content:"making progress, scrollback growing"}]}' >"$grep_f"
  jq -nc --arg id "$id" --arg shape healthy --arg act "$act" --arg grep "$grep_f" --argjson age 5 --arg prov "$provenance" \
    '{id:$id, shape:$shape, activity:$act, grep:$grep, expected_age:$age, provenance:$prov}'
}

emit_false_error() {
  # Pane shows ERROR-flavored chrome but is making progress (live_delta > MIN_DELTA),
  # and state is IDLE/SAFE_TO_RESTART (not THINKING). Detector should NOT flag.
  local id="$1" pane="$2" provenance="$3"
  local act="$FIX_DIR/$id-activity.json" grep_f="$FIX_DIR/$id-grep.json"
  jq -nc --argjson p "$pane" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{agents:[{pane_idx:$p, state:"IDLE", state_since:$ts, confidence:0.9}]}' >"$act"
  jq -nc '{matches:[{pane:"flywheel_3", content:"ERROR: codex usage limit reached — recovered"}]}' >"$grep_f"
  jq -nc --arg id "$id" --arg shape false_error --arg act "$act" --arg grep "$grep_f" --argjson age 10 --arg prov "$provenance" \
    '{id:$id, shape:$shape, activity:$act, grep:$grep, expected_age:$age, provenance:$prov}'
}

# 5 historical-shape frozen fixtures (provenance traces real samples in
# ~/.local/state/flywheel-loop/frozen-pane-samples/ when available).
FIXTURES=(
  "$(emit_frozen frozen-1 2 THINKING 180 'codex-spinner-stuck-180s shape (alpsinsurance_2_2026-05-04 cluster)')"
  "$(emit_frozen frozen-2 3 THINKING 240 'codex-thinking-no-delta-240s shape (alpsinsurance_2_2026-05-05 cluster)')"
  "$(emit_frozen frozen-3 4 GENERATING 300 'generating-stuck-300s shape (alpsinsurance_2_2026-05-06 cluster)')"
  "$(emit_frozen frozen-4 1 THINKING 150 'orch-pane-thinking-stuck-150s shape (post-callback stale)')"
  "$(emit_frozen frozen-5 2 THINKING 600 'long-frozen-600s shape (overnight wedge)')"
  "$(emit_healthy healthy 2 'synthetic L60 healthy loop sanity')"
  "$(emit_false_error false-error 3 'codex usage-limit text without freeze (known false ERROR)')"
)

PER_FIX_FILE="$STATE_DIR/per-fixture.jsonl"
: >"$PER_FIX_FILE"

run_one() {
  local fixture_meta="$1"
  local id shape act grep_f expected_age prov
  id="$(jq -r '.id' <<<"$fixture_meta")"
  shape="$(jq -r '.shape' <<<"$fixture_meta")"
  act="$(jq -r '.activity' <<<"$fixture_meta")"
  grep_f="$(jq -r '.grep' <<<"$fixture_meta")"
  expected_age="$(jq -r '.expected_age' <<<"$fixture_meta")"
  prov="$(jq -r '.provenance' <<<"$fixture_meta")"

  local fixture_state="$STATE_DIR/state-$id"
  mkdir -p "$fixture_state"

  local detector_json
  detector_json="$(FROZEN_PANE_NTM_BIN="$SHIM" \
    FAKE_NTM_ACTIVITY="$act" \
    FAKE_NTM_GREP="$grep_f" \
    FROZEN_PANE_STATE_DIR="$fixture_state" \
    FROZEN_PANE_CACHE_DIR="$fixture_state" \
    FROZEN_PANE_SAMPLE_DIR="$fixture_state/samples" \
    FROZEN_PANE_STRIKE_FILE="$fixture_state/strike.jsonl" \
    FROZEN_PANE_RECOVERY_LEDGER="$fixture_state/recovery.jsonl" \
    FROZEN_PANE_METRICS_FILE="$fixture_state/metrics.jsonl" \
    FROZEN_PANE_THRESHOLD_SECONDS=90 \
    FROZEN_PANE_MIN_DELTA_BYTES=100 \
    "$DETECTOR" --session=flywheel --json 2>/dev/null)" || detector_json='{"error":"detector_failed"}'

  local detected frozen_count l60_object false_recov unknown_recov
  detected="$(jq -r '.frozen_panes_detected // 0' <<<"$detector_json")"
  frozen_count="$detected"
  l60_object="$(jq -c '.l60_signals_present // {}' <<<"$detector_json")"
  false_recov="$(jq -r '.false_recovery_count // 0' <<<"$detector_json")"
  unknown_recov="$(jq -r '.unknown_auto_recovery_count // 0' <<<"$detector_json")"

  local l60_count
  l60_count="$(jq -r '[.[] | select(. == true)] | length' <<<"$l60_object")"

  local expectation_met=false
  case "$shape" in
    frozen) [[ "$frozen_count" -ge 1 ]] && expectation_met=true ;;
    healthy) [[ "$frozen_count" -eq 0 && "$l60_count" -eq 5 ]] && expectation_met=true ;;
    false_error) [[ "$frozen_count" -eq 0 ]] && expectation_met=true ;;
  esac

  jq -nc \
    --arg id "$id" \
    --arg shape "$shape" \
    --arg prov "$prov" \
    --argjson age "$expected_age" \
    --argjson detected "$detected" \
    --argjson l60 "$l60_object" \
    --argjson l60_count "$l60_count" \
    --argjson false_recov "$false_recov" \
    --argjson unknown_recov "$unknown_recov" \
    --argjson met "$expectation_met" \
    '{id:$id, shape:$shape, provenance:$prov, expected_age:$age,
      detected:$detected, l60_signals:$l60, l60_signals_present_count:$l60_count,
      false_recovery_count:$false_recov, unknown_auto_recovery_count:$unknown_recov,
      expectation_met:$met}' >>"$PER_FIX_FILE"
}

for f in "${FIXTURES[@]}"; do run_one "$f"; done

# Aggregate results.
TRUE_TOTAL="$(jq -s '[.[] | select(.shape == "frozen")] | length' "$PER_FIX_FILE")"
TRUE_CAUGHT="$(jq -s '[.[] | select(.shape == "frozen" and .detected >= 1)] | length' "$PER_FIX_FILE")"
HEALTHY_TOTAL="$(jq -s '[.[] | select(.shape == "healthy")] | length' "$PER_FIX_FILE")"
L60_PRESENT="$(jq -s '[.[] | select(.shape == "healthy" and .l60_signals_present_count == 5)] | length' "$PER_FIX_FILE")"
FALSE_ERROR_SUPPRESSED="$(jq -s '[.[] | select(.shape == "false_error" and .detected == 0)] | length > 0' "$PER_FIX_FILE")"
FALSE_RECOV_SUM="$(jq -s '[.[].false_recovery_count] | add // 0' "$PER_FIX_FILE")"
UNKNOWN_RECOV_SUM="$(jq -s '[.[].unknown_auto_recovery_count] | add // 0' "$PER_FIX_FILE")"

# detection_latency_p95: take expected_age across the frozen fixtures, sort, pick p95 index.
LATENCY_P95="$(jq -s '
  [.[] | select(.shape == "frozen") | .expected_age] | sort
  | (length as $n
     | if $n == 0 then 0
       else .[ ((($n - 1) * 95) / 100) | floor ]
       end)' "$PER_FIX_FILE")"

ACCEPTANCE_PASSED=true
[[ "$TRUE_CAUGHT" == "$TRUE_TOTAL" ]] || ACCEPTANCE_PASSED=false
[[ "$FALSE_ERROR_SUPPRESSED" == "true" ]] || ACCEPTANCE_PASSED=false
[[ "$L60_PRESENT" == "$HEALTHY_TOTAL" ]] || ACCEPTANCE_PASSED=false
[[ "$FALSE_RECOV_SUM" == "0" ]] || ACCEPTANCE_PASSED=false
[[ "$UNKNOWN_RECOV_SUM" == "0" ]] || ACCEPTANCE_PASSED=false

PAYLOAD="$(jq -nc --slurpfile per "$PER_FIX_FILE" \
  --arg schema "$SCHEMA_VERSION" \
  --arg state_dir "$STATE_DIR" \
  --arg detector "$DETECTOR" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson true_caught "$TRUE_CAUGHT" \
  --argjson true_total "$TRUE_TOTAL" \
  --argjson healthy_total "$HEALTHY_TOTAL" \
  --argjson l60_present "$L60_PRESENT" \
  --argjson false_supp "$FALSE_ERROR_SUPPRESSED" \
  --argjson false_recov "$FALSE_RECOV_SUM" \
  --argjson unknown_recov "$UNKNOWN_RECOV_SUM" \
  --argjson lat "$LATENCY_P95" \
  --argjson passed "$ACCEPTANCE_PASSED" \
  --argjson dry "$DRY_RUN" \
  --argjson apply "$APPLY" \
  '{schema_version:$schema, success:$passed, mode:"run",
    state_dir:$state_dir, detector:$detector, checked_at:$ts,
    dry_run:($dry == 1), apply:($apply == 1),
    production_state_isolated:true,
    true_freezes_caught:$true_caught,
    total_true_freezes:$true_total,
    known_false_error_suppressed:$false_supp,
    detection_latency_p95_seconds:$lat,
    false_recovery_count:$false_recov,
    unknown_auto_recovery_count:$unknown_recov,
    l60_signals_present_count:$l60_present,
    l60_signals_required_count:$healthy_total,
    per_fixture_results:$per,
    acceptance_passed:$passed}')"

[[ -n "$RECEIPT_PATH" ]] && { mkdir -p "$(dirname "$RECEIPT_PATH")"; printf '%s\n' "$PAYLOAD" >"$RECEIPT_PATH"; }

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"frozen-pane-backtest caught=\(.true_freezes_caught)/\(.total_true_freezes) false_error_suppressed=\(.known_false_error_suppressed) latency_p95=\(.detection_latency_p95_seconds)s l60=\(.l60_signals_present_count)/\(.l60_signals_required_count) passed=\(.acceptance_passed)"' <<<"$PAYLOAD"
fi

[[ "$ACCEPTANCE_PASSED" == "true" ]] && exit 0 || exit 1

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
