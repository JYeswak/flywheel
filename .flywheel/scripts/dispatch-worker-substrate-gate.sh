#!/usr/bin/env bash
set -euo pipefail

VERSION="dispatch-worker-substrate-gate/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
WORKER_SUBSTRATE=""
AGENT_TYPE=""
PROMPT=""
PROMPT_FILE=""
DISPATCH_LOG=""
TASK_ID="worker-substrate-lint"
JSON_OUT=0

usage() {
  cat <<'EOF'
usage:
  dispatch-worker-substrate-gate.sh [--worker-substrate VALUE] [--agent-type VALUE] [--prompt TEXT|--prompt-file PATH] [--dispatch-log PATH] [--task-id ID] [--json]

Classifies worker substrate for dispatch-log v2 and blocks convergence/adversarial review prompts routed to background agents unless JOSHUA_OVERRIDE is set.
EOF
}

die_usage() {
  printf 'ERR: %s\n' "$1" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --worker-substrate) [[ $# -ge 2 ]] || die_usage "--worker-substrate requires value"; WORKER_SUBSTRATE="$2"; shift 2 ;;
    --worker-substrate=*) WORKER_SUBSTRATE="${1#*=}"; shift ;;
    --agent-type) [[ $# -ge 2 ]] || die_usage "--agent-type requires value"; AGENT_TYPE="$2"; shift 2 ;;
    --agent-type=*) AGENT_TYPE="${1#*=}"; shift ;;
    --prompt) [[ $# -ge 2 ]] || die_usage "--prompt requires text"; PROMPT="$2"; shift 2 ;;
    --prompt=*) PROMPT="${1#*=}"; shift ;;
    --prompt-file) [[ $# -ge 2 ]] || die_usage "--prompt-file requires path"; PROMPT_FILE="$2"; shift 2 ;;
    --prompt-file=*) PROMPT_FILE="${1#*=}"; shift ;;
    --dispatch-log) [[ $# -ge 2 ]] || die_usage "--dispatch-log requires path"; DISPATCH_LOG="$2"; shift 2 ;;
    --dispatch-log=*) DISPATCH_LOG="${1#*=}"; shift ;;
    --task-id) [[ $# -ge 2 ]] || die_usage "--task-id requires id"; TASK_ID="$2"; shift 2 ;;
    --task-id=*) TASK_ID="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

if [[ -n "$PROMPT_FILE" ]]; then
  [[ -f "$PROMPT_FILE" ]] || die_usage "prompt file not found: $PROMPT_FILE"
  PROMPT="$(cat "$PROMPT_FILE")"
fi

AGENT_TYPE="${AGENT_TYPE:-codex}"
case "$AGENT_TYPE" in
  codex|claude|unknown) ;;
  *) die_usage "agent_type must be codex|claude|unknown" ;;
esac

if [[ -z "$WORKER_SUBSTRATE" ]]; then
  case "$AGENT_TYPE" in
    claude) WORKER_SUBSTRATE="claude-pane" ;;
    codex|unknown) WORKER_SUBSTRATE="codex-pane" ;;
  esac
fi

case "$WORKER_SUBSTRATE" in
  codex-pane|claude-pane|background-agent|local) ;;
  *) die_usage "worker_substrate must be codex-pane|claude-pane|background-agent|local" ;;
esac

if [[ "$WORKER_SUBSTRATE" == "codex-pane" && "$AGENT_TYPE" == "unknown" ]]; then
  AGENT_TYPE="codex"
fi

CONVERGENCE_MATCH=0
if printf '%s' "$PROMPT" | grep -Eiq 'convergence|adversarial review|audit wave|synthesis'; then
  CONVERGENCE_MATCH=1
fi

DECISION="pass"
REASON="ok"
OVERRIDE_PRESENT=false
if [[ "$CONVERGENCE_MATCH" -eq 1 && "$WORKER_SUBSTRATE" == "background-agent" ]]; then
  if [[ -n "${JOSHUA_OVERRIDE:-}" ]]; then
    DECISION="pass"
    REASON="joshua_override"
    OVERRIDE_PRESENT=true
  else
    DECISION="reject"
    REASON="convergence_to_background_agent_blocked"
  fi
fi

TS="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
ROW="$(jq -nc \
  --arg schema_version "$VERSION" \
  --arg event "dispatch_worker_substrate_lint" \
  --arg ts "$TS" \
  --arg task_id "$TASK_ID" \
  --arg worker_substrate "$WORKER_SUBSTRATE" \
  --arg agent_type "$AGENT_TYPE" \
  --arg decision "$DECISION" \
  --arg reason "$REASON" \
  --argjson convergence_match "$CONVERGENCE_MATCH" \
  --argjson override_present "$OVERRIDE_PRESENT" \
  '{schema_version:$schema_version,event:$event,ts:$ts,task_id:$task_id,worker_substrate:$worker_substrate,agent_type:$agent_type,decision:$decision,reason:$reason,convergence_keyword_match:($convergence_match == 1),joshua_override_present:$override_present}')"

if [[ -n "$DISPATCH_LOG" ]]; then
  mkdir -p "$(dirname "$DISPATCH_LOG")"
  printf '%s\n' "$ROW" >>"$DISPATCH_LOG"
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$ROW"
else
  printf '%s worker_substrate=%s agent_type=%s reason=%s\n' "$DECISION" "$WORKER_SUBSTRATE" "$AGENT_TYPE" "$REASON"
fi

[[ "$DECISION" == "pass" ]] || exit 1
