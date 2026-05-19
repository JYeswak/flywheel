#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HOOK="${CODEX_GOAL_FORMAT_HOOK:-$HOME/.claude/skills/codex-goal-format-enforcement/scripts/hook.sh}"
INSTALLER="$ROOT/.flywheel/scripts/install-goal-format-hook.sh"
AUDIT="$ROOT/.flywheel/scripts/codex-dispatch-format-audit.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-goal-format.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok() {
  local name="$1"
  shift
  if "$@"; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
  fi
}

ok_jq() {
  local name="$1" expr="$2" file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
    jq . "$file" >&2 || true
  fi
}

run_hook() {
  local session="$1" pane="$2" file="$3" out="$4" err="$5"
  jq -nc --arg cwd "$TMP/repo" --arg cmd "ntm send $session --pane=$pane --file=$file" \
    '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' \
    | CODEX_GOAL_FORMAT_TOPOLOGY="$TMP/session-topology.jsonl" \
      CODEX_GOAL_FORMAT_LEDGER="$TMP/repo/.flywheel/runtime/goal-format-override-ledger.jsonl" \
      bash "$HOOK" >"$out" 2>"$err"
}

mkdir -p "$TMP/repo/.flywheel/runtime"
git -C "$TMP/repo" init -q
jq -nc '{session:"fixture",effective_at:"2026-05-19T22:40:00Z",orchestrator_pane:1,orchestrator_kind:"claude",callback_pane:1,worker_panes:[2,3],worker_kinds:{"2":"codex","3":"claude"},shell_panes:[0],human_pane:0,expected_pane_count:4,registered_by:"fixture",notes:"goal format smoke"}' >"$TMP/session-topology.jsonl"

printf 'ordinary claude packet\n' >"$TMP/claude.md"
printf '/goal codex packet\nbody\n' >"$TMP/codex-goal.md"
printf 'ordinary codex packet\n' >"$TMP/codex-bad.md"
printf '/goal multiline packet\nsecond line\nthird line\n' >"$TMP/codex-multiline.md"

ok "hook syntax" bash -n "$HOOK"
ok "installer syntax" bash -n "$INSTALLER"
ok "audit syntax" bash -n "$AUDIT"

run_hook fixture 3 "$TMP/claude.md" "$TMP/claude.out" "$TMP/claude.err"
ok "claude pane dispatch with non-goal prefix passes" test ! -s "$TMP/claude.err"

run_hook fixture 2 "$TMP/codex-goal.md" "$TMP/codex-goal.out" "$TMP/codex-goal.err"
ok "codex pane dispatch with goal prefix passes" test ! -s "$TMP/codex-goal.err"

set +e
run_hook fixture 2 "$TMP/codex-bad.md" "$TMP/codex-bad.out" "$TMP/codex-bad.err"
bad_rc=$?
set -e
ok "codex pane dispatch with non-goal first line blocks" test "$bad_rc" -eq 1
ok "block message is actionable" grep -q "missing required '/goal ' prefix" "$TMP/codex-bad.err"
ok "block message names bypass env var" grep -q "CODEX_GOAL_FORMAT_BYPASS" "$TMP/codex-bad.err"

set +e
jq -nc --arg cwd "$TMP/repo" --arg cmd "ntm send fixture --pane=2 --file=$TMP/codex-bad.md" \
  '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' \
  | CODEX_GOAL_FORMAT_BYPASS=test-reason \
    CODEX_GOAL_FORMAT_TOPOLOGY="$TMP/session-topology.jsonl" \
    CODEX_GOAL_FORMAT_LEDGER="$TMP/repo/.flywheel/runtime/goal-format-override-ledger.jsonl" \
    bash "$HOOK" >"$TMP/bypass.out" 2>"$TMP/bypass.err"
bypass_rc=$?
set -e
ok "bypass allows codex non-goal dispatch" test "$bypass_rc" -eq 0
ok_jq "bypass writes audit ledger row" 'select(.session=="fixture" and .pane==2 and .reason=="test-reason" and (.file|endswith("codex-bad.md")))' "$TMP/repo/.flywheel/runtime/goal-format-override-ledger.jsonl"

set +e
jq -nc --arg cwd "$TMP/repo" --arg cmd "ntm send fixture --pane=2 --file=$TMP/codex-goal.md" \
  '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' \
  | CODEX_GOAL_FORMAT_TOPOLOGY="$TMP/missing-session-topology.jsonl" \
    bash "$HOOK" >"$TMP/missing.out" 2>"$TMP/missing.err"
missing_rc=$?
set -e
ok "session-topology read failure fails closed" test "$missing_rc" -eq 1
ok "fail-closed message names topology" grep -q "session-topology.jsonl read failed" "$TMP/missing.err"

run_hook fixture 2 "$TMP/codex-multiline.md" "$TMP/codex-multiline.out" "$TMP/codex-multiline.err"
ok "file with multi-line packet first line goal passes" test ! -s "$TMP/codex-multiline.err"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 && "$pass" -ge 6 ]]
