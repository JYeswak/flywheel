#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TAILER="$ROOT/.flywheel/scripts/pane1-bridge-tailer.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

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
  local name="$1"
  local expr="$2"
  local file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
    jq . "$file" >&2 || true
  fi
}

make_fake_ntm() {
  local path="$1"
  cat >"$path" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
CALLS="${FAKE_NTM_CALLS:?}"
python3 - "$CALLS" "$@" <<'PY'
import json
import sys
from pathlib import Path
path = Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
with path.open("a", encoding="utf-8") as handle:
    handle.write(json.dumps({"argv": sys.argv[2:]}, sort_keys=True) + "\n")
PY
printf 'Sent to pane 1\n'
SH
  chmod +x "$path"
}

write_callback() {
  local log="$1" status="$2" sprint="$3"
  shift 3
  local extra="${1:-}"
  [[ -n "$extra" ]] || extra='{}'
  jq -nc \
    --arg status "$status" \
    --arg sprint "$sprint" \
    --argjson extra "$extra" \
    '{
      schema_version:"callback-envelope/v1",
      ts:"2026-05-19T14:30:00Z",
      event:"worker_callback",
      mode:"goal",
      goal_id:$sprint,
      phase:"fixture",
      task_id:($sprint + "-task"),
      bead:($sprint + "-bead"),
      status:$status,
      session:"flywheel",
      sprint_id:$sprint,
      picks_completed:1,
      beads_closed:[($sprint + "-bead")],
      followup_beads:[],
      total_work_time:"under-1m",
      git_committed:"yes",
      commit:"abcdef12",
      tests:"PASS",
      pane1_callback:"sent",
      br_close_executed:"yes",
      evidence:"tests/pane1-callback-bridge.sh"
    } + $extra' >>"$log"
}

run_once_case() {
  local name="$1" status="$2" expected_prefix="$3" extra="$4"
  local dir="$TMPDIR/$name" fake calls log ledger out
  mkdir -p "$dir"
  fake="$dir/ntm"
  calls="$dir/ntm-calls.jsonl"
  log="$dir/dispatch-log.jsonl"
  ledger="$dir/pane1-sprint-complete-bridge.jsonl"
  out="$dir/tailer.json"
  make_fake_ntm "$fake"
  touch "$log"
  write_callback "$log" "$status" "$name-sprint" "$extra"
  FAKE_NTM_CALLS="$calls" "$TAILER" \
    --dispatch-log "$log" \
    --ledger "$ledger" \
    --ntm "$fake" \
    --once \
    --json >"$out"
  ok_jq "$name tailer sent one" '.sent == 1 and .failed == 0 and .status == "pass"' "$out"
  ok "$name ntm received one call" test "$(wc -l <"$calls" | tr -d ' ')" -eq 1
  ok "$name message prefix" grep -q "$expected_prefix" "$calls"
  ok_jq "$name ledger terminal state" ".status == \"sent\" and .callback_status == \"$status\" and .terminal_state == \"$status\"" "$ledger"
}

FAKE_NTM="$TMPDIR/ntm"
CALLS="$TMPDIR/ntm-calls.jsonl"
DISPATCH_LOG="$TMPDIR/dispatch-log.jsonl"
LEDGER="$TMPDIR/pane1-sprint-complete-bridge.jsonl"
OUT="$TMPDIR/tailer.json"
OUT2="$TMPDIR/tailer-duplicate.json"

make_fake_ntm "$FAKE_NTM"
touch "$DISPATCH_LOG"

FAKE_NTM_CALLS="$CALLS" "$TAILER" \
  --dispatch-log "$DISPATCH_LOG" \
  --ledger "$LEDGER" \
  --ntm "$FAKE_NTM" \
  --follow \
  --poll-seconds 1 \
  --max-seconds 60 \
  --max-sends 1 \
  --json >"$OUT" &
tailer_pid=$!

sleep 1
write_callback "$DISPATCH_LOG" "DONE" "fixture-sprint" '{}'

wait "$tailer_pid"

ok "tailer script is executable" test -x "$TAILER"
ok_jq "tailer emitted JSON" '.schema_version == "pane1-bridge-tailer/v1"' "$OUT"
ok_jq "DONE tailer sent one callback" '.sent == 1 and .failed == 0 and .status == "pass"' "$OUT"
ok "DONE fake ntm received one call" test "$(wc -l <"$CALLS" | tr -d ' ')" -eq 1
ok_jq "DONE ntm call targets pane 1" '.argv[0] == "send" and .argv[1] == "flywheel" and .argv[2] == "--pane=1"' "$CALLS"
ok_jq "DONE message prefix and fields" '(.argv | join(" ")) | contains("SPRINT DONE: sprint=fixture-sprint") and contains("commit=abcdef12") and contains("tests=PASS") and contains("evidence=tests/pane1-callback-bridge.sh")' "$CALLS"
ok_jq "DONE bridge ledger schema/status fields" '.schema_version == "pane1-sprint-complete-bridge/v1" and .status == "sent" and .callback_status == "DONE" and .terminal_state == "DONE" and .task_id == "fixture-sprint-task"' "$LEDGER"
ok_jq "DONE bridge ledger includes callback key" '(.callback_key | type) == "string" and (.callback_key | length) == 64' "$LEDGER"

FAKE_NTM_CALLS="$CALLS" "$TAILER" \
  --dispatch-log "$DISPATCH_LOG" \
  --ledger "$LEDGER" \
  --ntm "$FAKE_NTM" \
  --once \
  --json >"$OUT2"

ok_jq "duplicate row is idempotently skipped" '.sent == 0 and .failed == 0' "$OUT2"
ok "duplicate run did not invoke ntm again" test "$(wc -l <"$CALLS" | tr -d ' ')" -eq 1

BLOCKED_FOLLOW_DIR="$TMPDIR/blocked-follow"
mkdir -p "$BLOCKED_FOLLOW_DIR"
BLOCKED_FOLLOW_FAKE="$BLOCKED_FOLLOW_DIR/ntm"
BLOCKED_FOLLOW_CALLS="$BLOCKED_FOLLOW_DIR/ntm-calls.jsonl"
BLOCKED_FOLLOW_LOG="$BLOCKED_FOLLOW_DIR/dispatch-log.jsonl"
BLOCKED_FOLLOW_LEDGER="$BLOCKED_FOLLOW_DIR/pane1-sprint-complete-bridge.jsonl"
BLOCKED_FOLLOW_OUT="$BLOCKED_FOLLOW_DIR/tailer.json"
make_fake_ntm "$BLOCKED_FOLLOW_FAKE"
touch "$BLOCKED_FOLLOW_LOG"

FAKE_NTM_CALLS="$BLOCKED_FOLLOW_CALLS" "$TAILER" \
  --dispatch-log "$BLOCKED_FOLLOW_LOG" \
  --ledger "$BLOCKED_FOLLOW_LEDGER" \
  --ntm "$BLOCKED_FOLLOW_FAKE" \
  --follow \
  --poll-seconds 1 \
  --max-seconds 60 \
  --max-sends 1 \
  --json >"$BLOCKED_FOLLOW_OUT" &
blocked_follow_pid=$!

sleep 1
write_callback "$BLOCKED_FOLLOW_LOG" "BLOCKED" "blocked-follow-sprint" '{"reason":"follow_gate","tests":"HALTED"}'

wait "$blocked_follow_pid"

ok_jq "BLOCKED follow-mode sent one callback within 60s" '.sent == 1 and .failed == 0 and .status == "pass"' "$BLOCKED_FOLLOW_OUT"
ok "BLOCKED follow-mode ntm received one call" test "$(wc -l <"$BLOCKED_FOLLOW_CALLS" | tr -d ' ')" -eq 1
ok_jq "BLOCKED follow-mode message prefix" '(.argv | join(" ")) | contains("SPRINT BLOCKED: sprint=blocked-follow-sprint stop_reason=follow_gate")' "$BLOCKED_FOLLOW_CALLS"
ok_jq "BLOCKED follow-mode ledger status fields" '.status == "sent" and .callback_status == "BLOCKED" and .terminal_state == "BLOCKED"' "$BLOCKED_FOLLOW_LEDGER"

run_once_case "blocked" "BLOCKED" "SPRINT BLOCKED: sprint=blocked-sprint stop_reason=fixture_gate" '{"tests":"HALTED","reason":"fixture_gate"}'
ok_jq "BLOCKED message has evidence" '(.argv | join(" ")) | contains("evidence=tests/pane1-callback-bridge.sh")' "$TMPDIR/blocked/ntm-calls.jsonl"

run_once_case "declined" "DECLINED" "SPRINT DECLINED: sprint=declined-sprint declined_reason=fixture_decline" '{"declined_reason":"fixture_decline"}'

STARTED_DIR="$TMPDIR/started"
mkdir -p "$STARTED_DIR"
STARTED_FAKE="$STARTED_DIR/ntm"
STARTED_CALLS="$STARTED_DIR/ntm-calls.jsonl"
STARTED_LOG="$STARTED_DIR/dispatch-log.jsonl"
STARTED_LEDGER="$STARTED_DIR/pane1-sprint-complete-bridge.jsonl"
STARTED_OUT="$STARTED_DIR/tailer.json"
make_fake_ntm "$STARTED_FAKE"
touch "$STARTED_LOG"
write_callback "$STARTED_LOG" "STARTED" "started-sprint" '{}'
FAKE_NTM_CALLS="$STARTED_CALLS" "$TAILER" \
  --dispatch-log "$STARTED_LOG" \
  --ledger "$STARTED_LEDGER" \
  --ntm "$STARTED_FAKE" \
  --once \
  --json >"$STARTED_OUT"
ok_jq "STARTED does not route" '.sent == 0 and .failed == 0 and .candidate_count == 0' "$STARTED_OUT"
ok "STARTED did not invoke ntm" test ! -e "$STARTED_CALLS"
ok "STARTED wrote no ledger" test ! -e "$STARTED_LEDGER"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
