#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WRAPPER="$ROOT/.flywheel/scripts/flywheel-dispatch-wrapper.sh"
DAEMON="$ROOT/.flywheel/scripts/codex-goal-mode-monitor-daemon.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-dispatch-wrapper.XXXXXX")"
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

fake_ntm="$TMP/ntm"
cat >"$fake_ntm" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_LOG:?}"
FAKE
chmod +x "$fake_ntm"

printf '/goal wrapper fixture\nbody\n' >"$TMP/goal.md"
printf 'non goal fixture\n' >"$TMP/non-goal.md"
mkdir -p "$TMP/state" "$TMP/evidence"

env_common=(
  FLYWHEEL_NTM_BIN="$fake_ntm"
  FAKE_NTM_LOG="$TMP/ntm.log"
  FLYWHEEL_DISPATCH_LOG="$TMP/dispatch-log.jsonl"
  CODEX_GOAL_MODE_STATE_DIR="$TMP/state"
  CODEX_GOAL_MODE_TRAUMA_LOG="$TMP/trauma.jsonl"
  CODEX_GOAL_MODE_BYPASS_AUDIT="$TMP/bypass.jsonl"
  CODEX_GOAL_MODE_CAPTURE_FILE="$ROOT/tests/fixtures/codex-goal-mode/goal-in-progress.txt"
  CODEX_GOAL_MODE_WRAPPER_FOREGROUND_PROBE=1
)

ok "wrapper syntax" bash -n "$WRAPPER"
ok "daemon syntax" bash -n "$DAEMON"

env "${env_common[@]}" "$WRAPPER" --session fixture --pane 2 --file "$TMP/goal.md" --dispatch-id d-wrap --probe-max-entry-wait-s 0 --json >"$TMP/wrapper.json"
ok_jq "valid goal dispatch writes monitor_probe_id" 'select(.dispatch_id == "d-wrap" and (.monitor_probe_id | length > 10))' "$TMP/wrapper.json"
ok_jq "dispatch-log row has monitor_probe_id" 'select(.dispatch_id == "d-wrap" and (.monitor_probe_id | length > 10) and .goal_mode_trauma_fired == [])' "$TMP/dispatch-log.jsonl"
ok_jq "Layer 2 probe ran after dispatch" 'select(.dispatch_id == "d-wrap" and .state == "goal-in-progress")' "$TMP/state/state-history-d-wrap.jsonl"

env "${env_common[@]}" CODEX_GOAL_MODE_CAPTURE_FILE="$ROOT/tests/fixtures/codex-goal-mode/goal-in-progress.txt" \
  "$DAEMON" --repo "$TMP" --dispatch-log "$TMP/dispatch-log.jsonl" --once --json >"$TMP/daemon.json"
ok_jq "Layer 3 daemon picks up monitored dispatch" '.in_flight_count == 1 and .rows[0].dispatch_id == "d-wrap"' "$TMP/daemon.json"
ok_jq "Layer 3 probe appended history" 'select(.dispatch_id == "d-wrap" and .layer == 3 and .state == "goal-in-progress")' "$TMP/state/state-history-d-wrap.jsonl"

set +e
env "${env_common[@]}" CODEX_GOAL_MODE_CAPTURE_FILE="$ROOT/tests/fixtures/codex-goal-mode/idle-chat.txt" \
  "$WRAPPER" --callback --session fixture --pane 2 --dispatch-id d-callback --json >"$TMP/callback.json"
rc=$?
set -e
ok "callback write triggers Layer 4 synchronously rc=1" test "$rc" -eq 1
ok_jq "Layer 4 trauma written for callback without history" 'select(.dispatch_id == "d-callback" and .trauma_class == "codex-goal-mode-bypassed")' "$TMP/trauma.jsonl"

env "${env_common[@]}" CODEX_GOAL_FORMAT_BYPASS=test CODEX_GOAL_MODE_CAPTURE_FILE="$ROOT/tests/fixtures/codex-goal-mode/idle-chat.txt" \
  "$WRAPPER" --session fixture --pane 2 --file "$TMP/non-goal.md" --dispatch-id d-bypass-wrap --probe-max-entry-wait-s 0 --foreground-probe --json >"$TMP/bypass-wrapper.json"
ok_jq "non-goal synthetic bypass audit row written" 'select(.dispatch_id == "d-bypass-wrap" and .reason == "test" and .schema_version == "codex_goal_mode_bypass_audit.v1")' "$TMP/bypass.jsonl"
ok_jq "bypass dispatch still writes monitor_probe_id" 'select(.dispatch_id == "d-bypass-wrap" and (.monitor_probe_id | length > 10))' "$TMP/dispatch-log.jsonl"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 && "$pass" -ge 4 ]]
