#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
OUT_DIR="$ROOT/.flywheel/audits/supabase-rls-emergency-2026-05-19"
PROJECTS_JSON=""
CATALOG_DIR=""
json=0
api_base="${SUPABASE_MANAGEMENT_API_BASE:-https://api.supabase.com}"
secret_loader="${SUPABASE_SECRET_LOADER:-cf-secret}"

usage() {
  cat <<'EOF'
usage: supabase-rls-audit.sh [--json] [--out-dir DIR]
                             [--mock-projects-json FILE --mock-catalog-dir DIR]

Audits Supabase public-schema tables for RLS status and sensitive column names.
Real mode loads SUPABASE_PERSONAL_ACCESS_TOKEN or SUPABASE_ACCESS_TOKEN via
cf-secret just-in-time. Mock mode performs no network calls.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --mock-projects-json) PROJECTS_JSON="$2"; shift 2 ;;
    --mock-catalog-dir) CATALOG_DIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

mkdir -p "$OUT_DIR/catalog"
: >"$OUT_DIR/PROJECTS.jsonl"
: >"$OUT_DIR/api-calls.jsonl"

catalog_sql() {
  cat <<'SQL'
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
order by n.nspname, c.relname;
SQL
}

append_rows() {
  local ref="$1" name="$2" file="$3"
  jq -c --arg project_id "$ref" --arg project_name "$name" '
    .[]
    | {
        project_id:$project_id,
        project_name:$project_name,
        table_schema,
        table_name,
        rls_enabled,
        row_count_estimate,
        has_sensitive_column,
        sensitive_columns,
        severity:(if (.rls_enabled == false and .has_sensitive_column == true) then "SEVERE"
          elif (.rls_enabled == false) then "CRITICAL" else "OK" end)
      }
  ' "$file" >>"$OUT_DIR/PROJECTS.jsonl"
}

if [[ -n "$PROJECTS_JSON" || -n "$CATALOG_DIR" ]]; then
  [[ -r "$PROJECTS_JSON" && -d "$CATALOG_DIR" ]] || { printf 'mock projects/catalog missing\n' >&2; exit 64; }
  jq -c '.[]' "$PROJECTS_JSON" | while IFS= read -r project; do
    ref="$(jq -r '.ref' <<<"$project")"
    name="$(jq -r '.name' <<<"$project")"
    append_rows "$ref" "$name" "$CATALOG_DIR/$ref.json"
  done
else
  token="$("$secret_loader" SUPABASE_PERSONAL_ACCESS_TOKEN 2>/dev/null || "$secret_loader" SUPABASE_ACCESS_TOKEN 2>/dev/null)"
  [[ -n "$token" ]] || { printf 'missing Supabase Management API token\n' >&2; exit 70; }
  projects_tmp="$(mktemp)"
  http_status="$(curl -sS -o "$projects_tmp" -w '%{http_code}' -H "Authorization: Bearer $token" -H 'Accept: application/json' "$api_base/v1/projects")"
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg status "$http_status" '{ts:$ts,verb:"GET",endpoint:"/v1/projects",status_code:($status|tonumber)}' >>"$OUT_DIR/api-calls.jsonl"
  [[ "$http_status" == 2* ]] || { rm -f "$projects_tmp"; exit 70; }
  jq '[.[] | {ref:(.ref // .id), name:(.name // .project_name)}]' "$projects_tmp" >"$OUT_DIR/projects-raw.redacted.json"
  query="$(catalog_sql)"
  jq -c '.[]' "$OUT_DIR/projects-raw.redacted.json" | while IFS= read -r project; do
    ref="$(jq -r '.ref' <<<"$project")"
    name="$(jq -r '.name' <<<"$project")"
    tmp="$(mktemp)"
    payload="$(jq -nc --arg query "$query" '{query:$query}')"
    endpoint="/v1/projects/$ref/database/query"
    http_status="$(curl -sS -o "$tmp" -w '%{http_code}' -H "Authorization: Bearer $token" -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST "$api_base$endpoint" -d "$payload")"
    jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg endpoint "$endpoint" --arg status "$http_status" '{ts:$ts,verb:"POST",endpoint:$endpoint,status_code:($status|tonumber),purpose:"rls_catalog_audit"}' >>"$OUT_DIR/api-calls.jsonl"
    if [[ "$http_status" == 2* ]]; then
      cp "$tmp" "$OUT_DIR/catalog/$ref.json"
      append_rows "$ref" "$name" "$tmp"
    fi
    rm -f "$tmp"
  done
  rm -f "$projects_tmp"
  unset token
fi

summary="$(jq -s '{
  schema_version:"flywheel.supabase_rls_audit.v1",
  generated_at:now | todateiso8601,
  projects_audited:(map(.project_id) | unique | length),
  tables_audited:length,
  rls_disabled_count:(map(select(.rls_enabled == false)) | length),
  severe_count:(map(select(.severity == "SEVERE")) | length),
  by_project:(group_by(.project_name) | map({project_name:.[0].project_name,tables:length,rls_disabled:(map(select(.rls_enabled == false))|length),severe:(map(select(.severity == "SEVERE"))|length)}))
}' "$OUT_DIR/PROJECTS.jsonl")"
printf '%s\n' "$summary" >"$OUT_DIR/summary.json"

if [[ "$json" -eq 1 ]]; then
  printf '%s\n' "$summary"
else
  jq -r '"rls_disabled_count=\(.rls_disabled_count) severe_count=\(.severe_count)"' <<<"$summary"
fi
