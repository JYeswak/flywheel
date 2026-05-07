#!/usr/bin/env bash
# dispatch-and-verify — send a dispatch file to an ntm pane and verify the
# worker actually started thinking (vs. landing in codex's chevron buffer
# without submitting).
#
# Trauma class: codex-chevron-stuck-on-dispatch
# Source finding: mobile-eats/.flywheel/findings/2026-05-06-codex-chevron-stuck-on-dispatch.md
# Promoted to canonical: flywheel:1 verdict 2026-05-06
# Prior path (deprecated): ~/.local/bin/dispatch-and-verify
#
# Usage:
#   dispatch-and-verify.sh <session> <pane> <dispatch-file-path>
#
# Behavior:
#   1. Validates the dispatch file exists.
#   2. Sends the canonical "Read <file> and execute it..." prompt via ntm send.
#   3. Sleeps 15s, then probes pane state via ntm --robot-activity.
#   4. If the pane is still WAITING (or THINKING with zero velocity), sends an
#      empty Enter and re-probes. Up to 3 retry cycles.
#   5. Exits 0 on confirmed THINKING (work in flight); exits 1 with a diagnostic
#      dump if the pane is still stuck after retries.
#
# Cross-orch coordination ledger: ~/.local/state/flywheel/cross-orch-coordination.jsonl

set -euo pipefail

NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"

if [[ $# -ne 3 ]]; then
  echo "usage: dispatch-and-verify <session> <pane> <dispatch-file-path>" >&2
  exit 2
fi

SESSION="$1"
PANE="$2"
DISPATCH_FILE="$3"

if [[ ! -f "$DISPATCH_FILE" ]]; then
  echo "dispatch-and-verify: dispatch file not found: $DISPATCH_FILE" >&2
  exit 2
fi

PROMPT="Read ${DISPATCH_FILE} and execute it..."

ntm_changes_snapshot() {
  "$NTM_BIN" changes "$SESSION" --json 2>/dev/null || printf 'null\n'
}

ntm_conflicts_snapshot() {
  "$NTM_BIN" conflicts "$SESSION" --json --limit 50 2>/dev/null || printf 'null\n'
}

# probe_pane echoes one of: THINKING_LIVE | STUCK | UNKNOWN
probe_pane() {
  local activity_json
  activity_json="$("$NTM_BIN" --robot-activity --session "$SESSION" 2>/dev/null || true)"
  if [[ -z "$activity_json" ]]; then
    echo "UNKNOWN"
    return
  fi
  # Pull state and velocity for the requested pane via python (jq not assumed).
  ACTIVITY_JSON="$activity_json" python3 -c '
import json, os, sys
pane = sys.argv[1]
data = json.loads(os.environ.get("ACTIVITY_JSON", "") or "{}")
for a in data.get("agents", []):
    if str(a.get("pane")) == str(pane):
        state = a.get("state", "UNKNOWN")
        vel = a.get("velocity", 0) or 0
        if state == "THINKING" and vel > 0:
            print("THINKING_LIVE"); sys.exit(0)
        if state in ("WAITING", "UNKNOWN") or (state == "THINKING" and vel == 0):
            print("STUCK"); sys.exit(0)
        print("THINKING_LIVE" if state == "THINKING" else "STUCK"); sys.exit(0)
print("UNKNOWN")
' "$PANE"
}

# Initial dispatch. printf 'y\n' answers any interactive confirm ntm may emit.
echo "[dispatch-and-verify] sending dispatch to ${SESSION}:${PANE} -> ${DISPATCH_FILE}"
echo "[dispatch-and-verify] ntm conflicts pre-dispatch: $(ntm_conflicts_snapshot | jq -c '{status:(.status // .overall // "unknown"), conflict_count:(.conflict_count // .count // (.conflicts // [] | length) // 0)}' 2>/dev/null || printf 'null')"
printf 'y\n' | "$NTM_BIN" send "$SESSION" --pane "$PANE" "$PROMPT" >/dev/null

sleep 15

for attempt in 1 2 3; do
  state="$(probe_pane)"
  echo "[dispatch-and-verify] attempt ${attempt} state=${state}"
  if [[ "$state" == "THINKING_LIVE" ]]; then
    echo "[dispatch-and-verify] ntm changes post-dispatch: $(ntm_changes_snapshot | jq -c '{status:(.status // "ok"), changed_count:(.changed_count // .count // (.changes // [] | length) // 0)}' 2>/dev/null || printf 'null')"
    echo "[dispatch-and-verify] OK — worker is thinking."
    exit 0
  fi
  echo "[dispatch-and-verify] pane appears stuck (likely codex chevron buffer); firing empty Enter."
  printf 'y\n' | "$NTM_BIN" send "$SESSION" --pane "$PANE" "" >/dev/null || true
  sleep 5
done

echo "[dispatch-and-verify] FAIL — pane ${SESSION}:${PANE} still stuck after 3 retries." >&2
echo "[dispatch-and-verify] diagnostic dump:" >&2
"$NTM_BIN" --robot-activity --session "$SESSION" >&2 || true
echo "[dispatch-and-verify] ntm changes failure snapshot: $(ntm_changes_snapshot | jq -c . 2>/dev/null || printf 'null')" >&2
echo "[dispatch-and-verify] ntm conflicts failure snapshot: $(ntm_conflicts_snapshot | jq -c . 2>/dev/null || printf 'null')" >&2
echo "[dispatch-and-verify] consider: $NTM_BIN respawn ${SESSION} --panes=${PANE} --force" >&2
exit 1
