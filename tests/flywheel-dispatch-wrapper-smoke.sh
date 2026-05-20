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

fake_activate="$TMP/codex-goal-activate"
cat >"$fake_activate" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
task_file=""
printf '%s\n' "$*" >>"${FAKE_GOAL_ACTIVATE_LOG:?}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-file) task_file="$2"; shift 2 ;;
    --task-file=*) task_file="${1#*=}"; shift ;;
    *) shift ;;
  esac
done
[[ -n "$task_file" ]] && cat "$task_file" >"${FAKE_GOAL_DIRECTIVE:?}"
printf '{"schema_version":"codex_goal_activate.v1","outcome":"ok","stage":"stage5"}\n'
FAKE
chmod +x "$fake_activate"

printf '/goal wrapper fixture\nbody\n' >"$TMP/goal.md"
printf 'non goal fixture\n' >"$TMP/non-goal.md"
mkdir -p "$TMP/state" "$TMP/evidence" "$TMP/dispatches"
jq -nc '{session:"fixture",effective_at:"2026-05-20T01:00:00Z",orchestrator_pane:1,orchestrator_kind:"claude",callback_pane:1,worker_panes:[2,3,4],worker_kinds:{"2":"codex","3":"claude","4":"cc"},shell_panes:[0],human_pane:0}' >"$TMP/session-topology.jsonl"

env_common=(
  FLYWHEEL_NTM_BIN="$fake_ntm"
  CODEX_GOAL_ACTIVATE="$fake_activate"
  CODEX_GOAL_PAYLOAD_DIR="$TMP/dispatches"
  FLYWHEEL_SESSION_TOPOLOGY="$TMP/session-topology.jsonl"
  FAKE_NTM_LOG="$TMP/ntm.log"
  FAKE_GOAL_ACTIVATE_LOG="$TMP/goal-activate.log"
  FAKE_GOAL_DIRECTIVE="$TMP/goal-directive.txt"
  FLYWHEEL_DISPATCH_LOG="$TMP/dispatch-log.jsonl"
  CODEX_GOAL_MODE_STATE_DIR="$TMP/state"
  CODEX_GOAL_MODE_TRAUMA_LOG="$TMP/trauma.jsonl"
  CODEX_GOAL_MODE_BYPASS_AUDIT="$TMP/bypass.jsonl"
  CODEX_GOAL_MODE_CAPTURE_FILE="$ROOT/tests/fixtures/codex-goal-mode/goal-in-progress.txt"
  CODEX_GOAL_MODE_WRAPPER_FOREGROUND_PROBE=1
)

ok "wrapper syntax" bash -n "$WRAPPER"
ok "daemon syntax" bash -n "$DAEMON"

env "${env_common[@]}" "$WRAPPER" --session fixture --pane 2 --file "$TMP/goal.md" --dispatch-id d-wrap --probe-max-entry-wait-s 30 --json >"$TMP/wrapper.json"
ok_jq "valid goal dispatch writes monitor_probe_id" 'select(.dispatch_id == "d-wrap" and (.monitor_probe_id | length > 10))' "$TMP/wrapper.json"
ok_jq "dispatch-log row has monitor_probe_id" 'select(.dispatch_id == "d-wrap" and (.monitor_probe_id | length > 10) and .goal_mode_trauma_fired == [])' "$TMP/dispatch-log.jsonl"
ok_jq "dispatch-log row records topology codex agent type" 'select(.dispatch_id == "d-wrap" and .agent_type == "codex" and .agent_type_source == "topology")' "$TMP/dispatch-log.jsonl"
ok "codex dispatch uses activation primitive" test -s "$TMP/goal-activate.log"
ok "codex dispatch does not use raw ntm send" test ! -s "$TMP/ntm.log"
ok "codex payload file written" cmp -s "$TMP/goal.md" "$TMP/dispatches/codex-d-wrap.md"
ok "codex short directive points at payload file" grep -q 'codex-d-wrap.md' "$TMP/goal-directive.txt"
ok_jq "Layer 2 foreground probe verified goal-in-progress" 'select(.dispatch_id == "d-wrap" and .state == "goal-in-progress")' "$TMP/state/state-history-d-wrap.jsonl"

env "${env_common[@]}" CODEX_GOAL_MODE_CAPTURE_FILE="$ROOT/tests/fixtures/codex-goal-mode/goal-in-progress.txt" \
  "$DAEMON" --repo "$TMP" --dispatch-log "$TMP/dispatch-log.jsonl" --once --json >"$TMP/daemon.json"
ok_jq "Layer 3 daemon picks up monitored dispatch" '.in_flight_count == 1 and .rows[0].dispatch_id == "d-wrap"' "$TMP/daemon.json"
ok_jq "Layer 3 probe appended history" 'select(.dispatch_id == "d-wrap" and .layer == 3 and .state == "goal-in-progress")' "$TMP/state/state-history-d-wrap.jsonl"

: >"$TMP/ntm.log"
: >"$TMP/goal-activate.log"
env "${env_common[@]}" "$WRAPPER" --session fixture --pane 3 --file "$TMP/non-goal.md" --dispatch-id d-claude --json >"$TMP/claude-wrapper.json"
ok_jq "claude topology dispatch is unmonitored" 'select(.dispatch_id == "d-claude" and .status == "sent_unmonitored_non_codex")' "$TMP/claude-wrapper.json"
ok_jq "claude dispatch-log row records topology agent type" 'select(.dispatch_id == "d-claude" and .agent_type == "claude" and .agent_type_source == "topology")' "$TMP/dispatch-log.jsonl"
ok "claude dispatch uses raw ntm send" grep -q -- "send fixture --pane=3 --file=$TMP/non-goal.md" "$TMP/ntm.log"
ok "claude dispatch does not use activation primitive" test ! -s "$TMP/goal-activate.log"

: >"$TMP/ntm.log"
: >"$TMP/goal-activate.log"
env "${env_common[@]}" "$WRAPPER" --session fixture --pane 4 --file "$TMP/non-goal.md" --dispatch-id d-cc --json >"$TMP/cc-wrapper.json"
ok_jq "CC topology dispatch is unmonitored" 'select(.dispatch_id == "d-cc" and .status == "sent_unmonitored_non_codex")' "$TMP/cc-wrapper.json"
ok_jq "CC topology alias normalizes to claude" 'select(.dispatch_id == "d-cc" and .agent_type == "claude" and .agent_type_source == "topology")' "$TMP/dispatch-log.jsonl"
ok "CC dispatch uses raw ntm send" grep -q -- "send fixture --pane=4 --file=$TMP/non-goal.md" "$TMP/ntm.log"
ok "CC dispatch does not use activation primitive" test ! -s "$TMP/goal-activate.log"

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
[[ "$fail" -eq 0 && "$pass" -ge 6 ]]
