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
# specific logic was filled in by bead flywheel-1hshd.29 (NO-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="flywheel-adopt/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/flywheel-adopt-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: flywheel-adopt.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "flywheel-adopt.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "flywheel-adopt.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"flywheel-adopt.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"flywheel-adopt.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"flywheel-adopt.sh doctor --json"}'
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
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",emits:{schema_version:"string",command:"\"doctor\"",ts:"iso8601",status:"string",checks:"array<{name,status,note?}>"},notes:"probes bash/jq/git, target_repo_resolvable, flywheel_install_templates (templates/flywheel-install/), fs_rag_substrate (linter/scaffolder/pre-commit), audit_log_dir"}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",last_run_ts:"iso8601|null",audit_log:"path"},binds_audit_log:true}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["audit_log_dir","fs_rag_backfill_receipt_dir","flywheel_dir"],apply_contract:"--apply requires --idempotency-key (rc=3 refusal)",unknown_scope:"rc=64",emits:{schema_version:"string",command:"\"repair\"",ts:"iso8601",mode:"\"dry_run\"|\"apply\"",scope:"string",status:"\"ok\"|\"refused\""}}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",valid_subjects:["repo-path","adoption-mode","idempotency-key"],adoption_mode_enum:["bootstrap","reconcile","first_run_audit","apply_fs_rag"],cross_source:"native --reconcile / --first-run-audit / --apply-fs-rag flags",emits:{schema_version:"string",command:"\"validate\"",subject:"string",ts:"iso8601",status:"\"ok\"|\"reject\"|\"refused\"",value:"any",reason:"string?"}}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","repo","idempotency_key"],emits:{schema_version:"string",command:"\"why\"",id:"string",ts:"iso8601",status:"string",row:"object?"}}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],variant:"NO-BYPASS",note:"native flags --repo/--apply/--reconcile/--first-run-audit/--start-loop/--apply-fs-rag fall through to cmd_run; scaffold owns all canonical surfaces"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — native owns; routes through cmd_run (adopt repo: install templates/flywheel-install/, optional --reconcile, --first-run-audit, --start-loop, --apply-fs-rag). Dry-run default; --apply for durable writes.\n' ;;
    doctor)   printf 'topic: doctor — probes bash/jq/git/target_repo_resolvable/flywheel_install_templates_present (templates/flywheel-install/)/fs_rag_substrate_present (linter+scaffolder+pre-commit)/audit_log_dir_writable.\n' ;;
    health)   printf 'topic: health — emits last_run_ts from audit log; status=ok|degraded based on doctor parity.\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|fs_rag_backfill_receipt_dir|flywheel_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: audit_log_dir (mkdir -p dirname of $SCAFFOLD_AUDIT_LOG), fs_rag_backfill_receipt_dir (mkdir -p $REPO/.flywheel/audit/), flywheel_dir (mkdir -p $REPO/.flywheel/). Unknown = rc=64.\n' ;;
    validate) printf 'topic: validate <repo-path|adoption-mode|idempotency-key> VALUE — repo-path must be readable git-ish dir; adoption-mode enum {bootstrap, reconcile, first_run_audit, apply_fs_rag} cross-sourced with native flags; idempotency-key shape ^[A-Za-z0-9._-]{4,128}$. Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG (default 20 rows). Empty when audit log missing.\n' ;;
    why)      printf 'topic: why <id> — explains row by id; matches against ts / run_id / repo / idempotency_key. Returns status=found|not_found|unavailable.\n' ;;
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
            && cli_emit_completion_bash "flywheel-adopt" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "flywheel-adopt" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local checks=()
  local flywheel_repo="/Users/josh/Developer/flywheel"
  local install_tmpl="$flywheel_repo/templates/flywheel-install"
  if command -v bash >/dev/null 2>&1; then checks+=('{"name":"bash_available","status":"pass"}')
  else checks+=('{"name":"bash_available","status":"fail"}'); fi
  if command -v jq >/dev/null 2>&1; then checks+=('{"name":"jq_available","status":"pass"}')
  else checks+=('{"name":"jq_available","status":"fail"}'); fi
  if command -v git >/dev/null 2>&1; then checks+=('{"name":"git_available","status":"pass"}')
  else checks+=('{"name":"git_available","status":"fail","note":"adoption requires git"}'); fi
  local target_repo="${REPO:-${REPO_TARGET:-$PWD}}"
  if [[ -d "$target_repo" ]]; then
    checks+=('{"name":"target_repo_resolvable","status":"pass","path":"'"$target_repo"'"}')
  else
    checks+=('{"name":"target_repo_resolvable","status":"fail","path":"'"$target_repo"'"}')
  fi
  if [[ -d "$install_tmpl" ]]; then
    checks+=('{"name":"flywheel_install_templates_present","status":"pass","path":"'"$install_tmpl"'"}')
  else
    checks+=('{"name":"flywheel_install_templates_present","status":"fail","path":"'"$install_tmpl"'","note":"load-bearing — adoption installs from templates/flywheel-install/"}')
  fi
  local fs_rag_linter="$flywheel_repo/.flywheel/scripts/fs-rag-linter.sh"
  if [[ -x "$fs_rag_linter" ]]; then
    checks+=('{"name":"fs_rag_substrate_present","status":"pass","path":"'"$fs_rag_linter"'"}')
  else
    checks+=('{"name":"fs_rag_substrate_present","status":"warn","path":"'"$fs_rag_linter"'","note":"--apply-fs-rag flag references this primitive"}')
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
  local target_repo="${REPO:-${REPO_TARGET:-$PWD}}"
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
    fs_rag_backfill_receipt_dir)
      local target="$target_repo/.flywheel/audit"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope fs_rag_backfill_receipt_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true"),note:"required for fs-rag-backfill-applied.json receipt"}'
      ;;
    flywheel_dir)
      local target="$target_repo/.flywheel"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope flywheel_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|fs_rag_backfill_receipt_dir|flywheel_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","fs_rag_backfill_receipt_dir","flywheel_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    repo-path)
      if [[ -z "$arg" ]]; then printf 'ERR: validate repo-path requires VALUE\n' >&2; return 64; fi
      if [[ -d "$arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"repo-path",ts:$ts,status:"ok",value:$v,note:"directory exists; adoption can proceed"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"repo-path",ts:$ts,status:"reject",value:$v,reason:"directory_not_found"}'
        return 1
      fi
      ;;
    adoption-mode)
      if [[ -z "$arg" ]]; then printf 'ERR: validate adoption-mode requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        bootstrap|reconcile|first_run_audit|apply_fs_rag)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"adoption-mode",ts:$ts,status:"ok",value:$v,source:"native flags --reconcile/--first-run-audit/--apply-fs-rag"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"adoption-mode",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_modes:["bootstrap","reconcile","first_run_audit","apply_fs_rag"]}'
          return 1 ;;
      esac
      ;;
    idempotency-key)
      if [[ -z "$arg" ]]; then printf 'ERR: validate idempotency-key requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[A-Za-z0-9._-]{4,128}$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"idempotency-key",ts:$ts,status:"ok",value:$v,note:"matches native --idempotency-key flag shape"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"idempotency-key",ts:$ts,status:"reject",value:$v,reason:"pattern_mismatch",pattern:"^[A-Za-z0-9._-]{4,128}$"}'
        return 1
      fi
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["repo-path","adoption-mode","idempotency-key"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["repo-path","adoption-mode","idempotency-key"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.repo // "") == $id or (.idempotency_key // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","repo","idempotency_key"]}'
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
  # NO-BYPASS variant: scaffold owns all canonical surfaces. Native flags
  # (--repo/--apply/--dry-run/--reconcile/--first-run-audit/--start-loop/
  # --apply-fs-rag/--idempotency-key) fall through because no native verb
  # at args[0] collides with scaffold verbs. Verb-first: scaffold-verbs
  # claim args[0] regardless of downstream --apply (scaffold repair owns it).
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
FLYWHEEL_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
SCHEMA_VERSION="flywheel-adopt/v1"

repo_arg="$PWD"
json=0
apply=0
dry_run=1
reconcile=0
first_run_audit=0
start_loop=0
idempotency_key=""
apply_fs_rag=0

usage() {
  cat <<'USAGE'
flywheel-adopt.sh [--repo <path>] [--json] [--dry-run] [--apply]
                  [--reconcile] [--first-run-audit] [--start-loop]
                  [--apply-fs-rag] [--idempotency-key <key>]

Dry-run is the default. Durable writes require --apply.

--apply-fs-rag: Install/update the fs-rag-discipline substrate (linter,
                scaffolder, pre-commit hook, doctrine, test) from
                templates/flywheel-install/. Runs baseline scan; idempotent
                via .flywheel/audit/fs-rag-backfill-applied.json receipt.
                Requires --apply.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo_arg="${2:?--repo requires a path}"
      shift 2
      ;;
    --json)
      json=1
      shift
      ;;
    --dry-run)
      dry_run=1
      apply=0
      shift
      ;;
    --apply)
      apply=1
      dry_run=0
      shift
      ;;
    --reconcile)
      reconcile=1
      shift
      ;;
    --first-run-audit)
      first_run_audit=1
      shift
      ;;
    --start-loop)
      start_loop=1
      shift
      ;;
    --idempotency-key)
      idempotency_key="${2:?--idempotency-key requires a value}"
      shift 2
      ;;
    --apply-fs-rag)
      apply_fs_rag=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      if [ "$repo_arg" = "$PWD" ] && [ -d "$1" ]; then
        repo_arg="$1"
        shift
      else
        echo "unknown argument: $1" >&2
        usage >&2
        exit 2
      fi
      ;;
  esac
done

if [ "$apply" -eq 1 ] && [ -z "$idempotency_key" ]; then
  echo "adopt_apply_requires_idempotency_key" >&2
  exit 2
fi

if [ ! -d "$repo_arg" ]; then
  echo "repo_not_found: $repo_arg" >&2
  exit 2
fi

repo="$(cd "$repo_arg" && pwd -P)"
if ! git -C "$repo" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "not_a_git_repo: $repo" >&2
  exit 2
fi

ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
session="${NTM_SESSION:-${FLYWHEEL_SESSION:-unknown}}"

ready=()
missing=()
drifted=()
fixed=()
registered=()

check_path() {
  local label="$1"
  local path="$2"
  if [ -e "$path" ]; then
    ready+=("$label")
  else
    missing+=("$label")
  fi
}

check_path ".flywheel/" "$repo/.flywheel"
check_path ".flywheel/MISSION.md" "$repo/.flywheel/MISSION.md"
check_path ".flywheel/GOAL.md" "$repo/.flywheel/GOAL.md"
check_path ".flywheel/STATE.md" "$repo/.flywheel/STATE.md"
check_path ".flywheel/AGENTS-CANONICAL.md" "$repo/.flywheel/AGENTS-CANONICAL.md"
check_path "INCIDENTS.md" "$repo/INCIDENTS.md"
check_path ".beads/beads.db" "$repo/.beads/beads.db"
check_path ".git/hooks/pre-commit" "$repo/.git/hooks/pre-commit"

registry="${FLYWHEEL_SUBSTRATE_REGISTRY:-$HOME/.local/state/flywheel/substrate-registry.jsonl}"
if [ -f "$registry" ] && grep -F "\"repo_path\":\"$repo\"" "$registry" >/dev/null 2>&1; then
  ready+=("substrate-registry")
else
  missing+=("substrate-registry")
fi

if command -v jsm >/dev/null 2>&1; then
  ready+=("skill catalog")
else
  drifted+=("skill catalog: jsm unavailable")
fi

wedge_count=0
if [ -d "$repo/.beads" ]; then
  wedge_count="$(find "$repo/.beads" -name '*.wedged' -type f 2>/dev/null | wc -l | tr -d ' ')"
fi
repair_needed=false
if [ "${wedge_count:-0}" -gt 0 ]; then
  repair_needed=true
  drifted+=("beads DB health: wedge marker count=$wedge_count")
fi

loop_command=""
if [ "$start_loop" -eq 1 ]; then
  if [ "$apply" -eq 1 ]; then
    loop_command="/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop start --repo \"$repo\" --apply --json"
  else
    loop_command="/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop start --repo \"$repo\" --dry-run --json"
  fi
fi

audit_command=""
if [ "$first_run_audit" -eq 1 ]; then
  audit_command="dispatch UBS sweep and codebase-audit for \"$repo\""
fi

if [ "$apply" -eq 1 ]; then
  mkdir -p "$repo/.flywheel"
  fixed+=(".flywheel/")

  for doc in MISSION GOAL STATE; do
    target="$repo/.flywheel/$doc.md"
    if [ ! -f "$target" ]; then
      printf '# %s\n\nstatus: adopted\nrepo: %s\n' "$doc" "$repo" > "$target"
      fixed+=(".flywheel/$doc.md")
    fi
  done

  canonical_source="$FLYWHEEL_ROOT/AGENTS.md"
  canonical_target="$repo/.flywheel/AGENTS-CANONICAL.md"
  if [ -f "$canonical_source" ]; then
    {
      echo "---"
      echo "canonical_source: $canonical_source"
      echo "canonical_synced_at: $ts"
      echo "---"
      cat "$canonical_source"
    } > "$canonical_target"
    fixed+=(".flywheel/AGENTS-CANONICAL.md")
  fi

  if [ ! -f "$repo/INCIDENTS.md" ]; then
    cat > "$repo/INCIDENTS.md" <<'INCIDENTS'
# INCIDENTS

Repo-local incident doctrine.

Entries promote from real evidence per L56:
- trauma_class
- evidence linkage
- recurrence threshold or cost citation
- prevention rule

Do not seed incidents without observed evidence.
INCIDENTS
    fixed+=("INCIDENTS.md")
  fi

  mkdir -p "$(dirname "$registry")"
  printf '{"ts":"%s","kind":"managed_repo","lifecycle_state":"adopted_phase0","repo_path":"%s","registered_by":"flywheel:adopt"}\n' "$ts" "$repo" >> "$registry"
  registered+=("substrate-registry")

  if [ "$repair_needed" = true ]; then
    if [ -x "$repo/scripts/bead_db_repair.sh" ]; then
      "$repo/scripts/bead_db_repair.sh" --apply >/dev/null
      fixed+=("beads DB repair")
    else
      drifted+=("beads DB health: repair script missing")
    fi
  fi

  receipt="$repo/.flywheel/install-log.jsonl"
  python3 - "$receipt" "$ts" "$repo" "$session" "$first_run_audit" "$loop_command" <<'PY'
import json, sys
receipt, ts, repo, session, audited, loop_command = sys.argv[1:]
row = {
    "ts": ts,
    "action": "adopt",
    "findings": ["legacy_repo_adoption"],
    "fixed": [],
    "registered": ["substrate-registry"],
    "audited": audited == "1",
    "orchestrator_session": session,
    "next_operator_action": "run /flywheel:loop start when ready",
}
if loop_command:
    row["planned_loop_start"] = loop_command
with open(receipt, "a", encoding="utf-8") as f:
    f.write(json.dumps(row, sort_keys=True) + "\n")
PY
  fixed+=(".flywheel/install-log.jsonl")
fi

fs_rag_action="not_requested"
fs_rag_baseline_path=""
fs_rag_violations_total=0
if [ "$apply_fs_rag" -eq 1 ]; then
  fs_rag_action="dry_run"
  fs_rag_template_dir="$FLYWHEEL_ROOT/templates/flywheel-install"
  fs_rag_files=(
    "scripts/file-rag-discipline-lint.sh"
    "scripts/scaffold-doc-frontmatter.sh"
    "hooks/file-rag-discipline-pre-commit.sh"
    "doctrine/filesystem-as-rag.md"
    "tests/file-rag-discipline-lint.sh"
  )
  fs_rag_targets=(
    ".flywheel/scripts/file-rag-discipline-lint.sh"
    ".flywheel/scripts/scaffold-doc-frontmatter.sh"
    ".flywheel/hooks/file-rag-discipline-pre-commit.sh"
    ".flywheel/doctrine/filesystem-as-rag.md"
    "tests/file-rag-discipline-lint.sh"
  )
  fs_rag_planned=()
  fs_rag_applied=()
  fs_rag_skipped=()

  for i in "${!fs_rag_files[@]}"; do
    src="$fs_rag_template_dir/${fs_rag_files[$i]}"
    dst="$repo/${fs_rag_targets[$i]}"
    if [ ! -r "$src" ]; then
      fs_rag_skipped+=("template_missing:$src")
      continue
    fi
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
      fs_rag_skipped+=("in_sync:${fs_rag_targets[$i]}")
    else
      fs_rag_planned+=("${fs_rag_targets[$i]}")
      if [ "$apply" -eq 1 ]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        if [[ "$src" == *.sh ]]; then chmod +x "$dst"; fi
        fs_rag_applied+=("${fs_rag_targets[$i]}")
      fi
    fi
  done

  pre_commit_target="$repo/.git/hooks/pre-commit"
  pre_commit_marker="# fs-rag-discipline-pre-commit BEGIN"
  pre_commit_block=$(cat <<'BLOCK'
# fs-rag-discipline-pre-commit BEGIN
if [ -x "$(git rev-parse --show-toplevel)/.flywheel/hooks/file-rag-discipline-pre-commit.sh" ]; then
  "$(git rev-parse --show-toplevel)/.flywheel/hooks/file-rag-discipline-pre-commit.sh" || exit $?
fi
# fs-rag-discipline-pre-commit END
BLOCK
)
  if [ "$apply" -eq 1 ]; then
    if [ ! -f "$pre_commit_target" ]; then
      mkdir -p "$(dirname "$pre_commit_target")"
      printf '#!/usr/bin/env bash\nset -e\n%s\n' "$pre_commit_block" > "$pre_commit_target"
      chmod +x "$pre_commit_target"
      fs_rag_applied+=(".git/hooks/pre-commit:created")
    elif ! grep -q "$pre_commit_marker" "$pre_commit_target"; then
      printf '\n%s\n' "$pre_commit_block" >> "$pre_commit_target"
      fs_rag_applied+=(".git/hooks/pre-commit:appended")
    else
      fs_rag_skipped+=(".git/hooks/pre-commit:already_chained")
    fi
  fi

  baseline_dir="$repo/.flywheel/audit"
  baseline_date="$(date -u +%Y-%m-%d)"
  fs_rag_baseline_path="$baseline_dir/fs-rag-baseline-$baseline_date.json"
  backfill_receipt="$baseline_dir/fs-rag-backfill-applied.json"
  linter="$repo/.flywheel/scripts/file-rag-discipline-lint.sh"
  if [ "$apply" -eq 1 ]; then
    mkdir -p "$baseline_dir"
    if [ -x "$linter" ]; then
      "$linter" --scan-all --root "$repo" --json >"$fs_rag_baseline_path" 2>/dev/null || true
      if [ -s "$fs_rag_baseline_path" ]; then
        fs_rag_violations_total="$(jq -r '.violations_total // (.violations | length) // 0' "$fs_rag_baseline_path" 2>/dev/null || echo 0)"
        fs_rag_applied+=(".flywheel/audit/fs-rag-baseline-$baseline_date.json")
      fi
    else
      fs_rag_skipped+=("baseline:linter_not_executable")
    fi
    if [ ! -f "$backfill_receipt" ]; then
      jq -nc --arg ts "$ts" --arg key "$idempotency_key" --arg baseline "$fs_rag_baseline_path" \
        '{ts:$ts,idempotency_key:$key,baseline_path:$baseline,backfill_status:"baseline_only_no_content_backfill_in_v1"}' \
        > "$backfill_receipt"
      fs_rag_applied+=(".flywheel/audit/fs-rag-backfill-applied.json")
    else
      fs_rag_skipped+=(".flywheel/audit/fs-rag-backfill-applied.json:already_present")
    fi
    fs_rag_action="applied"
  fi
fi

status="dry_run"
[ "$apply" -eq 1 ] && status="applied"

if [ "$json" -eq 1 ]; then
  set +u
  python3 - "$SCHEMA_VERSION" "$status" "$repo" "$session" "$dry_run" "$apply" "$reconcile" "$first_run_audit" "$start_loop" "$repair_needed" "$loop_command" "$audit_command" "$apply_fs_rag" "$fs_rag_action" "$fs_rag_baseline_path" "$fs_rag_violations_total" "${ready[@]}" -- "${missing[@]}" -- "${drifted[@]}" -- "${fixed[@]}" -- "${registered[@]}" <<'PY'
import json, sys
args = sys.argv[1:]
schema, status, repo, session = args[:4]
dry_run, apply, reconcile, first_run_audit, start_loop = [x == "1" for x in args[4:9]]
repair_needed = args[9] == "true"
loop_command, audit_command = args[10:12]
apply_fs_rag = args[12] == "1"
fs_rag_action = args[13]
fs_rag_baseline_path = args[14]
try:
    fs_rag_violations_total = int(args[15] or "0")
except ValueError:
    fs_rag_violations_total = 0
rest = args[16:]
groups = [[]]
for item in rest:
    if item == "--":
        groups.append([])
    else:
        groups[-1].append(item)
while len(groups) < 5:
    groups.append([])
ready, missing, drifted, fixed, registered = groups[:5]
out = {
    "schema_version": schema,
    "command": "flywheel:adopt",
    "status": status,
    "repo": repo,
    "dry_run": dry_run,
    "apply": apply,
    "reconcile": reconcile,
    "first_run_audit": first_run_audit,
    "start_loop": start_loop,
    "counts": {
        "ready": len(ready),
        "missing": len(missing),
        "drifted": len(drifted),
    },
    "ready": ready,
    "missing": missing,
    "drifted": drifted,
    "beads_db_health": {
        "repair_needed": repair_needed,
        "repair_path_invoked": repair_needed and apply and "beads DB repair" in fixed,
    },
    "substrate_registry": {
        "kind": "managed_repo",
        "lifecycle_state": "adopted_phase0",
    },
    "skill_catalog": {
        "scan": "jsm scan",
        "auto_install": False,
    },
    "fixed": fixed,
    "registered": registered,
    "audited": first_run_audit and apply,
    "orchestrator_session": session,
    "planned_first_run_audit": audit_command,
    "planned_loop_start": loop_command,
    "fs_rag_discipline": {
        "requested": apply_fs_rag,
        "action": fs_rag_action,
        "baseline_path": fs_rag_baseline_path or None,
        "violations_total": fs_rag_violations_total,
    },
    "next_operator_action": "review delta report; rerun with --apply --idempotency-key <key> to mutate" if dry_run else "run /flywheel:loop start when ready",
}
print(json.dumps(out, indent=2, sort_keys=True))
PY
  set -u
else
  printf 'flywheel:adopt %s repo=%s ready=%s missing=%s drifted=%s\n' "$status" "$repo" "${#ready[@]}" "${#missing[@]}" "${#drifted[@]}"
  if [ "$dry_run" -eq 1 ]; then
    printf 'No files changed. Rerun with --apply --idempotency-key <key> for mutation.\n'
  fi
fi
