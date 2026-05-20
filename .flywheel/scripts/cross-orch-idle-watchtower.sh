#!/usr/bin/env bash
# cross-orch-idle-watchtower.sh — fleet-wide nudge for idle sister-orch codex panes.
#
# Joshua-direct 2026-05-20T03:45Z: "every time I come back skillos is idle" (15+ times today).
# Trauma class: orchestrator-idle-with-ready-beads.
# Solution: periodic probe → if sister orch's codex pane is idle-chat + their own ready
# queue has P0/P1 work → either:
#   (a) send a NUDGE handoff to sister orch CC pane (default — respects autonomy)
#   (b) DIRECT cross-orch /goal dispatch (per flywheel-owns-orch-pane-recovery memory
#       authority — use sparingly, only when sister CC unresponsive)
#
# Designed to run as launchd cadence every 5-10min.
#
# Exit codes:
#   0 = no idle panes detected, or all nudges sent
#   1 = config/probe error

set -uo pipefail

INTERVAL_DEFAULT=600
MODE="${WATCHTOWER_MODE:-nudge}"
JSON_OUT=false
DRY_RUN=false
SESSIONS=(
  "skillos:/Users/josh/Developer/skillos"
  "mobile-eats:/Users/josh/Developer/mobile-eats"
  "picoz:/Users/josh/Developer/picoz"
  "clutterfreespaces:/Users/josh/Developer/clutterfreespaces"
  "alpsinsurance:/Users/josh/Developer/alpsinsurance"
  "vrtx:/Users/josh/Developer/vrtx"
  "zesttube:/Users/josh/Developer/zesttube"
)
LEDGER="${HOME}/.local/state/flywheel/cross-orch-idle-watchtower.jsonl"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;       # nudge | direct-dispatch | report-only
    --json) JSON_OUT=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$(dirname "$LEDGER")"

classify_pane_state() {
  local target="$1"
  local snap
  snap="$(tmux capture-pane -t "$target" -p 2>/dev/null | tail -30)"
  if echo "$snap" | grep -qE 'Pursuing goal \('; then echo "goal-in-progress"
  elif echo "$snap" | grep -q "Goal paused"; then echo "goal-paused"
  elif echo "$snap" | grep -qE "Working \([0-9]+s"; then echo "working-non-goal"
  elif echo "$snap" | grep -q "Goal achieved\|Goal complete"; then echo "goal-completing"
  elif echo "$snap" | grep -qE "› (Use /skills|Explain this codebase|Implement \{|Write tests|Find and fix|Run /review|Summarize recent|Improve documentation)"; then echo "idle-chat-default-placeholder"
  elif echo "$snap" | grep -q "Application not found\|josh@.*%"; then echo "shell-no-codex"
  else echo "idle-chat-or-unknown"
  fi
}

count_ready_beads() {
  local repo_path="$1"
  if [[ -d "$repo_path/.beads" ]]; then
    (cd "$repo_path" && /Users/josh/.cargo/bin/br ready --json 2>/dev/null | \
      python3 -c "
import json,sys
try:
    d=json.load(sys.stdin); items=d if isinstance(d,list) else d.get('items',[])
    p0=sum(1 for i in items if i.get('priority')==0)
    p1=sum(1 for i in items if i.get('priority')==1)
    print(f'{p0} {p1}')
except: print('0 0')
")
  else
    echo "0 0"
  fi
}

emit_row() {
  printf '{"schema_version":"cross_orch_idle_watchtower.v1","ts":"%s","session":"%s","pane":%d,"state":"%s","p0_ready":%d,"p1_ready":%d,"action":"%s","reason":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" "$3" "$4" "$5" "$6" "$7" \
    | tee -a "$LEDGER"
}

idle_detected=0
nudges_sent=0
direct_dispatches=0

for entry in "${SESSIONS[@]}"; do
  sess="${entry%:*}"
  repo="${entry#*:}"
  if ! tmux has-session -t "$sess" 2>/dev/null; then
    continue
  fi
  read -r p0 p1 <<< "$(count_ready_beads "$repo")"

  for pane in 2 3 4; do
    if ! tmux list-panes -t "${sess}:0" -F '#{pane_index}' 2>/dev/null | grep -q "^${pane}$"; then
      continue
    fi
    state="$(classify_pane_state "${sess}:0.${pane}")"
    is_idle=0
    case "$state" in
      idle-chat-*|goal-completing) is_idle=1 ;;
    esac

    if (( is_idle == 1 )) && (( p0 + p1 > 0 )); then
      idle_detected=$((idle_detected + 1))
      action="report-only"
      reason="sister-orch-cc-may-handle"
      if [[ "$MODE" == "nudge" ]] && [[ "$DRY_RUN" != "true" ]]; then
        # Send handoff-style nudge to sister orch CC pane (pane 1)
        nudge_msg="ORCH-IDLE NUDGE from flywheel:1 cross-orch-idle-watchtower at $(date -u +%H:%MZ): your pane ${pane} is ${state} but your repo has P0=${p0} P1=${p1} ready beads. Dispatch via your own /skillos:dispatch (or equivalent) using /goal-mode workaround per memory feedback_goal_mode_is_codex_usage_limit_workaround. Don't go idle when work is available."
        if /Users/josh/.local/bin/ntm send "$sess" --pane=1 --no-cass-check "$nudge_msg" >/dev/null 2>&1; then
          action="nudge-sent"
          nudges_sent=$((nudges_sent + 1))
        else
          action="nudge-failed"
          reason="ntm-send-error"
        fi
      elif [[ "$MODE" == "direct-dispatch" ]] && [[ "$DRY_RUN" != "true" ]]; then
        # ONLY use when sister CC confirmed unresponsive — needs explicit override
        action="direct-dispatch-suppressed"
        reason="direct-dispatch-needs-explicit-override-flag-NOT-yet-built"
      fi
    fi

    if (( is_idle == 1 )) && (( p0 + p1 > 0 )); then
      emit_row "$sess" "$pane" "$state" "$p0" "$p1" "$action" "$reason" >/dev/null
    fi
  done
done

if [[ "$JSON_OUT" == "true" ]]; then
  printf '{"schema_version":"cross_orch_idle_watchtower.v1","ts":"%s","mode":"%s","dry_run":%s,"idle_panes_with_ready_beads":%d,"nudges_sent":%d,"direct_dispatches":%d,"ledger":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$MODE" "$DRY_RUN" "$idle_detected" "$nudges_sent" "$direct_dispatches" "$LEDGER"
else
  echo "idle_panes_with_ready_beads=$idle_detected nudges_sent=$nudges_sent direct_dispatches=$direct_dispatches"
fi
