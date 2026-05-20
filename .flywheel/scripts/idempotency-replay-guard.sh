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
# specific logic was filled in by bead flywheel-1hshd.37 (PARTIAL-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="idempotency-replay-guard/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/idempotency-replay-guard-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: idempotency-replay-guard.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "idempotency-replay-guard.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "idempotency-replay-guard.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"idempotency-replay-guard.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"idempotency-replay-guard.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"idempotency-replay-guard.sh doctor --json"}'
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
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",emits:{schema_version:"string",command:"\"doctor\"",ts:"iso8601",status:"string",checks:"array<{name,status,note?}>"},notes:"probes bash/jq/sha256sum/flock, ledger (~/.local/state/flywheel/dispatch-receipts.jsonl), lock_dir (~/.local/state/flywheel/idempotency-replay-locks), audit_log_dir"}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",last_run_ts:"iso8601|null",audit_log:"path"},binds_audit_log:true}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["audit_log_dir","ledger_dir","lock_dir"],apply_contract:"--apply requires --idempotency-key (rc=3 refusal)",unknown_scope:"rc=64",emits:{schema_version:"string",command:"\"repair\"",ts:"iso8601",mode:"\"dry_run\"|\"apply\"",scope:"string",status:"\"ok\"|\"refused\""}}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",valid_subjects:["status","receipt-ref","input-mode"],status_enum:["already_completed","in_flight","not_seen","completed"],input_mode_enum:["text","file","stdin"],cross_source:"native --info .statuses[] (4 states) + --input/--input-file flags",emits:{schema_version:"string",command:"\"validate\"",subject:"string",ts:"iso8601",status:"\"ok\"|\"reject\"|\"refused\"",value:"any",reason:"string?"}}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","input_hash","receipt_ref"],emits:{schema_version:"string",command:"\"why\"",id:"string",ts:"iso8601",status:"string",row:"object?"}}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],variant:"PARTIAL-BYPASS",bypassed_natively:["--info","--examples"],note:"native owns rich --info envelope (info/v1 with statuses array) + --examples envelope (examples/v1); scaffold owns --schema (native lacked) + all verbs"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — native owns; routes through cmd_run (check idempotency lock). Flags: --input TEXT, --input-file PATH, --ledger PATH, --lock-dir PATH, --json, --quiet, --mark-completed --receipt-ref REF, --release-lock.\n' ;;
    doctor)   printf 'topic: doctor — probes bash/jq/sha256sum/flock + ledger + lock_dir + audit_log_dir.\n' ;;
    health)   printf 'topic: health — emits last_run_ts from $SCAFFOLD_AUDIT_LOG.\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|ledger_dir|lock_dir> [--dry-run|--apply --idempotency-key KEY] — apply needs key (rc=3). Unknown = rc=64.\n' ;;
    validate) printf 'topic: validate <status|receipt-ref|input-mode> VALUE — status enum {already_completed, in_flight, not_seen, completed} cross-sourced with native --info .statuses[]; receipt-ref non-empty string; input-mode enum {text, file, stdin} cross-sourced with native --input/--input-file flags. Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG (default 20 rows).\n' ;;
    why)      printf 'topic: why <id> — explains row by id; matches against ts / run_id / input_hash / receipt_ref.\n' ;;
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
            && cli_emit_completion_bash "idempotency-replay-guard" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "idempotency-replay-guard" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local checks=()
  local ledger="${LEDGER:-$HOME/.local/state/flywheel/dispatch-receipts.jsonl}"
  local lock_dir="${LOCK_DIR:-$HOME/.local/state/flywheel/idempotency-replay-locks}"
  if command -v bash >/dev/null 2>&1; then checks+=('{"name":"bash_available","status":"pass"}')
  else checks+=('{"name":"bash_available","status":"fail"}'); fi
  if command -v jq >/dev/null 2>&1; then checks+=('{"name":"jq_available","status":"pass"}')
  else checks+=('{"name":"jq_available","status":"fail"}'); fi
  if command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1; then
    checks+=('{"name":"sha256_hasher_available","status":"pass","note":"load-bearing — input hashing for replay-key derivation"}')
  else
    checks+=('{"name":"sha256_hasher_available","status":"fail","note":"need sha256sum or shasum -a 256"}')
  fi
  if command -v flock >/dev/null 2>&1; then
    checks+=('{"name":"flock_available","status":"pass"}')
  else
    checks+=('{"name":"flock_available","status":"warn","note":"flock not present (macOS); script may fall back to mkdir-based locking"}')
  fi
  local ledger_dir; ledger_dir="$(dirname "$ledger")"
  if [[ -w "$ledger_dir" || ( ! -e "$ledger_dir" && -w "$(dirname "$ledger_dir")" ) ]]; then
    checks+=('{"name":"ledger_dir_writable","status":"pass","path":"'"$ledger_dir"'"}')
  else
    checks+=('{"name":"ledger_dir_writable","status":"fail","path":"'"$ledger_dir"'","note":"load-bearing — dispatch-receipts ledger writes here"}')
  fi
  if [[ -w "$lock_dir" || ( ! -e "$lock_dir" && -w "$(dirname "$lock_dir")" ) ]]; then
    checks+=('{"name":"lock_dir_writable","status":"pass","path":"'"$lock_dir"'"}')
  else
    checks+=('{"name":"lock_dir_writable","status":"fail","path":"'"$lock_dir"'","note":"load-bearing — replay locks live here"}')
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
    ledger_dir)
      local target; target="$(dirname "${LEDGER:-$HOME/.local/state/flywheel/dispatch-receipts.jsonl}")"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope ledger_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    lock_dir)
      local target="${LOCK_DIR:-$HOME/.local/state/flywheel/idempotency-replay-locks}"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope lock_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|ledger_dir|lock_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","ledger_dir","lock_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    status)
      if [[ -z "$arg" ]]; then printf 'ERR: validate status requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        already_completed|in_flight|not_seen|completed)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"status",ts:$ts,status:"ok",value:$v,source:"native --info .statuses[] (4 states)"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"status",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_states:["already_completed","in_flight","not_seen","completed"],source:"native --info .statuses[]"}'
          return 1 ;;
      esac
      ;;
    receipt-ref)
      if [[ -z "$arg" ]]; then printf 'ERR: validate receipt-ref requires VALUE\n' >&2; return 64; fi
      local len="${#arg}"
      if (( len >= 4 && len <= 256 )) && [[ "$arg" =~ ^[A-Za-z0-9._/#:-]+$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"receipt-ref",ts:$ts,status:"ok",value:$v,note:"matches --receipt-ref shape (file#L lines, URIs, etc)"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" --argjson len "$len" \
          '{schema_version:$sv,command:"validate",subject:"receipt-ref",ts:$ts,status:"reject",value:$v,reason:"pattern_or_length_mismatch",pattern:"^[A-Za-z0-9._/#:-]+$",length_range:"[4, 256]",observed_length:$len}'
        return 1
      fi
      ;;
    input-mode)
      if [[ -z "$arg" ]]; then printf 'ERR: validate input-mode requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        text|file|stdin)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"input-mode",ts:$ts,status:"ok",value:$v,source:"native --input/--input-file flag contract"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"input-mode",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_modes:["text","file","stdin"]}'
          return 1 ;;
      esac
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["status","receipt-ref","input-mode"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["status","receipt-ref","input-mode"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.input_hash // "") == $id or (.receipt_ref // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","input_hash","receipt_ref"]}'
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
  # PARTIAL-BYPASS variant: native owns rich --info envelope (info/v1 with
  # statuses array + output_schema) + rich --examples envelope (examples/v1).
  # Scaffold owns --schema (native lacked) + all verbs.
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --schema) return 0 ;;  # scaffold owns; native lacked
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
VERSION="idempotency-replay-guard/v1"
LEDGER="${IDEMPOTENCY_REPLAY_LEDGER:-$HOME/.local/state/flywheel/dispatch-receipts.jsonl}"
LOCK_DIR="${IDEMPOTENCY_REPLAY_LOCK_DIR:-$HOME/.local/state/flywheel/idempotency-replay-locks}"
INPUT_TEXT=""
INPUT_FILE=""
KEY=""
RECEIPT_REF=""
JSON_OUT=0
QUIET=0
NO_LOCK=0
MARK_COMPLETED=0
RELEASE_LOCK=0
usage() {
  cat <<'USAGE'
usage: idempotency-replay-guard.sh [--input TEXT|--input-file PATH] [--ledger PATH] [--lock-dir PATH] [--json] [--quiet]
       idempotency-replay-guard.sh --mark-completed --receipt-ref REF [--input TEXT|--input-file PATH] [--json]
       idempotency-replay-guard.sh --release-lock [--input TEXT|--input-file PATH] [--json]
       idempotency-replay-guard.sh --info|--examples|--help
USAGE
}
info() {
  jq -nc --arg version "$VERSION" --arg ledger "$LEDGER" --arg lock_dir "$LOCK_DIR" '{
    schema_version:"idempotency-replay-guard.info/v1",
    name:"idempotency-replay-guard",
    version:$version,
    ledger:$ledger,
    lock_dir:$lock_dir,
    canonical_cli_flags:["--help","--info","--examples","--json","--quiet"],
    statuses:["already_completed","in_flight","not_seen","completed"],
    output_schema:".flywheel/validation-schema/v1/dispatch-receipt.schema.json"
  }'
}
examples() {
  jq -nc '{schema_version:"idempotency-replay-guard.examples/v1",examples:[
    "idempotency-replay-guard.sh --input-file /tmp/dispatch.md --json",
    "printf %s payload | idempotency-replay-guard.sh --json",
    "idempotency-replay-guard.sh --mark-completed --receipt-ref .beads/issues.jsonl#L1 --input payload --json",
    "idempotency-replay-guard.sh --release-lock --input payload --json"
  ]}'
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --no-lock) NO_LOCK=1; shift ;;
    --mark-completed) MARK_COMPLETED=1; shift ;;
    --release-lock) RELEASE_LOCK=1; shift ;;
    --receipt-ref) RECEIPT_REF="${2:?--receipt-ref requires REF}"; shift 2 ;;
    --receipt-ref=*) RECEIPT_REF="${1#*=}"; shift ;;
    --ledger) LEDGER="${2:?--ledger requires PATH}"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --lock-dir) LOCK_DIR="${2:?--lock-dir requires PATH}"; shift 2 ;;
    --lock-dir=*) LOCK_DIR="${1#*=}"; shift ;;
    --input) INPUT_TEXT="${2:?--input requires TEXT}"; shift 2 ;;
    --input=*) INPUT_TEXT="${1#*=}"; shift ;;
    --input-file) INPUT_FILE="${2:?--input-file requires PATH}"; shift 2 ;;
    --input-file=*) INPUT_FILE="${1#*=}"; shift ;;
    --idempotency-key) KEY="${2:?--idempotency-key requires KEY}"; shift 2 ;;
    --idempotency-key=*) KEY="${1#*=}"; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done
if [[ -n "$INPUT_FILE" ]]; then
  INPUT_TEXT="$(cat "$INPUT_FILE")"
elif [[ -z "$INPUT_TEXT" && ! -t 0 ]]; then
  INPUT_TEXT="$(cat)"
fi
key_json="$(python3 - "$KEY" "$INPUT_TEXT" <<'PY'
import hashlib, json, sys
supplied, raw = sys.argv[1], sys.argv[2]
if supplied:
    key = supplied if supplied.startswith("sha256:") else "sha256:" + supplied
    canonical = raw
else:
    try:
        canonical = json.dumps(json.loads(raw), sort_keys=True, separators=(",", ":"))
    except Exception:
        canonical = raw
    key = "sha256:" + hashlib.sha256(canonical.encode("utf-8")).hexdigest()
print(json.dumps({"key": key, "hash": key, "canonical": canonical}, separators=(",", ":")))
PY
)"
KEY="$(jq -r '.key' <<<"$key_json")"
REPLAY_HASH="$(jq -r '.hash' <<<"$key_json")"
KEY_SAFE="${KEY#sha256:}"
LOCK_PATH="$LOCK_DIR/$KEY_SAFE.lock"
completeness='{"IDEM-001":true,"IDEM-002":true,"IDEM-003":true,"IDEM-004":true,"IDEM-005":true,"IDEM-006":true}'
emit() {
  local status="$1" lock_acquired="$2" receipt_ref="${3:-null}" line="${4:-null}" begin="$5" commit="$6" abort="$7"
  local row
  row="$(jq -nc \
    --arg schema_version "dispatch-receipt/v1" \
    --arg guard_version "$VERSION" \
    --arg status "$status" \
    --arg idempotency_key "$KEY" \
    --arg replay_detection_hash "$REPLAY_HASH" \
    --arg lock_path "$LOCK_PATH" \
    --argjson receipt_ref "$receipt_ref" \
    --argjson previous_close_row "$line" \
    --argjson lock_acquired "$lock_acquired" \
    --argjson completeness "$completeness" \
    --argjson begin "$begin" \
    --argjson commit "$commit" \
    --argjson abort "$abort" \
    '{
      schema_version:$schema_version,
      receipt_type:"replay_guard",
      guard_version:$guard_version,
      status:$status,
      idempotency_key:$idempotency_key,
      replay_detection_hash:$replay_detection_hash,
      dispatch_identity_key:$idempotency_key,
      packet_hash:$replay_detection_hash,
      close_identity_key:$idempotency_key,
      dedupe_policy:"latest-row-by-ref_id-event",
      previous_close_row:$previous_close_row,
      prior_receipt_ref:$receipt_ref,
      lock_path:$lock_path,
      lock_acquired:$lock_acquired,
      transaction_boundary:{begin:$begin,commit:$commit,abort:$abort},
      receipt_completeness:$completeness
    }')"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$row"
  elif [[ "$QUIET" -eq 0 ]]; then
    printf '%s idempotency_key=%s\n' "$status" "$KEY"
  fi
}
lookup_completed() {
  python3 - "$LEDGER" "$KEY" "$REPLAY_HASH" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1]).expanduser()
key, replay = sys.argv[2], sys.argv[3]
if not path.exists():
    print(json.dumps({"found": False, "line": None, "receipt_ref": None}))
    raise SystemExit
found = None
with path.open(encoding="utf-8", errors="replace") as handle:
    for line_no, line in enumerate(handle, start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if row.get("idempotency_key") == key or row.get("replay_detection_hash") == replay:
            status = str(row.get("status") or row.get("event") or "")
            if status in {"completed", "closed", "close"} or row.get("completed") is True:
                found = {"found": True, "line": line_no, "receipt_ref": row.get("receipt_ref") or row.get("prior_receipt_ref") or f"{path}#L{line_no}"}
if found is None:
    found = {"found": False, "line": None, "receipt_ref": None}
print(json.dumps(found, separators=(",", ":")))
PY
}
append_completed() {
  mkdir -p "$(dirname "$LEDGER")"
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg key "$KEY" --arg hash "$REPLAY_HASH" --arg ref "$RECEIPT_REF" --argjson completeness "$completeness" '{
    schema_version:"dispatch-receipt/v1",receipt_type:"replay_guard",status:"completed",ts:$ts,
    idempotency_key:$key,replay_detection_hash:$hash,dispatch_identity_key:$key,packet_hash:$hash,
    close_identity_key:$key,receipt_ref:$ref,dedupe_policy:"latest-row-by-ref_id-event",
    transaction_boundary:{begin:true,commit:true,abort:false},receipt_completeness:$completeness
  }' >>"$LEDGER"
}
completed="$(lookup_completed)"
if jq -e '.found == true' >/dev/null <<<"$completed"; then
  emit "already_completed" false "$(jq -c '.receipt_ref' <<<"$completed")" "$(jq -c '.line' <<<"$completed")" false true false
  exit 0
fi
if [[ "$RELEASE_LOCK" -eq 1 ]]; then
  rm -rf "$LOCK_PATH"
  emit "not_seen" false null null false false true
  exit 0
fi
if [[ "$MARK_COMPLETED" -eq 1 ]]; then
  append_completed
  rm -rf "$LOCK_PATH"
  emit "completed" false "$(jq -nc --arg ref "$RECEIPT_REF" '$ref')" null true true false
  exit 0
fi
if [[ -d "$LOCK_PATH" ]]; then
  emit "in_flight" false null null false false false
  exit 0
fi
if [[ "$NO_LOCK" -eq 1 ]]; then
  emit "not_seen" false null null true false false
  exit 0
fi
mkdir -p "$LOCK_DIR"
if mkdir "$LOCK_PATH" 2>/dev/null; then
  printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$LOCK_PATH/created_at"
  emit "not_seen" true null null true false false
else
  emit "in_flight" false null null false false false
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
