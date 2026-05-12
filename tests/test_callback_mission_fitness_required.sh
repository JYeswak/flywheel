#!/usr/bin/env bash
# test_callback_mission_fitness_required.sh
# Verifies that worker DONE callbacks missing mission_fitness= are rejected
# as malformed (orch_callback_missing_mission_fitness).
#
# canonical-cli-scoping: exit 0=all pass, 1=at least one FAIL, 2=usage error
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WORKER_TICK_MD="$HOME/.claude/commands/flywheel/worker-tick.md"
DISPATCH_TEMPLATE_MD="$HOME/.claude/commands/flywheel/_shared/dispatch-template.md"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

grep_file() {
  local file="$1" pattern="$2" label="$3"
  if grep -q "$pattern" "$file" 2>/dev/null; then pass "$label"; else fail "$label"; fi
}

# ── Test 1: worker-tick.md DONE callback includes mission_fitness= field ──────
grep_file "$WORKER_TICK_MD" "mission_fitness=" \
  "worker_tick/done_callback_includes_mission_fitness_field"

# ── Test 2: worker-tick.md explicitly rejects missing field as malformed ──────
grep_file "$WORKER_TICK_MD" "orch_callback_missing_mission_fitness" \
  "worker_tick/rejects_missing_mission_fitness_as_malformed"

# ── Test 3: worker-tick.md BLOCKED callback also includes mission_fitness= ────
# The BLOCKED callback block must also carry the field.
BLOCKED_SECTION="$(awk '/BLOCKED.*task_id/,/callback_delivery_verified/' "$WORKER_TICK_MD" 2>/dev/null || true)"
if printf '%s\n' "$BLOCKED_SECTION" | grep -q "mission_fitness="; then
  pass "worker_tick/blocked_callback_includes_mission_fitness_field"
else
  fail "worker_tick/blocked_callback_includes_mission_fitness_field"
fi

# ── Test 4: valid values are direct|adjacent|infrastructure|drift ─────────────
grep_file "$WORKER_TICK_MD" "direct|adjacent|infrastructure|drift" \
  "worker_tick/mission_fitness_valid_values_documented"

# ── Test 5: drift callbacks require mission_override_reason ───────────────────
grep_file "$WORKER_TICK_MD" "mission_override_reason" \
  "worker_tick/drift_callbacks_require_override_reason"

# ── Test 6: dispatch-template.md DONE contract requires mission_fitness_claim ─
grep_file "$DISPATCH_TEMPLATE_MD" "mission_fitness_claim" \
  "dispatch_template/callback_validation_block_requires_mission_fitness_claim"

# ── Test 7: dispatch-template.md rejects missing mission_fitness as malformed ──
grep_file "$DISPATCH_TEMPLATE_MD" "orch_callback_missing_mission_fitness" \
  "dispatch_template/rejects_missing_mission_fitness_as_malformed"

# ── Test 8: dispatch-template.md mission_fitness_class field present ──────────
grep_file "$DISPATCH_TEMPLATE_MD" "mission_fitness_class" \
  "dispatch_template/mission_fitness_class_field_present"

# ── Summary ───────────────────────────────────────────────────────────────────
printf '\n%s\n' "─────────────────────────────────────"
printf 'Results: %d PASS  %d FAIL\n' "$pass_count" "$fail_count"

[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
