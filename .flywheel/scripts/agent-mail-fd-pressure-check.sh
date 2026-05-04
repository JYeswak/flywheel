#!/usr/bin/env bash
# Probe Agent Mail file-descriptor pressure against the current soft ulimit.
set -euo pipefail

PROCESS_PATTERN="${AGENT_MAIL_FD_PROCESS_PATTERN:-mcp_agent_mail}"
WARN_PCT="${AGENT_MAIL_FD_WARN_PCT:-80}"
ERROR_PCT="${AGENT_MAIL_FD_ERROR_PCT:-95}"
JSON_OUT=0

usage() {
  cat <<'EOF'
usage: agent-mail-fd-pressure-check.sh [--json] [--process-pattern PATTERN] [--warn-pct N] [--error-pct N]

Environment overrides for synthetic tests:
  FAKE_FD_COUNT=N
  FAKE_ULIMIT=N
  FAKE_PID=N
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON_OUT=1
      shift
      ;;
    --process-pattern)
      [[ -n "${2:-}" ]] || { echo "ERR: --process-pattern requires a value" >&2; exit 64; }
      PROCESS_PATTERN="$2"
      shift 2
      ;;
    --warn-pct)
      [[ -n "${2:-}" ]] || { echo "ERR: --warn-pct requires a value" >&2; exit 64; }
      WARN_PCT="$2"
      shift 2
      ;;
    --error-pct)
      [[ -n "${2:-}" ]] || { echo "ERR: --error-pct requires a value" >&2; exit 64; }
      ERROR_PCT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERR: unknown argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "ERR: jq is required" >&2
  exit 69
fi

is_number() {
  [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
}

pct_of_limit() {
  local count="$1" limit="$2"
  awk -v c="$count" -v l="$limit" 'BEGIN { if (l <= 0) printf "0.00"; else printf "%.2f", (c / l) * 100 }'
}

headroom_pct() {
  local pct="$1"
  awk -v p="$pct" 'BEGIN { h = 100 - p; if (h < 0) h = 0; printf "%.2f", h }'
}

append_json() {
  local array="$1" item="$2"
  jq -c --argjson item "$item" '. + [$item]' <<<"$array"
}

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ULIMIT_RAW="${FAKE_ULIMIT:-$(ulimit -n)}"
LIMIT_JSON="null"
LIMIT_NUMERIC=0
LIMIT_UNLIMITED=false

if is_number "$ULIMIT_RAW"; then
  LIMIT_NUMERIC="$ULIMIT_RAW"
  LIMIT_JSON="$ULIMIT_RAW"
elif [[ "$ULIMIT_RAW" == "unlimited" ]]; then
  LIMIT_UNLIMITED=true
else
  LIMIT_UNLIMITED=false
fi

PROCESSES="[]"
WARNINGS="[]"
ERRORS="[]"
MAX_FD=0
MAX_PCT="0.00"

if [[ -n "${FAKE_FD_COUNT:-}" ]]; then
  if ! is_number "$FAKE_FD_COUNT"; then
    echo "ERR: FAKE_FD_COUNT must be numeric" >&2
    exit 64
  fi
  FAKE_PID_VALUE="${FAKE_PID:-0}"
  FD_PCT="$(pct_of_limit "$FAKE_FD_COUNT" "$LIMIT_NUMERIC")"
  PROCESS_JSON="$(jq -nc \
    --argjson pid "$FAKE_PID_VALUE" \
    --argjson fd_count "$FAKE_FD_COUNT" \
    --argjson pct "$FD_PCT" \
    '{pid:$pid,fd_count:$fd_count,pct:$pct,command:"synthetic",source:"fake"}')"
  PROCESSES="$(append_json "$PROCESSES" "$PROCESS_JSON")"
  MAX_FD="$FAKE_FD_COUNT"
  MAX_PCT="$FD_PCT"
else
  PIDS="$(pgrep -f "$PROCESS_PATTERN" 2>/dev/null | sort -n | uniq || true)"
  for PID in $PIDS; do
    [[ "$PID" == "$$" ]] && continue
    ps -p "$PID" >/dev/null 2>&1 || continue
    FD_COUNT="$(lsof -p "$PID" 2>/dev/null | awk 'END { print NR + 0 }')"
    FD_PCT="$(pct_of_limit "$FD_COUNT" "$LIMIT_NUMERIC")"
    COMMAND="$(ps -p "$PID" -o command= 2>/dev/null | sed 's/[[:space:]]*$//')"
    PROCESS_JSON="$(jq -nc \
      --argjson pid "$PID" \
      --argjson fd_count "$FD_COUNT" \
      --argjson pct "$FD_PCT" \
      --arg command "$COMMAND" \
      '{pid:$pid,fd_count:$fd_count,pct:$pct,command:$command,source:"pgrep+lsof"}')"
    PROCESSES="$(append_json "$PROCESSES" "$PROCESS_JSON")"
    if awk -v a="$FD_PCT" -v b="$MAX_PCT" 'BEGIN { exit !(a > b) }'; then
      MAX_PCT="$FD_PCT"
      MAX_FD="$FD_COUNT"
    fi
  done
fi

STATUS="ok"
if [[ "$(jq 'length' <<<"$PROCESSES")" -eq 0 ]]; then
  STATUS="warn"
  WARNING_JSON="$(jq -nc \
    --arg code "agent_mail_process_not_found" \
    --arg pattern "$PROCESS_PATTERN" \
    '{code:$code,message:"Agent Mail process was not found; fd pressure could not be measured",process_pattern:$pattern}')"
  WARNINGS="$(append_json "$WARNINGS" "$WARNING_JSON")"
elif awk -v pct="$MAX_PCT" -v threshold="$ERROR_PCT" 'BEGIN { exit !(pct >= threshold) }'; then
  STATUS="error"
  ERROR_JSON="$(jq -nc \
    --arg code "agent_mail_fd_pressure_critical" \
    --argjson fd_count "$MAX_FD" \
    --argjson pct "$MAX_PCT" \
    --argjson ulimit_soft "$LIMIT_JSON" \
    --argjson threshold "$ERROR_PCT" \
    '{code:$code,message:"Agent Mail fd usage is at or above the critical threshold",fd_count:$fd_count,pct:$pct,ulimit_soft:$ulimit_soft,threshold_pct:$threshold}')"
  ERRORS="$(append_json "$ERRORS" "$ERROR_JSON")"
elif awk -v pct="$MAX_PCT" -v threshold="$WARN_PCT" 'BEGIN { exit !(pct >= threshold) }'; then
  STATUS="warn"
  ERROR_JSON="$(jq -nc \
    --arg code "agent_mail_fd_pressure_warn" \
    --argjson fd_count "$MAX_FD" \
    --argjson pct "$MAX_PCT" \
    --argjson ulimit_soft "$LIMIT_JSON" \
    --argjson threshold "$WARN_PCT" \
    '{code:$code,message:"Agent Mail fd usage is at or above the warning threshold",fd_count:$fd_count,pct:$pct,ulimit_soft:$ulimit_soft,threshold_pct:$threshold}')"
  ERRORS="$(append_json "$ERRORS" "$ERROR_JSON")"
fi

HEADROOM="$(headroom_pct "$MAX_PCT")"
RESULT="$(jq -nc \
  --arg checked_at "$NOW" \
  --arg status "$STATUS" \
  --arg process_pattern "$PROCESS_PATTERN" \
  --arg ulimit_raw "$ULIMIT_RAW" \
  --argjson ulimit_soft "$LIMIT_JSON" \
  --argjson ulimit_unlimited "$LIMIT_UNLIMITED" \
  --argjson warn_pct "$WARN_PCT" \
  --argjson error_pct "$ERROR_PCT" \
  --argjson max_fd_count "$MAX_FD" \
  --argjson max_pct "$MAX_PCT" \
  --argjson headroom_pct "$HEADROOM" \
  --argjson processes "$PROCESSES" \
  --argjson errors "$ERRORS" \
  --argjson warnings "$WARNINGS" \
  '{
    subsystem:"agent-mail",
    checked_at:$checked_at,
    status:$status,
    process_pattern:$process_pattern,
    ulimit_raw:$ulimit_raw,
    ulimit_soft:$ulimit_soft,
    ulimit_unlimited:$ulimit_unlimited,
    warn_pct:$warn_pct,
    error_pct:$error_pct,
    max_fd_count:$max_fd_count,
    max_pct:$max_pct,
    headroom_pct:$headroom_pct,
    processes:$processes,
    errors:$errors,
    warnings:$warnings
  }')"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$RESULT"
else
  printf 'agent_mail_fd_pressure=%s max_pct=%.2f headroom_pct=%.2f max_fd_count=%s ulimit=%s\n' \
    "$STATUS" "$MAX_PCT" "$HEADROOM" "$MAX_FD" "$ULIMIT_RAW"
  jq -r '.errors[]? | "ERROR: \(.code) \(.message) pct=\(.pct // "n/a")"' <<<"$RESULT"
  jq -r '.warnings[]? | "WARN: \(.code) \(.message)"' <<<"$RESULT"
fi

[[ "$STATUS" == "error" ]] && exit 1
exit 0
