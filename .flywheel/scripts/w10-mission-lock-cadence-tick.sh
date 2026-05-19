#!/usr/bin/env bash
# w10-mission-lock-cadence-tick.sh — Daily W10 cadence (v5 forever-goal).
# Probes mission_lock_status age; warns at 14d, alarms at 30d.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="${W10_REPO:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
LEDGER="${W10_CADENCE_LEDGER:-$REPO_ROOT/.flywheel/state/mission-lock-cadence-ledger.jsonl}"
DOCTOR="${W10_FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"

case "${1:-tick}" in
  --info) echo '{"name":"w10-mission-lock-cadence-tick","schema_version":"flywheel.w10_cadence.v0","wave":"W10","cadence":"daily"}'; exit 0 ;;
  --schema) echo '{"row":"{ts,wave,mission_lock_age_hours,status,warn_threshold_hit,alarm_threshold_hit}"}'; exit 0 ;;
  --examples) echo '{"examples":[{"command":".flywheel/scripts/w10-mission-lock-cadence-tick.sh tick"}]}'; exit 0 ;;
  health|doctor)
    [[ -x "$DOCTOR" ]] && status=ok || status=fail
    printf '{"command":"%s","status":"%s","doctor":"%s"}\n' "${1}" "$status" "$DOCTOR"
    [[ "$status" == ok ]] && exit 0 || exit 1 ;;
esac

mkdir -p "$(dirname "$LEDGER")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

doctor_json="$("$DOCTOR" doctor --repo "$REPO_ROOT" --json 2>/dev/null || true)"
age_hours="$(jq -r '.mission_lock_age.mission_lock_age_hours // .mission_lock_age_hours // 0' <<<"$doctor_json" 2>/dev/null || echo 0)"
[[ -z "$age_hours" ]] && age_hours=0
# Guard against multi-line/empty values
age_hours="$(printf '%s' "$age_hours" | head -1 | tr -d '[:space:]')"
[[ "$age_hours" =~ ^[0-9.]+$ ]] || age_hours=0

warn=false; alarm=false
python3 -c "import sys; sys.exit(0 if float('$age_hours') >= 336 else 1)" 2>/dev/null && warn=true
python3 -c "import sys; sys.exit(0 if float('$age_hours') >= 720 else 1)" 2>/dev/null && alarm=true

status="fresh"
[[ "$warn" == true ]] && status="warn-14d"
[[ "$alarm" == true ]] && status="alarm-30d"

row="$(jq -nc --arg ts "$TS" --arg age "$age_hours" --arg s "$status" --argjson w "$warn" --argjson a "$alarm" \
  '{ts:$ts,wave:"W10",mission_lock_age_hours:($age|tonumber),status:$s,warn_threshold_hit:$w,alarm_threshold_hit:$a}')"
echo "$row" >>"$LEDGER"
echo "$row"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
