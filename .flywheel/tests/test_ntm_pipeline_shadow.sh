#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN="$ROOT/.flywheel/scripts/ntm-pipeline-shadow.sh"
TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/ntm-pipeline-shadow.XXXXXX")"
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
  assert_jq "$TMPDIR/$cmd.json" '.status == "pass" or .schema_version == "ntm-pipeline-shadow/v1"' "$cmd JSON"
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
  "status": "pass",
  "decision": "recommend_dispatch",
  "would_dispatch": true,
  "blockers": []
}
JSON
"$BIN" check --input "$TMPDIR/green.json" --artifact "$TMPDIR/dag.json" --json >"$TMPDIR/green.out"
assert_jq "$TMPDIR/green.out" '.status == "pass" and .decision == "dry_run_dag_ready" and .dry_run_dag_generated == true' "green dag ready"
assert_jq "$TMPDIR/green.out" '.native_pipeline_executed == false and .mutation_applied == false and .artifact_written == true' "green no native execution"
test -s "$TMPDIR/dag.json" || fail "DAG artifact missing"
pass "green coordinator receipt generates dry-run DAG artifact"

assert_jq "$TMPDIR/dag.json" '.schema_version == "ntm-pipeline-shadow-dag/v1" and (.nodes | length) == 9 and (.edges | length) == 8' "DAG artifact shape"
assert_jq "$TMPDIR/dag.json" '.rollback == "Disable native pipeline execution; keep generated DAG as dry-run artifact."' "rollback text"
pass "DAG artifact contains expected nodes, edges, and rollback"

cat >"$TMPDIR/hold.json" <<'JSON'
{
  "status": "hold",
  "decision": "recommend_hold",
  "would_dispatch": false,
  "blockers": ["approval:pending"]
}
JSON
"$BIN" check --input "$TMPDIR/hold.json" --json >"$TMPDIR/hold.out"
assert_jq "$TMPDIR/hold.out" '.status == "hold" and .decision == "recommend_hold" and .failure_class == "coordinator_not_green"' "hold receipt"
assert_jq "$TMPDIR/hold.out" '.native_pipeline_executed == false and .dry_run_dag_generated == false' "hold no DAG execution"
pass "non-green coordinator receipt holds pipeline"

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

if "$BIN" check --input "$TMPDIR/green.json" --artifact "$TMPDIR/no/such/dag.json" --json >"$TMPDIR/bad-artifact.out"; then
  fail "bad artifact dir must fail"
fi
assert_jq "$TMPDIR/bad-artifact.out" '.failure_class == "artifact_dir_missing" and .exit_code == 65' "bad artifact receipt"
pass "bad artifact path fails closed"

if "$BIN" check --input "$TMPDIR/green.json" --apply --json >"$TMPDIR/apply-no-key.out"; then
  fail "check --apply without key must fail"
fi
assert_jq "$TMPDIR/apply-no-key.out" '.failure_class == "missing_idempotency_key" and .exit_code == 2' "check apply key gate"
pass "check apply requires idempotency key"

"$BIN" check --input "$TMPDIR/green.json" --apply --idempotency-key test-key --json >"$TMPDIR/apply-pass.out"
assert_jq "$TMPDIR/apply-pass.out" '.status == "pass" and .apply == true and .native_pipeline_executed == false and (.idempotency_token | length) == 64' "apply pass no native execution"
assert_jq "$TMPDIR/apply-pass.out" '.ttl_native == "single_pipeline_snapshot" and .ttl_wrapper == "dry_run_artifact_lifetime" and .ttl_decision == "regenerate_before_native_execution"' "TTL fields"
assert_jq "$TMPDIR/apply-pass.out" '.native_wrapper_delta == "native_pipeline_disabled_shadow_dag_artifact_only" and .L112 == "OK_ntm_migrate_W3aP"' "delta and L112"
pass "acceptance receipt fields present"

assert_jq "$TMPDIR/apply-pass.out" '.authorized_operations | index("generate_dry_run_dag")' "authorized operations"
assert_jq "$TMPDIR/apply-pass.out" '.forbidden_operations | index("execute_native_pipeline")' "forbidden operations"
pass "authorized and forbidden operations present"

"$BIN" schema --json >"$TMPDIR/schema.json"
assert_jq "$TMPDIR/schema.json" '.stable_exit_codes."0" and (.mutation_modes | index("--dry-run")) and .native_pipeline_executed == false' "schema contract"
pass "schema describes JSON and native-disabled contract"

printf 'PASS ntm-pipeline-shadow %d/%d\n' "$pass_count" "$pass_count"
