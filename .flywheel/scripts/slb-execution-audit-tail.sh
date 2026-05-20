#!/usr/bin/env bash
set -euo pipefail

AUDIT_LOG="${SLB_AUDIT_LOG:-$HOME/.local/state/flywheel/slb-execution-audit.jsonl}"
LIMIT=20
RECIPE_ID=""
JSON_OUTPUT=0

usage() {
  cat <<'EOF'
Usage: slb-execution-audit-tail.sh [--audit-log PATH] [--limit N] [--recipe-id ID] [--json]
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --audit-log) AUDIT_LOG="${2:-}"; shift 2 ;;
    --limit) LIMIT="${2:-}"; shift 2 ;;
    --recipe-id) RECIPE_ID="${2:-}"; shift 2 ;;
    --json) JSON_OUTPUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

case "$LIMIT" in
  ''|*[!0-9]*) printf 'limit must be numeric\n' >&2; exit 2 ;;
esac

if [ ! -f "$AUDIT_LOG" ]; then
  if [ "$JSON_OUTPUT" -eq 1 ]; then
    jq -nc --arg audit_log "$AUDIT_LOG" '{schema_version:"flywheel.slb.audit_tail.v1",status:"missing",audit_log:$audit_log,rows:[]}'
  else
    printf 'SLB audit log missing: %s\n' "$AUDIT_LOG"
  fi
  exit 0
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/slb-audit-tail.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

jq -c --arg recipe_id "$RECIPE_ID" '
  select(($recipe_id == "") or (.recipe_id == $recipe_id))
' "$AUDIT_LOG" | tail -n "$LIMIT" >"$tmp"

if [ "$JSON_OUTPUT" -eq 1 ]; then
  jq -s --arg audit_log "$AUDIT_LOG" --arg recipe_id "$RECIPE_ID" \
    '{schema_version:"flywheel.slb.audit_tail.v1",status:"ok",audit_log:$audit_log,recipe_id:(if $recipe_id == "" then null else $recipe_id end),rows:.}' "$tmp"
else
  jq -r '[.ts,.outcome,.recipe_id,.stage,.snapshot_path] | @tsv' "$tmp"
fi
