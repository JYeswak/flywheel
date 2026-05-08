#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
LOOP_MD="${LOOP_MD:-$HOME/.claude/commands/flywheel/loop.md}"
TMP="$(mktemp -d -t 19g3.XXXXXX)"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; find "$TMP" -mindepth 1 -delete 2>/dev/null || true; rmdir "$TMP" 2>/dev/null || true' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_contains() {
  local needle="$1" label="$2"
  if grep -Fq "$needle" "$LOOP_MD"; then
    pass "$label"
  else
    fail "$label"
  fi
}

test -s "$LOOP_MD" && pass "loop_md_exists" || fail "loop_md_exists"

rg -n "start|stop|status|revive|tier-help|active_high|active_normal|doctrine|inactive" "$LOOP_MD" >"$TMP/rg.txt"
test -s "$TMP/rg.txt" && pass "rg_coverage" || fail "rg_coverage"

assert_contains "/flywheel:loop start --dry-run --json" "dry_run_command_documented"
assert_contains "/flywheel:loop start --apply --json" "apply_command_documented"
assert_contains "live_pane_input_written" "dry_run_live_input_field"
assert_contains "planned_orchestrator_cadence" "planned_orchestrator_cadence_field"
assert_contains "planned_worker_cadence" "planned_worker_cadence_field"
assert_contains "schema_version\": \"flywheel-loop-state/v1" "state_schema_version_documented"
assert_contains "worker_cadence" "worker_cadence_documented"
assert_contains "registration_order\": \"before_activation" "registry_before_activation_documented"
assert_contains "reason=missing_flywheel_state" "missing_state_reason_documented"
assert_contains "reason=existing_loop_active" "existing_loop_reason_documented"
assert_contains "status=idempotent" "idempotent_reconcile_documented"
assert_contains "writing the loop state file does NOT activate a loop" "driver_not_marker_doctrine"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 13 ]]
