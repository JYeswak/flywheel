#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

SCHEMA_VERSION="flywheel.supabase_local_validate_and_push.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DEFAULT_LEDGER="$ROOT/.flywheel/runtime/supabase-local-mirror-ledger.jsonl"
DEFAULT_RECEIPT_DIR="$ROOT/.flywheel/runtime/supabase-local-mirror-receipts"
AUDIT_SCRIPT="$ROOT/.flywheel/scripts/supabase-rls-audit.sh"
GATE_SCRIPT="$ROOT/.flywheel/scripts/supabase-rls-fleet-gate.sh"

json=0
dry_run=1
project=""
project_name=""
mirror_dir=""
local_db_url="${SUPABASE_LOCAL_DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
remote_db_url="${SUPABASE_REMOTE_DB_URL:-}"
ledger="$DEFAULT_LEDGER"
receipt_dir="$DEFAULT_RECEIPT_DIR"
receipt_file=""
audit_json=""
mock_projects_json=""
mock_catalog_dir=""
secret_loader="${SUPABASE_SECRET_LOADER:-cf-secret}"
supabase_bin="${SUPABASE_BIN:-supabase}"
psql_bin="${PSQL_BIN:-psql}"
push_mode="supabase"
declare -a migrations=()
declare -a test_cmds=()

usage() {
  cat <<'EOF'
usage: supabase-local-validate-and-push.sh --project REF [options]

Applies migrations/RLS fixes to the local mirror, runs local RLS audit plus
fixtures, and only pushes remote schema changes after green validation.
Default mode is dry-run; pass --apply to push.

Options:
  --project REF_OR_NAME       Project ref or canonical name
  --project-name NAME         Human-readable name for receipts
  --mirror-dir DIR            Local mirror workspace
  --local-db-url URL          Local mirror Postgres URL
  --remote-db-url URL         Remote Postgres URL for db push/apply
  --migration FILE            SQL migration/RLS fix to apply locally; repeatable
  --migrations-dir DIR        Apply *.sql files in lexical order
  --test-cmd CMD              Fixture/test command; repeatable
  --audit-json FILE           Precomputed local audit summary
  --mock-projects-json FILE   Reuse audit script in mock mode
  --mock-catalog-dir DIR      Reuse audit script in mock mode
  --receipt-file FILE         Validation receipt path
  --ledger FILE               Append JSONL cycle events here
  --push-mode supabase|psql   Remote push implementation for --apply
  --dry-run                   Validate only; do not push
  --apply                     Push after green validation
  --json                      Emit structured JSON
EOF
}

die_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

iso_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

jq_json() {
  jq -nc "$@"
}

sanitize() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_-' '-'
}

secret_key_fragment() {
  printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_' | tr -c 'A-Z0-9_' '_'
}

append_ledger() {
  local event="$1" status="$2" reason="$3" audit_status="$4" push_status="$5" receipt="$6"
  mkdir -p "$(dirname "$ledger")"
  jq_json \
    --arg schema "$SCHEMA_VERSION" \
    --arg ts "$(iso_now)" \
    --arg event "$event" \
    --arg status "$status" \
    --arg reason "$reason" \
    --arg project_ref "$project" \
    --arg project_name "$project_name" \
    --arg audit_status "$audit_status" \
    --arg push_status "$push_status" \
    --arg receipt_path "$receipt" \
    '{schema_version:$schema,ts:$ts,event:$event,status:$status,reason:$reason,project_ref:$project_ref,project_name:$project_name,audit_status:$audit_status,push_status:$push_status,receipt_path:$receipt_path}' >>"$ledger"
}

emit() {
  local status="$1" reason="$2" audit_status="$3" push_status="$4" exit_code="$5"
  if [[ "$json" -eq 1 ]]; then
    jq_json \
      --arg schema "$SCHEMA_VERSION" \
      --arg ts "$(iso_now)" \
      --arg status "$status" \
      --arg reason "$reason" \
      --arg project_ref "$project" \
      --arg project_name "$project_name" \
      --arg mirror_dir "$mirror_dir" \
      --arg audit_status "$audit_status" \
      --arg push_status "$push_status" \
      --arg receipt_path "$receipt_file" \
      --arg ledger "$ledger" \
      --argjson dry_run "$dry_run" \
      --argjson migrations_count "${#migrations[@]}" \
      --argjson tests_count "${#test_cmds[@]}" \
      --argjson exit_code "$exit_code" \
      '{
        schema_version:$schema,
        ts:$ts,
        status:$status,
        reason:$reason,
        project_ref:$project_ref,
        project_name:$project_name,
        mirror_dir:$mirror_dir,
        migrations_count:$migrations_count,
        tests_count:$tests_count,
        audit_status:$audit_status,
        push_status:$push_status,
        receipt_path:$receipt_path,
        ledger:$ledger,
        dry_run:($dry_run == 1),
        exit_code:$exit_code
      }'
  else
    printf 'supabase-local-validate-and-push status=%s reason=%s audit=%s push=%s receipt=%s\n' \
      "$status" "$reason" "$audit_status" "$push_status" "$receipt_file"
  fi
}

load_remote_db_url() {
  local key value
  if [[ -n "$remote_db_url" ]]; then
    printf '%s' "$remote_db_url"
    return 0
  fi
  command -v "$secret_loader" >/dev/null 2>&1 || return 1
  for key in \
    "SUPABASE_$(secret_key_fragment "$project")_DATABASE_URL" \
    "SUPABASE_$(secret_key_fragment "$project_name")_DATABASE_URL" \
    "$(secret_key_fragment "$project_name")_DATABASE_URL" \
    "$(secret_key_fragment "$project")_DATABASE_URL"; do
    if value="$("$secret_loader" "$key" 2>/dev/null)" && [[ -n "$value" ]]; then
      printf '%s' "$value"
      return 0
    fi
  done
  return 1
}

apply_local_migration() {
  local file="$1"
  [[ -r "$file" ]] || return 1
  command -v "$psql_bin" >/dev/null 2>&1 || return 1
  "$psql_bin" "$local_db_url" -v ON_ERROR_STOP=1 -f "$file" >/dev/null
}

local_catalog_sql() {
  cat <<'SQL'
select coalesce(json_agg(row_to_json(t)), '[]'::json)
from (
  select
    n.nspname as table_schema,
    c.relname as table_name,
    c.relrowsecurity as rls_enabled,
    greatest(c.reltuples::bigint, 0) as row_count_estimate,
    exists (
      select 1 from information_schema.columns col
      where col.table_schema = n.nspname
        and col.table_name = c.relname
        and col.column_name ~* '(password|pwd|secret|api_?key|personal|ssn|dob|email|phone)'
    ) as has_sensitive_column,
    coalesce((
      select json_agg(col.column_name order by col.ordinal_position)
      from information_schema.columns col
      where col.table_schema = n.nspname
        and col.table_name = c.relname
        and col.column_name ~* '(password|pwd|secret|api_?key|personal|ssn|dob|email|phone)'
    ), '[]'::json) as sensitive_columns
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind in ('r','p')
  order by n.nspname, c.relname
) t;
SQL
}

run_local_audit() {
  local out_dir="$1"
  mkdir -p "$out_dir/catalog"
  if [[ -n "$audit_json" ]]; then
    cat "$audit_json"
    return 0
  fi
  if [[ -n "$mock_projects_json" || -n "$mock_catalog_dir" ]]; then
    [[ -r "$mock_projects_json" && -d "$mock_catalog_dir" ]] || return 1
    "$AUDIT_SCRIPT" --json --out-dir "$out_dir" --mock-projects-json "$mock_projects_json" --mock-catalog-dir "$mock_catalog_dir"
    return 0
  fi
  command -v "$psql_bin" >/dev/null 2>&1 || return 1
  jq_json --arg ref "$project" --arg name "$project_name" '[{ref:$ref,name:$name}]' >"$out_dir/projects.json"
  "$psql_bin" "$local_db_url" -XAt -v ON_ERROR_STOP=1 -c "$(local_catalog_sql)" >"$out_dir/catalog/$project.json"
  "$AUDIT_SCRIPT" --json --out-dir "$out_dir" --mock-projects-json "$out_dir/projects.json" --mock-catalog-dir "$out_dir/catalog"
}

write_receipt() {
  local status="$1" audit_status="$2" push_status="$3" audit_summary="$4"
  mkdir -p "$(dirname "$receipt_file")"
  jq_json \
    --arg schema "$SCHEMA_VERSION.receipt" \
    --arg ts "$(iso_now)" \
    --arg status "$status" \
    --arg project_ref "$project" \
    --arg project_name "$project_name" \
    --arg mirror_dir "$mirror_dir" \
    --arg audit_status "$audit_status" \
    --arg push_status "$push_status" \
    --argjson dry_run "$dry_run" \
    --argjson audit "$audit_summary" \
    '{schema_version:$schema,ts:$ts,status:$status,project_ref:$project_ref,project_name:$project_name,mirror_dir:$mirror_dir,audit_status:$audit_status,push_status:$push_status,dry_run:($dry_run == 1),audit_summary:$audit}' >"$receipt_file"
}

push_remote() {
  local remote_url="$1"
  if [[ "$dry_run" -eq 1 ]]; then
    printf 'dry_run_not_pushed\n'
    return 0
  fi
  [[ -n "$remote_url" ]] || return 1
  case "$push_mode" in
    supabase)
      command -v "$supabase_bin" >/dev/null 2>&1 || return 1
      (cd "${mirror_dir:-$ROOT}" && "$supabase_bin" db push --db-url "$remote_url" >/dev/null)
      ;;
    psql)
      command -v "$psql_bin" >/dev/null 2>&1 || return 1
      for file in "${migrations[@]}"; do
        "$psql_bin" "$remote_url" -v ON_ERROR_STOP=1 -f "$file" >/dev/null
      done
      ;;
    *) return 1 ;;
  esac
  printf 'pushed\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    --apply) dry_run=0; shift ;;
    --project) project="${2:-}"; [[ -n "$project" ]] || die_usage "--project requires value"; shift 2 ;;
    --project=*) project="${1#--project=}"; shift ;;
    --project-name) project_name="${2:-}"; [[ -n "$project_name" ]] || die_usage "--project-name requires value"; shift 2 ;;
    --project-name=*) project_name="${1#--project-name=}"; shift ;;
    --mirror-dir) mirror_dir="${2:-}"; [[ -n "$mirror_dir" ]] || die_usage "--mirror-dir requires DIR"; shift 2 ;;
    --mirror-dir=*) mirror_dir="${1#--mirror-dir=}"; shift ;;
    --local-db-url) local_db_url="${2:-}"; [[ -n "$local_db_url" ]] || die_usage "--local-db-url requires URL"; shift 2 ;;
    --local-db-url=*) local_db_url="${1#--local-db-url=}"; shift ;;
    --remote-db-url) remote_db_url="${2:-}"; [[ -n "$remote_db_url" ]] || die_usage "--remote-db-url requires URL"; shift 2 ;;
    --remote-db-url=*) remote_db_url="${1#--remote-db-url=}"; shift ;;
    --migration) value="${2:-}"; [[ -n "$value" ]] || die_usage "--migration requires FILE"; migrations+=("$value"); shift 2 ;;
    --migration=*) migrations+=("${1#--migration=}"); shift ;;
    --migrations-dir)
      dir="${2:-}"; [[ -d "$dir" ]] || die_usage "--migrations-dir requires DIR"
      while IFS= read -r file; do migrations+=("$file"); done < <(find "$dir" -maxdepth 1 -type f -name '*.sql' | sort)
      shift 2
      ;;
    --migrations-dir=*)
      dir="${1#--migrations-dir=}"; [[ -d "$dir" ]] || die_usage "--migrations-dir requires DIR"
      while IFS= read -r file; do migrations+=("$file"); done < <(find "$dir" -maxdepth 1 -type f -name '*.sql' | sort)
      shift
      ;;
    --test-cmd) value="${2:-}"; [[ -n "$value" ]] || die_usage "--test-cmd requires CMD"; test_cmds+=("$value"); shift 2 ;;
    --test-cmd=*) test_cmds+=("${1#--test-cmd=}"); shift ;;
    --audit-json) audit_json="${2:-}"; [[ -r "$audit_json" ]] || die_usage "--audit-json requires readable FILE"; shift 2 ;;
    --audit-json=*) audit_json="${1#--audit-json=}"; [[ -r "$audit_json" ]] || die_usage "--audit-json requires readable FILE"; shift ;;
    --mock-projects-json) mock_projects_json="${2:-}"; [[ -n "$mock_projects_json" ]] || die_usage "--mock-projects-json requires FILE"; shift 2 ;;
    --mock-projects-json=*) mock_projects_json="${1#--mock-projects-json=}"; shift ;;
    --mock-catalog-dir) mock_catalog_dir="${2:-}"; [[ -n "$mock_catalog_dir" ]] || die_usage "--mock-catalog-dir requires DIR"; shift 2 ;;
    --mock-catalog-dir=*) mock_catalog_dir="${1#--mock-catalog-dir=}"; shift ;;
    --receipt-file) receipt_file="${2:-}"; [[ -n "$receipt_file" ]] || die_usage "--receipt-file requires FILE"; shift 2 ;;
    --receipt-file=*) receipt_file="${1#--receipt-file=}"; shift ;;
    --ledger) ledger="${2:-}"; [[ -n "$ledger" ]] || die_usage "--ledger requires FILE"; shift 2 ;;
    --ledger=*) ledger="${1#--ledger=}"; shift ;;
    --secret-loader) secret_loader="${2:-}"; [[ -n "$secret_loader" ]] || die_usage "--secret-loader requires CMD"; shift 2 ;;
    --push-mode) push_mode="${2:-}"; [[ -n "$push_mode" ]] || die_usage "--push-mode requires value"; shift 2 ;;
    --push-mode=*) push_mode="${1#--push-mode=}"; shift ;;
    --supabase-bin) supabase_bin="${2:-}"; [[ -n "$supabase_bin" ]] || die_usage "--supabase-bin requires CMD"; shift 2 ;;
    --psql-bin) psql_bin="${2:-}"; [[ -n "$psql_bin" ]] || die_usage "--psql-bin requires CMD"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die_usage "unknown option: $1" ;;
  esac
done

[[ -n "$project" ]] || die_usage "--project is required"
project_name="${project_name:-$project}"
mirror_dir="${mirror_dir:-$ROOT/.flywheel/runtime/supabase-local-mirror/$(sanitize "$project")}"
receipt_file="${receipt_file:-$receipt_dir/$(sanitize "$project")-latest.json}"
case "$push_mode" in supabase|psql) ;; *) die_usage "--push-mode must be supabase or psql" ;; esac

for file in "${migrations[@]}"; do
  if ! apply_local_migration "$file"; then
    append_ledger "validate" "blocked" "migration_failed" "not_run" "not_pushed" ""
    emit "blocked" "migration_failed" "not_run" "not_pushed" 1
    exit 1
  fi
done

audit_dir="$mirror_dir/audit-$(date -u +%Y%m%dT%H%M%SZ)"
if ! audit_summary="$(run_local_audit "$audit_dir")"; then
  append_ledger "validate" "blocked" "audit_failed" "failed" "not_pushed" ""
  emit "blocked" "audit_failed" "failed" "not_pushed" 1
  exit 1
fi

audit_file="$audit_dir/summary.json"
mkdir -p "$audit_dir"
printf '%s\n' "$audit_summary" >"$audit_file"
if ! "$GATE_SCRIPT" --json --audit-json "$audit_file" >"$audit_dir/gate.json"; then
  append_ledger "validate" "blocked" "local_audit_blocked" "blocked" "not_pushed" ""
  emit "blocked" "local_audit_blocked" "blocked" "not_pushed" 1
  exit 1
fi

for cmd in "${test_cmds[@]}"; do
  if ! bash -lc "$cmd"; then
    append_ledger "validate" "blocked" "fixture_failed" "pass" "not_pushed" ""
    emit "blocked" "fixture_failed" "pass" "not_pushed" 1
    exit 1
  fi
done

remote_url=""
push_status="dry_run_not_pushed"
if [[ "$dry_run" -eq 0 ]]; then
  remote_url="$(load_remote_db_url || true)"
  if [[ -z "$remote_url" ]]; then
    append_ledger "validate" "blocked" "remote_db_url_unavailable" "pass" "not_pushed" ""
    emit "blocked" "remote_db_url_unavailable" "pass" "not_pushed" 1
    exit 1
  fi
fi

if ! push_status="$(push_remote "$remote_url")"; then
  append_ledger "validate" "blocked" "push_failed" "pass" "failed" ""
  emit "blocked" "push_failed" "pass" "failed" 1
  exit 1
fi

write_receipt "pass" "pass" "$push_status" "$audit_summary"
append_ledger "validate" "pass" "validated" "pass" "$push_status" "$receipt_file"
emit "pass" "validated" "pass" "$push_status" 0
