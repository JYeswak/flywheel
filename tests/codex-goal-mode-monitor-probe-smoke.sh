#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-goal-mode-monitor-probe.sh"
FIX="$ROOT/tests/fixtures/codex-goal-mode"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-goal-mode-probe.XXXXXX")"
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
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name" >&2
  fi
}

ok_jq() {
  local name="$1" expr="$2" file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name" >&2
    [[ -f "$file" ]] && cat "$file" >&2
  fi
}

env_base=(
  CODEX_GOAL_MODE_SESSION=fixture
  CODEX_GOAL_MODE_STATE_DIR="$TMP/state"
  CODEX_GOAL_MODE_TRAUMA_LOG="$TMP/trauma.jsonl"
  CODEX_GOAL_MODE_UNKNOWN_LOG="$TMP/unknown.jsonl"
  CODEX_GOAL_MODE_BYPASS_AUDIT="$TMP/bypass.jsonl"
)

ok "probe syntax" bash -n "$SCRIPT"

env "${env_base[@]}" CODEX_GOAL_MODE_CAPTURE_FILE="$FIX/goal-in-progress.txt" \
  "$SCRIPT" --pane 2 --dispatch-id d-entry-ok --layer 2 --max-entry-wait-s 0 --json >"$TMP/entry-ok.json"
ok_jq "Layer 2 goal-in-progress exits ok" '.status == "ok" and .state == "goal-in-progress"' "$TMP/entry-ok.json"

set +e
env "${env_base[@]}" CODEX_GOAL_MODE_CAPTURE_FILE="$FIX/idle-chat.txt" \
  "$SCRIPT" --pane 2 --dispatch-id d-entry-fail --layer 2 --max-entry-wait-s 0 --json >"$TMP/entry-fail.json"
rc=$?
set -e
ok "Layer 2 idle-chat fires trauma rc=1" test "$rc" -eq 1
ok_jq "Layer 2 trauma class is codex-goal-entry-failed" 'select(.trauma_class == "codex-goal-entry-failed" and .dispatch_id == "d-entry-fail")' "$TMP/trauma.jsonl"

hist="$TMP/state/state-history-d-resume.jsonl"
mkdir -p "$(dirname "$hist")"
jq -nc '{ts:"2026-05-20T00:00:00Z",state:"goal-in-progress"}' >"$hist"
jq -nc '{ts:"2026-05-20T00:00:01Z",state:"goal-paused"}' >>"$hist"
set +e
env "${env_base[@]}" CODEX_GOAL_MODE_NOW="2026-05-20T00:02:05Z" CODEX_GOAL_MODE_CAPTURE_FILE="$FIX/goal-paused.txt" \
  "$SCRIPT" --pane 2 --dispatch-id d-resume --layer 3 --json >"$TMP/resume.json"
rc=$?
set -e
ok "Layer 3 goal-paused 120s fires resume-stuck rc=1" test "$rc" -eq 1
ok_jq "resume-stuck trauma written" 'select(.trauma_class == "codex-goal-resume-stuck" and .dispatch_id == "d-resume")' "$TMP/trauma.jsonl"

hist="$TMP/state/state-history-d-abandoned.jsonl"
jq -nc '{ts:"2026-05-20T00:03:00Z",state:"goal-in-progress"}' >"$hist"
set +e
env "${env_base[@]}" CODEX_GOAL_MODE_NOW="2026-05-20T00:03:10Z" CODEX_GOAL_MODE_CAPTURE_FILE="$FIX/working-non-goal.txt" \
  "$SCRIPT" --pane 2 --dispatch-id d-abandoned --layer 3 --json >"$TMP/abandoned.json"
rc=$?
set -e
ok "Layer 3 mode regression fires abandoned rc=1" test "$rc" -eq 1
ok_jq "abandoned trauma written" 'select(.trauma_class == "codex-goal-abandoned" and .dispatch_id == "d-abandoned")' "$TMP/trauma.jsonl"

hist="$TMP/state/state-history-d-flap.jsonl"
jq -nc '{ts:"2026-05-20T00:04:00Z",state:"goal-in-progress"}' >"$hist"
jq -nc '{ts:"2026-05-20T00:04:20Z",state:"goal-paused"}' >>"$hist"
jq -nc '{ts:"2026-05-20T00:04:40Z",state:"goal-in-progress"}' >>"$hist"
set +e
env "${env_base[@]}" CODEX_GOAL_MODE_NOW="2026-05-20T00:05:00Z" CODEX_GOAL_MODE_CAPTURE_FILE="$FIX/goal-paused.txt" \
  "$SCRIPT" --pane 2 --dispatch-id d-flap --layer 3 --flap-threshold 3 --flap-window-s 240 --json >"$TMP/flap.json"
rc=$?
set -e
ok "Layer 3 flap threshold fires rc=1" test "$rc" -eq 1
ok_jq "flapping trauma written" 'select(.trauma_class == "codex-goal-mode-flapping" and .dispatch_id == "d-flap")' "$TMP/trauma.jsonl"

set +e
env "${env_base[@]}" CODEX_GOAL_MODE_CAPTURE_FILE="$FIX/idle-chat.txt" \
  "$SCRIPT" --pane 2 --dispatch-id d-bypass-mode --layer 4 --json >"$TMP/mode-bypassed.json"
rc=$?
set -e
ok "Layer 4 callback without goal history fires rc=1" test "$rc" -eq 1
ok_jq "mode-bypassed trauma written" 'select(.trauma_class == "codex-goal-mode-bypassed" and .dispatch_id == "d-bypass-mode")' "$TMP/trauma.jsonl"

set +e
env "${env_base[@]}" CODEX_GOAL_MODE_CAPTURE_FILE="$FIX/respawn-residue.txt" \
  "$SCRIPT" --pane 2 --dispatch-id d-respawn --layer 2 --max-entry-wait-s 0 --json >"$TMP/respawn.json"
rc=$?
set -e
ok "respawn-residue suppresses with defer rc=2" test "$rc" -eq 2
ok_jq "respawn state reported" '.status == "defer" and .state == "respawn-residue"' "$TMP/respawn.json"

set +e
env "${env_base[@]}" CODEX_GOAL_FORMAT_BYPASS=test-reason CODEX_GOAL_MODE_CAPTURE_FILE="$FIX/idle-chat.txt" \
  "$SCRIPT" --pane 2 --dispatch-id d-bypass --layer 2 --max-entry-wait-s 0 --json >"$TMP/bypass.json"
rc=$?
set -e
ok "CODEX_GOAL_FORMAT_BYPASS suppresses trauma rc=0" test "$rc" -eq 0
ok_jq "bypass audit row written" 'select(.schema_version == "codex_goal_mode_bypass_audit.v1" and .dispatch_id == "d-bypass" and .reason == "test-reason")' "$TMP/bypass.jsonl"
ok_jq "bypass reported by probe" '.status == "bypassed"' "$TMP/bypass.json"

set +e
env "${env_base[@]}" CODEX_GOAL_MODE_CAPTURE_FILE="$FIX/unknown.txt" \
  "$SCRIPT" --pane 2 --dispatch-id d-unknown --layer 2 --max-entry-wait-s 0 --json >"$TMP/unknown.json"
rc=$?
set -e
ok "unknown fall-through exits rc=3" test "$rc" -eq 3
ok_jq "unknown telemetry written" 'select(.schema_version == "codex_goal_mode_unknown_state.v1" and .dispatch_id == "d-unknown")' "$TMP/unknown.jsonl"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 && "$pass" -ge 8 ]]
