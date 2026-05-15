#!/usr/bin/env bash
# w4-skill-consumed-cadence-tick.sh — Hourly W4 cadence (v5 forever-goal).
# Scans dispatch-log.jsonl for skill_consumed callbacks in last 24h.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="${W4_REPO:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
LEDGER="${W4_CADENCE_LEDGER:-$REPO_ROOT/.flywheel/state/skill-consumed-cadence-ledger.jsonl}"
DISPATCH_LOG="${W4_DISPATCH_LOG:-$REPO_ROOT/.flywheel/dispatch-log.jsonl}"

case "${1:-tick}" in
  --info) echo '{"name":"w4-skill-consumed-cadence-tick","schema_version":"flywheel.w4_cadence.v0","wave":"W4","cadence":"hourly"}'; exit 0 ;;
  --schema) echo '{"row":"{ts,wave,skill_consumed_count_24h,skills,total_dispatches_24h}"}'; exit 0 ;;
  --examples) echo '{"examples":[{"command":".flywheel/scripts/w4-skill-consumed-cadence-tick.sh tick"}]}'; exit 0 ;;
  health|doctor)
    [[ -f "$DISPATCH_LOG" ]] && status=ok || status=warn
    printf '{"command":"%s","status":"%s","dispatch_log":"%s"}\n' "${1}" "$status" "$DISPATCH_LOG"
    exit 0 ;;
esac

mkdir -p "$(dirname "$LEDGER")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

result="$(python3 -c "
import json
from datetime import datetime, timezone, timedelta
from pathlib import Path
path = Path('$DISPATCH_LOG')
if not path.exists():
    print(json.dumps({'count':0,'skills':[],'total':0}))
    exit(0)
cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
skills_consumed = []
total = 0
for line in path.read_text().splitlines():
    line = line.strip()
    if not line: continue
    try: row = json.loads(line)
    except: continue
    ts = row.get('ts') or row.get('callback_received_at') or ''
    try:
        if not ts or datetime.fromisoformat(ts.replace('Z','+00:00')) < cutoff:
            continue
    except: continue
    total += 1
    sk = row.get('skill_consumed')
    if sk:
        skills_consumed.append(sk)
print(json.dumps({'count': len(skills_consumed),'skills': sorted(set(skills_consumed))[:10],'total': total}))
" 2>/dev/null || echo '{"count":0,"skills":[],"total":0}')"

count="$(echo "$result" | jq -r '.count')"
total="$(echo "$result" | jq -r '.total')"
skills="$(echo "$result" | jq -c '.skills')"

row="$(jq -nc --arg ts "$TS" --argjson c "$count" --argjson t "$total" --argjson s "$skills" \
  '{ts:$ts,wave:"W4",skill_consumed_count_24h:$c,skills:$s,total_dispatches_24h:$t}')"
echo "$row" >>"$LEDGER"
echo "$row"
