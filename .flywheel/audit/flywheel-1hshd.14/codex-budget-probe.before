#!/usr/bin/env bash
# codex-budget-probe.sh — sample codex account budget, write fleet state.
#
# Strategy (account-level, NOT per-pane):
#   - send `/status` to ONE codex pane (round-robin across sessions)
#   - read scrollback, parse "5h limit: N% left"
#   - cross-check codex-tui.log for "hit your usage limit" recent (5min)
#   - write ~/.local/state/flywheel/codex-account-budget.json
#
# Output schema:
#   {
#     ts, account, pct_5h_left, pct_weekly_left, pct_context_left,
#     resets_5h, fleet_state ("ready"|"draining"|"limit_hit"),
#     drain_threshold, source_pane, source_session, evidence_lines
#   }
#
# fleet_state computed:
#   - "limit_hit"  if any "hit your usage limit" line in last 10min OR pct_5h_left==0
#   - "draining"   if pct_5h_left <= DRAIN_THRESHOLD (default 10)
#   - "ready"      otherwise

set -uo pipefail

STATE_FILE="${CODEX_BUDGET_STATE:-$HOME/.local/state/flywheel/codex-account-budget.json}"
DRAIN_THRESHOLD="${CODEX_DRAIN_THRESHOLD:-10}"
PROBE_SESSION="${CODEX_PROBE_SESSION:-flywheel}"
PROBE_PANE="${CODEX_PROBE_PANE:-2}"
SCRATCH_DIR="${CODEX_PROBE_SCRATCH:-$HOME/.local/state/flywheel}"

mkdir -p "$SCRATCH_DIR"

usage() {
  cat <<EOF
Usage: codex-budget-probe.sh [--apply] [--session NAME] [--pane N] [--threshold PCT]

Default: --apply (writes state file).
  --session NAME    pane session to probe (default: flywheel)
  --pane N          pane index to probe (default: 2)
  --threshold PCT   drain threshold % (default: 10)
  --no-write        skip writing state file (test mode)

Reads codex-tui.log for recent "hit your usage limit" errors as fast path.
EOF
}

WRITE=1
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) WRITE=1; shift ;;
    --no-write) WRITE=0; shift ;;
    --session) PROBE_SESSION="$2"; shift 2 ;;
    --session=*) PROBE_SESSION="${1#*=}"; shift ;;
    --pane) PROBE_PANE="$2"; shift 2 ;;
    --pane=*) PROBE_PANE="${1#*=}"; shift ;;
    --threshold) DRAIN_THRESHOLD="$2"; shift 2 ;;
    --threshold=*) DRAIN_THRESHOLD="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; usage; exit 2 ;;
  esac
done

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOG="$HOME/.codex/log/codex-tui.log"

# === Fast path: check log for recent "hit your usage limit" ===
LIMIT_HIT_RECENT=0
LIMIT_HIT_TS=""
if [ -f "$LOG" ]; then
  # Look for "hit your usage limit" in last 600 lines (~10 min of activity)
  # Extract timestamp; if within last 10 min, fleet=limit_hit
  RECENT_HIT=$(tail -2000 "$LOG" 2>/dev/null | grep -E "hit your usage limit|usage limit\. Visit" | tail -1)
  if [ -n "$RECENT_HIT" ]; then
    HIT_TS=$(echo "$RECENT_HIT" | grep -oE "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z" | head -1)
    if [ -n "$HIT_TS" ]; then
      HIT_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${HIT_TS%.*}" +%s 2>/dev/null || echo 0)
      NOW_EPOCH=$(date +%s)
      AGE=$((NOW_EPOCH - HIT_EPOCH))
      if [ "$AGE" -lt 600 ]; then
        LIMIT_HIT_RECENT=1
        LIMIT_HIT_TS="$HIT_TS"
      fi
    fi
  fi
fi

# === Slow path: probe via /status, take MIN across all idle codex panes ===
# Why MIN: codex caches /status per-pane; freshest reading is lowest.
PROBE_OK=0
PCT_5H=""
PCT_WEEKLY=""
PCT_CONTEXT=""
RESETS_5H=""
ACCOUNT=""
PROBED_PANES=""

probe_one_pane() {
  local sess="$1" pane="$2"
  local info agent state tail
  info=$(/Users/josh/.local/bin/ntm --robot-activity="$sess" --activity-type=codex 2>/dev/null \
    | jq -r --argjson p "$pane" '.agents[] | select((.pane_idx|tostring) == ($p|tostring)) | "\(.agent_type)|\(.state)"' 2>/dev/null \
    | head -1)
  agent=$(echo "$info" | cut -d'|' -f1)
  state=$(echo "$info" | cut -d'|' -f2)
  [ "$agent" != "codex" ] && return 1
  [ "$state" != "WAITING" ] && return 1

  /Users/josh/.local/bin/ntm send "$sess" --pane="$pane" --no-cass-check "/status" 2>/dev/null >/dev/null
  sleep 4

  tail=$(/Users/josh/.local/bin/ntm --robot-tail="$sess" --panes="$pane" --lines=80 2>/dev/null \
    | jq -r ".panes[\"$pane\"].lines[]" 2>/dev/null | tail -50)
  echo "$tail" | grep -q "5h limit:" || return 1

  local p5h pweekly pctx resets acct
  p5h=$(echo "$tail" | grep -E "^\s*│?\s*5h limit:" | grep -v "Spark" | head -1 | grep -oE "[0-9]+% left" | head -1 | grep -oE "^[0-9]+")
  pweekly=$(echo "$tail" | grep -E "^\s*│?\s*Weekly limit:" | head -1 | grep -oE "[0-9]+% left" | head -1 | grep -oE "^[0-9]+")
  pctx=$(echo "$tail" | grep -E "Context window:" | head -1 | grep -oE "[0-9]+% left" | head -1 | grep -oE "^[0-9]+")
  resets=$(echo "$tail" | grep -A 1 -E "^\s*│?\s*5h limit:" | grep -v "Spark" | grep -oE "resets [^)│]+" | head -1 | sed 's/^resets //' | xargs)
  acct=$(echo "$tail" | grep -E "Account:" | head -1 | sed 's/.*Account:\s*//; s/[│║].*//' | xargs)

  [ -z "$p5h" ] && return 1
  echo "$sess|$pane|$p5h|$pweekly|$pctx|$resets|$acct"
}

# Enumerate all sessions; probe one idle codex pane per session (first found)
SESSIONS=$(/Users/josh/.local/bin/ntm list 2>/dev/null | awk -F: '/[a-z].*windows/ {gsub(/^ +/,"",$1); print $1}')
declare -a PROBE_RESULTS=()

for sess in $SESSIONS; do
  PANES=$(/Users/josh/.local/bin/ntm --robot-activity="$sess" --activity-type=codex 2>/dev/null \
    | jq -r '.agents[] | select(.state == "WAITING") | .pane_idx' 2>/dev/null)
  for p in $PANES; do
    result=$(probe_one_pane "$sess" "$p" 2>/dev/null)
    if [ -n "$result" ]; then
      PROBE_RESULTS+=("$result")
      PROBED_PANES="$PROBED_PANES $sess:$p"
      break  # one pane per session is enough
    fi
  done
done

# Compute min across results
if [ "${#PROBE_RESULTS[@]}" -gt 0 ]; then
  PROBE_OK=1
  # Find result with lowest pct_5h
  MIN_5H=999
  for r in "${PROBE_RESULTS[@]}"; do
    p5h=$(echo "$r" | cut -d'|' -f3)
    if [ -n "$p5h" ] && [ "$p5h" -lt "$MIN_5H" ]; then
      MIN_5H="$p5h"
      PROBE_SESSION=$(echo "$r" | cut -d'|' -f1)
      PROBE_PANE=$(echo "$r" | cut -d'|' -f2)
      PCT_5H="$p5h"
      PCT_WEEKLY=$(echo "$r" | cut -d'|' -f4)
      PCT_CONTEXT=$(echo "$r" | cut -d'|' -f5)
      RESETS_5H=$(echo "$r" | cut -d'|' -f6)
      ACCOUNT=$(echo "$r" | cut -d'|' -f7)
    fi
  done
fi

# === Compute fleet state ===
# Note: log-based LIMIT_HIT_RECENT can fire from a PRIOR account that hit the limit
# but has since been rotated away. Trust the live /status reading over the log
# unless we see a hit AND the current account is still showing low pct.
FLEET_STATE="ready"
REASON=""
if [ "$PROBE_OK" = "1" ] && [ -n "$PCT_5H" ]; then
  if [ "$PCT_5H" -le 0 ]; then
    FLEET_STATE="limit_hit"
    REASON="pct_5h_left=$PCT_5H% (live /status)"
  elif [ "$PCT_5H" -le "$DRAIN_THRESHOLD" ]; then
    FLEET_STATE="draining"
    REASON="pct_5h_left=$PCT_5H% <= threshold=$DRAIN_THRESHOLD% (live /status)"
  else
    REASON="pct_5h_left=$PCT_5H% > threshold=$DRAIN_THRESHOLD% (live /status)"
  fi
  # Only flag log-hit if CURRENT pct is also low (cross-validation)
  if [ "$LIMIT_HIT_RECENT" = "1" ] && [ "$PCT_5H" -le "$DRAIN_THRESHOLD" ]; then
    FLEET_STATE="limit_hit"
    REASON="$REASON; log confirms hit at $LIMIT_HIT_TS"
  fi
elif [ "$LIMIT_HIT_RECENT" = "1" ]; then
  FLEET_STATE="limit_hit"
  REASON="usage limit hit at $LIMIT_HIT_TS (no live probe — assuming worst)"
else
  REASON="probe failed (no idle codex pane returned /status)"
fi

# === Write JSON state file ===
JSON=$(jq -n \
  --arg ts "$TS" \
  --arg account "$ACCOUNT" \
  --arg pct_5h "$PCT_5H" \
  --arg pct_weekly "$PCT_WEEKLY" \
  --arg pct_context "$PCT_CONTEXT" \
  --arg resets_5h "$RESETS_5H" \
  --arg fleet_state "$FLEET_STATE" \
  --argjson drain_threshold "$DRAIN_THRESHOLD" \
  --arg reason "$REASON" \
  --arg source_session "$PROBE_SESSION" \
  --arg source_pane "$PROBE_PANE" \
  --argjson probe_ok "$PROBE_OK" \
  --argjson limit_hit_recent "$LIMIT_HIT_RECENT" \
  --arg limit_hit_ts "$LIMIT_HIT_TS" \
  --arg probed_panes "$PROBED_PANES" \
  '{
    ts: $ts,
    account: $account,
    pct_5h_left: ($pct_5h | if . == "" then null else (. | tonumber) end),
    pct_weekly_left: ($pct_weekly | if . == "" then null else (. | tonumber) end),
    pct_context_left: ($pct_context | if . == "" then null else (. | tonumber) end),
    resets_5h: $resets_5h,
    fleet_state: $fleet_state,
    drain_threshold: $drain_threshold,
    reason: $reason,
    source: {session: $source_session, pane: ($source_pane | tonumber), probe_ok: ($probe_ok == 1), limit_hit_recent: ($limit_hit_recent == 1), limit_hit_ts: $limit_hit_ts, probed_panes: ($probed_panes | ltrimstr(" "))}
  }')

if [ "$WRITE" = "1" ]; then
  TMP=$(mktemp "${SCRATCH_DIR}/.budget-probe.XXXXXX.json")
  echo "$JSON" > "$TMP"
  mv "$TMP" "$STATE_FILE"
fi

echo "$JSON"
exit 0
