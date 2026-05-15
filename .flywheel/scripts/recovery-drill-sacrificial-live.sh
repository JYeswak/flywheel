#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DRILL="${KILL_RECOVER_DRILL_SCRIPT:-$HOME/.claude/skills/.flywheel/scripts/kill-recover-drill.sh}"
NTM_BIN="${NTM_BIN:-$(command -v ntm 2>/dev/null || printf '/Users/josh/.local/bin/ntm')}"
NODE_BIN="${NODE_BIN:-$(command -v node 2>/dev/null || printf '/opt/homebrew/bin/node')}"
DRILL_LOG="${DRILL_LOG:-$HOME/.local/state/flywheel/recovery-drill.jsonl}"
ROWS_PER_CLASS=5
APPLY=""
JSON_OUTPUT=""
SESSION_PREFIX="flywheel-recovery-drill"
CALLBACK_TIMEOUT_SECONDS="${CALLBACK_TIMEOUT_SECONDS:-8}"
TARGET_PANE=1
SESSION=""
TMP_DIR=""

usage() {
  cat <<USAGE
Usage: recovery-drill-sacrificial-live.sh --apply [--rows-per-class N] [--log PATH] [--json]

Creates a disposable tmux session, adopts it into NTM, and runs live
kill-recover-drill rows for D1, D2, and D3 without touching active sessions.

Options:
  --apply             Required. Creates/kills a disposable session and appends drill rows.
  --rows-per-class N  Rows per D1/D2/D3 damage class. Default: 5.
  --log PATH          Drill log path. Default: ~/.local/state/flywheel/recovery-drill.jsonl.
  --session-prefix S  Prefix for disposable session name. Default: flywheel-recovery-drill.
  --json              Emit machine-readable summary.
USAGE
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

cleanup_session() {
  if [[ -n "$SESSION" ]]; then
    "$NTM_BIN" kill "$SESSION" --force >/dev/null 2>&1 || tmux kill-session -t "$SESSION" >/dev/null 2>&1 || true
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --rows-per-class) ROWS_PER_CLASS="${2:?}"; shift 2 ;;
    --log) DRILL_LOG="${2:?}"; shift 2 ;;
    --session-prefix) SESSION_PREFIX="${2:?}"; shift 2 ;;
    --json) JSON_OUTPUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$APPLY" ]] || die "--apply is required because this creates a disposable live session"
[[ "$ROWS_PER_CLASS" =~ ^[1-9][0-9]*$ ]] || die "--rows-per-class must be a positive integer"
[[ -x "$DRILL" ]] || die "kill-recover-drill script not executable: $DRILL"
[[ -x "$NTM_BIN" || -n "$(command -v "$NTM_BIN" 2>/dev/null)" ]] || die "ntm not found: $NTM_BIN"
[[ -x "$NODE_BIN" || -n "$(command -v "$NODE_BIN" 2>/dev/null)" ]] || die "node not found: $NODE_BIN"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-1k7-live.XXXXXX")"
SESSION="${SESSION_PREFIX}-$$"
NODE_JS="$TMP_DIR/echo-agent.js"
RUNNER="$TMP_DIR/echo-agent.sh"
PROBE="$TMP_DIR/session-topology-probe.sh"
mkdir -p "$(dirname "$DRILL_LOG")"
trap cleanup_session EXIT INT TERM

cat > "$NODE_JS" <<'JS'
process.stdin.setEncoding('utf8');
process.stdin.on('data', d => process.stdout.write(String(d)));
setInterval(() => process.stdout.write('READY\n'), 30000);
JS

cat > "$RUNNER" <<SH
#!/usr/bin/env bash
child=""
agent_dead=0
trap 'agent_dead=1; if [[ -n "\${child:-}" ]]; then kill -INT "\$child" 2>/dev/null || true; wait "\$child" 2>/dev/null || true; fi' INT
while true; do
  if [[ "\$agent_dead" -eq 1 ]]; then
    sleep 3600
  else
    "$NODE_BIN" "$NODE_JS" &
    child="\$!"
    wait "\$child" 2>/dev/null || true
    agent_dead=1
  fi
done
SH
chmod +x "$RUNNER"

cat > "$PROBE" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
session="${DRILL_SESSION:?}"
pane="${DRILL_PANE:-0}"
ntm --robot-activity="$session" | jq -e --argjson pane "$pane" '.agents[]? | select(.pane_idx == $pane)' >/dev/null
jq -nc --arg session "$session" --argjson pane "$pane" \
  '{status:"pass",probe:"session-scoped-sacrificial-topology",session:$session,pane:$pane}'
SH
chmod +x "$PROBE"

tmux new-session -d -s "$SESSION"
tmux split-window -t "$SESSION:0" -h "$RUNNER"
"$NTM_BIN" adopt "$SESSION" --user=0 --cod="$TARGET_PANE" --auto-name >/dev/null
sleep 1

run_drill() {
  local damage_class="$1"
  shift
  DRILL_LOG="$DRILL_LOG" \
  DRILL_TOPOLOGY_PROBE="$PROBE" \
  DRILL_SESSION="$SESSION" \
  DRILL_PANE="$TARGET_PANE" \
  DRILL_D3_KEEP_PANE=1 \
  CALLBACK_TIMEOUT_SECONDS="$CALLBACK_TIMEOUT_SECONDS" \
    "$DRILL" --session "$SESSION" --pane "$TARGET_PANE" --damage-class "$damage_class" \
      --wait-seconds 0 --apply --json "$@"
}

for _ in $(seq 1 "$ROWS_PER_CLASS"); do
  run_drill D1 --no-inject --primitive manual >/dev/null
done
for _ in $(seq 1 "$ROWS_PER_CLASS"); do
  run_drill D2 --primitive ntm-respawn --dangerous-drill >/dev/null
done
for _ in $(seq 1 "$ROWS_PER_CLASS"); do
  run_drill D3 --primitive ntm-respawn --dangerous-drill >/dev/null
done

session_summary="$(jq -s --arg session "$SESSION" '
  def class: (.legacy_damage_class // .damage_class);
  map(select(.session == $session))
  | {
      session:$session,
      rows:length,
      green_rows:map(select(.green == true)) | length,
      classes:(group_by(class) | map({key:(.[0] | class), value:length}) | from_entries),
      all_green:all(.[]; .green == true and .liveness_verified == true and .topology_verified == true and .callback_verified == true),
      required_rows_per_class:'"$ROWS_PER_CLASS"'
    }
' "$DRILL_LOG")"

validation="$("$DRILL" --validate-log --log "$DRILL_LOG" --json)"

summary="$(jq -cn \
  --arg schema "flywheel.recovery_drill_sacrificial_live.v1" \
  --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg root "$ROOT" \
  --arg log "$DRILL_LOG" \
  --arg tmp "$TMP_DIR" \
  --arg probe "$PROBE" \
  --argjson session_summary "$session_summary" \
  --argjson validation "$validation" \
  '{
    schema_version:$schema,
    created_at:$created_at,
    repo:$root,
    drill_log:$log,
    temp_dir:$tmp,
    topology_probe:$probe,
    session_summary:$session_summary,
    validation:$validation,
    status:(if $session_summary.all_green == true and $validation.status == "pass" then "pass" else "fail" end)
  }')"

if [[ -n "$JSON_OUTPUT" ]]; then
  printf '%s\n' "$summary"
else
  printf '%s\n' "$summary" | jq -r '"status=\(.status) session=\(.session_summary.session) rows=\(.session_summary.rows) log=\(.drill_log)"'
fi

printf '%s\n' "$summary" | jq -e '.status == "pass"' >/dev/null
