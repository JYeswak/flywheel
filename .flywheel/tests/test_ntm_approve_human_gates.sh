#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN="$ROOT/.flywheel/scripts/ntm-approve-human-gates.sh"
TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/ntm-approve-human-gates.XXXXXX")"
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
  assert_jq "$TMPDIR/$cmd.json" '.status == "pass" or .schema_version == "ntm-approve-human-gates/v1"' "$cmd JSON"
done
pass "canonical diagnostic subcommands emit JSON"

"$BIN" repair --dry-run --json >"$TMPDIR/repair-dry.json"
assert_jq "$TMPDIR/repair-dry.json" '.status == "pass" and .dry_run == true' "repair dry-run"
if "$BIN" repair --apply --json >"$TMPDIR/repair-apply-no-key.json"; then
  fail "repair --apply without key must fail"
fi
assert_jq "$TMPDIR/repair-apply-no-key.json" '.failure_class == "missing_idempotency_key" and .exit_code == 2' "repair apply key gate"
pass "mutation discipline enforced"

question="Approve W2A human-gate wrapper promotion after tests pass?"
if "$BIN" check --gate W2A --question "$question" --json >"$TMPDIR/pending.json"; then
  fail "missing approval receipt must be pending/nonzero"
fi
assert_jq "$TMPDIR/pending.json" '.status == "pending" and .decision == "requires_human_approval" and .exact_question == "Approve W2A human-gate wrapper promotion after tests pass?"' "pending exact question"
pass "missing receipt preserves exact question"

cat >"$TMPDIR/approved.json" <<EOF
{
  "status": "approved",
  "gate": "W2A",
  "exact_question": "$question",
  "approved_by": "Joshua Nowak",
  "approved_at": "2026-05-07T15:20:00Z"
}
EOF
"$BIN" check --gate W2A --question "$question" --approval-receipt "$TMPDIR/approved.json" --json >"$TMPDIR/pass.json"
assert_jq "$TMPDIR/pass.json" '.status == "pass" and .decision == "approved" and .failure_class == "none"' "approved receipt pass"
assert_jq "$TMPDIR/pass.json" '.authorized_operations | index("preserve_exact_question")' "authorized operations"
assert_jq "$TMPDIR/pass.json" '.forbidden_operations | index("answer_for_human")' "forbidden operations"
pass "matching approval receipt passes"

cat >"$TMPDIR/mismatch.json" <<'EOF'
{
  "status": "approved",
  "gate": "W2A",
  "exact_question": "Different approval question?",
  "approved_by": "Joshua Nowak",
  "approved_at": "2026-05-07T15:20:00Z"
}
EOF
if "$BIN" check --gate W2A --question "$question" --approval-receipt "$TMPDIR/mismatch.json" --json >"$TMPDIR/mismatch.out"; then
  fail "question mismatch must fail"
fi
assert_jq "$TMPDIR/mismatch.out" '.failure_class == "exact_question_mismatch" and .exit_code == 65' "question mismatch receipt"
pass "exact question mismatch fails closed"

cat >"$TMPDIR/gate-mismatch.json" <<EOF
{
  "status": "approved",
  "gate": "OTHER",
  "exact_question": "$question",
  "approved_by": "Joshua Nowak",
  "approved_at": "2026-05-07T15:20:00Z"
}
EOF
if "$BIN" check --gate W2A --question "$question" --approval-receipt "$TMPDIR/gate-mismatch.json" --json >"$TMPDIR/gate-mismatch.out"; then
  fail "gate mismatch must fail"
fi
assert_jq "$TMPDIR/gate-mismatch.out" '.failure_class == "gate_mismatch" and .exit_code == 65' "gate mismatch receipt"
pass "gate mismatch fails closed"

printf 'not-json\n' >"$TMPDIR/bad.json"
if "$BIN" check --gate W2A --question "$question" --approval-receipt "$TMPDIR/bad.json" --json >"$TMPDIR/bad.out"; then
  fail "bad approval JSON must fail"
fi
assert_jq "$TMPDIR/bad.out" '.failure_class == "approval_receipt_non_json" and .exit_code == 65' "bad JSON receipt"
pass "non-JSON approval receipt fails closed"

if "$BIN" check --gate W2A --question "Approve token=abc123?" --json >"$TMPDIR/secret.out"; then
  fail "secret-shaped question must fail"
fi
assert_jq "$TMPDIR/secret.out" '.failure_class == "secret_like_question" and .exit_code == 66' "secret-shaped question receipt"
pass "secret-shaped approval question refused"

if "$BIN" check --gate W2A --question "$question" --approval-receipt "$TMPDIR/approved.json" --apply --json >"$TMPDIR/apply-no-key.out"; then
  fail "check --apply without idempotency key must fail"
fi
assert_jq "$TMPDIR/apply-no-key.out" '.failure_class == "missing_idempotency_key" and .exit_code == 2' "check apply key gate"
pass "check apply requires idempotency key"

"$BIN" check --gate W2A --question "$question" --approval-receipt "$TMPDIR/approved.json" --apply --idempotency-key test-key --json >"$TMPDIR/apply-pass.json"
assert_jq "$TMPDIR/apply-pass.json" '.status == "pass" and .apply == true and (.idempotency_token | length) == 64' "apply pass receipt"
assert_jq "$TMPDIR/apply-pass.json" '.ttl_native == "single_approval_question" and .ttl_wrapper == "approval_receipt_lifetime" and .ttl_decision == "revalidate_on_question_change"' "TTL fields"
assert_jq "$TMPDIR/apply-pass.json" '.native_wrapper_delta == "exact_question_receipt_required_before_human_gate_pass" and .L112 == "OK_ntm_migrate_W2A"' "delta and L112"
pass "acceptance receipt fields present"

"$BIN" schema --json >"$TMPDIR/schema.json"
assert_jq "$TMPDIR/schema.json" '.stable_exit_codes."0" and (.mutation_modes | index("--dry-run")) and (.approval_receipt_required_fields | index("exact_question"))' "schema contract"
pass "schema describes JSON and approval contract"

printf 'PASS ntm-approve-human-gates %d/%d\n' "$pass_count" "$pass_count"
