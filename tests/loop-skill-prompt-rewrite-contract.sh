#!/usr/bin/env bash
# tests/loop-skill-prompt-rewrite-contract.sh
#
# Smoke test for flywheel-msixq: verify /loop SKILL.md dynamic-mode step 3
# encodes the prompt-rewrite-from-state contract (state checkpoint, not script
# replay). The /loop command is interpreted by an agent reading the markdown,
# so this contract is testable as required substring/structure presence in the
# canonical command file.
#
# AG2 smoke test path: stale args (referencing a closed bead) → next /loop
# re-entry shows fresh state. The contract that guarantees "shows fresh state"
# is the doctrine directive in step 3; this test verifies the directive is
# present and unambiguous.

set -euo pipefail

LOOP_MD="${LOOP_MD:-$HOME/.claude/commands/loop.md}"

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

[[ -f "$LOOP_MD" ]] || fail "loop.md not found at $LOOP_MD"
pass "loop.md exists at $LOOP_MD"

# 1. Step 3 must contain the canonical "state checkpoint, not a script replay" framing.
grep -qE 'wake-?up is a state checkpoint, not a script replay' "$LOOP_MD" \
  || fail "loop.md step 3 missing 'wake-up is a state checkpoint, not a script replay' framing"
pass "step 3 names the state-checkpoint-not-script-replay rule"

# 2. Step 3 must explicitly forbid replaying original /loop arguments.
grep -qiE '(never replay|do not replay).*(originally-captured|original).*(/loop arguments|\$ARGUMENTS|argument)' "$LOOP_MD" \
  || fail "loop.md step 3 missing the forbid-replay-of-original-arguments rule"
pass "step 3 forbids replay of originally-captured arguments"

# 3. Step 3 must source pane state from ntm --robot-activity.
grep -qE 'ntm --robot-activity' "$LOOP_MD" \
  || fail "loop.md step 3 missing the ntm --robot-activity source for pane state"
pass "step 3 sources pane state from ntm --robot-activity"

# 4. Step 3 must source in-flight task IDs from dispatch-log tail.
grep -qE 'dispatch-log\.jsonl' "$LOOP_MD" \
  || fail "loop.md step 3 missing the dispatch-log.jsonl source for in-flight task IDs"
pass "step 3 sources in-flight task IDs from dispatch-log.jsonl"

# 5. Step 3 must source open/ready beads from br ready.
grep -qE 'br ready' "$LOOP_MD" \
  || fail "loop.md step 3 missing the 'br ready' source for open beads"
pass "step 3 sources open/ready beads from br ready"

# 6. Negative: a literal "$ARGUMENTS" passthrough into ScheduleWakeup must not be advised.
# (The string $ARGUMENTS is referenced earlier in the file as the input macro,
# but it must NOT be re-armed verbatim into a wake prompt.)
if grep -B 2 -A 2 -E 'ScheduleWakeup' "$LOOP_MD" | grep -qE 'prompt:.*\$ARGUMENTS'; then
  fail "loop.md ScheduleWakeup section appears to advise replaying \$ARGUMENTS verbatim"
fi
pass "ScheduleWakeup section does not advise replaying \$ARGUMENTS verbatim"

# 7. Synthetic stale-args scenario:
#   simulate a captured /loop invocation that names a closed bead, and verify
#   the doctrine directs the agent to drop the closed-bead reference instead
#   of replaying it.
if ! grep -qE 'closed.*drop|drop that reference|since closed' "$LOOP_MD"; then
  fail "loop.md missing explicit guidance for closed-bead references in stale prompts"
fi
pass "step 3 directs the agent to drop references to since-closed beads"

# 8. Provenance: the amendment cites the peer finding and memory rule that
# motivated it (auditability for future reviewers).
grep -qE 'alpsinsurance:1.*2026-05-08|feedback_orch_wake_event_driven_not_time_based' "$LOOP_MD" \
  || fail "loop.md amendment missing peer-finding/memory-rule provenance"
pass "amendment cites peer finding and memory rule provenance"

printf 'loop-skill-prompt-rewrite-contract tests passed\n'
