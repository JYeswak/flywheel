#!/usr/bin/env bash
set -uo pipefail

SCRIPT="${GOAL_BUILD_LIVE_BIN:-$HOME/.claude/skills/goal-build/bin/goal-build}"
SLASH="${GOAL_BUILD_SLASH_COMMAND:-$HOME/.claude/commands/goal-build.md}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/goal-build-live-canonical.XXXXXX")"
export GOAL_BUILD_GOALS_DIR="$TMP/goals"
export GOAL_BUILD_REPO_NAME="flywheel"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

valid_goal="$TMP/valid-goal.txt"
cat > "$valid_goal" <<'GOAL'
Flywheel Sprint Goal

Scope Clarifier
This is a sprint goal: closes in one day.

End-to-End Loop
1. Ingest: dispatch-log.jsonl rows.
2. Produce: closed bead evidence.
3. Measure: callback_received_at and br close receipt feed the next pick.

Canonical Gates
- A passing validation command is NOT success unless a dispatch-log.jsonl callback row exists.

Recent Progress Pattern
- .flywheel/dispatch-log.jsonl already records callback rows.
- .beads/issues.jsonl already records close state.
- tests/goal-build-live-canonical-cli.sh covers location validation.

The Plain English Version
This goal keeps the work pointed at closed, checkable outcomes. Success means Joshua can inspect one file and know where the goal lives.
GOAL

canonical_dir="$GOAL_BUILD_GOALS_DIR/flywheel"
mkdir -p "$canonical_dir"
canonical_goal="$canonical_dir/valid-goal.txt"
cp "$valid_goal" "$canonical_goal"

if bash -n "$SCRIPT"; then pass "bash syntax"; else fail "bash syntax"; fi

warn_err="$TMP/warn.err"
if "$SCRIPT" validate "$valid_goal" 2>"$warn_err" >/dev/null; then
  if grep -q "WARN: .*outside canonical goal directory .*flywheel/" "$warn_err"; then
    pass "PASS-validate /tmp emits WARN and exits 0"
  else
    fail "PASS-validate /tmp missing WARN"
  fi
else
  fail "PASS-validate /tmp should exit 0"
fi

strict_err="$TMP/strict.err"
"$SCRIPT" validate --strict "$valid_goal" 2>"$strict_err" >/dev/null
strict_rc=$?
if [[ "$strict_rc" == "7" ]] && grep -q "location violation" "$strict_err"; then
  pass "strict outside canonical exits 7"
else
  fail "strict outside canonical expected rc=7 got rc=$strict_rc"
fi

canonical_err="$TMP/canonical.err"
if "$SCRIPT" validate --strict "$canonical_goal" 2>"$canonical_err" >/dev/null; then
  if [[ ! -s "$canonical_err" ]]; then
    pass "canonical strict validate stays silent"
  else
    fail "canonical strict validate emitted stderr"
  fi
else
  fail "canonical strict validate should pass"
fi

json_out="$TMP/strict.json"
if "$SCRIPT" validate --strict "$valid_goal" --json >"$json_out" 2>/dev/null; then
  fail "strict JSON outside canonical should exit 7"
else
  rc=$?
  if [[ "$rc" == "7" ]] && jq -e '.exit_code == 7 and .canonical_location.violation == true and .canonical_location.strict == true' "$json_out" >/dev/null; then
    pass "strict JSON reports location violation"
  else
    fail "strict JSON violation envelope"
  fi
fi

if "$SCRIPT" help exit-codes | grep -q "7  location violation"; then
  pass "exit-code table includes 7"
else
  fail "exit-code table missing 7"
fi

if grep -q 'validate.*--strict' "$SLASH"; then
  pass "/goal-build slash command defaults validate to strict"
else
  fail "/goal-build slash command missing strict validate default"
fi

printf 'Summary: %d passed, %d failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
