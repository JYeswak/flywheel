#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/br-db-corruption-monitor.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/br-db-monitor-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo/.beads" "$repo/.flywheel/scripts"
  sqlite3 "$repo/.beads/beads.db" 'CREATE TABLE issues(id TEXT PRIMARY KEY, title TEXT); INSERT INTO issues VALUES ("x","ok");'
}

corrupt_db() {
  local db="$1"
  printf 'X' | dd of="$db" bs=1 seek=100 conv=notrunc >/dev/null 2>&1
  if [[ "$(sqlite3 "$db" 'PRAGMA integrity_check;' 2>&1 || true)" == "ok" ]]; then
    printf 'Y' | dd of="$db" bs=1 seek=4096 conv=notrunc >/dev/null 2>&1
  fi
  [[ "$(sqlite3 "$db" 'PRAGMA integrity_check;' 2>&1 || true)" != "ok" ]]
}

run_monitor() {
  env BR_DB_CORRUPTION_MONITOR_LEDGER="$TMP/ledger.jsonl" "$SCRIPT" "$@"
}

bash -n "$SCRIPT" && pass "script_syntax"
run_monitor --help >/dev/null && pass "help_ok"
run_monitor --examples >/dev/null && pass "examples_ok"
run_monitor --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "br-db-corruption-monitor.sh" and .mutation_requires == "--auto-rebuild"' "info_shape"

repo_ok="$TMP/repo-ok"
make_repo "$repo_ok"
run_monitor check --repo "$repo_ok" --json >"$TMP/ok.json"
assert_jq "$TMP/ok.json" '.status == "pass" and .corrupted == false and .integrity_output == "ok" and .exit_code == 0' "healthy_db_passes"

repo_bad="$TMP/repo-bad"
make_repo "$repo_bad"
repo_bad_abs="$(cd "$repo_bad" && pwd -P)"
corrupt_db "$repo_bad/.beads/beads.db"
set +e
run_monitor check --repo "$repo_bad" --json >"$TMP/bad.json" 2>"$TMP/bad.err"
bad_rc=$?
set -e
[[ "$bad_rc" -eq 1 ]] && pass "corrupt_db_exits_1" || fail "corrupt_db_exits_1"
assert_jq "$TMP/bad.json" '.status == "fail" and .corrupted == true and .auto_rebuild == false and .exit_code == 1' "corrupt_db_json"
grep -q 'ALERT br-db-corruption-monitor' "$TMP/bad.err" && pass "corrupt_db_alerts_stderr" || fail "corrupt_db_alerts_stderr"

repo_rebuild="$TMP/repo-rebuild"
make_repo "$repo_rebuild"
repo_rebuild_abs="$(cd "$repo_rebuild" && pwd -P)"
corrupt_db "$repo_rebuild/.beads/beads.db"
cat >"$repo_rebuild/.flywheel/scripts/beads-db-recover.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
repo=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --repo) repo="$2"; shift 2 ;;
    *) shift ;;
  esac
done
rm -f "$repo/.beads/beads.db" "$repo/.beads/beads.db-wal" "$repo/.beads/beads.db-shm"
sqlite3 "$repo/.beads/beads.db" 'CREATE TABLE issues(id TEXT PRIMARY KEY, title TEXT); INSERT INTO issues VALUES ("rebuilt","ok");'
printf '{"status":"pass","success":true}\n'
SH
chmod +x "$repo_rebuild/.flywheel/scripts/beads-db-recover.sh"
run_monitor check --repo "$repo_rebuild" --auto-rebuild --json >"$TMP/rebuilt.json"
assert_jq "$TMP/rebuilt.json" '.status == "rebuilt" and .corrupted == false and .rebuild_invoked == true and .post_rebuild_integrity_output == "ok" and .exit_code == 0' "auto_rebuild_invokes_recovery"

assert_jq "$TMP/ledger.jsonl" 'select(.schema_version == "br-db-corruption-monitor/v1" and .repo == "'"$repo_bad_abs"'" and .status == "fail")' "ledger_records_failure"
assert_jq "$TMP/ledger.jsonl" 'select(.schema_version == "br-db-corruption-monitor/v1" and .repo == "'"$repo_rebuild_abs"'" and .status == "rebuilt")' "ledger_records_rebuild"

if [[ "$fail_count" -ne 0 ]]; then
  printf 'FAIL br-db-corruption-monitor tests failed=%s passed=%s\n' "$fail_count" "$pass_count" >&2
  exit 1
fi
printf 'PASS br-db-corruption-monitor tests passed=%s\n' "$pass_count"
