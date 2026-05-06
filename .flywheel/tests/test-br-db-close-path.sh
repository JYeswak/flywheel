#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DB="$ROOT/.beads/beads.db"
JSONL="$ROOT/.beads/issues.jsonl"
VERIFY="$ROOT/.flywheel/scripts/verify-br-db-close-path-active.sh"
RECOVER="$ROOT/.flywheel/scripts/beads-db-recover.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/br-db-close-path-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

hash_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

assert_cmd() {
  local label="$1"
  shift
  if "$@" >"$TMP/$label.out" 2>"$TMP/$label.err"; then
    pass "$label"
  else
    fail "$label"
    cat "$TMP/$label.out" >&2 || true
    cat "$TMP/$label.err" >&2 || true
  fi
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

cd "$ROOT"

before_hash="$(hash_file "$JSONL")"
before_jsonl_count="$(jq -r '.id' "$JSONL" | sort -u | wc -l | tr -d ' ')"
before_db_count="$(sqlite3 "$DB" "SELECT count(*) FROM issues WHERE COALESCE(ephemeral, 0) = 0;")"

sqlite3 "$DB" "PRAGMA integrity_check;" | grep -qx "ok" && pass "integrity_check_ok" || fail "integrity_check_ok"
sqlite3 "$DB" "PRAGMA quick_check;" | grep -qx "ok" && pass "quick_check_ok" || fail "quick_check_ok"
sqlite3 "$DB" ".schema" | grep -q "CREATE TABLE.*issues" && pass "schema_introspection_succeeds" || fail "schema_introspection_succeeds"

if [[ "$before_jsonl_count" == "$before_db_count" ]]; then
  pass "jsonl_db_count_match_before"
else
  fail "jsonl_db_count_match_before"
fi

assert_cmd "round_trip_verify_probe" bash "$VERIFY"
grep -q "OK_br_db_close_path_active" "$TMP/round_trip_verify_probe.out" && pass "round_trip_returns_ok" || fail "round_trip_returns_ok"
if grep -qi "fallback\\|Auto-flush" "$TMP/round_trip_verify_probe.err"; then
  fail "round_trip_no_jsonl_fallback_noise"
else
  pass "round_trip_no_jsonl_fallback_noise"
fi

bash "$RECOVER" --dry-run --json >"$TMP/recover-dry-run-1.json"
bash "$RECOVER" --dry-run --json >"$TMP/recover-dry-run-2.json"
assert_jq "$TMP/recover-dry-run-1.json" '.dry_run == true and (.planned_actions | length) >= 5' "recovery_dry_run_shape"
assert_jq "$TMP/recover-dry-run-2.json" '.dry_run == true and (.planned_actions | length) >= 5' "recovery_dry_run_idempotent_second_run"

after_hash="$(hash_file "$JSONL")"
after_jsonl_count="$(jq -r '.id' "$JSONL" | sort -u | wc -l | tr -d ' ')"
after_db_count="$(sqlite3 "$DB" "SELECT count(*) FROM issues WHERE COALESCE(ephemeral, 0) = 0;")"

[[ "$after_hash" == "$before_hash" ]] && pass "jsonl_hash_preserved" || fail "jsonl_hash_preserved"
[[ "$after_jsonl_count" == "$before_jsonl_count" ]] && pass "jsonl_count_preserved" || fail "jsonl_count_preserved"
[[ "$after_db_count" == "$before_db_count" ]] && pass "db_count_preserved" || fail "db_count_preserved"
[[ "$after_db_count" == "$after_jsonl_count" ]] && pass "jsonl_db_count_match_after" || fail "jsonl_db_count_match_after"

if [[ "$fail_count" -eq 0 ]]; then
  printf 'PASS tests=%s failures=0\n' "$pass_count"
else
  printf 'FAIL tests=%s failures=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
