#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="codex-goal-mode-monitor-daemon/v0.1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
REPO="$ROOT"
DISPATCH_LOG=""
INTERVAL_S=60
JSON_OUT=0
DRY_RUN=0
ONCE=0
PROBE="${CODEX_GOAL_MODE_PROBE:-$ROOT/.flywheel/scripts/codex-goal-mode-monitor-probe.sh}"

usage() {
  cat <<'EOF'
usage: codex-goal-mode-monitor-daemon.sh [--repo PATH] [--dispatch-log PATH] [--interval-s N] [--once] [--json] [--dry-run]

Polls dispatch-log.jsonl for in-flight Codex dispatch rows and invokes the
Layer 3 codex goal-mode monitor probe. Rows without monitor_probe_id are
treated as legacy/non-monitored.
EOF
}

die_usage() {
  printf 'codex-goal-mode-monitor-daemon: %s\n' "$1" >&2
  usage >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) [[ $# -ge 2 ]] || die_usage "--repo requires PATH"; REPO="$(cd "$2" && pwd -P)"; shift 2 ;;
    --repo=*) REPO="$(cd "${1#*=}" && pwd -P)"; shift ;;
    --dispatch-log) [[ $# -ge 2 ]] || die_usage "--dispatch-log requires PATH"; DISPATCH_LOG="$2"; shift 2 ;;
    --dispatch-log=*) DISPATCH_LOG="${1#*=}"; shift ;;
    --interval-s) [[ $# -ge 2 ]] || die_usage "--interval-s requires N"; INTERVAL_S="$2"; shift 2 ;;
    --interval-s=*) INTERVAL_S="${1#*=}"; shift ;;
    --once) ONCE=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

[[ "$INTERVAL_S" =~ ^[0-9]+$ ]] || die_usage "--interval-s must be an integer"
[[ -n "$DISPATCH_LOG" ]] || DISPATCH_LOG="$REPO/.flywheel/dispatch-log.jsonl"

emit_cycle() {
  local rows_file="$1"
  local count
  count="$(jq 'length' "$rows_file")"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc \
      --arg schema_version "$SCHEMA_VERSION" \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg repo "$REPO" \
      --arg dispatch_log "$DISPATCH_LOG" \
      --argjson in_flight_count "$count" \
      --slurpfile rows "$rows_file" \
      '{schema_version:$schema_version,ts:$ts,repo:$repo,dispatch_log:$dispatch_log,in_flight_count:$in_flight_count,rows:$rows[0]}'
  else
    printf 'codex-goal-mode-daemon repo=%s in_flight=%s dispatch_log=%s\n' "$REPO" "$count" "$DISPATCH_LOG"
  fi
}

scan_once() {
  local rows tmp row dispatch_id pane session rc
  rows="$(mktemp "${TMPDIR:-/tmp}/codex-goal-mode-daemon-rows.XXXXXX")"
  tmp="$(mktemp "${TMPDIR:-/tmp}/codex-goal-mode-daemon-out.XXXXXX")"
  trap 'rm -f "$rows" "$tmp"' RETURN
  if [[ ! -s "$DISPATCH_LOG" ]]; then
    printf '[]\n' >"$rows"
    emit_cycle "$rows"
    return 0
  fi
  jq -Rsc '
    split("\n")
    | map(select(length > 0) | fromjson? | select(type == "object"))
    | map(select((.agent_type // "") == "codex"))
    | map(select((.monitor_probe_id // "") != ""))
    | map(select((.dispatch_ts // .ts // "") != ""))
    | map(select((.callback_ts // .callback_received_at // null) == null))
    | map(select((.event // "dispatch_sent") == "dispatch_sent" or (.event // "") == "worker_dispatch"))
  ' "$DISPATCH_LOG" >"$rows"
  emit_cycle "$rows"
  jq -c '.[]' "$rows" | while IFS= read -r row; do
    dispatch_id="$(jq -r '.dispatch_id // .task_id // .id' <<<"$row")"
    pane="$(jq -r '.pane' <<<"$row")"
    session="$(jq -r '.session // "flywheel"' <<<"$row")"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      continue
    fi
    set +e
    CODEX_GOAL_MODE_SESSION="$session" "$PROBE" --pane "$pane" --dispatch-id "$dispatch_id" --layer 3 --json >"$tmp" 2>&1
    rc=$?
    set -e
    jq -nc \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg schema_version "$SCHEMA_VERSION" \
      --arg dispatch_id "$dispatch_id" \
      --argjson pane "$pane" \
      --arg session "$session" \
      --argjson probe_rc "$rc" \
      --rawfile probe_output "$tmp" \
      '{ts:$ts,schema_version:$schema_version,event:"layer3_probe_invoked",dispatch_id:$dispatch_id,pane:$pane,session:$session,probe_rc:$probe_rc,probe_output:$probe_output}' >>"${CODEX_GOAL_MODE_DAEMON_LEDGER:-$HOME/.flywheel/evidence/codex-goal-mode-daemon.jsonl}"
  done
}

while true; do
  scan_once
  [[ "$ONCE" -eq 1 ]] && exit 0
  sleep "$INTERVAL_S"
done
