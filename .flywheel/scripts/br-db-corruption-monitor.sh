#!/usr/bin/env bash
set -euo pipefail

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
