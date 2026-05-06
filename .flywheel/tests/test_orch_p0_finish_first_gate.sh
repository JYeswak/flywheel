#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/orch-p0-completion-gate.sh"
HOOK="${ORCH_P0_HOOK:-$HOME/.claude/hooks/flywheel-orch-p0-finish-first-gate.sh}"
FIXTURES="$ROOT/.flywheel/tests/fixtures/orch-p0-gate"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/orch-p0-gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else jq . "$file" >&2 || true; fail "$label"; fi
}

run_case() {
  local name="$1" fixture="$2" expected_rc="$3" command="${4:-br create fixture}"
  local out="$TMP/$name.json" before after
  before="$(shasum -a 256 "$fixture" | awk '{print $1}')"
  set +e
  "$SCRIPT" check --issues-jsonl "$fixture" --command "$command" --orch-id flywheel:1 --now-epoch 86400 --json >"$out"
  rc=$?
  set -e
  after="$(shasum -a 256 "$fixture" | awk '{print $1}')"
  [[ "$rc" -eq "$expected_rc" ]] || { cat "$out" >&2 || true; fail "$name rc=$rc expected=$expected_rc"; }
  [[ "$before" == "$after" ]] || fail "$name fixture_mutated"
  jq empty "$out" >/dev/null || fail "$name json_parse"
  pass "$name rc_and_read_only"
}

bash -n "$SCRIPT" && pass "detector_syntax"
bash -n "$HOOK" && pass "hook_syntax"
"$SCRIPT" --help >/dev/null && pass "help"
"$SCRIPT" --info | jq -e '.read_only == true and .exit_codes."1" == "block"' >/dev/null && pass "info_json"
"$SCRIPT" --examples | grep -q -- 'br create' && pass "examples"

run_case zero "$FIXTURES/zero.jsonl" 0
assert_jq "$TMP/zero.json" '.decision == "allow" and .reason == "no_owned_unfinished_p0"' "case_zero_allowed"

run_case one_current "$FIXTURES/one-current.jsonl" 1
assert_jq "$TMP/one_current.json" '.decision == "block" and .oldest_unfinished_p0.id == "fixture-p0-current" and .oldest_unfinished_p0.age_seconds == 86400' "case_one_current_blocked_with_age"

run_case one_other "$FIXTURES/one-other.jsonl" 0
assert_jq "$TMP/one_other.json" '.decision == "allow" and .reason == "no_owned_unfinished_p0"' "case_other_orch_allowed"

run_case two_current "$FIXTURES/two-current.jsonl" 1
assert_jq "$TMP/two_current.json" '.decision == "block" and .unfinished_p0_count == 2 and .oldest_unfinished_p0.id == "fixture-p0-oldest"' "case_two_reports_oldest"

run_case malformed "$FIXTURES/malformed.jsonl" 2
assert_jq "$TMP/malformed.json" '.decision == "error" and .reason == "malformed_jsonl" and .exit_code == 2' "case_malformed_no_false_block"

run_case downgrade "$FIXTURES/one-current.jsonl" 1 "br update fixture-p0-current --priority 1"
assert_jq "$TMP/downgrade.json" '.decision == "block" and .command_action == "p0_downgrade"' "case_priority_downgrade_blocked"

repo="$TMP/repo"
mkdir -p "$repo/.beads"
git -C "$repo" init -q
cp "$FIXTURES/one-current.jsonl" "$repo/.beads/issues.jsonl"
hook_input="$(jq -nc --arg cwd "$repo" --arg cmd 'br create hook-fixture' '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}')"
printf '%s\n' "$hook_input" | ORCH_P0_GATE_BIN="$SCRIPT" TICK_SESSION_ID=flywheel TICK_PANE_ID=1 "$HOOK" >"$TMP/hook-block.json"
assert_jq "$TMP/hook-block.json" '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | test("fixture-p0-current"))' "hook_blocks_create"

printf 'PASS cases=5 detector_cases_plus_hook assertions=%s failures=0\n' "$pass_count"
