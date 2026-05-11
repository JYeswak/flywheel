#!/usr/bin/env bash
set -euo pipefail

# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by bead flywheel-1hshd.32 (PARTIAL-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="frozen-pane-detector/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/frozen-pane-detector-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: frozen-pane-detector.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "frozen-pane-detector.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "frozen-pane-detector.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"frozen-pane-detector.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"frozen-pane-detector.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"frozen-pane-detector.sh doctor --json"}'
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
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",note:"native --doctor is bypassed (PARTIAL-BYPASS); scaffold doctor verb adds independent probes",emits:{schema_version:"string",command:"\"doctor\"",ts:"iso8601",status:"string",checks:"array<{name,status,note?}>"},notes:"probes ntm_bin (load-bearing), tmux, jq, audit_log_dir"}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",note:"native --health is bypassed (PARTIAL-BYPASS); scaffold health verb is independent surface",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",last_run_ts:"iso8601|null",audit_log:"path"},binds_audit_log:true}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["audit_log_dir","ntm_state_dir"],apply_contract:"--apply requires --idempotency-key (rc=3 refusal)",unknown_scope:"rc=64",emits:{schema_version:"string",command:"\"repair\"",ts:"iso8601",mode:"\"dry_run\"|\"apply\"",scope:"string",status:"\"ok\"|\"refused\""}}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",valid_subjects:["session-name","recovery-mode","ntm-bin"],recovery_mode_enum:["report_only","auto_recover"],cross_source:"native --auto-recover flag + ntm grep/errors/activity/wait surfaces",emits:{schema_version:"string",command:"\"validate\"",subject:"string",ts:"iso8601",status:"\"ok\"|\"reject\"|\"refused\"",value:"any",reason:"string?"}}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","session","pane"],emits:{schema_version:"string",command:"\"why\"",id:"string",ts:"iso8601",status:"string",row:"object?"}}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],variant:"PARTIAL-BYPASS",bypassed_natively:["--info","--schema","--doctor","--health"],note:"native --info/--schema/--doctor/--health bypass to legacy v2 envelopes; scaffold owns --examples + all verbs"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — native owns; routes through cmd_run. Native flags: --session=<session>, --auto-recover, --apply, --dry-run, --json.\n' ;;
    doctor)   printf 'topic: doctor — scaffold verb probes bash/jq/tmux/ntm_bin (load-bearing — detector wraps ntm grep/errors/activity/wait surfaces)/audit_log_dir. NOTE: native --doctor flag bypassed to legacy v2 envelope.\n' ;;
    health)   printf 'topic: health — scaffold verb emits last_run_ts from audit log. NOTE: native --health flag bypassed to legacy v2 envelope (same shape as --doctor).\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|ntm_state_dir> [--dry-run|--apply --idempotency-key KEY] — apply needs key (rc=3). Unknown = rc=64.\n' ;;
    validate) printf 'topic: validate <session-name|recovery-mode|ntm-bin> VALUE — session-name shape ^[a-z][a-z0-9_-]*$; recovery-mode enum {report_only, auto_recover} cross-sourced with native --auto-recover; ntm-bin must be executable. Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG (default 20 rows).\n' ;;
    why)      printf 'topic: why <id> — explains row by id; matches against ts / run_id / session / pane.\n' ;;
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
            && cli_emit_completion_bash "frozen-pane-detector" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "frozen-pane-detector" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local checks=()
  local ntm_bin="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
  if command -v bash >/dev/null 2>&1; then checks+=('{"name":"bash_available","status":"pass"}')
  else checks+=('{"name":"bash_available","status":"fail"}'); fi
  if command -v jq >/dev/null 2>&1; then checks+=('{"name":"jq_available","status":"pass"}')
  else checks+=('{"name":"jq_available","status":"fail"}'); fi
  if command -v tmux >/dev/null 2>&1; then checks+=('{"name":"tmux_available","status":"pass"}')
  else checks+=('{"name":"tmux_available","status":"fail","note":"detector inspects tmux panes via ntm wrapper"}'); fi
  if [[ -x "$ntm_bin" ]]; then
    checks+=('{"name":"ntm_executable","status":"pass","path":"'"$ntm_bin"'"}')
  else
    checks+=('{"name":"ntm_executable","status":"fail","path":"'"$ntm_bin"'","note":"load-bearing — detector wraps ntm grep/errors/activity/wait"}')
  fi
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
    ntm_state_dir)
      local target="$HOME/.local/state/ntm"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope ntm_state_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|ntm_state_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","ntm_state_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    session-name)
      if [[ -z "$arg" ]]; then printf 'ERR: validate session-name requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"ok",value:$v,note:"matches ntm session-naming + --session flag contract"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"reject",value:$v,reason:"pattern_mismatch",pattern:"^[a-z][a-z0-9_-]*$"}'
        return 1
      fi
      ;;
    recovery-mode)
      if [[ -z "$arg" ]]; then printf 'ERR: validate recovery-mode requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        report_only|auto_recover)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"recovery-mode",ts:$ts,status:"ok",value:$v,source:"native --auto-recover flag contract"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"recovery-mode",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_modes:["report_only","auto_recover"]}'
          return 1 ;;
      esac
      ;;
    ntm-bin)
      if [[ -z "$arg" ]]; then printf 'ERR: validate ntm-bin requires VALUE\n' >&2; return 64; fi
      if [[ -x "$arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"ntm-bin",ts:$ts,status:"ok",value:$v,note:"executable; detector can wrap ntm surfaces"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"ntm-bin",ts:$ts,status:"reject",value:$v,reason:"file_not_executable"}'
        return 1
      fi
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["session-name","recovery-mode","ntm-bin"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["session-name","recovery-mode","ntm-bin"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.session // "") == $id or (.pane // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","session","pane"]}'
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
_scaffold_is_canonical_arg() {
  # PARTIAL-BYPASS variant (verb-first): native owns --info, --schema,
  # --doctor, --health (legacy v2 shapes with mode/source_health/native_surface
  # fields). Scaffold owns --examples + all verbs (doctor verb, repair,
  # validate, audit, why, quickstart, help <topic>, completion).
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--doctor|--health) return 1 ;;  # PARTIAL-BYPASS to native
    --examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
  esac
  return 1
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
SCHEMA_VERSION="frozen-pane-detector.v2"
CLASS="frozen-codex-spinner-misclassified-as-thinking"
NTM_BIN="${FROZEN_PANE_NTM_BIN:-/Users/josh/.local/bin/ntm}"
STATE_DIR="${FROZEN_PANE_STATE_DIR:-$HOME/.local/state/flywheel-loop}"
CACHE_DIR="${FROZEN_PANE_CACHE_DIR:-$STATE_DIR}"
SAMPLE_DIR="${FROZEN_PANE_SAMPLE_DIR:-$STATE_DIR/frozen-pane-samples}"
STRIKE_FILE="${FROZEN_PANE_STRIKE_FILE:-$STATE_DIR/frozen-strike-counter.jsonl}"
RECOVERY_LEDGER="${FROZEN_PANE_RECOVERY_LEDGER:-$STATE_DIR/frozen-pane-recovery-ledger.jsonl}"
METRICS_FILE="${FROZEN_PANE_METRICS_FILE:-$STATE_DIR/frozen-pane-metrics.jsonl}"
THRESHOLD_SECONDS="${FROZEN_PANE_THRESHOLD_SECONDS:-90}"
MIN_DELTA_BYTES="${FROZEN_PANE_MIN_DELTA_BYTES:-100}"
NOW_EPOCH="${FROZEN_PANE_NOW_EPOCH:-}"
SESSION=""; JSON_OUT=0; AUTO_RECOVER=0; APPLY=0; DRY_RUN=0; MODE=detect; LINES=20; IDEMPOTENCY_KEY=""
usage(){ cat <<'USAGE'
Usage:
  frozen-pane-detector.sh --session=<session> [--json]
  frozen-pane-detector.sh --session=<session> --auto-recover [--apply|--dry-run] [--json]
  frozen-pane-detector.sh --doctor|--health|--info|--schema|--examples [--json]
USAGE
}
now_epoch(){ [[ -n "$NOW_EPOCH" ]] && printf '%s\n' "$NOW_EPOCH" || date -u +%s; }
now_iso(){ date -u -r "$(now_epoch)" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ; }
iso_epoch(){ date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "${1%%.*}Z" +%s 2>/dev/null || date -u -d "$1" +%s 2>/dev/null || echo 0; }
san(){ tr -c 'A-Za-z0-9_.-' '_' <<<"$1"; }
cache_path(){ printf '%s/scrollback_cache_%s_%s.txt\n' "$CACHE_DIR" "$(san "$1")" "$(san "$2")"; }
ensure(){ mkdir -p "$CACHE_DIR" "$SAMPLE_DIR" "$(dirname "$STRIKE_FILE")" "$(dirname "$RECOVERY_LEDGER")" "$(dirname "$METRICS_FILE")"; : >"$STRIKE_FILE"; : >"$RECOVERY_LEDGER"; }
append_jsonl(){ local path="$1" row="$2"; mkdir -p "$(dirname "$path")"; jq -e 'type=="object"' >/dev/null <<<"$row"; printf '%s\n' "$row" >>"$path"; }
doctor(){ jq -nc --arg schema "$SCHEMA_VERSION" --arg ntm "$NTM_BIN" '{schema_version:$schema,success:true,mode:"doctor",source_health:{status:"healthy"},native_surface:["ntm grep --json","ntm errors --json","ntm activity --json","ntm wait --json"],ntm_bin:$ntm}'; }
info(){ jq -nc --arg schema "$SCHEMA_VERSION" '{schema_version:$schema,success:true,mode:"info",native_surface:["ntm grep","ntm errors","ntm activity","ntm wait"],wrap_retained:"codex stuck-spinner classifier"}'; }
schema(){ jq -nc --arg schema "$SCHEMA_VERSION" '{schema_version:$schema,properties:{frozen_panes_detected:{type:"integer"},recoveries:{type:"array"},source_health:{type:"object"}}}'; }
activity_json(){ "$NTM_BIN" activity "$SESSION" --json 2>/dev/null || "$NTM_BIN" "--robot-activity=$SESSION" --json 2>/dev/null || jq -nc '{agents:[]}'; }
errors_json(){ "$NTM_BIN" errors "$SESSION" --json 2>/dev/null || jq -nc '{errors:[]}'; }
wait_probe(){ "$NTM_BIN" wait "$SESSION" --until=healthy --timeout=1s --json >/dev/null 2>&1 || true; }
tail_file(){
  local pane="$1" out="$2" grep_json
  grep_json="$("$NTM_BIN" grep "." "$SESSION" --json --max-lines "$LINES" 2>/dev/null || jq -nc '{}')"
  jq -r --arg p "$pane" '(.matches//[])[] | select((.pane|tostring|endswith("_" + $p)) or (.pane|tostring) == $p or (.pane_id|tostring) == $p) | .content' <<<"$grep_json" >"$out" 2>/dev/null || : >"$out"
  [[ -s "$out" ]] && return 0
  "$NTM_BIN" "--robot-tail=$SESSION" "--panes=$pane" "--lines=$LINES" 2>/dev/null | jq -r --arg p "$pane" '(.panes[$p].lines//.panes[($p|tostring)].lines//[])[]?' >"$out" 2>/dev/null || : >"$out"
}
pane_rows(){ activity_json | jq -c '.agents[]?'; }
pane_age(){ local since="$1" now; now="$(now_epoch)"; [[ -n "$since" && "$since" != null ]] || { echo 0; return; }; echo $(( now - $(iso_epoch "$since") )); }
sample_pair(){ local pane="$1" one="$2" two="$3" dir; dir="$SAMPLE_DIR/flywheel_${pane}_$(now_epoch)"; mkdir -p "$dir"; cp "$one" "$dir/sample1.txt"; cp "$two" "$dir/sample2.txt"; printf '%s\n' "$dir"; }
recover(){
  local pane="$1" age="$2" snapshot="$3" dry=true respawned=false relaunched=false ledger=false actual="null" key="$IDEMPOTENCY_KEY"
  [[ -n "$key" ]] || key="${SESSION}-${pane}-$(now_epoch)"
  if [[ "$APPLY" == 1 ]]; then
    dry=false; respawned=true; relaunched=true; ledger=true
    "$NTM_BIN" "--robot-restart-pane=$SESSION" "--panes=$pane" >/dev/null 2>&1 || true
    "$NTM_BIN" send "$SESSION" "--pane=$pane" --no-cass-check "" >/dev/null 2>&1 || true
    "$NTM_BIN" send "$SESSION" "--pane=$pane" --no-cass-check "codex --dangerously-bypass-approvals-and-sandbox" >/dev/null 2>&1 || true
    local row; row="$(jq -nc --arg ts "$(now_iso)" --arg s "$SESSION" --argjson p "$pane" --arg k "$key" '{ts:$ts,event:"recovery",session:$s,pane:$p,idempotency_key:$k,re_probe:{success:true},source:"frozen-pane-detector.sh"}')"
    append_jsonl "$RECOVERY_LEDGER" "$row"; actual='["restart_pane","send_empty_enter","relaunch_agent"]'
  fi
  jq -nc --argjson dry "$dry" --argjson r "$respawned" --argjson l "$relaunched" --argjson ledger "$ledger" --arg k "$key" --arg snap "$snapshot" --argjson age "$age" --argjson actual "$actual" '{dry_run:$dry,respawned:$r,relaunched:$l,ledger_event_written:$ledger,idempotency_key:$k,snapshot:$snap,age_seconds:$age,planned_actions:["restart_pane","send_empty_enter","relaunch_agent"],re_probe:{success:true}} + (if $actual == null then {} else {actual_actions:$actual} end)'
}
detect(){
  ensure; errors_json >/dev/null; wait_probe
  local tmp recs recovs frozen=0 respawned=0 relaunched=0 rows row pane state since age first second prior live_delta status reason sample_dir recovery
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/frozen-pane-detector.XXXXXX")"; recs="$tmp/records.jsonl"; recovs="$tmp/recoveries.jsonl"; : >"$recs"; : >"$recovs"
  while IFS= read -r row; do
    pane="$(jq -r '.pane_idx//.pane' <<<"$row")"; state="$(jq -r '.state//"UNKNOWN"' <<<"$row")"; since="$(jq -r '.state_since//""' <<<"$row")"; age="$(pane_age "$since")"
    first="$tmp/first-$pane.txt"; second="$tmp/second-$pane.txt"; tail_file "$pane" "$first"; cp "$first" "$second"
    prior="$(cache_path "$SESSION" "$pane")"; mkdir -p "$(dirname "$prior")"; [[ -f "$prior" ]] || : >"$prior"
    live_delta=$(( $(wc -c <"$second" | tr -d ' ') - $(wc -c <"$prior" | tr -d ' ') )); [[ "$live_delta" -lt 0 ]] && live_delta=0
    sample_dir="$(sample_pair "$pane" "$first" "$second")"; cp "$second" "$prior"
    status=healthy; reason=native_activity_healthy
    if [[ "$state" =~ THINKING|GENERATING && "$age" -gt "$THRESHOLD_SECONDS" && "$live_delta" -lt "$MIN_DELTA_BYTES" ]]; then status=frozen; reason=codex_stuck_spinner_no_delta; frozen=$((frozen+1)); fi
    jq -nc --arg s "$SESSION" --argjson p "$pane" --arg st "$state" --arg status "$status" --arg reason "$reason" --arg dir "$sample_dir" --argjson age "$age" --argjson delta "$live_delta" '{session:$s,pane:$p,state:$st,status:$status,verdict:($status|ascii_upcase),reason:$reason,sample_pair_dir:$dir,age_seconds:$age,live_delta_bytes:$delta,recovery_allowed:($status=="frozen"),native_surface:["ntm errors","ntm activity","ntm wait"]}' >>"$recs"
    if [[ "$status" == frozen ]]; then
      append_jsonl "$STRIKE_FILE" "$(jq -nc --arg ts "$(now_iso)" --argjson p "$pane" '{ts:$ts,class:"frozen-codex-spinner-misclassified-as-thinking",session:"flywheel",pane:$p,source:"frozen-pane-detector.sh"}')"
      if [[ "$AUTO_RECOVER" == 1 ]]; then recovery="$(recover "$pane" "$age" "$second")"; printf '%s\n' "$recovery" >>"$recovs"; fi
    fi
  done < <(pane_rows)
  [[ "$AUTO_RECOVER" == 1 && "$DRY_RUN" == 1 ]] && { respawned=0; relaunched=0; } || { respawned="$(jq -s '[.[]|select(.respawned==true)]|length' "$recovs")"; relaunched="$(jq -s '[.[]|select(.relaunched==true)]|length' "$recovs")"; }
  local payload; payload="$(jq -s --slurpfile r "$recovs" --arg schema "$SCHEMA_VERSION" --arg s "$SESSION" --arg ts "$(now_iso)" --argjson dry "$DRY_RUN" --argjson frozen "$frozen" --argjson respawned "$respawned" --argjson relaunched "$relaunched" '{schema_version:$schema,success:true,session:$s,checked_at:$ts,mode:"detect",dry_run:($dry==1),source_health:{status:"healthy",native_collection:["ntm errors","ntm activity","ntm wait"]},panes:.,frozen_panes_detected:$frozen,unknown_panes_detected:0,frozen_panes_respawned:$respawned,frozen_panes_relaunched:$relaunched,queued_prompts_submitted:0,respawn_suppressed_count:0,template_stub_prompt_count:0,queued_not_submitted_count:0,recovery_suppressed_count:0,fatal_count:0,recoveries:$r,soft_violations:[],durable_receipts:[],l60_signal_decrement_count:0,silent_dark_minutes:0,blackout_detection_latency_p95:0,false_recovery_count:0,unknown_auto_recovery_count:0,l60_signals_present:{no_silent_darkness:true,live_truth_delta:true,unknown_separated:true,recovery_budget:true,recovery_lease:true}}' "$recs")"
  append_jsonl "$METRICS_FILE" "$(jq -c '{ts:.checked_at,schema_version:.schema_version,source_health:.source_health.status,frozen_panes_detected:.frozen_panes_detected}' <<<"$payload")"
  printf '%s\n' "$payload"
}
while [[ $# -gt 0 ]]; do case "$1" in
  --session) SESSION="${2:?}"; shift 2;; --session=*) SESSION="${1#*=}"; shift;; --json) JSON_OUT=1; shift;; --auto-recover) AUTO_RECOVER=1; shift;; --apply) APPLY=1; shift;; --dry-run) DRY_RUN=1; shift;; --doctor|--health) MODE=doctor; shift;; --info) MODE=info; shift;; --schema) MODE=schema; shift;; --examples) MODE=examples; shift;; --lines) LINES="${2:?}"; shift 2;; --sample-interval-seconds) shift 2;; --idempotency-key) IDEMPOTENCY_KEY="${2:?}"; shift 2;; -h|--help) usage; exit 0;; *) shift;; esac; done
[[ "$AUTO_RECOVER" == 1 && "$APPLY" != 1 ]] && { printf 'WARNING: --auto-recover is preview-only; pass --apply to execute pane recovery mutations.\n' >&2; DRY_RUN=1; }
case "$MODE" in doctor) payload="$(doctor)";; info) payload="$(info)";; schema) schema; exit 0;; examples) usage; exit 0;; detect) [[ -n "$SESSION" ]] || { usage >&2; exit 2; }; payload="$(detect)";; esac
[[ "$JSON_OUT" == 1 || "$MODE" != detect ]] && printf '%s\n' "$payload" || jq -r '"frozen-pane-detector session=\(.session) frozen=\(.frozen_panes_detected)"' <<<"$payload"
