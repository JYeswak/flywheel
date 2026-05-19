#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
MIRROR="$ROOT/.flywheel/scripts/supabase-local-mirror.sh"
VALIDATE="$ROOT/.flywheel/scripts/supabase-local-validate-and-push.sh"
CLEANUP="$ROOT/.flywheel/scripts/supabase-local-mirror-cleanup.sh"
GATE="$ROOT/.flywheel/scripts/supabase-prepush-mirror-gate.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/supabase-local-mirror.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok() {
  local name="$1"
  shift
  if "$@"; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
  fi
}

ok_jq() {
  local name="$1" expr="$2" file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

BIN="$TMP/bin"
mkdir -p "$BIN"

cat >"$BIN/supabase" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${SUPABASE_CALLS:?}"
case "${1:-}" in
  init)
    mkdir -p supabase
    printf '[api]\n' >supabase/config.toml
    ;;
  start|stop)
    ;;
  db)
    case "${2:-}" in
      dump)
        out=""
        prev=""
        for arg in "$@"; do
          if [[ "$prev" == "-f" || "$prev" == "--file" ]]; then out="$arg"; fi
          prev="$arg"
        done
        [[ -n "$out" ]] || exit 44
        mkdir -p "$(dirname "$out")"
        printf 'create table public.fixture(id bigint primary key);\nalter table public.fixture enable row level security;\n' >"$out"
        ;;
      push)
        ;;
      *) exit 45 ;;
    esac
    ;;
  *) exit 46 ;;
esac
SH
chmod +x "$BIN/supabase"

cat >"$BIN/psql" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${PSQL_CALLS:?}"
if [[ "$*" == *"row_to_json"* ]]; then
  cat "${LOCAL_CATALOG_JSON:?}"
fi
SH
chmod +x "$BIN/psql"

cat >"$BIN/docker" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${DOCKER_CALLS:?}"
SH
chmod +x "$BIN/docker"

cat >"$TMP/projects.json" <<'JSON'
[
  {"ref":"hsmyagcerajgjmlljtmx","name":"ZestStream"}
]
JSON
cat >"$TMP/schema.sql" <<'SQL'
create table public.fixture(id bigint primary key);
alter table public.fixture enable row level security;
SQL
cat >"$TMP/migration.sql" <<'SQL'
create policy fixture_service_role on public.fixture for all to service_role using (true) with check (true);
SQL
cat >"$TMP/local-catalog.json" <<'JSON'
[
  {"table_schema":"public","table_name":"fixture","rls_enabled":true,"row_count_estimate":0,"has_sensitive_column":false,"sensitive_columns":[]}
]
JSON
cat >"$TMP/clean-audit.json" <<'JSON'
{
  "schema_version": "flywheel.supabase_rls_audit.v1",
  "projects_audited": 1,
  "tables_audited": 1,
  "rls_disabled_count": 0,
  "severe_count": 0,
  "by_project": []
}
JSON

export PATH="$BIN:$PATH"
export SUPABASE_CALLS="$TMP/supabase-calls.log"
export PSQL_CALLS="$TMP/psql-calls.log"
export DOCKER_CALLS="$TMP/docker-calls.log"
export LOCAL_CATALOG_JSON="$TMP/local-catalog.json"
: >"$SUPABASE_CALLS"
: >"$PSQL_CALLS"
: >"$DOCKER_CALLS"

LEDGER="$TMP/ledger.jsonl"
MIRROR_DIR="$TMP/mirror"
RECEIPT="$TMP/receipt.json"

ok "script syntax" bash -n "$MIRROR" "$VALIDATE" "$CLEANUP" "$GATE"
ok "fixture syntax" bash -n "$0"
ok "mirror script enforces schema-only pg_dump" grep -q -- '--schema-only' "$MIRROR"

"$MIRROR" --json --project ZestStream --mock-projects-json "$TMP/projects.json" \
  --schema-file "$TMP/schema.sql" --mirror-dir "$MIRROR_DIR" --ledger "$LEDGER" \
  --local-db-url "postgresql://local" >"$TMP/mirror.json"
ok_jq "mirror starts via supabase cli" '.status == "pass" and .start_mode == "supabase-cli"' "$TMP/mirror.json"
ok "schema synced to mirror" grep -q 'create table public.fixture' "$MIRROR_DIR/schema/remote-schema.sql"
ok "schema imported into local mirror" grep -q -- '-f' "$PSQL_CALLS"

"$VALIDATE" --json --dry-run --project hsmyagcerajgjmlljtmx --project-name ZestStream \
  --mirror-dir "$MIRROR_DIR" --local-db-url "postgresql://local" \
  --migration "$TMP/migration.sql" --audit-json "$TMP/clean-audit.json" \
  --test-cmd "test -f '$MIRROR_DIR/schema/remote-schema.sql'" \
  --receipt-file "$RECEIPT" --ledger "$LEDGER" >"$TMP/validate.json"
ok_jq "migration applies locally" '.status == "pass" and .migrations_count == 1' "$TMP/validate.json"
ok_jq "validate-and-push respects dry-run" '.push_status == "dry_run_not_pushed" and .dry_run == true' "$TMP/validate.json"
ok "audit receipt written" test -s "$RECEIPT"
ok "audit gate ran from clean audit" jq -e '.audit_status == "pass"' "$TMP/validate.json" >/dev/null

REPO="$TMP/repo"
mkdir -p "$REPO/supabase/migrations"
git -C "$REPO" init -q
git -C "$REPO" config user.email fixture@example.invalid
git -C "$REPO" config user.name Fixture
printf 'baseline\n' >"$REPO/README.md"
git -C "$REPO" add README.md
git -C "$REPO" commit -q -m baseline
cat >"$REPO/supabase/migrations/20260519000000_rls.sql" <<'SQL'
alter table public.fixture enable row level security;
SQL
git -C "$REPO" add supabase/migrations/20260519000000_rls.sql

set +e
"$GATE" --json --repo "$REPO" --ledger "$TMP/missing-ledger.jsonl" >"$TMP/gate-block.json"
gate_block_rc=$?
set -e
ok "gate blocks bare push" test "$gate_block_rc" -eq 1
ok_jq "gate block reason is missing receipt" '.status == "blocked" and .reason == "missing_fresh_local_mirror_validation_receipt"' "$TMP/gate-block.json"

"$GATE" --json --repo "$REPO" --ledger "$LEDGER" --project hsmyagcerajgjmlljtmx >"$TMP/gate-pass.json"
ok_jq "gate allows post-validation push" '.status == "pass" and .reason == "fresh_local_mirror_validation_receipt"' "$TMP/gate-pass.json"

"$CLEANUP" --json --project hsmyagcerajgjmlljtmx --mirror-dir "$MIRROR_DIR" --ledger "$LEDGER" >"$TMP/cleanup.json"
ok_jq "cleanup tears down cleanly" '.status == "pass" and (.stop_mode | length > 0)' "$TMP/cleanup.json"

ok "ledger records mirror validate cleanup" jq -s -e 'map(.event) | index("mirror") and index("validate") and index("cleanup")' "$LEDGER" >/dev/null

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
