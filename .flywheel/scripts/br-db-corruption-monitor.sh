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

SCAFFOLD_SCHEMA_VERSION="br-db-corruption-monitor/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/br-db-corruption-monitor-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: br-db-corruption-monitor.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "br-db-corruption-monitor.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "br-db-corruption-monitor.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"br-db-corruption-monitor.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"br-db-corruption-monitor.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"br-db-corruption-monitor.sh doctor --json"}'
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
            && cli_emit_completion_bash "br-db-corruption-monitor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "br-db-corruption-monitor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  # Canonical pattern (per L4 lint rule — NEVER use `[[ ]] && X || Y`
  # as the last expression of a helper; use if/then/else/fi):
  #   if [[ -d "$ROOT/.flywheel" ]]; then
  #     printf '{"check":"flywheel-dir","status":"pass"}\n'
  #   else
  #     printf '{"check":"flywheel-dir","status":"fail"}\n'
  #   fi
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
VERSION="br-db-corruption-monitor.v1.0.0"
SCHEMA_VERSION="br-db-corruption-monitor/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
LEDGER="${BR_DB_CORRUPTION_MONITOR_LEDGER:-$HOME/.local/state/flywheel/br-db-corruption-monitor-ledger.jsonl}"

COMMAND="check"
REPO="$REPO_DEFAULT"
AUTO_REBUILD=0
JSON_OUT=0

usage() {
  cat <<'EOF'
usage:
  br-db-corruption-monitor.sh check [--repo PATH] [--auto-rebuild] [--json]
  br-db-corruption-monitor.sh --info|--help|--examples

Checks .beads/beads.db with SQLite PRAGMA integrity_check. Without
--auto-rebuild, corruption exits 1 and records the finding. With --auto-rebuild,
the script invokes .flywheel/scripts/beads-db-recover.sh on the selected repo.
EOF
}

examples() {
  cat <<'EOF'
examples:
  .flywheel/scripts/br-db-corruption-monitor.sh check --repo /Users/josh/Developer/flywheel --json
  .flywheel/scripts/br-db-corruption-monitor.sh check --repo /tmp/disposable --auto-rebuild --json
  BR_DB_CORRUPTION_MONITOR_LEDGER=/tmp/monitor.jsonl .flywheel/scripts/br-db-corruption-monitor.sh check --json
EOF
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

repo_abs() {
  local repo="$1"
  if [[ -d "$repo" ]]; then
    (cd "$repo" && pwd -P)
  else
    python3 - "$repo" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).expanduser())
PY
  fi
}

json_string() {
  jq -Rs . <<<"${1:-}"
}

emit_payload() {
  local payload="$1" text="$2" rc="$3"
  mkdir -p "$(dirname "$LEDGER")"
  printf '%s\n' "$payload" >>"$LEDGER"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$text"
  fi
  return "$rc"
}

integrity_output() {
  local db="$1"
  sqlite3 "$db" 'PRAGMA integrity_check;' 2>&1 || true
}

recover_script_for_repo() {
  local repo="$1"
  if [[ -x "$repo/.flywheel/scripts/beads-db-recover.sh" ]]; then
    printf '%s\n' "$repo/.flywheel/scripts/beads-db-recover.sh"
  elif [[ -x "$REPO_DEFAULT/.flywheel/scripts/beads-db-recover.sh" ]]; then
    printf '%s\n' "$REPO_DEFAULT/.flywheel/scripts/beads-db-recover.sh"
  else
    printf '%s\n' "$repo/.flywheel/scripts/beads-db-recover.sh"
  fi
}

info_json() {
  jq -nc \
    --arg version "$VERSION" \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ledger "$LEDGER" \
    '{name:"br-db-corruption-monitor.sh",version:$version,schema_version:$schema_version,
      canonical_cli:["check","--repo","--auto-rebuild","--json","--info","--examples","--help"],
      ledger_path:$ledger,
      mutation_requires:"--auto-rebuild",
      exits:{"0":"integrity ok or rebuild succeeded","1":"corruption or rebuild failure","2":"usage error"}}'
}

run_check() {
  local repo_abs_path db checked_at out status corrupted rebuild_script rebuild_out rebuild_rc post_out
  repo_abs_path="$(repo_abs "$REPO")"
  db="$repo_abs_path/.beads/beads.db"
  checked_at="$(now_iso)"
  status="pass"
  corrupted=false
  rebuild_script="$(recover_script_for_repo "$repo_abs_path")"
  rebuild_out=""
  rebuild_rc=0
  post_out=""

  if [[ ! -d "$repo_abs_path" ]]; then
    local payload
    payload="$(jq -nc --arg schema "$SCHEMA_VERSION" --arg version "$VERSION" --arg repo "$repo_abs_path" --arg ts "$checked_at" --arg ledger "$LEDGER" \
      '{schema_version:$schema,version:$version,command:"check",repo:$repo,checked_at:$ts,ledger_path:$ledger,status:"fail",corrupted:null,reason:"repo_missing",exit_code:1}')"
    emit_payload "$payload" "FAIL reason=repo_missing repo=$repo_abs_path" 1
    return $?
  fi

  if [[ ! -f "$db" ]]; then
    local payload
    payload="$(jq -nc --arg schema "$SCHEMA_VERSION" --arg version "$VERSION" --arg repo "$repo_abs_path" --arg db "$db" --arg ts "$checked_at" --arg ledger "$LEDGER" \
      '{schema_version:$schema,version:$version,command:"check",repo:$repo,db_path:$db,checked_at:$ts,ledger_path:$ledger,status:"pass",corrupted:false,integrity_output:"missing_db",exit_code:0}')"
    emit_payload "$payload" "PASS missing_db repo=$repo_abs_path" 0
    return $?
  fi

  if ! command -v sqlite3 >/dev/null 2>&1; then
    local payload
    payload="$(jq -nc --arg schema "$SCHEMA_VERSION" --arg version "$VERSION" --arg repo "$repo_abs_path" --arg db "$db" --arg ts "$checked_at" --arg ledger "$LEDGER" \
      '{schema_version:$schema,version:$version,command:"check",repo:$repo,db_path:$db,checked_at:$ts,ledger_path:$ledger,status:"fail",corrupted:null,reason:"sqlite3_missing",exit_code:1}')"
    emit_payload "$payload" "FAIL reason=sqlite3_missing repo=$repo_abs_path" 1
    return $?
  fi

  out="$(integrity_output "$db")"
  if [[ "$out" != "ok" ]]; then
    status="fail"
    corrupted=true
  fi

  if [[ "$corrupted" == true && "$AUTO_REBUILD" -eq 1 ]]; then
    if [[ -x "$rebuild_script" ]]; then
      set +e
      rebuild_out="$("$rebuild_script" --repo "$repo_abs_path" --apply --force --json 2>&1)"
      rebuild_rc=$?
      set -e
      post_out="$(integrity_output "$db")"
      if [[ "$rebuild_rc" -eq 0 && "$post_out" == "ok" ]]; then
        status="rebuilt"
        corrupted=false
      else
        status="fail"
        corrupted=true
      fi
    else
      rebuild_rc=127
      rebuild_out="recovery_script_missing_or_not_executable:$rebuild_script"
    fi
  fi

  local rc payload
  if [[ "$status" == "pass" || "$status" == "rebuilt" ]]; then rc=0; else rc=1; fi
  payload="$(jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg repo "$repo_abs_path" \
    --arg db "$db" \
    --arg ts "$checked_at" \
    --arg ledger "$LEDGER" \
    --arg status "$status" \
    --arg integrity "$out" \
    --arg rebuild_script "$rebuild_script" \
    --arg rebuild_out "$rebuild_out" \
    --arg post_integrity "$post_out" \
    --argjson auto_rebuild "$([[ "$AUTO_REBUILD" -eq 1 ]] && printf true || printf false)" \
    --argjson corrupted "$corrupted" \
    --argjson rebuild_rc "$rebuild_rc" \
    --argjson exit_code "$rc" \
    '{schema_version:$schema,version:$version,command:"check",repo:$repo,db_path:$db,
      checked_at:$ts,ledger_path:$ledger,status:$status,corrupted:$corrupted,
      integrity_output:$integrity,auto_rebuild:$auto_rebuild,rebuild_script:$rebuild_script,
      rebuild_invoked:($auto_rebuild and ($integrity != "ok")),rebuild_exit_code:$rebuild_rc,
      rebuild_output:(if $rebuild_out == "" then null else $rebuild_out end),
      post_rebuild_integrity_output:(if $post_integrity == "" then null else $post_integrity end),
      exit_code:$exit_code}')"

  if [[ "$rc" -eq 0 ]]; then
    emit_payload "$payload" "PASS status=$status repo=$repo_abs_path" 0
  else
    printf 'ALERT br-db-corruption-monitor repo=%s integrity=%s\n' "$repo_abs_path" "$out" >&2
    emit_payload "$payload" "FAIL status=$status repo=$repo_abs_path" 1
  fi
}

if [[ "$#" -eq 0 ]]; then
  usage
  exit 2
fi

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    check) COMMAND="check"; shift ;;
    --repo) REPO="${2:?}"; shift 2 ;;
    --repo=*) REPO="${1#*=}"; shift ;;
    --auto-rebuild) AUTO_REBUILD=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --info)
      if [[ "${2:-}" == "--json" || "$JSON_OUT" -eq 1 ]]; then info_json; else info_json | jq .; fi
      exit 0
      ;;
    --examples) examples; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$COMMAND" in
  check) run_check ;;
  *) printf 'ERR unknown command: %s\n' "$COMMAND" >&2; exit 2 ;;
esac
