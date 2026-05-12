#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN="$ROOT/.flywheel/scripts/ntm-coordinator-shadow.sh"
TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/ntm-coordinator-shadow.XXXXXX")"
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

bash -n "$BIN"
"$BIN" --help >/dev/null
pass "syntax and help"

for cmd in doctor health validate audit why schema; do
  "$BIN" "$cmd" --json >"$TMPDIR/$cmd.json"
  assert_jq "$TMPDIR/$cmd.json" '.status == "pass" or .schema_version == "ntm-coordinator-shadow/v1"' "$cmd JSON"
done
pass "canonical diagnostic subcommands emit JSON"

"$BIN" repair --dry-run --json >"$TMPDIR/repair-dry.json"
assert_jq "$TMPDIR/repair-dry.json" '.status == "pass" and .dry_run == true' "repair dry-run"
if "$BIN" repair --apply --json >"$TMPDIR/repair-apply-no-key.json"; then
  fail "repair --apply without key must fail"
fi
assert_jq "$TMPDIR/repair-apply-no-key.json" '.failure_class == "missing_idempotency_key" and .exit_code == 2' "repair key gate"
pass "mutation discipline enforced"

cat >"$TMPDIR/green.json" <<'JSON'
{
  "quota_status": "ok",
  "metrics_status": "pass",
  "eventstream_status": "pass",
  "safety_status": "pass",
  "approval_status": "approved",
  "ready_bead_count": 2,
  "idle_worker_count": 1
}
JSON
"$BIN" check --input "$TMPDIR/green.json" --json >"$TMPDIR/green.out"
assert_jq "$TMPDIR/green.out" '.status == "pass" and .decision == "recommend_dispatch" and .would_dispatch == true' "green recommends dispatch"
assert_jq "$TMPDIR/green.out" '.actual_dispatch_performed == false and .mutation_applied == false and .auto_assign_enabled == false' "green no mutation"
pass "green inputs produce shadow dispatch recommendation"

assert_jq "$TMPDIR/green.out" '.daemon_enable_blocked_until_ntm124_closes == true and .ntm124 == "https://github.com/Dicklesworthstone/ntm/issues/124"' "ntm124 block"
assert_jq "$TMPDIR/green.out" '.command_not_run == "ntm assign --watch --auto"' "daemon command not run"
pass "daemon enable explicitly blocked"

cat >"$TMPDIR/hold.json" <<'JSON'
{
  "quota_status": "warn",
  "metrics_status": "pass",
  "eventstream_status": "pass",
  "safety_status": "pass",
  "approval_status": "pending",
  "ready_bead_count": 0,
  "idle_worker_count": 1
}
JSON
"$BIN" check --input "$TMPDIR/hold.json" --json >"$TMPDIR/hold.out"
assert_jq "$TMPDIR/hold.out" '.status == "hold" and .decision == "recommend_hold" and .would_dispatch == false' "hold recommendation"
assert_jq "$TMPDIR/hold.out" '(.blockers | index("quota:warn")) and (.blockers | index("approval:pending")) and (.blockers | index("ready_bead_count:0"))' "hold blockers"
pass "failing upstream receipts produce hold recommendation"

printf 'not-json\n' >"$TMPDIR/bad.json"
if "$BIN" check --input "$TMPDIR/bad.json" --json >"$TMPDIR/bad.out"; then
  fail "bad input JSON must fail"
fi
assert_jq "$TMPDIR/bad.out" '.failure_class == "input_non_json" and .exit_code == 65' "bad input receipt"
pass "non-JSON input fails closed"

if "$BIN" check --json >"$TMPDIR/missing.out"; then
  fail "missing input must fail"
fi
assert_jq "$TMPDIR/missing.out" '.failure_class == "missing_input" and .exit_code == 64' "missing input receipt"
pass "missing input fails closed"

if "$BIN" check --input "$TMPDIR/green.json" --apply --json >"$TMPDIR/apply-no-key.out"; then
  fail "check --apply without idempotency key must fail"
fi
assert_jq "$TMPDIR/apply-no-key.out" '.failure_class == "missing_idempotency_key" and .exit_code == 2' "check apply key gate"
pass "check apply requires idempotency key"

"$BIN" check --input "$TMPDIR/green.json" --apply --idempotency-key test-key --json >"$TMPDIR/apply-pass.out"
assert_jq "$TMPDIR/apply-pass.out" '.status == "pass" and .apply == true and .mutation_applied == false and (.idempotency_token | length) == 64' "apply pass no mutation"
assert_jq "$TMPDIR/apply-pass.out" '.ttl_native == "single_shadow_snapshot" and .ttl_wrapper == "shadow_receipt_lifetime" and .ttl_decision == "recompute_before_dispatch"' "TTL fields"
assert_jq "$TMPDIR/apply-pass.out" '.native_wrapper_delta == "coordinator_recommendation_only_daemon_blocked_ntm124" and .L112 == "OK_ntm_migrate_W3aC"' "delta and L112"
pass "acceptance receipt fields present"

assert_jq "$TMPDIR/apply-pass.out" '.authorized_operations | index("compute_shadow_recommendation")' "authorized operations"
assert_jq "$TMPDIR/apply-pass.out" '.forbidden_operations | index("enable_daemon")' "forbidden operations"
pass "authorized and forbidden operations present"

"$BIN" schema --json >"$TMPDIR/schema.json"
assert_jq "$TMPDIR/schema.json" '.stable_exit_codes."0" and (.mutation_modes | index("--dry-run")) and .daemon_enable_blocked_until_ntm124_closes == true' "schema contract"
pass "schema describes JSON and daemon-block contract"

printf 'PASS ntm-coordinator-shadow %d/%d\n' "$pass_count" "$pass_count"
