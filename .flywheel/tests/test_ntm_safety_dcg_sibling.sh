#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN="$ROOT/.flywheel/scripts/ntm-safety-dcg-sibling.sh"
TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/ntm-safety-dcg-sibling.XXXXXX")"
trap 'rm -rf "$TMPDIR"' EXIT

pass_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'ok %d - %s\n' "$pass_count" "$1"
}

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  jq -e "$expr" "$file" >/dev/null || fail "$label"
}

fixture() {
  local name="$1" body="$2"
  printf '%s\n' "$body" >"$TMPDIR/$name"
}

bash -n "$BIN"
"$BIN" --help >/dev/null
pass "syntax and help"

for cmd in doctor health validate audit why schema; do
  "$BIN" "$cmd" --json >"$TMPDIR/$cmd.json"
  assert_jq "$TMPDIR/$cmd.json" '.status == "pass" or .schema_version == "ntm-safety-dcg-sibling/v1"' "$cmd JSON status"
done
pass "canonical diagnostic subcommands emit JSON"

"$BIN" repair --dry-run --json >"$TMPDIR/repair-dry-run.json"
assert_jq "$TMPDIR/repair-dry-run.json" '.status == "pass" and .dry_run == true' "repair dry-run pass"
if "$BIN" repair --apply --json >"$TMPDIR/repair-apply-no-key.json"; then
  fail "repair --apply without idempotency key must fail"
fi
assert_jq "$TMPDIR/repair-apply-no-key.json" '.failure_class == "missing_idempotency_key" and .exit_code == 2' "repair apply requires key"
pass "mutation discipline enforced"

fixture ntm-safe.json '{"status":"pass","classification":"safe","destructive":false}'
fixture dcg-allow.json '{"status":"allow","classification":"safe","allowed":true}'
"$BIN" check --command "printf safe" --ntm-fixture "$TMPDIR/ntm-safe.json" --dcg-fixture "$TMPDIR/dcg-allow.json" --json >"$TMPDIR/allow.json"
assert_jq "$TMPDIR/allow.json" '.status == "pass" and .decision == "allowed" and .dcg_authority == true' "allow receipt"
assert_jq "$TMPDIR/allow.json" '.authorized_operations | index("verify_with_dcg")' "authorized operations"
assert_jq "$TMPDIR/allow.json" '.forbidden_operations | index("execute_command")' "forbidden operations"
pass "allowed command requires NTM pass and DCG allow"

fixture ntm-danger.json '{"status":"pass","classification":"destructive","destructive":true}'
fixture dcg-deny.json '{"status":"deny","classification":"destructive","allowed":false}'
if "$BIN" check --command "git reset --hard HEAD" --ntm-fixture "$TMPDIR/ntm-danger.json" --dcg-fixture "$TMPDIR/dcg-deny.json" --json >"$TMPDIR/deny.json"; then
  fail "DCG deny must fail"
fi
assert_jq "$TMPDIR/deny.json" '.status == "fail" and .decision == "denied" and .failure_class == "dcg_denied"' "DCG deny receipt"
pass "DCG denial is authoritative"

if "$BIN" check --command "printf disputed" --ntm-fixture "$TMPDIR/ntm-safe.json" --dcg-fixture "$TMPDIR/dcg-deny.json" --json >"$TMPDIR/mismatch.json"; then
  fail "NTM/DCG mismatch must fail"
fi
assert_jq "$TMPDIR/mismatch.json" '.failure_class == "ntm_dcg_mismatch" and .dcg_authority == true' "mismatch receipt"
pass "NTM safe plus DCG deny fails closed"

printf 'not-json\n' >"$TMPDIR/bad-ntm.json"
if "$BIN" check --command "printf bad" --ntm-fixture "$TMPDIR/bad-ntm.json" --dcg-fixture "$TMPDIR/dcg-allow.json" --json >"$TMPDIR/bad-ntm.out"; then
  fail "bad NTM JSON must fail"
fi
assert_jq "$TMPDIR/bad-ntm.out" '.failure_class == "ntm_non_json" and .exit_code == 65' "bad NTM JSON receipt"
pass "NTM non-JSON fails closed"

printf 'not-json\n' >"$TMPDIR/bad-dcg.json"
if "$BIN" check --command "printf bad" --ntm-fixture "$TMPDIR/ntm-safe.json" --dcg-fixture "$TMPDIR/bad-dcg.json" --json >"$TMPDIR/bad-dcg.out"; then
  fail "bad DCG JSON must fail"
fi
assert_jq "$TMPDIR/bad-dcg.out" '.failure_class == "dcg_non_json" and .exit_code == 65' "bad DCG JSON receipt"
pass "DCG non-JSON fails closed"

if DCG_SIMULATE_TIMEOUT=1 "$BIN" check --command "printf slow" --ntm-fixture "$TMPDIR/ntm-safe.json" --dcg-fixture "$TMPDIR/dcg-allow.json" --json >"$TMPDIR/timeout.out"; then
  fail "DCG timeout must fail"
fi
assert_jq "$TMPDIR/timeout.out" '.failure_class == "dcg_timeout" and .exit_code == 70' "DCG timeout receipt"
pass "DCG timeout fails closed"

"$BIN" check --command "printf local" --json >"$TMPDIR/local-safe.json"
assert_jq "$TMPDIR/local-safe.json" '.status == "pass" and .ttl_native == "current_command_only" and .ttl_wrapper == "callback_lifetime" and .ttl_decision == "recheck_before_execution"' "TTL fields"
assert_jq "$TMPDIR/local-safe.json" '.native_wrapper_delta == "ntm_safety_advisory_dcg_authoritative" and .L112 == "OK_ntm_migrate_W2D"' "delta and L112"
pass "acceptance receipt fields present"

"$BIN" schema --json >"$TMPDIR/schema.json"
assert_jq "$TMPDIR/schema.json" '.stable_exit_codes."0" and (.mutation_modes | index("--dry-run"))' "schema stable exit codes"
pass "schema describes JSON and mutation contract"

printf 'PASS ntm-safety-dcg-sibling %d/%d\n' "$pass_count" "$pass_count"
