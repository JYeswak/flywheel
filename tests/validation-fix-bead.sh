#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HELPER="$ROOT/.flywheel/scripts/validation-fix-bead.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/validation-fix-bead.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

assert_rc() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label"
  else
    fail "$label expected=$expected actual=$actual"
  fi
}

make_repo() {
  local repo="$TMP/repo"
  mkdir -p "$repo"
  git -C "$repo" init -q
  br --no-auto-import -q --db "$repo/.beads/beads.db" init >/dev/null 2>&1 || (cd "$repo" && br init >/dev/null)
  printf '%s\n' "$repo"
}

write_receipts() {
  local repo="$1"
  python3 - "$TMP" "$repo" <<'PY'
import json
import sys
from pathlib import Path

tmp = Path(sys.argv[1])
repo = Path(sys.argv[2])
proof = tmp / "proof.md"
proof.write_text("proof\n")
base_callback = {
    "transport": "manual_fixture",
    "session": "flywheel",
    "pane": 2,
    "kind": "DONE",
    "received_at": "2026-05-03T23:55:00Z",
    "raw_ref": "DONE fixture evidence=/tmp/missing.md",
}
missing = {
    "status": "fail",
    "failure_class": "missing_artifact",
    "retry_policy": "manual",
    "recovery_hint": "Restore or regenerate the referenced evidence artifact, then rerun validation with the same evidence path.",
    "failure_classes": ["artifact_missing", "remediation_missing"],
    "validation_receipt": {
        "schema_version": "validation-receipt/v1",
        "dispatch_id": "dispatch-missing",
        "callback_ref": base_callback,
        "status": "fail",
        "failure_class": "missing_artifact",
        "retry_policy": "manual",
        "recovery_hint": "Restore or regenerate the referenced evidence artifact, then rerun validation with the same evidence path.",
        "failure_classes": ["artifact_missing", "remediation_missing"],
        "evidence": [],
        "artifact_checks": [{"artifact_id": "callback_evidence", "path": str(tmp / "missing.md"), "status": "missing"}],
        "runtime_context": {"timeout": False},
        "bead_actions": [{"action": "none"}],
    },
}
missing_callback = {
    "status": "fail",
    "failure_class": "invalid_callback",
    "retry_policy": "manual",
    "recovery_hint": "Resend or regenerate the callback with required fields, evidence, and durable bead/no-bead routing.",
    "failure_classes": ["evidence_missing", "remediation_missing"],
    "validation_receipt": {
        "schema_version": "validation-receipt/v1",
        "dispatch_id": "dispatch-no-evidence",
        "callback_ref": {**base_callback, "raw_ref": "DONE fixture"},
        "status": "fail",
        "failure_class": "invalid_callback",
        "retry_policy": "manual",
        "recovery_hint": "Resend or regenerate the callback with required fields, evidence, and durable bead/no-bead routing.",
        "failure_classes": ["evidence_missing", "remediation_missing"],
        "evidence": [],
        "artifact_checks": [],
        "runtime_context": {"timeout": False},
        "bead_actions": [{"action": "none"}],
    },
}
runtime = {
    "status": "unknown",
    "failure_class": "transient",
    "retry_policy": "exponential",
    "recovery_hint": "Rerun the bounded probe once; if it repeats, promote to persistent with the timeout source attached.",
    "failure_classes": ["runtime_unresponsive"],
    "validation_receipt": {
        "schema_version": "validation-receipt/v1",
        "dispatch_id": "dispatch-timeout",
        "callback_ref": {**base_callback, "kind": "TIMEOUT", "raw_ref": "TIMEOUT dispatch-timeout"},
        "status": "unknown",
        "failure_class": "transient",
        "retry_policy": "exponential",
        "recovery_hint": "Rerun the bounded probe once; if it repeats, promote to persistent with the timeout source attached.",
        "failure_classes": ["runtime_unresponsive"],
        "evidence": [{"type": "path", "ref": str(proof)}],
        "artifact_checks": [],
        "runtime_context": {"timeout": True},
        "bead_actions": [{"action": "none"}],
    },
}
(tmp / "missing.json").write_text(json.dumps(missing))
(tmp / "missing-callback-field.json").write_text(json.dumps(missing_callback))
(tmp / "runtime.json").write_text(json.dumps(runtime))
PY
}

run_helper() {
  local name="$1"; shift
  local out="$TMP/$name.json"
  local rc=0
  "$HELPER" --json "$@" >"$out" || rc=$?
  printf '%s\n' "$rc" >"$TMP/$name.rc"
  printf '%s\n' "$out"
}

repo="$(make_repo)"
write_receipts "$repo"
parent_id="$(cd "$repo" && br create "parent validation source" --type task --priority P2 --description "parent" --json | jq -r '.id')"

doctor_out="$(run_helper doctor --repo "$repo" --doctor)"
assert_jq "$doctor_out" '.status == "pass" and .repo_local_proof.repo_local == true' "B06_AG6 repo-local br proof"

dry_out="$(run_helper dry --repo "$repo" --receipt "$TMP/missing.json" --parent "$parent_id" --dry-run --explain)"
assert_jq "$dry_out" '.status == "dry_run" and .action == "create"' "B06_AG1 dry-run plans create"
assert_jq "$dry_out" '.planned_actions[0].would_call_external[0] == "br" and (.planned_actions[0].br_argv | index("--dry-run"))' "B06_AG1 dry-run br create payload"
assert_jq "$dry_out" '.title | contains("[auto-fix:")' "B06_AG4 title carries idempotency marker"
if jq -e --arg parent "$parent_id" '.evidence.original_dispatch_id == "dispatch-missing" and (.dependency_refs | index("blocks:" + $parent))' "$dry_out" >/dev/null; then
  pass "B06_AG4 evidence and parent dependency"
else
  fail "B06_AG4 evidence and parent dependency"
  jq . "$dry_out" || true
fi

apply_no_key_out="$(run_helper apply-no-key --repo "$repo" --receipt "$TMP/missing.json" --parent "$parent_id" --apply)"
assert_rc "$(cat "$TMP/apply-no-key.rc")" "1" "B06_AG3 apply without idempotency key fails"
assert_jq "$apply_no_key_out" '.error == "--apply requires --idempotency-key"' "B06_AG3 explicit idempotency gate"

apply_out="$(run_helper apply --repo "$repo" --receipt "$TMP/missing.json" --parent "$parent_id" --apply --idempotency-key b06-test)"
assert_jq "$apply_out" '.status == "applied" and .action == "create" and .fix_bead_id != null' "B06_AG3 apply creates one fix bead"
assert_jq "$apply_out" '.audit_receipt.idempotency_key == "b06-test"' "B06_AG3 audit receipt written"

dup_out="$(run_helper duplicate --repo "$repo" --receipt "$TMP/missing.json" --parent "$parent_id" --dry-run --idempotency-key b06-test)"
assert_jq "$dup_out" '.status == "dry_run" and .action == "update_existing" and .existing_fix_bead != null' "B06_AG2 duplicate routes to update"

missing_callback_out="$(run_helper missing-callback --repo "$repo" --receipt "$TMP/missing-callback-field.json" --parent "$parent_id" --dry-run)"
assert_jq "$missing_callback_out" '.status == "dry_run" and .action == "create" and (.evidence.failure_classes | index("evidence_missing"))' "B06_AG7 missing callback field covered"

no_bead_out="$(run_helper no-bead --repo "$repo" --receipt "$TMP/runtime.json" --no-bead-reason "runtime probe stale")"
assert_jq "$no_bead_out" '.status == "dry_run" and .no_bead_reason == "runtime probe stale" and (.planned_actions | length) == 0' "B06_AG5 low-confidence no_bead_reason"

blocked_no_bead_out="$(run_helper blocked-no-bead --repo "$repo" --receipt "$TMP/missing.json" --no-bead-reason "skip critical")"
assert_rc "$(cat "$TMP/blocked-no-bead.rc")" "1" "B06_AG5 high-confidence no_bead_reason blocked"
assert_jq "$blocked_no_bead_out" '.error == "no_bead_reason_not_allowed_for_high_confidence_failure"' "B06_AG5 high-criticality cannot no-op"

schema_out="$(run_helper schema --repo "$repo" --schema)"
assert_jq "$schema_out" '.mutation_requires == ["--apply","--idempotency-key"] and .default_mode == "dry-run"' "B06 CLI schema documents mutation posture"

echo
echo "Summary: $pass_count passed, $fail_count failed"
[[ "$fail_count" -eq 0 ]]
