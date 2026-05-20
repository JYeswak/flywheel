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
# specific logic was filled in by bead flywheel-1hshd.36 (SELECTIVE-VERB-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="hub-blocker-detect/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/hub-blocker-detect-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: hub-blocker-detect.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "hub-blocker-detect.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "hub-blocker-detect.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"hub-blocker-detect.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"hub-blocker-detect.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"hub-blocker-detect.sh doctor --json"}'
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
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",note:"NATIVE owns doctor verb (legacy contract); use `hub-blocker-detect.sh doctor --json` for hub_blocker_count/signal/dashboard_line",native_emit_fields:["hub_blocker_count","max_parent_block_count","top_hub_blocker_id","signal","dashboard_line","operator_lens"]}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",last_run_ts:"iso8601|null",audit_log:"path"},binds_audit_log:true,note:"scaffold-only surface; native lacks health"}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["audit_log_dir","beads_dir"],apply_contract:"--apply requires --idempotency-key (rc=3 refusal)",unknown_scope:"rc=64",emits:{schema_version:"string",command:"\"repair\"",ts:"iso8601",mode:"\"dry_run\"|\"apply\"",scope:"string",status:"\"ok\"|\"refused\""}}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",valid_subjects:["threshold","bead-id","signal"],signal_enum:["GREEN","YELLOW","RED"],threshold_range:"[1, 100]",bead_id_pattern:"^[a-z][a-z0-9]+-[a-z0-9.]+$",cross_source:"native --threshold flag + signal output field",emits:{schema_version:"string",command:"\"validate\"",subject:"string",ts:"iso8601",status:"\"ok\"|\"reject\"|\"refused\"",value:"any",reason:"string?"}}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","bead_id","idempotency_key"],emits:{schema_version:"string",command:"\"why\"",id:"string",ts:"iso8601",status:"string",row:"object?"}}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],variant:"SELECTIVE-VERB-BYPASS",bypassed_natively:["--info","--examples","doctor","check"],note:"native owns rich --info envelope + doctor/check verbs (legacy hub-blocker-detect/v1 contract); scaffold owns --schema (native lacks) + health/repair/validate/audit/why/quickstart"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — native owns; routes through cmd_run (check|doctor). Flags: --repo PATH, --threshold N (default 3), --apply, --idempotency-key KEY, --json.\n' ;;
    doctor)   printf 'topic: doctor — NATIVE owns (legacy hub-blocker-detect/v1 contract). Emits hub_blocker_count/signal/dashboard_line/operator_lens. Use `hub-blocker-detect.sh doctor --json`.\n' ;;
    health)   printf 'topic: health — scaffold-only surface; emits last_run_ts from $SCAFFOLD_AUDIT_LOG. NOTE: distinct from native doctor verb.\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|beads_dir> [--dry-run|--apply --idempotency-key KEY] — apply needs key (rc=3). Unknown = rc=64.\n' ;;
    validate) printf 'topic: validate <threshold|bead-id|signal> VALUE — threshold int [1, 100] cross-sources native --threshold (default 3); bead-id shape ^[a-z][a-z0-9]+-[a-z0-9.]+$; signal enum {GREEN, YELLOW, RED} cross-sources native signal output. Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG (default 20 rows).\n' ;;
    why)      printf 'topic: why <id> — explains row by id; matches against ts / run_id / bead_id / idempotency_key.\n' ;;
    *)        printf 'topics: run | doctor (NATIVE) | health | repair | validate | audit | why\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "hub-blocker-detect" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "hub-blocker-detect" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # NOTE: SELECTIVE-VERB-BYPASS — this scaffold_cmd_doctor is dead code.
  # Native owns `doctor` verb (see _scaffold_is_canonical_arg). Routed for
  # introspection only; emits a delegation envelope.
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:"delegated_to_native",note:"native owns doctor verb (legacy hub-blocker-detect/v1 contract)",native_invocation:"hub-blocker-detect.sh doctor --json"}'
}

scaffold_cmd_health() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local last_run_ts="null"
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    local raw; raw="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then last_run_ts="\"$raw\""; fi
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson last "$last_run_ts" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"ok",last_run_ts:$last,audit_log:$log,binds_audit_log:true,note:"distinct from native doctor verb"}'
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
  local repo="${REPO:-/Users/josh/Developer/flywheel}"
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
    beads_dir)
      local target="$repo/.beads"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope beads_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|beads_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","beads_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    threshold)
      if [[ -z "$arg" ]]; then printf 'ERR: validate threshold requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 1 && arg <= 100 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"threshold",ts:$ts,status:"ok",value:$v,default:3,note:"cross-sources native --threshold flag"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"threshold",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[1, 100]"}'
        return 1
      fi
      ;;
    bead-id)
      if [[ -z "$arg" ]]; then printf 'ERR: validate bead-id requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[a-z][a-z0-9]+-[a-z0-9.]+$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"bead-id",ts:$ts,status:"ok",value:$v,note:"matches canonical beads ID shape"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"bead-id",ts:$ts,status:"reject",value:$v,reason:"pattern_mismatch",pattern:"^[a-z][a-z0-9]+-[a-z0-9.]+$"}'
        return 1
      fi
      ;;
    signal)
      if [[ -z "$arg" ]]; then printf 'ERR: validate signal requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        GREEN|YELLOW|RED)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"signal",ts:$ts,status:"ok",value:$v,source:"native doctor output .signal field"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"signal",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_signals:["GREEN","YELLOW","RED"]}'
          return 1 ;;
      esac
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["threshold","bead-id","signal"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["threshold","bead-id","signal"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.bead_id // "") == $id or (.idempotency_key // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","bead_id","idempotency_key"]}'
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
  # SELECTIVE-VERB-BYPASS variant: native owns rich --info envelope + doctor
  # verb (legacy hub-blocker-detect/v1 contract with hub_blocker_count,
  # operator_lens, etc.) + check verb (sister of doctor) + --examples.
  # Scaffold owns --schema (native lacks it) + health/repair/validate/audit/
  # why/quickstart/help <topic>/completion.
  case "${1:-}" in
    health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    doctor) return 1 ;;  # SELECTIVE-VERB-BYPASS — native owns legacy contract
    --schema) return 0 ;;  # native lacks --schema; scaffold owns
    --info|--examples) return 1 ;;  # native owns rich envelopes
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
VERSION="hub-blocker-detect.v1.0.0"
SCHEMA_VERSION="hub-blocker-detect/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="${HUB_BLOCKER_REPO:-$REPO_DEFAULT}"
BR_BIN="${BR_BIN:-$HOME/.cargo/bin/br}"
LOOP_BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
THRESHOLD="${HUB_BLOCKER_THRESHOLD:-3}"
APPLY=0
JSON_OUT=0
COMMAND="check"
IDEMPOTENCY_KEY=""
AUDIT_LOG="${HUB_BLOCKER_AUDIT_LOG:-$HOME/.local/state/flywheel/hub-blocker-detect-runs.jsonl}"

usage() {
  cat <<'EOF'
usage:
  hub-blocker-detect.sh [check|doctor] [--repo PATH] [--threshold N] [--apply --idempotency-key KEY] [--json]
  hub-blocker-detect.sh --info|--examples|--help

Detects open beads that block more than N parent closures. In apply mode it
promotes hub blockers to P0, labels them hub_blocker, and logs one fuckup row
per detected occurrence.

--apply requires --idempotency-key (rc=3 if missing). Per-bead ledger-replay
filters bead_ids already promoted under the same key (sister 1o9fa pattern).

Exit codes:
  0  probe completed or replay-no-op
  1  hub blocker detected (doctor/check mode)
  2  usage or substrate error
  3  --apply without --idempotency-key (canonical refusal contract)
EOF
}

examples() {
  cat <<'EOF'
examples:
  .flywheel/scripts/hub-blocker-detect.sh --json
  .flywheel/scripts/hub-blocker-detect.sh --threshold 3 --apply --idempotency-key=hourly-$(date -u +%Y%m%d-%H) --json
  HUB_BLOCKER_THRESHOLD=5 .flywheel/scripts/hub-blocker-detect.sh doctor --json
EOF
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

json_bool() {
  if [[ "${1:-0}" == "1" ]]; then
    printf true
  else
    printf false
  fi
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    check|doctor)
      COMMAND="$1"
      shift
      ;;
    --repo)
      REPO="${2:?missing --repo value}"
      shift 2
      ;;
    --threshold)
      THRESHOLD="${2:?missing --threshold value}"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    --idempotency-key)
      [[ -n "${2:-}" ]] || { printf 'ERR: --idempotency-key requires VALUE\n' >&2; exit 2; }
      IDEMPOTENCY_KEY="$2"
      shift 2
      ;;
    --idempotency-key=*)
      IDEMPOTENCY_KEY="${1#--idempotency-key=}"
      [[ -n "$IDEMPOTENCY_KEY" ]] || { printf 'ERR: --idempotency-key requires VALUE\n' >&2; exit 2; }
      shift
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --info)
      jq -nc --arg version "$VERSION" --arg schema "$SCHEMA_VERSION" --arg repo "$REPO" --arg audit_log "$AUDIT_LOG" \
        '{name:"hub-blocker-detect.sh",version:$version,schema_version:$schema,repo:$repo,audit_log:$audit_log,apply_requires:"--idempotency-key",commands:["check","doctor","--repo","--threshold","--apply","--idempotency-key","--json","--info","--examples","--help"],exits:{"0":"probe completed or replay-no-op","1":"hub blocker detected in doctor/check mode","2":"usage or substrate error","3":"--apply without --idempotency-key (canonical refusal)"}}'
      exit 0
      ;;
    --examples)
      examples
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'ERR: unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

case "$THRESHOLD" in
  ''|*[!0-9]*)
    printf 'ERR: --threshold must be a non-negative integer\n' >&2
    exit 2
    ;;
esac

# Mutation gate (7axmt P2 fix, sister 1o9fa per-pane-replay-granularity-pattern adapted
# to per-bead). Fires BEFORE any br update call (hoqq8 invariant). Without a key,
# retries double-write br audit-trail rows; per-(key, bead_id) replay prevents this.
if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg repo "$REPO" \
    '{schema_version:$schema,command:"hub-blocker-detect",status:"refused",mode:"apply",repo:$repo,reason:"--apply requires --idempotency-key"}' >&2
  exit 3
fi

# Per-bead replay-check (sister 1o9fa per-target variant). Tolerant-parse via
# jq -R 'fromjson?' per sister 8sx9w skill discovery. Returns JSON array of
# bead_id values already promoted with the same idempotency_key.
replay_already_promoted_bead_ids() {
  if [[ -z "$IDEMPOTENCY_KEY" || ! -r "$AUDIT_LOG" ]]; then
    printf '[]\n'
    return 0
  fi
  jq -Rcs --arg k "$IDEMPOTENCY_KEY" \
    '[ split("\n")[] | select(length > 0) | fromjson? | select((.idempotency_key // "") == $k and (.action // "") == "br_update_priority") | (.bead_id // empty) ] | unique' \
    "$AUDIT_LOG" 2>/dev/null || printf '[]\n'
}

audit_append_hub() {
  local row="$1"
  mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null || true
  printf '%s\n' "$row" >>"$AUDIT_LOG"
}

if ! command -v jq >/dev/null 2>&1; then
  printf '{"schema_version":"%s","status":"error","error":"jq_missing"}\n' "$SCHEMA_VERSION"
  exit 2
fi

if [[ ! -x "$BR_BIN" ]] && ! command -v "$BR_BIN" >/dev/null 2>&1; then
  printf '{"schema_version":"%s","status":"error","error":"br_missing"}\n' "$SCHEMA_VERSION"
  exit 2
fi

if [[ ! -d "$REPO/.beads" ]]; then
  jq -nc --arg schema "$SCHEMA_VERSION" --arg repo "$REPO" \
    '{schema_version:$schema,status:"error",signal:"GRAY",repo:$repo,error:"beads_workspace_missing",hub_blocker_count:0,hub_blockers:[]}'
  exit 2
fi

issues_json="$(cd "$REPO" && "$BR_BIN" list --all --json --limit 0)"
if ! jq -e . >/dev/null 2>&1 <<<"$issues_json"; then
  jq -nc --arg schema "$SCHEMA_VERSION" --arg repo "$REPO" \
    '{schema_version:$schema,status:"error",signal:"GRAY",repo:$repo,error:"br_list_invalid_json",hub_blocker_count:0,hub_blockers:[]}'
  exit 2
fi

hub_ids="$(
  jq -r --argjson threshold "$THRESHOLD" '
    (if type == "array" then . else (.issues // []) end)[]
    | select((.status // "" | ascii_downcase) != "closed")
    | select((.dependency_count // 0) > $threshold)
    | [.id, (.priority // 4), (.dependency_count // 0), (.title // ""), (.status // "")] | @tsv
  ' <<<"$issues_json"
)"

rows_file="$(mktemp "${TMPDIR:-/tmp}/hub-blocker-rows.XXXXXX")"
trap 'rm -f "$rows_file"' EXIT
: >"$rows_file"

promoted_count=0
fuckup_log_count=0
replay_skipped_count=0
actions=()

# Per-bead replay-skip set (sister 1o9fa pattern): bead_ids already promoted with
# this idempotency_key. Filter them out before the promote/label/fuckup loop fires.
REPLAY_SKIPPED_BEAD_IDS_JSON="$(replay_already_promoted_bead_ids)"
declare -A REPLAY_SKIP_SET=()
while IFS= read -r skipped; do
  [[ -n "$skipped" ]] || continue
  REPLAY_SKIP_SET["$skipped"]=1
done < <(jq -r '.[]' <<<"$REPLAY_SKIPPED_BEAD_IDS_JSON")

while IFS=$'\t' read -r bead_id priority parent_count title status; do
  [[ -n "${bead_id:-}" ]] || continue
  deps_json="$(cd "$REPO" && "$BR_BIN" dep list "$bead_id" --json 2>/dev/null || printf '[]')"
  parent_ids="$(jq -r '[.[]? | select((.type // "") == "blocks") | .depends_on_id] | unique | join(",")' <<<"$deps_json")"
  parent_status_counts="$(jq -c '[.[]? | select((.type // "") == "blocks") | (.status // "unknown")] | group_by(.) | map({(.[0]): length}) | add // {}' <<<"$deps_json")"
  would_promote=false
  promoted=false
  labeled=false
  replay_skipped=false
  if [[ "${priority:-4}" != "0" ]]; then
    would_promote=true
  fi
  # Per-bead replay: if this bead_id was already promoted under the same key, skip
  # the br update / br label / fuckup-log calls entirely. Row still emitted for
  # transparency (with replay_skipped=true).
  if [[ "$APPLY" -eq 1 && -n "${REPLAY_SKIP_SET[$bead_id]:-}" ]]; then
    replay_skipped=true
    replay_skipped_count=$((replay_skipped_count + 1))
    actions+=("replay_skipped:$bead_id")
  elif [[ "$APPLY" -eq 1 ]]; then
    prior_priority="${priority:-4}"
    if [[ "$prior_priority" != "0" ]]; then
      (cd "$REPO" && "$BR_BIN" update "$bead_id" --priority 0 --json >/dev/null)
      promoted=true
      promoted_count=$((promoted_count + 1))
    fi
    (cd "$REPO" && "$BR_BIN" label add "$bead_id" --label hub_blocker --json >/dev/null) || true
    labeled=true
    actions+=("promoted_or_labeled:$bead_id")
    audit_append_hub "$(jq -nc \
      --arg sv "$SCHEMA_VERSION" \
      --arg ts "$(now_iso)" \
      --arg k "$IDEMPOTENCY_KEY" \
      --arg bead_id "$bead_id" \
      --argjson prior_priority "$prior_priority" \
      --argjson new_priority 0 \
      --argjson parent_block_count "${parent_count:-0}" \
      '{schema_version:$sv,ts:$ts,action:"br_update_priority",idempotency_key:$k,bead_id:$bead_id,prior_priority:$prior_priority,new_priority:$new_priority,parent_block_count:$parent_block_count}')"
    if [[ -x "$LOOP_BIN" ]]; then
      if (cd "$REPO" && "$LOOP_BIN" fuckup log \
          --class hub-blocker \
          --severity high \
          --what-happened "Hub blocker $bead_id parent_block_count=$parent_count. Hub blockers are the ops-manager's bottleneck signal: when one child is blocking 5 parents, that is the queue depth metric you escalate before the storm hits." \
          --what-attempted "hub-blocker-detect.sh --apply" \
          --what-worked "auto-promoted to P0 and labeled hub_blocker" \
          --evidence "$bead_id,parent_block_count=$parent_count" \
          --should-become bead \
          --session flywheel \
          --pane 3 \
          --json >/dev/null); then
        fuckup_log_count=$((fuckup_log_count + 1))
      else
        actions+=("fuckup_log_failed:$bead_id")
      fi
    else
      actions+=("fuckup_log_skipped_loop_bin_missing:$bead_id")
    fi
  else
    actions+=("would_promote_or_label:$bead_id")
  fi

  jq -nc \
    --arg id "$bead_id" \
    --arg title "$title" \
    --arg status "$status" \
    --argjson priority "${priority:-4}" \
    --argjson parent_block_count "${parent_count:-0}" \
    --arg parent_ids "$parent_ids" \
    --argjson parent_status_counts "$parent_status_counts" \
    --argjson would_promote "$would_promote" \
    --argjson promoted "$promoted" \
    --argjson labeled "$labeled" \
    --argjson replay_skipped "$replay_skipped" \
    '{
      id:$id,
      title:$title,
      status:$status,
      priority:$priority,
      parent_block_count:$parent_block_count,
      parent_ids:($parent_ids | split(",") | map(select(length > 0))),
      parent_status_counts:$parent_status_counts,
      would_promote:$would_promote,
      promoted:$promoted,
      labeled:$labeled,
      replay_skipped:$replay_skipped
    }' >>"$rows_file"
done <<<"$hub_ids"

hub_blocker_count="$(jq -s 'length' "$rows_file")"
max_parent_block_count="$(jq -s '[.[].parent_block_count] | max // 0' "$rows_file")"
top_hub_blocker_id="$(jq -rs 'sort_by(.parent_block_count) | reverse | .[0].id // "none"' "$rows_file")"
top_parent_ids="$(jq -cs 'sort_by(.parent_block_count) | reverse | .[0].parent_ids // []' "$rows_file")"
rows_json="$(jq -s -c 'sort_by(.parent_block_count) | reverse' "$rows_file")"
if [[ "${#actions[@]}" -eq 0 ]]; then
  actions_json="[]"
else
  actions_json="$(printf '%s\n' "${actions[@]}" | sed '/^$/d' | jq -R . | jq -s .)"
fi
signal="GREEN"
status="pass"
exit_code=0
if [[ "$hub_blocker_count" -gt 0 ]]; then
  signal="RED"
  status="fail"
  [[ "$COMMAND" == "doctor" || "$COMMAND" == "check" ]] && exit_code=1
fi
dashboard_line="Hub blockers: ${hub_blocker_count} active | top=${top_hub_blocker_id}:${max_parent_block_count} parents | promoted=${promoted_count} | fuckups_logged=${fuckup_log_count}"

payload="$(
  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg repo "$REPO" \
    --arg signal "$signal" \
    --arg status "$status" \
    --argjson threshold "$THRESHOLD" \
    --argjson apply "$(json_bool "$APPLY")" \
    --argjson hub_blocker_count "$hub_blocker_count" \
    --argjson max_parent_block_count "$max_parent_block_count" \
    --arg top_hub_blocker_id "$top_hub_blocker_id" \
    --argjson top_parent_ids "$top_parent_ids" \
    --argjson promoted_count "$promoted_count" \
    --argjson fuckup_log_count "$fuckup_log_count" \
    --argjson replay_skipped_count "$replay_skipped_count" \
    --argjson replay_skipped_bead_ids "$REPLAY_SKIPPED_BEAD_IDS_JSON" \
    --arg idempotency_key "$IDEMPOTENCY_KEY" \
    --arg audit_log "$AUDIT_LOG" \
    --arg dashboard_line "$dashboard_line" \
    --argjson rows "$rows_json" \
    --argjson actions "$actions_json" \
    '{
      schema_version:$schema,
      version:$version,
      audit_ts:$ts,
      repo:$repo,
      status:$status,
      signal:$signal,
      threshold:$threshold,
      apply:$apply,
      idempotency_key:$idempotency_key,
      audit_log:$audit_log,
      hub_blocker_count:$hub_blocker_count,
      max_parent_block_count:$max_parent_block_count,
      top_hub_blocker_id:$top_hub_blocker_id,
      top_parent_ids:$top_parent_ids,
      promoted_count:$promoted_count,
      fuckup_log_count:$fuckup_log_count,
      replay_skipped_count:$replay_skipped_count,
      replay_skipped_bead_ids:$replay_skipped_bead_ids,
      dashboard_line:$dashboard_line,
      operator_lens:"Hub blockers are the ops-manager bottleneck signal: when one child blocks more than three parent closures, queue depth escalates before the storm hits.",
      hub_blockers:$rows,
      actions:$actions
    }'
)"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$payload"
else
  jq -r '.dashboard_line' <<<"$payload"
fi

exit "$exit_code"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
