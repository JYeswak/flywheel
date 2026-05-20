#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

SCHEMA_VERSION="flywheel.supabase_local_mirror.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
RUNTIME_DIR="$ROOT/.flywheel/runtime/supabase-local-mirror"
DEFAULT_LEDGER="$ROOT/.flywheel/runtime/supabase-local-mirror-ledger.jsonl"

json=0
dry_run=0
project=""
project_map="${SUPABASE_PROJECT_MAP_JSON:-$ROOT/.flywheel/runtime/supabase-projects.json}"
mirror_dir=""
remote_db_url="${SUPABASE_REMOTE_DB_URL:-}"
schema_file=""
seed_fixture=""
skip_start=0
ledger="$DEFAULT_LEDGER"
secret_loader="${SUPABASE_SECRET_LOADER:-cf-secret}"
supabase_bin="${SUPABASE_BIN:-supabase}"
docker_bin="${DOCKER_BIN:-docker}"
psql_bin="${PSQL_BIN:-psql}"
pg_dump_bin="${PG_DUMP_BIN:-pg_dump}"
api_base="${SUPABASE_MANAGEMENT_API_BASE:-https://api.supabase.com}"
local_db_url="${SUPABASE_LOCAL_DB_URL:-}"
mock_projects_json=""

usage() {
  cat <<'EOF'
usage: supabase-local-mirror.sh --project REF_OR_NAME [options]

Starts a local Supabase/Postgres mirror, syncs remote schema only, and never
dumps remote data. Use --seed-fixture for anonymized local fixtures only.

Options:
  --project REF_OR_NAME       Supabase project ref or canonical name
  --remote-db-url URL         Remote Postgres URL for schema-only pg_dump
  --schema-file FILE          Existing schema-only SQL fixture to import
  --seed-fixture FILE         Anonymized fixture SQL to apply locally
  --mirror-dir DIR            Override local mirror workspace
  --local-db-url URL          Override local mirror Postgres URL
  --project-map FILE          JSON array/object mapping names to refs
  --mock-projects-json FILE   Project list fixture for name resolution
  --skip-start                Do not start Supabase/Docker; use local DB URL
  --ledger FILE               Append JSONL cycle events here
  --dry-run                   Print planned actions; do not start/import
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
  local event="$1" status="$2" project_ref="$3" project_name="$4" detail="$5"
  mkdir -p "$(dirname "$ledger")"
  jq_json \
    --arg schema "$SCHEMA_VERSION" \
    --arg ts "$(iso_now)" \
    --arg event "$event" \
    --arg status "$status" \
    --arg project_ref "$project_ref" \
    --arg project_name "$project_name" \
    --arg detail "$detail" \
    '{schema_version:$schema,ts:$ts,event:$event,status:$status,project_ref:$project_ref,project_name:$project_name,detail:$detail}' >>"$ledger"
}

emit() {
  local status="$1" reason="$2" project_ref="$3" project_name="$4" start_mode="$5" schema_path="$6" seed_status="$7" exit_code="$8"
  if [[ "$json" -eq 1 ]]; then
    jq_json \
      --arg schema "$SCHEMA_VERSION" \
      --arg ts "$(iso_now)" \
      --arg status "$status" \
      --arg reason "$reason" \
      --arg project_ref "$project_ref" \
      --arg project_name "$project_name" \
      --arg mirror_dir "$mirror_dir" \
      --arg local_db_url "${local_db_url:-}" \
      --arg start_mode "$start_mode" \
      --arg schema_path "$schema_path" \
      --arg seed_status "$seed_status" \
      --arg ledger "$ledger" \
      --argjson dry_run "$dry_run" \
      --argjson exit_code "$exit_code" \
      '{
        schema_version:$schema,
        ts:$ts,
        status:$status,
        reason:$reason,
        project_ref:$project_ref,
        project_name:$project_name,
        mirror_dir:$mirror_dir,
        local_db_url:$local_db_url,
        start_mode:$start_mode,
        schema_path:$schema_path,
        seed_status:$seed_status,
        ledger:$ledger,
        dry_run:($dry_run == 1),
        exit_code:$exit_code
      }'
  else
    printf 'supabase-local-mirror status=%s reason=%s project_ref=%s mirror_dir=%s schema=%s\n' \
      "$status" "$reason" "$project_ref" "$mirror_dir" "$schema_path"
  fi
}

load_token() {
  if [[ -n "${SUPABASE_PERSONAL_ACCESS_TOKEN:-}" ]]; then
    printf '%s' "$SUPABASE_PERSONAL_ACCESS_TOKEN"
    return 0
  fi
  if [[ -n "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
    printf '%s' "$SUPABASE_ACCESS_TOKEN"
    return 0
  fi
  command -v "$secret_loader" >/dev/null 2>&1 || return 1
  "$secret_loader" SUPABASE_PERSONAL_ACCESS_TOKEN 2>/dev/null || "$secret_loader" SUPABASE_ACCESS_TOKEN 2>/dev/null
}

resolve_from_map() {
  local needle="$1" map="$2"
  [[ -r "$map" ]] || return 1
  jq -cer --arg needle "$needle" '
    def rows:
      if type == "array" then .
      elif has("projects") then .projects
      else [.[]] end;
    rows[]
    | select((.ref // .project_ref // .id // "") == $needle
      or (.name // .canonical_name // .slug // "") == $needle)
    | {ref:(.ref // .project_ref // .id), name:(.name // .canonical_name // .slug // $needle)}
  ' "$map" | head -1
}

resolve_from_api() {
  local needle="$1"
  local token tmp http_status
  token="$(load_token)" || return 1
  [[ -n "$token" ]] || return 1
  tmp="$(mktemp)"
  http_status="$(curl -sS -o "$tmp" -w '%{http_code}' -H "Authorization: Bearer $token" -H 'Accept: application/json' "$api_base/v1/projects")"
  append_ledger "management_api_call" "$http_status" "" "$needle" "GET /v1/projects"
  unset token
  [[ "$http_status" == 2* ]] || { rm -f "$tmp"; return 1; }
  jq -cer --arg needle "$needle" '
    .[]
    | select((.ref // .id // "") == $needle or (.name // .project_name // "") == $needle)
    | {ref:(.ref // .id), name:(.name // .project_name // $needle)}
  ' "$tmp" | head -1
  rm -f "$tmp"
}

resolve_project() {
  local needle="$1"
  if [[ "$needle" =~ ^[a-z0-9]{20}$ ]]; then
    jq_json --arg ref "$needle" '{ref:$ref,name:$ref}'
    return 0
  fi
  if [[ -n "$mock_projects_json" && -r "$mock_projects_json" ]]; then
    resolve_from_map "$needle" "$mock_projects_json" && return 0
  fi
  resolve_from_map "$needle" "$project_map" && return 0
  resolve_from_api "$needle" && return 0
  return 1
}

load_remote_db_url() {
  local project_ref="$1" project_name="$2" key
  if [[ -n "$remote_db_url" ]]; then
    printf '%s' "$remote_db_url"
    return 0
  fi
  command -v "$secret_loader" >/dev/null 2>&1 || return 1
  for key in \
    "SUPABASE_$(secret_key_fragment "$project_ref")_DATABASE_URL" \
    "SUPABASE_$(secret_key_fragment "$project_name")_DATABASE_URL" \
    "$(secret_key_fragment "$project_name")_DATABASE_URL" \
    "$(secret_key_fragment "$project_ref")_DATABASE_URL"; do
    if value="$("$secret_loader" "$key" 2>/dev/null)" && [[ -n "$value" ]]; then
      printf '%s' "$value"
      return 0
    fi
  done
  return 1
}

start_local_stack() {
  local project_ref="$1" safe_ref="$2"
  if [[ "$skip_start" -eq 1 ]]; then
    printf 'skipped\n'
    return 0
  fi
  if [[ "$dry_run" -eq 1 ]]; then
    printf 'planned\n'
    return 0
  fi
  mkdir -p "$mirror_dir"
  if command -v "$supabase_bin" >/dev/null 2>&1; then
    if [[ ! -f "$mirror_dir/supabase/config.toml" ]]; then
      (cd "$mirror_dir" && "$supabase_bin" init >/dev/null)
    fi
    (cd "$mirror_dir" && "$supabase_bin" start >/dev/null)
    printf 'supabase-cli\n'
    return 0
  fi
  if command -v "$docker_bin" >/dev/null 2>&1; then
    "$docker_bin" rm -f "flywheel-supabase-mirror-$safe_ref" >/dev/null 2>&1 || true
    "$docker_bin" run -d --name "flywheel-supabase-mirror-$safe_ref" \
      -e POSTGRES_PASSWORD=postgres \
      -p 127.0.0.1:54322:5432 \
      postgres:15-alpine >/dev/null
    local_db_url="${local_db_url:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
    printf 'docker-postgres-fallback\n'
    return 0
  fi
  printf 'missing-runtime\n'
  return 1
}

sync_schema() {
  local remote_url="$1" schema_out="$2"
  mkdir -p "$(dirname "$schema_out")"
  if [[ "$dry_run" -eq 1 ]]; then
    return 0
  fi
  if [[ -n "$schema_file" ]]; then
    cp "$schema_file" "$schema_out"
    return 0
  fi
  [[ -n "$remote_url" ]] || return 1
  if command -v "$pg_dump_bin" >/dev/null 2>&1; then
    "$pg_dump_bin" --schema-only --no-owner --no-privileges "$remote_url" >"$schema_out"
  elif command -v "$supabase_bin" >/dev/null 2>&1; then
    (cd "$mirror_dir" && "$supabase_bin" db dump --db-url "$remote_url" -f "$schema_out" >/dev/null)
  else
    return 1
  fi
}

import_sql() {
  local sql_file="$1"
  [[ "$dry_run" -eq 0 ]] || return 0
  [[ -r "$sql_file" ]] || return 1
  [[ -n "$local_db_url" ]] || local_db_url="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
  command -v "$psql_bin" >/dev/null 2>&1 || return 1
  "$psql_bin" "$local_db_url" -v ON_ERROR_STOP=1 -f "$sql_file" >/dev/null
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    --project) project="${2:-}"; [[ -n "$project" ]] || die_usage "--project requires value"; shift 2 ;;
    --project=*) project="${1#--project=}"; shift ;;
    --project-map) project_map="${2:-}"; [[ -n "$project_map" ]] || die_usage "--project-map requires FILE"; shift 2 ;;
    --project-map=*) project_map="${1#--project-map=}"; shift ;;
    --mock-projects-json) mock_projects_json="${2:-}"; [[ -n "$mock_projects_json" ]] || die_usage "--mock-projects-json requires FILE"; shift 2 ;;
    --mock-projects-json=*) mock_projects_json="${1#--mock-projects-json=}"; shift ;;
    --remote-db-url) remote_db_url="${2:-}"; [[ -n "$remote_db_url" ]] || die_usage "--remote-db-url requires URL"; shift 2 ;;
    --remote-db-url=*) remote_db_url="${1#--remote-db-url=}"; shift ;;
    --schema-file) schema_file="${2:-}"; [[ -n "$schema_file" ]] || die_usage "--schema-file requires FILE"; shift 2 ;;
    --schema-file=*) schema_file="${1#--schema-file=}"; shift ;;
    --seed-fixture) seed_fixture="${2:-}"; [[ -n "$seed_fixture" ]] || die_usage "--seed-fixture requires FILE"; shift 2 ;;
    --seed-fixture=*) seed_fixture="${1#--seed-fixture=}"; shift ;;
    --mirror-dir) mirror_dir="${2:-}"; [[ -n "$mirror_dir" ]] || die_usage "--mirror-dir requires DIR"; shift 2 ;;
    --mirror-dir=*) mirror_dir="${1#--mirror-dir=}"; shift ;;
    --local-db-url) local_db_url="${2:-}"; [[ -n "$local_db_url" ]] || die_usage "--local-db-url requires URL"; shift 2 ;;
    --local-db-url=*) local_db_url="${1#--local-db-url=}"; shift ;;
    --skip-start) skip_start=1; shift ;;
    --ledger) ledger="${2:-}"; [[ -n "$ledger" ]] || die_usage "--ledger requires FILE"; shift 2 ;;
    --ledger=*) ledger="${1#--ledger=}"; shift ;;
    --secret-loader) secret_loader="${2:-}"; [[ -n "$secret_loader" ]] || die_usage "--secret-loader requires CMD"; shift 2 ;;
    --supabase-bin) supabase_bin="${2:-}"; [[ -n "$supabase_bin" ]] || die_usage "--supabase-bin requires CMD"; shift 2 ;;
    --docker-bin) docker_bin="${2:-}"; [[ -n "$docker_bin" ]] || die_usage "--docker-bin requires CMD"; shift 2 ;;
    --psql-bin) psql_bin="${2:-}"; [[ -n "$psql_bin" ]] || die_usage "--psql-bin requires CMD"; shift 2 ;;
    --pg-dump-bin) pg_dump_bin="${2:-}"; [[ -n "$pg_dump_bin" ]] || die_usage "--pg-dump-bin requires CMD"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die_usage "unknown option: $1" ;;
  esac
done

[[ -n "$project" ]] || die_usage "--project is required"

resolved="$(resolve_project "$project")" || {
  mirror_dir="${mirror_dir:-$RUNTIME_DIR/$(sanitize "$project")}"
  append_ledger "mirror" "blocked" "$project" "$project" "project_resolution_failed"
  emit "blocked" "project_resolution_failed" "$project" "$project" "not_started" "" "not_requested" 1
  exit 1
}
project_ref="$(jq -r '.ref' <<<"$resolved")"
project_name="$(jq -r '.name' <<<"$resolved")"
safe_ref="$(sanitize "$project_ref")"
mirror_dir="${mirror_dir:-$RUNTIME_DIR/$safe_ref}"
schema_out="$mirror_dir/schema/remote-schema.sql"

if [[ -n "$schema_file" && ! -r "$schema_file" ]]; then
  append_ledger "mirror" "blocked" "$project_ref" "$project_name" "schema_file_unreadable"
  emit "blocked" "schema_file_unreadable" "$project_ref" "$project_name" "not_started" "$schema_out" "not_requested" 1
  exit 1
fi
if [[ -n "$seed_fixture" && ! -r "$seed_fixture" ]]; then
  append_ledger "mirror" "blocked" "$project_ref" "$project_name" "seed_fixture_unreadable"
  emit "blocked" "seed_fixture_unreadable" "$project_ref" "$project_name" "not_started" "$schema_out" "not_requested" 1
  exit 1
fi

start_mode="$(start_local_stack "$project_ref" "$safe_ref")" || {
  append_ledger "mirror" "blocked" "$project_ref" "$project_name" "local_runtime_unavailable"
  emit "blocked" "local_runtime_unavailable" "$project_ref" "$project_name" "$start_mode" "$schema_out" "not_requested" 1
  exit 1
}

remote_url=""
if [[ -z "$schema_file" && "$dry_run" -eq 0 ]]; then
  remote_url="$(load_remote_db_url "$project_ref" "$project_name" || true)"
  if [[ -z "$remote_url" ]]; then
    append_ledger "mirror" "blocked" "$project_ref" "$project_name" "remote_db_url_unavailable"
    emit "blocked" "remote_db_url_unavailable" "$project_ref" "$project_name" "$start_mode" "$schema_out" "not_requested" 1
    exit 1
  fi
fi

if ! sync_schema "$remote_url" "$schema_out"; then
  append_ledger "mirror" "blocked" "$project_ref" "$project_name" "schema_sync_failed"
  emit "blocked" "schema_sync_failed" "$project_ref" "$project_name" "$start_mode" "$schema_out" "not_requested" 1
  exit 1
fi

if ! import_sql "$schema_out"; then
  append_ledger "mirror" "blocked" "$project_ref" "$project_name" "schema_import_failed"
  emit "blocked" "schema_import_failed" "$project_ref" "$project_name" "$start_mode" "$schema_out" "not_requested" 1
  exit 1
fi

seed_status="not_requested"
if [[ -n "$seed_fixture" ]]; then
  if import_sql "$seed_fixture"; then
    seed_status="applied_anonymized_fixture"
  else
    append_ledger "mirror" "blocked" "$project_ref" "$project_name" "seed_fixture_failed"
    emit "blocked" "seed_fixture_failed" "$project_ref" "$project_name" "$start_mode" "$schema_out" "$seed_status" 1
    exit 1
  fi
fi

[[ "$dry_run" -eq 1 ]] && seed_status="planned"
append_ledger "mirror" "pass" "$project_ref" "$project_name" "$start_mode"
emit "pass" "schema_only_mirror_ready" "$project_ref" "$project_name" "$start_mode" "$schema_out" "$seed_status" 0
