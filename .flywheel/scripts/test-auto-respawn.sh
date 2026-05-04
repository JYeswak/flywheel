#!/usr/bin/env bash
set -euo pipefail

DETECTOR="${DETECTOR:-/Users/josh/.claude/skills/.flywheel/bin/auto-respawn-detector.sh}"
REAL_NTM_BIN="${REAL_NTM_BIN:-/Users/josh/.local/bin/ntm}"
ts="$(date -u +%Y%m%dT%H%M%SZ)"
session="auto-respawn-test-${ts}-$$"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/auto-respawn-test.XXXXXX")"
state_dir="$tmp/state"
topology="$tmp/session-topology.jsonl"
fake_ntm="$tmp/ntm"
calls="$tmp/calls.log"
mkdir -p "$state_dir"
touch "$calls"

cleanup() {
  if command -v "$REAL_NTM_BIN" >/dev/null 2>&1; then
    "$REAL_NTM_BIN" kill "$session" --force >/dev/null 2>&1 || true
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT HUP INT TERM

if command -v "$REAL_NTM_BIN" >/dev/null 2>&1; then
  "$REAL_NTM_BIN" kill "$session" --force >/dev/null 2>&1 || true
  "$REAL_NTM_BIN" create "$session" --panes=2 --json >/dev/null
fi

state_since="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) - timedelta(minutes=10)).strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
)"

jq -nc --arg session "$session" --arg effective_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{session:$session, effective_at:$effective_at, human_pane:0, orchestrator_pane:2, callback_pane:2}' > "$topology"

cat > "$fake_ntm" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
calls="${AUTO_RESPAWN_TEST_CALLS:?}"
session="${AUTO_RESPAWN_TEST_SESSION:?}"
state_since="${AUTO_RESPAWN_TEST_STATE_SINCE:?}"

log_call() {
  printf '%s\n' "$*" >> "$calls"
}

case "${1:-}" in
  list)
    if [[ "${2:-}" == "--json" ]]; then
      jq -nc --arg s "$session" '{sessions:[{name:$s}]}'
      exit 0
    fi
    ;;
  --robot-activity=*)
    jq -nc --arg s "$session" --arg since "$state_since" '{
      session:$s,
      success:true,
      agents:[
        {pane:"0",pane_idx:0,agent_type:"codex",state:"ERROR",state_since:$since,velocity:0},
        {pane:"1",pane_idx:1,agent_type:"codex",state:"ERROR",state_since:$since,velocity:0},
        {pane:"2",pane_idx:2,agent_type:"codex",state:"WAITING",state_since:$since,velocity:0}
      ],
      summary:{total_agents:3,by_state:{ERROR:2,WAITING:1}}
    }'
    exit 0
    ;;
  --robot-tail=*)
    pane="unknown"
    for arg in "$@"; do
      case "$arg" in
        --panes=*) pane="${arg#--panes=}" ;;
      esac
    done
    jq -nc --arg pane "$pane" '{panes:{($pane):{lines:["synthetic dead pane output"]}}}'
    exit 0
    ;;
  respawn)
    log_call "respawn session=$2 panes=${3#--panes=}"
    exit 0
    ;;
  send)
    pane="unknown"
    file=""
    prompt=""
    shift
    sess="$1"; shift
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --pane=*) pane="${1#--pane=}" ; shift ;;
        --pane) pane="$2"; shift 2 ;;
        --file) file="$2"; shift 2 ;;
        --no-cass-check) shift ;;
        *) prompt="$1"; shift ;;
      esac
    done
    if [[ -n "$file" ]]; then
      log_call "send session=$sess pane=$pane file=$file"
    else
      log_call "send session=$sess pane=$pane prompt=$prompt"
    fi
    exit 0
    ;;
esac

printf 'fake ntm unsupported args: %s\n' "$*" >&2
exit 9
FAKE
chmod +x "$fake_ntm"

set +e
AUTO_RESPAWN_NTM_BIN="$fake_ntm" \
AUTO_RESPAWN_STATE_DIR="$state_dir" \
AUTO_RESPAWN_TOPOLOGY_FILE="$topology" \
AUTO_RESPAWN_TEST_CALLS="$calls" \
AUTO_RESPAWN_TEST_SESSION="$session" \
AUTO_RESPAWN_TEST_STATE_SINCE="$state_since" \
AUTO_RESPAWN_WAIT_SECONDS=0 \
"$DETECTOR" --session "$session" --threshold-seconds 60 --throttle-seconds 1800 >"$tmp/first.out" 2>"$tmp/first.err"
first_rc=$?

AUTO_RESPAWN_NTM_BIN="$fake_ntm" \
AUTO_RESPAWN_STATE_DIR="$state_dir" \
AUTO_RESPAWN_TOPOLOGY_FILE="$topology" \
AUTO_RESPAWN_TEST_CALLS="$calls" \
AUTO_RESPAWN_TEST_SESSION="$session" \
AUTO_RESPAWN_TEST_STATE_SINCE="$state_since" \
AUTO_RESPAWN_WAIT_SECONDS=0 \
"$DETECTOR" --session "$session" --threshold-seconds 60 --throttle-seconds 1800 >"$tmp/second.out" 2>"$tmp/second.err"
second_rc=$?
set -e

if [[ "$first_rc" -ne 1 ]]; then
  echo "FAIL: first detector run rc=$first_rc expected 1"
  cat "$tmp/first.err"
  exit 1
fi
if [[ "$second_rc" -ne 2 ]]; then
  echo "FAIL: second detector run rc=$second_rc expected 2 throttle"
  cat "$tmp/second.err"
  exit 1
fi

if ! grep -q '^respawn session=.* panes=1$' "$calls"; then
  echo "FAIL: pane 1 was not respawned"
  cat "$calls"
  exit 1
fi
if grep -q 'panes=0\\|panes=2' "$calls"; then
  echo "FAIL: excluded/live pane was respawned"
  cat "$calls"
  exit 1
fi
if [[ "$(grep -c '^respawn ' "$calls")" -ne 1 ]]; then
  echo "FAIL: expected exactly one respawn call"
  cat "$calls"
  exit 1
fi
if [[ "$(grep -c '^send ' "$calls")" -lt 2 ]]; then
  echo "FAIL: expected relaunch and resume send calls"
  cat "$calls"
  exit 1
fi

jq -e 'select(.respawn_outcome=="success" and .session=="'"$session"'" and .pane==1)' "$state_dir/auto-respawn.jsonl" >/dev/null
jq -e 'select(.respawn_outcome=="throttled" and .session=="'"$session"'" and .pane==1)' "$state_dir/auto-respawn.jsonl" >/dev/null

echo "PASS: auto-respawn detector respawned synthetic dead pane, left live/excluded panes untouched, and enforced throttle"
