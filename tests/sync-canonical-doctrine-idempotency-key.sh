#!/usr/bin/env bash
# Regression test for flywheel-8sx9w: --idempotency-key gate on sync-canonical-doctrine.sh.
# Verifies: AG1 refusal contract (rc=3 when --apply lacks key), AG2 receipt envelope
# carries the key, AG3 replay-check no-ops on re-run with the same key, AG4 fresh key
# does not replay, AG5 schema documents the new field.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/sync-canonical-idem.XXXXXX")"
trap 'find "$TMP" -type f -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Isolated ledger for this test (so we don't contaminate the real one).
export SYNC_CANONICAL_LEDGER="$TMP/test-ledger.jsonl"
export SYNC_CANONICAL_LEDGER_DISABLE=0

# Test 1: --apply without --idempotency-key returns rc=3 + refusal envelope
set +e
"$SCRIPT" --apply --root /tmp/no-such-root --json >"$TMP/refused.json" 2>&1
rc=$?
set -e
if [[ "$rc" -eq 3 ]]; then pass "AG1.rc: --apply without --idempotency-key exits 3"
else fail "AG1.rc: expected rc=3, got $rc"; fi
if jq -e '.status == "refused" and (.reason | test("idempotency-key"))' "$TMP/refused.json" >/dev/null 2>&1; then
  pass "AG1.envelope: refusal shape correct"
else fail "AG1.envelope: refusal envelope malformed"; fi

# Test 2: --apply --idempotency-key passes the gate; receipt carries the key
"$SCRIPT" --apply --idempotency-key=ag2-fresh-key --root /tmp/no-such-root --json >"$TMP/ag2.json" 2>&1
if jq -e '.mode == "apply" and .status == "ok" and .idempotency_key == "ag2-fresh-key"' "$TMP/ag2.json" >/dev/null 2>&1; then
  pass "AG2: receipt envelope carries idempotency_key"
else fail "AG2: receipt missing idempotency_key"; fi

# Test 3: replay-check fires on re-run with same key
"$SCRIPT" --apply --idempotency-key=ag2-fresh-key --root /tmp/no-such-root --json >"$TMP/ag3.json" 2>&1
if jq -e '.replay == true and .replay_for_idempotency_key == "ag2-fresh-key"' "$TMP/ag3.json" >/dev/null 2>&1; then
  pass "AG3: replay-check no-ops re-run with same key"
else fail "AG3: replay-check did not fire (no-op missing)"; fi

# Test 4: fresh key does NOT replay; new row written
"$SCRIPT" --apply --idempotency-key=ag4-different-key --root /tmp/no-such-root --json >"$TMP/ag4.json" 2>&1
if jq -e '(.replay // false) == false and .idempotency_key == "ag4-different-key"' "$TMP/ag4.json" >/dev/null 2>&1; then
  pass "AG4: fresh key does not replay"
else fail "AG4: fresh key incorrectly replayed"; fi

# Test 5: --schema includes idempotency_key
if "$SCRIPT" --schema 2>&1 | jq -e '.properties.idempotency_key.type == "string"' >/dev/null 2>&1; then
  pass "AG5: --schema declares idempotency_key property"
else fail "AG5: --schema missing idempotency_key"; fi

# Test 6: --idempotency-key with no value → rc=2 usage error
set +e
"$SCRIPT" --apply --idempotency-key 2>"$TMP/no-value.err"
rc=$?
set -e
if [[ "$rc" -eq 2 ]]; then pass "AG6: --idempotency-key without value returns rc=2"
else fail "AG6: expected rc=2 for empty key, got $rc"; fi

# Test 7: --idempotency-key=VALUE form (equals syntax) works
"$SCRIPT" --apply --idempotency-key=ag7-equals-form --root /tmp/no-such-root --json >"$TMP/ag7.json" 2>&1
if jq -e '.idempotency_key == "ag7-equals-form"' "$TMP/ag7.json" >/dev/null 2>&1; then
  pass "AG7: --idempotency-key=VALUE equals form works"
else fail "AG7: equals form not parsed"; fi

# Test 8: --check mode emits idempotency_key="" (not required in check mode)
SYNC_CANONICAL_LEDGER_DISABLE=1 "$SCRIPT" --check --json >"$TMP/check.json" 2>&1 || true
if jq -e '.mode == "check" and (.idempotency_key // "") == ""' "$TMP/check.json" >/dev/null 2>&1; then
  pass "AG8: --check mode emits empty idempotency_key (not required)"
else fail "AG8: check mode envelope missing idempotency_key field"; fi

# Test 9: --info documents the new flag
if "$SCRIPT" --info --json 2>/dev/null | grep -q 'idempotency-key'; then
  pass "AG9: --info documents --idempotency-key"
else fail "AG9: --info does not mention --idempotency-key"; fi

# Test 10: --help documents the new flag + rc=3
if "$SCRIPT" --help 2>&1 | grep -q -- '--idempotency-key' && "$SCRIPT" --help 2>&1 | grep -q 'rc=3\|exit 3\|^\s*3 '; then
  pass "AG10: --help documents --idempotency-key + exit code 3"
else fail "AG10: --help missing --idempotency-key or rc=3 documentation"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
