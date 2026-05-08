#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${FLYWHEEL_STORAGE_PAUSE_STATE:-$HOME/.local/state/flywheel/storage-pause-active.json}"
RECLAIM_DIR="${FLYWHEEL_RECLAIM_RECEIPT_DIR:-$HOME/.local/state/flywheel/reclaim-receipts}"
APPLY=0
JSON_OUT=0
KILL_BIN="${KILL_BIN:-kill}"

usage() {
  cat <<'EOF'
usage: storage-pause-auto-resume.sh [--state PATH] [--reclaim-dir PATH] [--dry-run|--apply] [--json]

Resumes SIGSTOP-paused storage-growth workers when a reclaim receipt exists
newer than the active storage-pause signal. Default is dry-run.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --state) STATE_FILE="$2"; shift 2 ;;
    --reclaim-dir) RECLAIM_DIR="$2"; shift 2 ;;
    --dry-run) APPLY=0; shift ;;
    --apply) APPLY=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERR: unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ ! -f "$STATE_FILE" ]; then
  jq -nc '{schema_version:"storage-pause-auto-resume/v1",status:"no_active_pause",resumed_count:0}'
  exit 0
fi

latest_reclaim="$(find "$RECLAIM_DIR" -type f -name '*.json' -print 2>/dev/null | sort | tail -1 || true)"
if [ -z "$latest_reclaim" ]; then
  jq -nc --arg state "$STATE_FILE" '{schema_version:"storage-pause-auto-resume/v1",status:"waiting_for_reclaim_receipt",state_path:$state,resumed_count:0}'
  exit 0
fi

reclaim_ts="$(jq -r '.issued_at // .created_at // .ts // empty' "$latest_reclaim" 2>/dev/null || true)"
pause_ts="$(jq -r '.generated_at // empty' "$STATE_FILE" 2>/dev/null || true)"
if [ -n "$reclaim_ts" ] && [ -n "$pause_ts" ] && [[ "$reclaim_ts" < "$pause_ts" ]]; then
  jq -nc --arg state "$STATE_FILE" --arg reclaim "$latest_reclaim" '{schema_version:"storage-pause-auto-resume/v1",status:"reclaim_receipt_stale",state_path:$state,reclaim_receipt:$reclaim,resumed_count:0}'
  exit 0
fi

pids="$(jq -r '.paused_workers[]? | .pids[]?' "$STATE_FILE" 2>/dev/null | sort -n | uniq || true)"
resumed_count=0
failed_count=0
resumed_json="[]"
failed_json="[]"

while IFS= read -r pid; do
  [ -n "$pid" ] || continue
  if [ "$APPLY" -eq 1 ]; then
    if "$KILL_BIN" -CONT "$pid" 2>/dev/null; then
      resumed_count=$((resumed_count + 1))
      resumed_json="$(jq -nc --argjson old "$resumed_json" --arg pid "$pid" '$old + [$pid]')"
    else
      failed_count=$((failed_count + 1))
      failed_json="$(jq -nc --argjson old "$failed_json" --arg pid "$pid" '$old + [$pid]')"
    fi
  else
    resumed_json="$(jq -nc --argjson old "$resumed_json" --arg pid "$pid" '$old + [$pid]')"
  fi
done <<EOF
$pids
EOF

status="would_resume"
if [ "$APPLY" -eq 1 ]; then
  if [ "$failed_count" -gt 0 ]; then
    status="partial"
  else
    status="resumed"
  fi
fi

jq -nc \
  --arg status "$status" \
  --arg state "$STATE_FILE" \
  --arg reclaim "$latest_reclaim" \
  --argjson apply "$APPLY" \
  --argjson resumed_count "$resumed_count" \
  --argjson failed_count "$failed_count" \
  --argjson resumed "$resumed_json" \
  --argjson failed "$failed_json" \
  '{schema_version:"storage-pause-auto-resume/v1",status:$status,apply:($apply==1),state_path:$state,reclaim_receipt:$reclaim,resumed_count:$resumed_count,failed_count:$failed_count,pids:$resumed,failed_pids:$failed}'
