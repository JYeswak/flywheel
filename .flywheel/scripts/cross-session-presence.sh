#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing
#
# cross-session-presence.sh — canonical probe of who's alive across sessions.
#
# Closes P8 of substrate-compounding-v2. Fixes the ntm-robot-activity Claude
# blindspot we found in this session (memory rule:
# feedback_cross_session_probe_canonical_truth_sources): tmux capture-pane is
# canonical truth; ntm --robot-activity has agent-type-filter blindspots.
#
# For each known session:
#   1. tmux capture-pane -t <session>:0 -p (canonical truth)
#   2. Detect agent type from capture content (claude / codex / shell / dead)
#   3. Extract /goal-active state if claude
#   4. Cross-reference with git log of session's repo for last-delta-ts
#
# Emits JSON envelope. Disabled via FLYWHEEL_CROSS_SESSION_PRESENCE=0.
#
# Exit codes:
#   0  probe ran successfully
#   1  I/O error / required tool missing
#   2  usage error
#   3  disabled via env

set -euo pipefail

VERSION="cross-session-presence.v0.1.0"
SCHEMA_VERSION="flywheel.cross_session_presence.v0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${CSP_REPO:-$REPO_DEFAULT}"
STATE_DIR="${CSP_STATE_DIR:-$REPO_ROOT/.flywheel/state}"
LOG_PATH="${CSP_LOG:-$STATE_DIR/cross-session-presence.jsonl}"

# Known fleet sessions (per goal P8 contract)
SESSIONS=("${CSP_SESSIONS:-flywheel skillos mobile-eats alps cfs vrtx zeststream-public}")
# Repo paths for each session
declare -A SESSION_REPO=(
  [flywheel]="$HOME/Developer/flywheel"
  [skillos]="$HOME/Developer/skillos"
  [mobile-eats]="$HOME/Developer/mobile-eats"
  [alps]="$HOME/Developer/alpsinsurance"
  [cfs]="$HOME/Developer/clutterfreespaces"
  [vrtx]="$HOME/Developer/vrtx-insurance"
  [zeststream-public]="$HOME/Developer/zeststream-public"
)

if [[ "${FLYWHEEL_CROSS_SESSION_PRESENCE:-1}" == "0" ]]; then
  printf '{"status":"disabled","reason":"FLYWHEEL_CROSS_SESSION_PRESENCE=0"}\n'
  exit 3
fi

usage() {
  cat <<EOF
usage:
  cross-session-presence.sh probe [--session NAME] [--json]
  cross-session-presence.sh gate --target-session NAME [--max-delta-hours N] [--json]
  cross-session-presence.sh --info|--schema|--examples [--json]
  cross-session-presence.sh doctor|health [--json]
  cross-session-presence.sh --help|-h

Probes who's alive across fleet sessions. Uses tmux capture-pane as canonical
truth (NOT ntm --robot-activity, which has Claude-orch blindspots).

Env overrides:
  CSP_SESSIONS  space-separated session names (default: known fleet)
  CSP_LOG       default <repo>/.flywheel/state/cross-session-presence.jsonl
  FLYWHEEL_CROSS_SESSION_PRESENCE=0  disable entirely
EOF
}

emit_info() {
  cat <<JSON
{
  "name": "cross-session-presence",
  "version": "$VERSION",
  "schema_version": "$SCHEMA_VERSION",
  "purpose": "Canonical fleet-presence probe; fixes ntm-robot-activity Claude blindspot",
  "subcommands": ["probe", "gate", "doctor", "health"],
  "canonical_cli_flags": ["--info", "--schema", "--examples", "--json", "--help"],
  "mutates_state": "appends to $LOG_PATH on probe; read-only on gate",
  "canonical_truth_source": "tmux capture-pane -t <session>:0 -p",
  "anti_pattern_fixed": "ntm --robot-activity filtered by agent-type; misses Claude orchs"
}
JSON
}

emit_schema() {
  cat <<JSON
{
  "schema_version": "$SCHEMA_VERSION",
  "output_schema": {
    "probe": {
      "row_shape": "{session, alive, agent_type, goal_active, last_delta_ts, last_delta_path, capture_excerpt}",
      "agent_types": ["claude", "codex", "shell", "dead", "unknown"]
    },
    "gate": {
      "decision_shape": "{target_session, decision: 'allow'|'block', reason, last_delta_age_hours}"
    }
  }
}
JSON
}

emit_examples() {
  cat <<JSON
{
  "examples": [
    {"name": "probe all known sessions", "command": "cross-session-presence.sh probe --json"},
    {"name": "probe one session", "command": "cross-session-presence.sh probe --session skillos --json"},
    {"name": "dispatch-gate decision for cross-orch send", "command": "cross-session-presence.sh gate --target-session skillos --max-delta-hours 24 --json"}
  ]
}
JSON
}

emit_doctor() {
  local checks=()
  local status="ok"
  if command -v tmux >/dev/null 2>&1; then
    checks+=('{"check":"tmux_available","ok":true}')
  else
    checks+=('{"check":"tmux_available","ok":false}')
    status="fail"
  fi
  if command -v jq >/dev/null 2>&1; then
    checks+=('{"check":"jq_available","ok":true}')
  else
    checks+=('{"check":"jq_available","ok":false}')
    status="fail"
  fi
  local mkdir_ok="true"
  mkdir -p "$STATE_DIR" 2>/dev/null || mkdir_ok="false"
  checks+=("$(printf '{"check":"state_dir_writable","ok":%s,"path":"%s"}' "$mkdir_ok" "$STATE_DIR")")
  printf '{"command":"doctor","status":"%s","checks":[%s]}\n' "$status" "$(IFS=,; echo "${checks[*]}")"
  [[ "$status" == "fail" ]] && return 1 || return 0
}

probe_one_session() {
  local session="$1"
  local repo="${SESSION_REPO[$session]:-}"
  local now; now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Capture pane 0 of the session via tmux. If tmux session doesn't exist, mark dead.
  local capture=""
  local capture_ok="false"
  if tmux has-session -t "$session" 2>/dev/null; then
    capture="$(tmux capture-pane -t "${session}:0" -p 2>/dev/null || echo "")"
    [[ -n "$capture" ]] && capture_ok="true"
  fi

  # Detect agent type from capture content
  local agent_type="unknown"
  local goal_active="false"
  local alive="false"
  if [[ "$capture_ok" == "true" ]]; then
    if echo "$capture" | grep -qE "Scurrying|Working|Cogitating|Wrangling|/goal active" 2>/dev/null; then
      agent_type="claude"
      alive="true"
      echo "$capture" | grep -qE "/goal active" && goal_active="true"
    elif echo "$capture" | grep -qE "^❯|codex|chevron_prompt" 2>/dev/null; then
      agent_type="codex"
      alive="true"
    elif echo "$capture" | grep -qE "^\\\$ |bash-|zsh:" 2>/dev/null; then
      agent_type="shell"
    else
      agent_type="unknown"
    fi
  else
    agent_type="dead"
  fi

  # Get last-delta-ts from session's repo git log
  local last_delta_ts="null"
  local last_delta_sha="null"
  local last_delta_age_hours="null"
  if [[ -n "$repo" && -d "$repo/.git" ]]; then
    last_delta_ts="$(git -C "$repo" log -1 --format='%aI' 2>/dev/null || echo null)"
    last_delta_sha="$(git -C "$repo" log -1 --format='%h' 2>/dev/null || echo null)"
    if [[ "$last_delta_ts" != "null" && -n "$last_delta_ts" ]]; then
      # age in hours via Python (portable date math)
      last_delta_age_hours="$(python3 -c "
from datetime import datetime, timezone
import sys
try:
    last = datetime.fromisoformat('$last_delta_ts'.replace('Z','+00:00'))
    now = datetime.now(timezone.utc)
    print(round((now - last).total_seconds() / 3600, 2))
except Exception:
    print('null')
")"
    fi
  fi

  # Build row
  local excerpt
  excerpt="$(echo "$capture" | tail -5 | tr -d '\n' | head -c 200)"
  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg ts "$now" \
    --arg session "$session" \
    --arg repo "$repo" \
    --arg agent_type "$agent_type" \
    --argjson alive "$alive" \
    --argjson goal_active "$goal_active" \
    --arg last_delta_ts "$last_delta_ts" \
    --arg last_delta_sha "$last_delta_sha" \
    --arg last_delta_age_hours "$last_delta_age_hours" \
    --arg excerpt "$excerpt" \
    '{
      schema_version: $schema,
      probed_at: $ts,
      session: $session,
      repo: $repo,
      alive: $alive,
      agent_type: $agent_type,
      goal_active: $goal_active,
      last_delta_ts: ($last_delta_ts | if . == "null" or . == "" then null else . end),
      last_delta_sha: ($last_delta_sha | if . == "null" or . == "" then null else . end),
      last_delta_age_hours: ($last_delta_age_hours | if . == "null" or . == "" then null else (tonumber? // null) end),
      capture_excerpt: $excerpt
    }'
}

cmd_probe() {
  local session="" json_out=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --session) session="$2"; shift 2 ;;
      --json) json_out=1; shift ;;
      *) printf 'unknown arg: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  mkdir -p "$STATE_DIR"
  local rows=()
  if [[ -n "$session" ]]; then
    rows+=("$(probe_one_session "$session")")
  else
    for s in $SESSIONS; do
      rows+=("$(probe_one_session "$s")")
    done
  fi
  # Append rows to rolling log
  for row in "${rows[@]}"; do
    echo "$row" >>"$LOG_PATH"
  done
  if [[ "$json_out" -eq 1 ]]; then
    printf '{"status":"probed","session_count":%d,"log":"%s","rows":[%s]}\n' "${#rows[@]}" "$LOG_PATH" "$(IFS=,; echo "${rows[*]}")"
  else
    printf 'PROBED %d sessions → %s\n' "${#rows[@]}" "$LOG_PATH"
    for row in "${rows[@]}"; do
      echo "$row" | jq -r '"  \(.session) \(.agent_type) alive=\(.alive) /goal=\(.goal_active) last_delta=\(.last_delta_age_hours // "?")h"'
    done
  fi
}

cmd_gate() {
  local target_session="" max_age_hours=24 json_out=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target-session) target_session="$2"; shift 2 ;;
      --max-delta-hours) max_age_hours="$2"; shift 2 ;;
      --json) json_out=1; shift ;;
      *) printf 'unknown arg: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  [[ -z "$target_session" ]] && { printf 'usage: gate --target-session NAME\n' >&2; return 2; }
  local probe_row; probe_row="$(probe_one_session "$target_session")"
  local alive; alive="$(echo "$probe_row" | jq -r '.alive')"
  local age; age="$(echo "$probe_row" | jq -r '.last_delta_age_hours // "999999"')"
  local decision="block"
  local reason=""
  if [[ "$alive" != "true" ]]; then
    reason="receiver_not_alive"
  elif python3 -c "import sys; sys.exit(0 if float('$age') > float('$max_age_hours') else 1)" 2>/dev/null; then
    reason="receiver_stale_age_hours=$age_max=$max_age_hours"
  else
    decision="allow"
    reason="receiver_alive_and_fresh"
  fi
  if [[ "$json_out" -eq 1 ]]; then
    printf '{"target_session":"%s","decision":"%s","reason":"%s","alive":%s,"last_delta_age_hours":%s,"max_age_hours":%s}\n' \
      "$target_session" "$decision" "$reason" "$alive" "$age" "$max_age_hours"
  else
    printf 'GATE %s → %s (%s)\n' "$target_session" "$decision" "$reason"
  fi
  [[ "$decision" == "allow" ]] && return 0 || return 1
}

main() {
  case "${1:-}" in
    --info) shift; emit_info ;;
    --schema) shift; emit_schema ;;
    --examples) shift; emit_examples ;;
    --help|-h|"") usage ;;
    probe) shift; cmd_probe "$@" ;;
    gate) shift; cmd_gate "$@" ;;
    doctor|health) shift; emit_doctor ;;
    *) printf 'unknown subcommand: %s\n' "$1" >&2; usage >&2; return 2 ;;
  esac
}

main "$@"
