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

ok_test() {
  local name="$1"
  local expr="$2"
  if eval "$expr"; then
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
  fi
}

FAKE_NTM="$TMPDIR/ntm"
CALLS="$TMPDIR/ntm-calls.jsonl"
DISPATCH_LOG="$TMPDIR/dispatch-log.jsonl"
LEDGER="$TMPDIR/pane1-sprint-complete-bridge.jsonl"
OUT="$TMPDIR/tailer.json"
OUT2="$TMPDIR/tailer-duplicate.json"

cat >"$FAKE_NTM" <<'SH'
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
chmod +x "$FAKE_NTM"

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
printf '%s\n' '{"schema_version":"callback-envelope/v1","ts":"2026-05-19T14:30:00Z","event":"worker_callback","mode":"goal","goal_id":"fixture-goal","phase":"fixture","task_id":"fixture-task","bead":"fixture-bead","status":"DONE","session":"flywheel","sprint_id":"fixture-sprint","picks_completed":1,"beads_closed":["fixture-bead"],"followup_beads":[],"total_work_time":"under-1m","git_committed":"yes","commit":"abcdef12","tests":"PASS","pane1_callback":"sent","br_close_executed":"yes","evidence":"tests/pane1-callback-bridge.sh"}' >>"$DISPATCH_LOG"

wait "$tailer_pid"

ok "tailer script is executable" test -x "$TAILER"
ok_jq "tailer emitted JSON" '.schema_version == "pane1-bridge-tailer/v1"' "$OUT"
ok_jq "tailer sent one callback" '.sent == 1 and .failed == 0 and .status == "pass"' "$OUT"
ok "fake ntm received one call" test "$(wc -l <"$CALLS" | tr -d ' ')" -eq 1
ok_jq "ntm call targets pane 1" '.argv[0] == "send" and .argv[1] == "flywheel" and .argv[2] == "--pane=1"' "$CALLS"
ok_jq "ntm message includes sprint and evidence" '(.argv | join(" ")) | contains("sprint=fixture-sprint") and contains("evidence=tests/pane1-callback-bridge.sh")' "$CALLS"
ok_jq "bridge ledger row written" '.schema_version == "pane1-sprint-complete-bridge/v1" and .status == "sent" and .task_id == "fixture-task"' "$LEDGER"
ok_jq "bridge ledger includes callback key" '(.callback_key | type) == "string" and (.callback_key | length) == 64' "$LEDGER"

FAKE_NTM_CALLS="$CALLS" "$TAILER" \
  --dispatch-log "$DISPATCH_LOG" \
  --ledger "$LEDGER" \
  --ntm "$FAKE_NTM" \
  --once \
  --json >"$OUT2"

ok_jq "duplicate row is idempotently skipped" '.sent == 0 and .failed == 0' "$OUT2"
ok "duplicate run did not invoke ntm again" test "$(wc -l <"$CALLS" | tr -d ' ')" -eq 1

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
