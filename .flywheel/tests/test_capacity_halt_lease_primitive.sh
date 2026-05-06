#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/capacity-halt-lease-primitive.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/capacity-halt-lease-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
DIGEST_A="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
DIGEST_B="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
LEDGER="$TMP/lease.jsonl"

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

run_lease() {
  local now="$1" out="$2"
  shift 2
  CAPACITY_HALT_LEASE_LEDGER="$LEDGER" CAPACITY_HALT_LEASE_NOW_EPOCH="$now" "$SCRIPT" "$@" --json >"$out" 2>"$out.err"
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
chmod +x "$SCRIPT"

run_lease 1000 "$TMP/info.json" --info
assert_jq "$TMP/info.json" '.verbs | index("--acquire") and index("--release") and index("--list")' "info_lists_canonical_verbs"

run_lease 1000 "$TMP/acquire.json" --acquire --session flywheel --pane 3 --digest "$DIGEST_A" --ttl 90
[[ "$?" -eq 0 ]] && pass "fresh_acquire_rc0" || fail "fresh_acquire_rc0"
assert_jq "$TMP/acquire.json" '.status == "acquired" and .ledger_written == true' "fresh_acquire_json"
[[ "$(wc -l <"$LEDGER" | tr -d ' ')" -eq 1 ]] && pass "fresh_acquire_one_row" || fail "fresh_acquire_one_row"

set +e
run_lease 1010 "$TMP/duplicate.json" --acquire --session flywheel --pane 3 --digest "$DIGEST_A" --ttl 90
dup_rc=$?
set -e
[[ "$dup_rc" -eq 1 ]] && pass "duplicate_acquire_rc1" || fail "duplicate_acquire_rc1"
assert_jq "$TMP/duplicate.json" '.status == "already_held" and .ledger_written == false' "duplicate_acquire_json"
[[ "$(wc -l <"$LEDGER" | tr -d ' ')" -eq 1 ]] && pass "duplicate_no_double_row" || fail "duplicate_no_double_row"

run_lease 1100 "$TMP/expired.json" --acquire --session flywheel --pane 3 --digest "$DIGEST_A" --ttl 90
[[ "$?" -eq 0 ]] && pass "expired_reacquire_rc0" || fail "expired_reacquire_rc0"
[[ "$(jq -s '[.[] | select(.event=="acquire" and .digest=="'"$DIGEST_A"'")] | length' "$LEDGER")" -eq 2 ]] && pass "expired_reacquire_new_row" || fail "expired_reacquire_new_row"

run_lease 1110 "$TMP/different.json" --acquire --session flywheel --pane 3 --digest "$DIGEST_B" --ttl 90
[[ "$?" -eq 0 ]] && pass "different_digest_rc0" || fail "different_digest_rc0"
assert_jq "$TMP/different.json" '.status == "acquired" and .digest == "'"$DIGEST_B"'"' "different_digest_json"

run_lease 1120 "$TMP/release.json" --release --session flywheel --pane 3 --digest "$DIGEST_B" --result success
[[ "$?" -eq 0 ]] && pass "release_rc0" || fail "release_rc0"
assert_jq "$TMP/release.json" '.status == "released" and .result == "success"' "release_json"
jq -e 'select(.event=="release" and .result=="success" and .digest=="'"$DIGEST_B"'")' "$LEDGER" >/dev/null && pass "release_row_appended" || fail "release_row_appended"

set +e
run_lease 1130 "$TMP/malformed.json" --acquire --session flywheel --pane 3 --digest not-a-sha --ttl 90
bad_rc=$?
set -e
[[ "$bad_rc" -eq 2 ]] && pass "malformed_rc2" || fail "malformed_rc2"
assert_jq "$TMP/malformed.json" '.status == "malformed" and .ledger_written == false' "malformed_json"

run_lease 1130 "$TMP/list.json" --list
assert_jq "$TMP/list.json" '.status == "ok" and .active_count >= 1' "list_read_only_active"

printf 'Capacity halt lease summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
