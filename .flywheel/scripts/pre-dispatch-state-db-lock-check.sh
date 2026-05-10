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
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="pre-dispatch-state-db-lock-check/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/pre-dispatch-state-db-lock-check-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: pre-dispatch-state-db-lock-check.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "pre-dispatch-state-db-lock-check.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "pre-dispatch-state-db-lock-check.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"pre-dispatch-state-db-lock-check.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"pre-dispatch-state-db-lock-check.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"pre-dispatch-state-db-lock-check.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
    '{schema_version:$sv,command:"schema",surface:$surface,note:"TODO(canonical-cli-scaffold): per-surface schema fill-in"}'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\n' ;;
    doctor)   printf 'topic: doctor — TODO(canonical-cli-scaffold): document doctor checks specific to this surface.\n' ;;
    health)   printf 'topic: health — TODO(canonical-cli-scaffold): document health probes specific to this surface.\n' ;;
    repair)   printf 'topic: repair — TODO(canonical-cli-scaffold): document repair scopes + idempotency contract.\n' ;;
    validate) printf 'topic: validate — TODO(canonical-cli-scaffold): document validation subjects + contracts.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "pre-dispatch-state-db-lock-check" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "pre-dispatch-state-db-lock-check" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:"todo",checks:[],note:"TODO(canonical-cli-scaffold): fill in doctor checks"}'
}

scaffold_cmd_health() {
  # TODO(canonical-cli-scaffold): summarize last-run state from audit log.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"todo",note:"TODO(canonical-cli-scaffold): fill in health probe from audit log"}'
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
  # TODO(canonical-cli-scaffold): per-scope repair actions go here.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
    '{schema_version:$sv,command:"repair",status:"todo",mode:$mode,scope:$scope,idempotency_key:$idem,note:"TODO(canonical-cli-scaffold): fill in repair scope actions"}'
}

scaffold_cmd_validate() {
  # TODO(canonical-cli-scaffold): document validation subjects + contracts.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{schema_version:$sv,command:"validate",status:"todo",note:"TODO(canonical-cli-scaffold): fill in per-subject validation"}'
}

scaffold_cmd_audit() {
  # TODO(canonical-cli-scaffold): tail audit log; emit recent rows.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    '{schema_version:$sv,command:"audit",audit_log:$log,status:"todo",note:"TODO(canonical-cli-scaffold): fill in audit tail"}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # TODO(canonical-cli-scaffold): explain why <id> is/isn't in scope.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
    '{schema_version:$sv,command:"why",id:$id,status:"todo",note:"TODO(canonical-cli-scaffold): fill in why-id semantics"}'
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
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      # Intercept `help <topic>` and `help --help`; bare `help` could be
      # a legacy subcommand of the target so it falls through.
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
usage() {
  cat <<'EOF'
usage: pre-dispatch-state-db-lock-check.sh --db PATH --operation CLASS [--owner NAME] [--timeout SECONDS] [--keep-lock] [--json]
       pre-dispatch-state-db-lock-check.sh --schema

Acquires an atomic repo/fleet SQLite writer lock long enough to prove that a
mutating dispatch can own the single-writer lane. Without --keep-lock, the lock
is released before exit and this is a preflight receipt, not a write wrapper.
EOF
}

json=0
schema=0
keep_lock=0
db_path=""
operation_class="unspecified"
owner="${USER:-unknown}:$PPID"
timeout_seconds=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --db) db_path="${2:-}"; shift 2 ;;
    --operation) operation_class="${2:-}"; shift 2 ;;
    --owner) owner="${2:-}"; shift 2 ;;
    --timeout) timeout_seconds="${2:-0}"; shift 2 ;;
    --keep-lock) keep_lock=1; shift ;;
    --json) json=1; shift ;;
    --schema) schema=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ "$schema" -eq 1 ]]; then
  jq -n '{
    schema_version:"sqlite-write-lock-check/v1",
    required_fields:["db_path","db_fingerprint","operation_class","writer_owner","lock_path","lock_acquired_at","lock_timeout_seconds","competing_writer_count","pre_integrity_state","post_integrity_state","release_status"],
    doctor_fields:["sqlite_concurrent_writer_risk_count","sqlite_write_lock_conflict_count","sqlite_write_locks.top_conflicts"]
  }'
  exit 0
fi

if [[ -z "$db_path" ]]; then
  printf 'missing required --db PATH\n' >&2
  exit 64
fi

canonical_db() {
  local path="$1" dir base
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  if [[ -d "$dir" ]]; then
    (cd "$dir" && printf '%s/%s\n' "$(pwd -P)" "$base")
  else
    printf '%s\n' "$path"
  fi
}

integrity_state() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    printf 'missing'
    return
  fi
  if ! command -v sqlite3 >/dev/null 2>&1; then
    printf 'sqlite3_unavailable'
    return
  fi
  local out
  out="$(sqlite3 "$path" 'PRAGMA quick_check;' 2>&1 || true)"
  if [[ "$out" == "ok" ]]; then
    printf 'ok'
  else
    printf '%s' "$out" | tr '\n' ' ' | cut -c 1-240
  fi
}

competing_writers() {
  local path="$1"
  if [[ ! -f "$path" ]] || ! command -v lsof >/dev/null 2>&1; then
    printf '0'
    return
  fi
  { lsof -t -- "$path" 2>/dev/null || true; } | sort -u | wc -l | tr -d ' '
}

db_path="$(canonical_db "$db_path")"
db_fingerprint="$(printf '%s' "$db_path" | shasum -a 256 | awk '{print $1}')"
lock_root="${FLYWHEEL_SQLITE_LOCK_DIR:-$HOME/.local/state/flywheel/sqlite-locks}"
lock_path="$lock_root/$db_fingerprint.lock"
mkdir -p "$lock_root"

pre_integrity_state="$(integrity_state "$db_path")"
competing_writer_count="$(competing_writers "$db_path")"
lock_acquired=false
lock_acquired_at=null
release_status="not_acquired"
conflict_owner=""
conflict_age_seconds=null
start_epoch="$(date +%s)"

while true; do
  if mkdir "$lock_path" 2>/dev/null; then
    lock_acquired=true
    lock_acquired_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    jq -n \
      --arg owner "$owner" \
      --arg db_path "$db_path" \
      --arg operation_class "$operation_class" \
      --arg acquired_at "$lock_acquired_at" \
      '{owner:$owner, db_path:$db_path, operation_class:$operation_class, acquired_at:$acquired_at, pid:env.PPID}' \
      >"$lock_path/owner.json"
    break
  fi

  if [[ "$timeout_seconds" -le 0 || $(( $(date +%s) - start_epoch )) -ge "$timeout_seconds" ]]; then
    if [[ -f "$lock_path/owner.json" ]]; then
      conflict_owner="$(jq -r '.owner // empty' "$lock_path/owner.json" 2>/dev/null || true)"
      local_acquired="$(jq -r '.acquired_at // empty' "$lock_path/owner.json" 2>/dev/null || true)"
      if [[ -n "$local_acquired" ]]; then
        conflict_epoch="$(date -j -f '%Y-%m-%dT%H:%M:%SZ' "$local_acquired" +%s 2>/dev/null || echo '')"
        if [[ -n "$conflict_epoch" ]]; then
          conflict_age_seconds=$(( $(date +%s) - conflict_epoch ))
        fi
      fi
    fi
    break
  fi
  sleep 1
done

post_integrity_state="$pre_integrity_state"
if [[ "$lock_acquired" == true ]]; then
  post_integrity_state="$(integrity_state "$db_path")"
  if [[ "$keep_lock" -eq 1 ]]; then
    release_status="kept"
  else
    rm -rf "$lock_path"
    release_status="released"
  fi
fi

sqlite_concurrent_writer_risk_count=0
sqlite_write_lock_conflict_count=0
if [[ "$competing_writer_count" -gt 0 ]]; then
  sqlite_concurrent_writer_risk_count=1
fi
if [[ "$lock_acquired" != true ]]; then
  sqlite_write_lock_conflict_count=1
fi

jq -n \
  --arg db_path "$db_path" \
  --arg db_fingerprint "$db_fingerprint" \
  --arg operation_class "$operation_class" \
  --arg writer_owner "$owner" \
  --arg lock_path "$lock_path" \
  --arg lock_acquired_at "$lock_acquired_at" \
  --arg pre_integrity_state "$pre_integrity_state" \
  --arg post_integrity_state "$post_integrity_state" \
  --arg release_status "$release_status" \
  --arg conflict_owner "$conflict_owner" \
  --argjson lock_acquired "$lock_acquired" \
  --argjson lock_timeout_seconds "$timeout_seconds" \
  --argjson competing_writer_count "$competing_writer_count" \
  --argjson sqlite_concurrent_writer_risk_count "$sqlite_concurrent_writer_risk_count" \
  --argjson sqlite_write_lock_conflict_count "$sqlite_write_lock_conflict_count" \
  --argjson conflict_age_seconds "$conflict_age_seconds" \
  '{
    schema_version:"sqlite-write-lock-check/v1",
    status:(if $lock_acquired then "ok" else "conflict" end),
    db_path:$db_path,
    db_fingerprint:$db_fingerprint,
    operation_class:$operation_class,
    writer_owner:$writer_owner,
    lock_path:$lock_path,
    lock_acquired:$lock_acquired,
    lock_acquired_at:(if $lock_acquired_at == "null" then null else $lock_acquired_at end),
    lock_timeout_seconds:$lock_timeout_seconds,
    competing_writer_count:$competing_writer_count,
    pre_integrity_state:$pre_integrity_state,
    post_integrity_state:$post_integrity_state,
    release_status:$release_status,
    sqlite_concurrent_writer_risk_count:$sqlite_concurrent_writer_risk_count,
    sqlite_write_lock_conflict_count:$sqlite_write_lock_conflict_count,
    sqlite_write_locks:{
      top_conflicts:(
        if $lock_acquired then []
        else [{lock_path:$lock_path, owner:($conflict_owner // ""), age_seconds:$conflict_age_seconds}]
        end
      )
    }
  }'

if [[ "$lock_acquired" != true ]]; then
  exit 2
fi
