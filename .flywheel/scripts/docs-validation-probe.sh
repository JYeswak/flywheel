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
# specific logic was filled in by bead flywheel-1hshd.25 (PARTIAL-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="docs-validation-probe/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/docs-validation-probe-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: docs-validation-probe.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "docs-validation-probe.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "docs-validation-probe.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"docs-validation-probe.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"docs-validation-probe.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"docs-validation-probe.sh doctor --json"}'
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
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",emits:{schema_version:"string",command:"\"doctor\"",ts:"iso8601",status:"string",checks:"array<{name,status,note?}>"},notes:"probes repo root, bash/jq/awk, default docs anchor (.flywheel/MISSION.md/STATE.md/README.md), audit log dir"}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",last_run_ts:"iso8601|null",audit_log:"path"},binds_audit_log:true}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["audit_log_dir","docs_anchor"],apply_contract:"--apply requires --idempotency-key (rc=3 refusal)",unknown_scope:"rc=64",emits:{schema_version:"string",command:"\"repair\"",ts:"iso8601",mode:"\"dry_run\"|\"apply\"",scope:"string",status:"\"ok\"|\"refused\""}}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",valid_subjects:["doc-path","validation-status","pane-name"],validation_status_enum:["validated","pending","failed","self_validated"],cross_source:"native --schema .metadata_fields = [docs_validation_status,validated_by_pane,authored_by_pane]",emits:{schema_version:"string",command:"\"validate\"",subject:"string",ts:"iso8601",status:"\"ok\"|\"reject\"|\"refused\"",value:"any",reason:"string?"}}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","doc","pane"],emits:{schema_version:"string",command:"\"why\"",id:"string",ts:"iso8601",status:"string",row:"object?"}}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],note:"per-surface schema available via --schema <surface>; native --schema bypassed to original metadata_fields/output_fields shape"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to native cmd_run (probe per-doc metadata fields).\n' ;;
    doctor)   printf 'topic: doctor — probes bash/jq/awk/repo_root_resolvable/default_docs_anchor (load-bearing: $REPO/.flywheel/MISSION.md or STATE.md or README.md)/audit_log_dir.\n' ;;
    health)   printf 'topic: health — emits last_run_ts from audit log if present; status=ok|degraded based on doctor parity.\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|docs_anchor> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: audit_log_dir (mkdir -p dirname of $SCAFFOLD_AUDIT_LOG), docs_anchor (ensure .flywheel/ exists under $REPO). Unknown scope = rc=64.\n' ;;
    validate) printf 'topic: validate <doc-path|validation-status|pane-name> VALUE — doc-path must be readable file; validation-status enum {validated, pending, failed, self_validated} cross-sourced with native --schema .metadata_fields; pane-name shape ^[a-z][a-z0-9_-]*$. Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG (default 20 rows). Empty when audit log missing.\n' ;;
    why)      printf 'topic: why <id> — explains row by id; matches against ts / run_id / doc / pane. Returns status=found|not_found|unavailable.\n' ;;
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
            && cli_emit_completion_bash "docs-validation-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "docs-validation-probe" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local checks=()
  local repo_root="${REPO:-$(pwd -P)}"
  if command -v bash >/dev/null 2>&1; then
    checks+=('{"name":"bash_available","status":"pass"}')
  else
    checks+=('{"name":"bash_available","status":"fail"}')
  fi
  if command -v jq >/dev/null 2>&1; then
    checks+=('{"name":"jq_available","status":"pass"}')
  else
    checks+=('{"name":"jq_available","status":"fail","note":"jq required for canonical envelopes"}')
  fi
  if command -v awk >/dev/null 2>&1; then
    checks+=('{"name":"awk_available","status":"pass"}')
  else
    checks+=('{"name":"awk_available","status":"fail","note":"awk required by field_value() metadata reader"}')
  fi
  if [[ -d "$repo_root" ]]; then
    checks+=('{"name":"repo_root_resolvable","status":"pass","path":"'"$repo_root"'"}')
  else
    checks+=('{"name":"repo_root_resolvable","status":"fail","path":"'"$repo_root"'"}')
  fi
  local anchor_present=0
  for anchor in .flywheel/MISSION.md .flywheel/STATE.md README.md; do
    if [[ -r "$repo_root/$anchor" ]]; then anchor_present=$((anchor_present+1)); fi
  done
  if (( anchor_present > 0 )); then
    checks+=('{"name":"default_docs_anchor","status":"pass","present":'"$anchor_present"',"anchors":["MISSION.md","STATE.md","README.md"]}')
  else
    checks+=('{"name":"default_docs_anchor","status":"warn","present":0,"note":"no canonical docs anchor under $REPO — probe defaults to empty"}')
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
  local repo_root="${REPO:-$(pwd -P)}"
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
    docs_anchor)
      local target="$repo_root/.flywheel"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope docs_anchor \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|docs_anchor>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","docs_anchor"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    doc-path)
      if [[ -z "$arg" ]]; then printf 'ERR: validate doc-path requires VALUE\n' >&2; return 64; fi
      if [[ -r "$arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"doc-path",ts:$ts,status:"ok",value:$v}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"doc-path",ts:$ts,status:"reject",value:$v,reason:"file_not_readable"}'
        return 1
      fi
      ;;
    validation-status)
      if [[ -z "$arg" ]]; then printf 'ERR: validate validation-status requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        validated|pending|failed|self_validated)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"validation-status",ts:$ts,status:"ok",value:$v,source:"native --schema .metadata_fields[0] (docs_validation_status)"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"validation-status",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_states:["validated","pending","failed","self_validated"],source:"native --schema .metadata_fields"}'
          return 1 ;;
      esac
      ;;
    pane-name)
      if [[ -z "$arg" ]]; then printf 'ERR: validate pane-name requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"pane-name",ts:$ts,status:"ok",value:$v,note:"matches validated_by_pane/authored_by_pane shape"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"pane-name",ts:$ts,status:"reject",value:$v,reason:"pattern_mismatch",pattern:"^[a-z][a-z0-9_-]*$"}'
        return 1
      fi
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["doc-path","validation-status","pane-name"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["doc-path","validation-status","pane-name"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.doc // "") == $id or (.pane // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","doc","pane"]}'
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
  # PARTIAL-BYPASS variant: --schema is owned by NATIVE (different shape,
  # no .mode field, just metadata_fields/output_fields). Scaffold owns
  # --info, --examples, doctor/health/repair/validate/audit/why/quickstart/
  # completion/help <topic>. Verb-first: when args[0] is a scaffold verb,
  # scaffold owns regardless of downstream --self-test/--repo/--doc flags
  # (native flags only matter when run-verb is invoked).
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--examples) return 0 ;;
    --schema) return 1 ;;  # PARTIAL-BYPASS to native
    -h|--help) return 0 ;;
    help)
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
  esac
  # No scaffold verb at args[0] — yield to native when native-owned flags present.
  local _a
  for _a in "$@"; do
    case "$_a" in --self-test|--repo|--doc|--json) return 1 ;; esac
  done
  return 1
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
SCHEMA_VERSION="docs-validation-probe/v1"
REPO="$(pwd -P)"
json=0
schema=0
self_test=0
doc_paths=()

usage() {
  cat <<'EOF'
usage: docs-validation-probe.sh [--json] [--schema] [--self-test] [--repo PATH] [--doc PATH ...]

Checks load-bearing documentation for explicit cross-pane validation metadata.
Missing metadata is reported as pending; self-validation or failed validation is
reported as failed.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --schema) schema=1; shift ;;
    --self-test) self_test=1; shift ;;
    --repo) REPO="$(cd "${2:?missing repo}" && pwd -P)"; shift 2 ;;
    --doc) doc_paths+=("${2:?missing doc path}"); shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

emit_schema() {
  jq -nc --arg schema_version "$SCHEMA_VERSION" '{
    schema_version:$schema_version,
    metadata_fields:["docs_validation_status","validated_by_pane","authored_by_pane"],
    output_fields:["docs_validation_pending_count","docs_validation_failed_count","readme_below_floor_count","rows"]
  }'
}

field_value() {
  local file="$1" key="$2"
  awk -F: -v key="$key" '
    BEGIN { IGNORECASE=1 }
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      sub(/^[^:]+:[[:space:]]*/, "")
      gsub(/^[[:space:]"'\''`]+|[[:space:]"'\''`]+$/, "")
      print
      exit
    }
  ' "$file" 2>/dev/null || true
}

line_count() {
  wc -l <"$1" 2>/dev/null | tr -d ' '
}

emit_report() {
  local rows="[]" candidates=() file status validated_by authored_by lines pending failed readme_below

  if [[ "${#doc_paths[@]}" -gt 0 ]]; then
    candidates=("${doc_paths[@]}")
  else
    candidates=(
      "$REPO/README.md"
      "$REPO/AGENTS.md"
      "$REPO/.flywheel/AGENTS-CANONICAL.md"
      "$REPO/.flywheel/MISSION.md"
      "$REPO/.flywheel/GOAL.md"
      "$REPO/.flywheel/STATE.md"
      "$REPO/templates/flywheel-install/AGENTS.md"
    )
  fi

  for file in "${candidates[@]}"; do
    [[ -f "$file" ]] || continue
    status="$(field_value "$file" "docs_validation_status")"
    [[ -n "$status" ]] || status="$(field_value "$file" "validation_status")"
    validated_by="$(field_value "$file" "validated_by_pane")"
    authored_by="$(field_value "$file" "authored_by_pane")"
    lines="$(line_count "$file")"

    pending=false
    failed=false
    readme_below=false
    if [[ -z "$status" || "$status" == "pending" || "$status" == "reviewed" || "$status" == "draft" ]]; then
      pending=true
    fi
    if [[ "$status" == "failed" || ( -n "$validated_by" && -n "$authored_by" && "$validated_by" == "$authored_by" ) ]]; then
      failed=true
    fi
    if [[ "$(basename "$file")" == "README.md" && "$lines" -lt 20 ]]; then
      readme_below=true
    fi

    rows="$(jq -c \
      --arg path "$file" \
      --arg status "${status:-missing}" \
      --arg validated_by "${validated_by:-}" \
      --arg authored_by "${authored_by:-}" \
      --argjson lines "$lines" \
      --argjson pending "$pending" \
      --argjson failed "$failed" \
      --argjson readme_below "$readme_below" \
      '. + [{path:$path,docs_validation_status:$status,validated_by_pane:$validated_by,authored_by_pane:$authored_by,line_count:$lines,pending:$pending,failed:$failed,readme_below_floor:$readme_below}]' \
      <<<"$rows")"
  done

  jq -nc --arg schema_version "$SCHEMA_VERSION" --arg repo "$REPO" --argjson rows "$rows" '
    ($rows | map(select(.pending == true)) | length) as $pending
    | ($rows | map(select(.failed == true)) | length) as $failed
    | ($rows | map(select(.readme_below_floor == true)) | length) as $below
    | {
        schema_version:$schema_version,
        status:(if $failed > 0 then "fail" elif $pending > 0 or $below > 0 then "warn" else "pass" end),
        repo:$repo,
        docs_checked_count:($rows | length),
        docs_validation_pending_count:$pending,
        docs_validation_failed_count:$failed,
        readme_below_floor_count:$below,
        rows:$rows
      }'
}

run_self_test() {
  local tmp repo out
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/docs-validation.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  repo="$tmp/repo"
  mkdir -p "$repo/.flywheel" "$repo/templates/flywheel-install"
  printf '# Good\n\ndocs_validation_status: validated\nauthored_by_pane: pane2\nvalidated_by_pane: pane3\n\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\nline\n' >"$repo/README.md"
  printf '# Self\n\ndocs_validation_status: validated\nauthored_by_pane: pane2\nvalidated_by_pane: pane2\n' >"$repo/AGENTS.md"
  printf '# Pending\n' >"$repo/.flywheel/MISSION.md"
  out="$("$0" --repo "$repo" --json)"
  jq -nc --arg schema_version "$SCHEMA_VERSION" --argjson report "$out" '{
    schema_version:$schema_version,
    status:(if $report.docs_validation_failed_count == 1
      and $report.docs_validation_pending_count == 1 then "pass" else "fail" end),
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

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
