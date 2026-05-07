#!/usr/bin/env bash
set -euo pipefail

LOOP_MD="${LOOP_MD:-$HOME/.claude/commands/loop.md}"
REPO_PATH="${REPO_PATH:-/tmp/flywheel-loop-monitor-fixture}"
SESSION_NAME="${SESSION_NAME:-flywheel}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local needle="$1"
  local file="$2"
  grep -Fq -- "$needle" "$file" || fail "missing required text: $needle"
}

fake_ntm_robot_activity() {
  case "${1:-thinking}" in
    thinking)
      cat <<'JSON'
{"session":"flywheel","agents":[{"pane":2,"runtime":"codex","state":"THINKING"}]}
JSON
      ;;
    idle)
      cat <<'JSON'
{"session":"flywheel","agents":[{"pane":2,"runtime":"codex","state":"WAITING"}]}
JSON
      ;;
    *)
      fail "unknown fake activity fixture: $1"
      ;;
  esac
}

has_thinking_worker() {
  fake_ntm_robot_activity "$1" | jq -e '.agents[] | select(.state == "THINKING")' >/dev/null
}

monitor_already_armed() {
  local tasklist_fixture="$1"
  grep -Fq "${REPO_PATH}/.flywheel/dispatch-log.jsonl" "$tasklist_fixture" &&
    grep -Fq '"event":"callback"' "$tasklist_fixture"
}

planned_monitor_command() {
  local activity_fixture="$1"
  local tasklist_fixture="$2"

  if has_thinking_worker "$activity_fixture" && ! monitor_already_armed "$tasklist_fixture"; then
    printf "tail -F %s/.flywheel/dispatch-log.jsonl | grep --line-buffered '\\\"event\\\":\\\"callback\\\"'\n" "$REPO_PATH"
  fi
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/no_tasks.txt"
cat >"$tmpdir/monitor_tasks.txt" <<EOF_TASKS
Task 12 Monitor persistent true tail -F ${REPO_PATH}/.flywheel/dispatch-log.jsonl | grep --line-buffered '"event":"callback"'
EOF_TASKS

assert_contains 'feedback_orch_wake_event_driven_not_time_based' "$LOOP_MD"
assert_contains 'allowed-tools: Bash, Read, Edit, Write, Skill, TaskList, Monitor, ScheduleWakeup' "$LOOP_MD"
assert_contains 'ntm --robot-activity=<session> --activity-type=codex,claude' "$LOOP_MD"
assert_contains "tail -F <repo>/.flywheel/dispatch-log.jsonl | grep --line-buffered '\\\"event\\\":\\\"callback\\\"'" "$LOOP_MD"
assert_contains 'ScheduleWakeup` is the FALLBACK heartbeat only' "$LOOP_MD"
assert_contains '_Wake: event-driven via dispatch-log Monitor (task <id>); fallback heartbeat 1800s_' "$LOOP_MD"
assert_contains 'Worker callback append to orchestrator callback reap should be <=30s' "$LOOP_MD"
assert_contains 'gap exceeds 2min' "$LOOP_MD"
assert_contains '<task-notification>' "$LOOP_MD"

cmd="$(planned_monitor_command thinking "$tmpdir/no_tasks.txt")"
[[ -n "$cmd" ]] || fail "workers THINKING should arm Monitor"
[[ "$cmd" == *"${REPO_PATH}/.flywheel/dispatch-log.jsonl"* ]] || fail "Monitor command missing dispatch log path"
[[ "$cmd" == *'"event":"callback"'* ]] || fail "Monitor command missing callback matcher"

cmd="$(planned_monitor_command idle "$tmpdir/no_tasks.txt")"
[[ -z "$cmd" ]] || fail "idle workers should not arm Monitor"

cmd="$(planned_monitor_command thinking "$tmpdir/monitor_tasks.txt")"
[[ -z "$cmd" ]] || fail "existing TaskList Monitor should prevent duplicate"

printf 'PASS: loop dynamic mode Monitor contract fixture (%s, session=%s)\n' "$LOOP_MD" "$SESSION_NAME"
