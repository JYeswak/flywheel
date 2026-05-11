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
# specific logic was filled in by bead flywheel-1hshd.33 (PARTIAL-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="fuckup-coverage-join/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/fuckup-coverage-join-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: fuckup-coverage-join.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "fuckup-coverage-join.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "fuckup-coverage-join.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"fuckup-coverage-join.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"fuckup-coverage-join.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"fuckup-coverage-join.sh doctor --json"}'
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
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",emits:{schema_version:"string",command:"\"doctor\"",ts:"iso8601",status:"string",checks:"array<{name,status,note?}>"},notes:"probes jq/bash, fuckup_log (load-bearing), memory_dir, INCIDENTS.md, canonical L-rule dir, audit_log_dir"}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",last_run_ts:"iso8601|null",audit_log:"path"},binds_audit_log:true}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["audit_log_dir","memory_dir","fuckup_log_dir"],apply_contract:"--apply requires --idempotency-key (rc=3 refusal)",unknown_scope:"rc=64",emits:{schema_version:"string",command:"\"repair\"",ts:"iso8601",mode:"\"dry_run\"|\"apply\"",scope:"string",status:"\"ok\"|\"refused\""}}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",valid_subjects:["fuckup-class","join-layer","limit"],join_layer_enum:["memory","incident","canonical_l_rule","probe","dashboard"],cross_source:"native --schema .joins[] (5 join layers)",limit_range:"[1, 10000]",emits:{schema_version:"string",command:"\"validate\"",subject:"string",ts:"iso8601",status:"\"ok\"|\"reject\"|\"refused\"",value:"any",reason:"string?"}}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","fuckup_class","join_layer"],emits:{schema_version:"string",command:"\"why\"",id:"string",ts:"iso8601",status:"string",row:"object?"}}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],variant:"PARTIAL-BYPASS",bypassed_natively:["--schema"],note:"native --schema bypassed to legacy joins/output_fields shape; scaffold owns --info/--examples + all verbs"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — native owns; joins unprocessed fuckup classes to durable routing layers (memory/INCIDENTS/canonical L-rules/probes/dashboard). Flags: --self-test, --repo PATH, --log PATH, --memory-dir PATH, --limit N.\n' ;;
    doctor)   printf 'topic: doctor — probes bash/jq, fuckup_log (load-bearing for join input), memory_dir, INCIDENTS.md, canonical L-rule dir, audit_log_dir.\n' ;;
    health)   printf 'topic: health — emits last_run_ts from audit log.\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|memory_dir|fuckup_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply needs key (rc=3). Unknown = rc=64.\n' ;;
    validate) printf 'topic: validate <fuckup-class|join-layer|limit> VALUE — fuckup-class shape ^[a-z][a-z0-9_]*$; join-layer enum {memory, incident, canonical_l_rule, probe, dashboard} cross-sourced with native --schema .joins[]; limit integer in [1, 10000]. Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG (default 20 rows).\n' ;;
    why)      printf 'topic: why <id> — explains row by id; matches against ts / run_id / fuckup_class / join_layer.\n' ;;
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
            && cli_emit_completion_bash "fuckup-coverage-join" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "fuckup-coverage-join" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local checks=()
  local repo="${REPO:-/Users/josh/Developer/flywheel}"
  local fuckup_log="${FUCKUP_LOG:-$repo/.flywheel/fuckup-log.jsonl}"
  local memory_dir="${MEMORY_DIR:-/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory}"
  local incidents="$repo/.flywheel/INCIDENTS.md"
  local rule_dir="$repo/.flywheel/rules"
  if command -v bash >/dev/null 2>&1; then checks+=('{"name":"bash_available","status":"pass"}')
  else checks+=('{"name":"bash_available","status":"fail"}'); fi
  if command -v jq >/dev/null 2>&1; then checks+=('{"name":"jq_available","status":"pass"}')
  else checks+=('{"name":"jq_available","status":"fail","note":"required for join logic"}'); fi
  if [[ -r "$fuckup_log" ]]; then
    checks+=('{"name":"fuckup_log_readable","status":"pass","path":"'"$fuckup_log"'"}')
  else
    checks+=('{"name":"fuckup_log_readable","status":"warn","path":"'"$fuckup_log"'","note":"load-bearing — join input; empty when no fuckups logged"}')
  fi
  if [[ -d "$memory_dir" ]]; then
    checks+=('{"name":"memory_dir_present","status":"pass","path":"'"$memory_dir"'"}')
  else
    checks+=('{"name":"memory_dir_present","status":"warn","path":"'"$memory_dir"'","note":"join target for memory routing layer"}')
  fi
  if [[ -r "$incidents" ]]; then
    checks+=('{"name":"incidents_md_present","status":"pass","path":"'"$incidents"'"}')
  else
    checks+=('{"name":"incidents_md_present","status":"warn","path":"'"$incidents"'","note":"join target for incident routing layer"}')
  fi
  if [[ -d "$rule_dir" ]]; then
    checks+=('{"name":"canonical_l_rule_dir_present","status":"pass","path":"'"$rule_dir"'"}')
  else
    checks+=('{"name":"canonical_l_rule_dir_present","status":"warn","path":"'"$rule_dir"'","note":"join target for canonical L-rule routing layer"}')
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
    memory_dir)
      local target="${MEMORY_DIR:-/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory}"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope memory_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    fuckup_log_dir)
      local target="$repo/.flywheel"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope fuckup_log_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|memory_dir|fuckup_log_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","memory_dir","fuckup_log_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    fuckup-class)
      if [[ -z "$arg" ]]; then printf 'ERR: validate fuckup-class requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[a-z][a-z0-9_]*$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"fuckup-class",ts:$ts,status:"ok",value:$v,note:"matches canonical fuckup_class shape (snake_case)"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"fuckup-class",ts:$ts,status:"reject",value:$v,reason:"pattern_mismatch",pattern:"^[a-z][a-z0-9_]*$"}'
        return 1
      fi
      ;;
    join-layer)
      if [[ -z "$arg" ]]; then printf 'ERR: validate join-layer requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        memory|incident|canonical_l_rule|probe|dashboard)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"join-layer",ts:$ts,status:"ok",value:$v,source:"native --schema .joins[] (5 layers)"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"join-layer",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_layers:["memory","incident","canonical_l_rule","probe","dashboard"],source:"native --schema .joins[]"}'
          return 1 ;;
      esac
      ;;
    limit)
      if [[ -z "$arg" ]]; then printf 'ERR: validate limit requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 1 && arg <= 10000 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"limit",ts:$ts,status:"ok",value:$v,note:"matches native --limit flag contract"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"limit",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[1, 10000]"}'
        return 1
      fi
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["fuckup-class","join-layer","limit"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["fuckup-class","join-layer","limit"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.fuckup_class // "") == $id or (.join_layer // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","fuckup_class","join_layer"]}'
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
  # PARTIAL-BYPASS (verb-first): native owns --schema (custom shape with
  # .joins + .output_fields, no .command/.mode). Scaffold owns --info,
  # --examples + all verbs.
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --schema) return 1 ;;  # PARTIAL-BYPASS to native
    --info|--examples) return 0 ;;
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
SCHEMA_VERSION="fuckup-coverage-join/v1"
REPO="$(pwd -P)"
LOG="${FLYWHEEL_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
MEMORY_DIR="${FLYWHEEL_MEMORY_DIR:-$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory}"
STATUS_DOC="${FLYWHEEL_STATUS_DOC:-$HOME/.claude/commands/flywheel/status.md}"
limit=50
json=0
schema=0
self_test=0

usage() {
  cat <<'EOF'
usage: fuckup-coverage-join.sh [--json] [--schema] [--self-test] [--repo PATH] [--log PATH] [--memory-dir PATH] [--limit N]

Joins unprocessed fuckup trauma classes to durable routing layers: memory,
INCIDENTS, canonical L-rules, probe scripts, and dashboard/status surfacing.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --schema) schema=1; shift ;;
    --self-test) self_test=1; shift ;;
    --repo) REPO="$(cd "${2:?missing repo}" && pwd -P)"; shift 2 ;;
    --log) LOG="${2:?missing log path}"; shift 2 ;;
    --memory-dir) MEMORY_DIR="${2:?missing memory dir}"; shift 2 ;;
    --status-doc) STATUS_DOC="${2:?missing status doc path}"; shift 2 ;;
    --limit) limit="${2:?missing limit}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

emit_schema() {
  jq -nc --arg schema_version "$SCHEMA_VERSION" '{
    schema_version:$schema_version,
    joins:["memory","incident","canonical_l_rule","probe","dashboard"],
    output_fields:["fuckup_classes_without_route_count","promotion_ready_without_mechanism_count","rows"]
  }'
}

fixed_ref_exists() {
  local needle="$1"; shift
  local path
  for path in "$@"; do
    [[ -e "$path" ]] || continue
    if rg -q -F "$needle" "$path" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

class_groups() {
  if [[ ! -f "$LOG" ]]; then
    return 0
  fi
  jq -Rsc --argjson limit "$limit" '
    split("\n")
    | map(select(length > 0) | try fromjson catch empty)
    | [ .[]
      | select(type == "object")
      | select((.trauma_class // "") != "")
      | select((.processed_at // null) == null)
    ]
    | group_by(.trauma_class)
    | map({
        trauma_class:.[0].trauma_class,
        count:length,
        max_severity:(
          if any(.[]; .severity == "high") then "high"
          elif any(.[]; .severity == "medium") then "medium"
          else "low" end
        ),
        latest_ts:(map(.ts // "") | max),
        should_become:(map(.should_become // empty) | unique)
      })
    | sort_by(-.count, .trauma_class)
    | .[:$limit]
    | .[]
  ' "$LOG"
}

emit_report() {
  local rows="[]" group class count has_memory has_incident has_l_rule has_probe has_dashboard route_missing promotion_ready no_mechanism

  while IFS= read -r group; do
    [[ -n "$group" ]] || continue
    class="$(jq -r '.trauma_class' <<<"$group")"
    count="$(jq -r '.count' <<<"$group")"

    has_memory=false
    has_incident=false
    has_l_rule=false
    has_probe=false
    has_dashboard=false

    if fixed_ref_exists "$class" "$MEMORY_DIR" "$REPO/.flywheel/doctrine" "$REPO/.flywheel/fuckup-log"; then
      has_memory=true
    fi
    if fixed_ref_exists "$class" "$REPO/INCIDENTS.md" "$HOME/.claude/skills"/*/references/INCIDENTS.md; then
      has_incident=true
    fi
    if fixed_ref_exists "$class" "$REPO/AGENTS.md" "$REPO/.flywheel/AGENTS-CANONICAL.md" "$REPO/templates/flywheel-install/AGENTS.md"; then
      has_l_rule=true
    fi
    if fixed_ref_exists "$class" "$REPO/.flywheel/scripts"; then
      has_probe=true
    fi
    if fixed_ref_exists "$class" "$STATUS_DOC" "$REPO/README.md"; then
      has_dashboard=true
    fi

    route_missing=false
    if [[ "$has_memory" == false && "$has_incident" == false && "$has_l_rule" == false && "$has_probe" == false && "$has_dashboard" == false ]]; then
      route_missing=true
    fi
    promotion_ready=false
    no_mechanism=false
    if [[ "$count" -ge 3 ]]; then
      promotion_ready=true
      if [[ "$has_l_rule" == false && "$has_probe" == false && "$has_dashboard" == false ]]; then
        no_mechanism=true
      fi
    fi

    rows="$(jq -c \
      --argjson group "$group" \
      --argjson has_memory "$has_memory" \
      --argjson has_incident "$has_incident" \
      --argjson has_l_rule "$has_l_rule" \
      --argjson has_probe "$has_probe" \
      --argjson has_dashboard "$has_dashboard" \
      --argjson route_missing "$route_missing" \
      --argjson promotion_ready "$promotion_ready" \
      --argjson no_mechanism "$no_mechanism" \
      '. + [$group + {has_memory:$has_memory,has_incident:$has_incident,has_canonical_l_rule:$has_l_rule,has_probe:$has_probe,has_dashboard:$has_dashboard,route_missing:$route_missing,promotion_ready:$promotion_ready,promotion_ready_without_mechanism:$no_mechanism}]' \
      <<<"$rows")"
  done < <(class_groups)

  jq -nc --arg schema_version "$SCHEMA_VERSION" --arg repo "$REPO" --arg log "$LOG" --arg memory_dir "$MEMORY_DIR" --argjson rows "$rows" '
    ($rows | map(select(.route_missing == true)) | length) as $without_route
    | ($rows | map(select(.promotion_ready_without_mechanism == true)) | length) as $without_mechanism
    | {
        schema_version:$schema_version,
        status:(if $without_route > 0 or $without_mechanism > 0 then "warn" else "pass" end),
        repo:$repo,
        fuckup_log:$log,
        memory_dir:$memory_dir,
        classes_checked_count:($rows | length),
        fuckup_classes_without_route_count:$without_route,
        promotion_ready_without_mechanism_count:$without_mechanism,
        rows:$rows
      }'
}

run_self_test() {
  local tmp repo log memory status out
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/fuckup-coverage.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  repo="$tmp/repo"
  memory="$tmp/memory"
  log="$tmp/fuckup-log.jsonl"
  status="$tmp/status.md"
  mkdir -p "$repo/.flywheel/scripts" "$repo/templates/flywheel-install" "$memory"
  printf 'known-class\n' >"$repo/AGENTS.md"
  printf 'probe-class\n' >"$repo/.flywheel/scripts/probe.sh"
  printf 'dashboard-class\n' >"$status"
  jq -nc '{trauma_class:"known-class",severity:"medium",ts:"2026-05-04T00:00:00Z",processed_at:null}' >>"$log"
  jq -nc '{trauma_class:"missing-class",severity:"high",ts:"2026-05-04T00:01:00Z",processed_at:null}' >>"$log"
  jq -nc '{trauma_class:"missing-class",severity:"high",ts:"2026-05-04T00:02:00Z",processed_at:null}' >>"$log"
  jq -nc '{trauma_class:"missing-class",severity:"high",ts:"2026-05-04T00:03:00Z",processed_at:null}' >>"$log"
  out="$("$0" --repo "$repo" --log "$log" --memory-dir "$memory" --status-doc "$status" --json)"
  jq -nc --arg schema_version "$SCHEMA_VERSION" --argjson report "$out" '{
    schema_version:$schema_version,
    status:(if $report.fuckup_classes_without_route_count == 1
      and $report.promotion_ready_without_mechanism_count == 1 then "pass" else "fail" end),
    report:$report
  }'
}

if [[ "$schema" -eq 1 ]]; then
  emit_schema
elif [[ "$self_test" -eq 1 ]]; then
  run_self_test
else
  emit_report
fi
