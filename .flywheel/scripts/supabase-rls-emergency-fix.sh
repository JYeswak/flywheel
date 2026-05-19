#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
AUDIT_FILE="$ROOT/.flywheel/audits/supabase-rls-emergency-2026-05-19/PROJECTS.jsonl"
OUT_DIR="$ROOT/.flywheel/audits/supabase-rls-emergency-2026-05-19"
apply=0
json=0
mock_apply_log=""
api_base="${SUPABASE_MANAGEMENT_API_BASE:-https://api.supabase.com}"
secret_loader="${SUPABASE_SECRET_LOADER:-cf-secret}"

usage() {
  cat <<'EOF'
usage: supabase-rls-emergency-fix.sh [--apply] [--json] [--audit-file FILE]
                                     [--out-dir DIR] [--mock-apply-log FILE]

Default is dry-run: emit per-project SQL files only. --apply executes through
Supabase Management API. Mock apply logs requests without network calls.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) apply=1; shift ;;
    --json) json=1; shift ;;
    --audit-file) AUDIT_FILE="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --mock-apply-log) mock_apply_log="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

mkdir -p "$OUT_DIR/fix-sql" "$OUT_DIR/receipts"
[[ -r "$AUDIT_FILE" ]] || { printf 'audit file not readable: %s\n' "$AUDIT_FILE" >&2; exit 66; }

python3 - "$AUDIT_FILE" "$OUT_DIR/fix-sql" <<'PY'
import collections, json, pathlib, sys
audit, out_dir = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
by = collections.defaultdict(list)
for line in audit.read_text().splitlines():
    if not line.strip():
        continue
    row = json.loads(line)
    if row.get("rls_enabled") is False:
        by[(row["project_id"], row["project_name"])].append({"schema": row["table_schema"], "table": row["table_name"]})
for (ref, name), tables in by.items():
    payload = json.dumps(tables, separators=(",", ":"))
    sql = f"""DO $flywheel_rls_p0$
DECLARE
  item jsonb;
  sch text;
  tbl text;
  pol text;
BEGIN
  FOR item IN SELECT * FROM jsonb_array_elements('{payload}'::jsonb)
  LOOP
    sch := item->>'schema';
    tbl := item->>'table';
    pol := 'flywheel_p0_service_role_' || substr(md5(sch || '.' || tbl), 1, 12);
    EXECUTE format('ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY', sch, tbl);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol, sch, tbl);
    EXECUTE format('CREATE POLICY %I ON %I.%I FOR ALL TO service_role USING (true) WITH CHECK (true)', pol, sch, tbl);
    EXECUTE format('REVOKE ALL PRIVILEGES ON TABLE %I.%I FROM anon, authenticated', sch, tbl);
    EXECUTE format('GRANT ALL PRIVILEGES ON TABLE %I.%I TO service_role', sch, tbl);
  END LOOP;
END
$flywheel_rls_p0$;
"""
    (out_dir / f"{ref}.sql").write_text(sql)
    print(json.dumps({"project_id": ref, "project_name": name, "tables_fixed": len(tables), "sql_file": str(out_dir / f"{ref}.sql")}))
PY

plan="$OUT_DIR/fix-plan.jsonl"
python3 - "$AUDIT_FILE" "$OUT_DIR/fix-sql" >"$plan" <<'PY'
import collections, json, pathlib, sys
audit, out_dir = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
by = collections.defaultdict(int)
for line in audit.read_text().splitlines():
    if line.strip():
        row = json.loads(line)
        if row.get("rls_enabled") is False:
            by[(row["project_id"], row["project_name"])] += 1
for (ref, name), count in by.items():
    print(json.dumps({"project_id": ref, "project_name": name, "tables_fixed": count, "sql_file": str(out_dir / f"{ref}.sql")}))
PY

if [[ "$apply" -eq 1 ]]; then
  if [[ -n "$mock_apply_log" ]]; then
    : >"$mock_apply_log"
  else
    token="$("$secret_loader" SUPABASE_PERSONAL_ACCESS_TOKEN 2>/dev/null || "$secret_loader" SUPABASE_ACCESS_TOKEN 2>/dev/null)"
    [[ -n "$token" ]] || { printf 'missing Supabase Management API token\n' >&2; exit 70; }
  fi
  while IFS= read -r item; do
    ref="$(jq -r '.project_id' <<<"$item")"
    name="$(jq -r '.project_name' <<<"$item")"
    count="$(jq -r '.tables_fixed' <<<"$item")"
    sql_file="$(jq -r '.sql_file' <<<"$item")"
    if [[ -n "$mock_apply_log" ]]; then
      jq -nc --arg project_id "$ref" --arg project_name "$name" --argjson count "$count" '{project_id:$project_id,project_name:$project_name,tables_fixed:$count,applied:true}' >>"$mock_apply_log"
    else
      tmp="$(mktemp)"
      endpoint="/v1/projects/$ref/database/query"
      payload="$(jq -Rs '{query:.}' <"$sql_file")"
      http_status="$(curl -sS -o "$tmp" -w '%{http_code}' -H "Authorization: Bearer $token" -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST "$api_base$endpoint" -d "$payload")"
      jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg endpoint "$endpoint" --arg status "$http_status" '{ts:$ts,verb:"POST",endpoint:$endpoint,status_code:($status|tonumber),purpose:"supabase_rls_emergency_fix"}' >>"$OUT_DIR/api-calls.jsonl"
      [[ "$http_status" == 2* ]] || { cat "$tmp" >&2; rm -f "$tmp"; exit 71; }
      rm -f "$tmp"
    fi
    jq -nc --arg project_id "$ref" --arg project_name "$name" --argjson tables_fixed "$count" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{schema_version:"flywheel.supabase_rls_emergency_receipt.v1",project_id:$project_id,project_name:$project_name,tables_fixed:$tables_fixed,policies_added:$tables_fixed,anon_authenticated_grants_revoked:$tables_fixed,fix_timestamp:$ts,fix_mode:"enable_rls_service_role_only"}' >"$OUT_DIR/receipts/${name// /-}-receipt.json"
  done <"$plan"
  unset token 2>/dev/null || true
fi

mode="dry_run"
[[ "$apply" -eq 1 ]] && mode="apply"
summary="$(jq -s --arg mode "$mode" '{schema_version:"flywheel.supabase_rls_fix_plan.v1",mode:$mode,project_count:length,tables_fixed:(map(.tables_fixed)|add // 0),projects:.}' "$plan")"
if [[ "$json" -eq 1 ]]; then
  printf '%s\n' "$summary"
else
  jq -r '"project_count=\(.project_count) tables_fixed=\(.tables_fixed)"' <<<"$summary"
fi
