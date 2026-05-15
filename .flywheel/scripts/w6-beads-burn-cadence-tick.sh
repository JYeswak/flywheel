#!/usr/bin/env bash
# w6-beads-burn-cadence-tick.sh — Hourly W6 cadence (v5 forever-goal).
# Scans br ready + counts closures; tracks burn-down trend.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="${W6_REPO:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
LEDGER="${W6_CADENCE_LEDGER:-$REPO_ROOT/.flywheel/state/beads-burn-cadence-ledger.jsonl}"

case "${1:-tick}" in
  --info) echo '{"name":"w6-beads-burn-cadence-tick","schema_version":"flywheel.w6_cadence.v0","wave":"W6","cadence":"hourly"}'; exit 0 ;;
  --schema) echo '{"row":"{ts,wave,ready_count,closed_24h,trend}"}'; exit 0 ;;
  --examples) echo '{"examples":[{"command":".flywheel/scripts/w6-beads-burn-cadence-tick.sh tick"}]}'; exit 0 ;;
  health|doctor)
    command -v br >/dev/null 2>&1 && status=ok || status=fail
    printf '{"command":"%s","status":"%s"}\n' "${1}" "$status"
    [[ "$status" == ok ]] && exit 0 || exit 1 ;;
esac

mkdir -p "$(dirname "$LEDGER")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

ready_count="$(br ready --json 2>/dev/null | jq 'length' 2>/dev/null || echo 0)"
# Count closures from beads jsonl in last 24h
issues_jsonl="$REPO_ROOT/.beads/issues.jsonl"
closed_24h=0
if [[ -f "$issues_jsonl" ]]; then
  closed_24h="$(python3 -c "
import json
from datetime import datetime, timezone, timedelta
cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
n = 0
seen = {}
for line in open('$issues_jsonl'):
    line = line.strip()
    if not line: continue
    try: row = json.loads(line)
    except: continue
    if row.get('status') == 'closed':
        seen[row.get('id')] = row.get('closed_at') or row.get('updated_at') or ''
for ts in seen.values():
    try:
        if datetime.fromisoformat(ts.replace('Z','+00:00')) >= cutoff:
            n += 1
    except: pass
print(n)
" 2>/dev/null || echo 0)"
fi

# Trend: compare to last ledger row's ready_count
prev_ready=0
if [[ -f "$LEDGER" ]]; then
  prev_ready="$(tail -1 "$LEDGER" 2>/dev/null | jq -r '.ready_count // 0' 2>/dev/null || echo 0)"
fi
trend="flat"
if [[ "$ready_count" -gt "$prev_ready" ]]; then trend="up"
elif [[ "$ready_count" -lt "$prev_ready" ]]; then trend="down"; fi

row="$(jq -nc --arg ts "$TS" --argjson rc "$ready_count" --argjson c24 "$closed_24h" --arg trend "$trend" \
  '{ts:$ts,wave:"W6",ready_count:$rc,closed_24h:$c24,trend:$trend}')"
echo "$row" >>"$LEDGER"
echo "$row"
