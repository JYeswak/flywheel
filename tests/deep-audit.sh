#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/deep-audit"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/deep-audit.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
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

cat >"$TMP/cross-repo.json" <<'JSON'
{
  "autoloop_receipts": [
    {"repo": "/repo/a", "doctor_status": "warn"},
    {"repo": "/repo/a", "doctor_status": "fail"}
  ],
  "fuckup_rows": [
    {"repo": "/repo/a", "trauma_class": "repeat-dispatch-drift", "id": "a1"},
    {"repo": "/repo/b", "trauma_class": "repeat-dispatch-drift", "id": "b1"},
    {"repo": "/repo/b", "trauma_class": "repeat-dispatch-drift", "id": "b2"}
  ],
  "tick_violations": [
    {"repo": "/repo/a", "check": "worker-low-socraticode"},
    {"repo": "/repo/a", "check": "worker-low-socraticode"},
    {"repo": "/repo/a", "check": "worker-low-socraticode"}
  ],
  "incidents_deltas": [
    {"repo": "/repo/a", "trauma_class": "repeat-dispatch-drift"}
  ]
}
JSON

cat >"$TMP/single-repo.json" <<'JSON'
{
  "fuckup_rows": [
    {"repo": "/repo/solo", "trauma_class": "solo-drift", "id": "s1"},
    {"repo": "/repo/solo", "trauma_class": "solo-drift", "id": "s2"},
    {"repo": "/repo/solo", "trauma_class": "solo-drift", "id": "s3"}
  ],
  "existing_beads": {"solo-drift": "solo-123"}
}
JSON

cat >"$TMP/budget.json" <<'JSON'
{
  "simulated_elapsed_minutes": 61,
  "fuckup_rows": [
    {"repo": "/repo/a", "trauma_class": "budget-drift", "id": "b1"}
  ]
}
JSON

python3 -m py_compile "$BIN" && pass "syntax"

"$BIN" --help >"$TMP/help.txt"
rg -q 'AUTOLOOP RECEIPT REVIEW' "$TMP/help.txt"
rg -q 'FUCKUP-LOG CROSS-REPO AGGREGATE' "$TMP/help.txt"
rg -q 'TICK-CONTRACT VIOLATION RATE' "$TMP/help.txt"
rg -q 'GAP-TO-BEADS' "$TMP/help.txt"
pass "help_describes_8_step_contract"

"$BIN" --dry-run --json --fixture "$TMP/cross-repo.json" --now "2026-05-08T00:00:00Z" >"$TMP/cross.json"
assert_jq "$TMP/cross.json" '.status == "planned" and .duration_budget_minutes == 60 and (.steps | length) == 8 and all(.steps[]; (.planned_actions | length) >= 1)' "dry_run_emits_8_steps_budget_actions"
assert_jq "$TMP/cross.json" '.fuckup_log_cross_repo_aggregate.promotion_candidates[] | select(.action == "planned_canonical_l_rule_promotion_bead" and .trauma_class == "repeat-dispatch-drift" and .repo_count == 2)' "cross_repo_repeated_trauma_plans_canonical_bead"
assert_jq "$TMP/cross.json" '.tick_contract_violation_rate.graduation_candidates[] | select(.check == "worker-low-socraticode" and .count == 3)' "tick_violation_rate_graduation_candidate"
assert_jq "$TMP/cross.json" '.docs_sync_lock.docs_sync_status == "planned" and .docs_sync_lock.lock_status == "planned" and (.docs_sync_lock.next_scheduled_doctrine_tick | test("2026-05-08T12:00:00Z"))' "receipt_records_docs_sync_lock_next_tick"

"$BIN" --dry-run --json --fixture "$TMP/single-repo.json" >"$TMP/single.json"
assert_jq "$TMP/single.json" '(.fuckup_log_cross_repo_aggregate.promotion_candidates | length) == 0' "single_repo_no_canonical_promotion"
assert_jq "$TMP/single.json" '.fuckup_log_cross_repo_aggregate.repo_orchestrator_deferrals[] | select(.trauma_class == "solo-drift" and .existing_bead == "solo-123")' "single_repo_existing_bead_reference"

"$BIN" --dry-run --json --fixture "$TMP/budget.json" --budget-minutes 60 >"$TMP/budget.json.out"
assert_jq "$TMP/budget.json.out" '.status == "handoff" and .budget_exceeded == true and .handoff_receipt.reason == "duration_budget_exceeded" and .docs_sync_lock.docs_sync_status == "deferred_budget_exceeded"' "budget_exceeded_handoff_receipt"

"$BIN" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "flywheel.deep-audit.v1" and (.step_names | length) == 8' "schema_json"

printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
