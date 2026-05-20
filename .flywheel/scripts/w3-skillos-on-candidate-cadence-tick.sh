#!/usr/bin/env bash
# w3-skillos-on-candidate-cadence-tick.sh — Daily W3 cadence (v5).
# Triggers skillos on-candidate for any pending candidates; records decision.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="${W3_REPO:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
LEDGER="${W3_CADENCE_LEDGER:-$REPO_ROOT/.flywheel/state/skill-emission-cadence-ledger.jsonl}"
SKILLOS_REPO="${W3_SKILLOS_REPO:-$HOME/Developer/skillos}"
SKILLOS_FEEDBACK="$SKILLOS_REPO/state/skillos_feedback_ledger.jsonl"

case "${1:-tick}" in
  --info) echo '{"name":"w3-skillos-on-candidate-cadence-tick","schema_version":"flywheel.w3_cadence.v0","wave":"W3","cadence":"daily"}'; exit 0 ;;
  --schema) echo '{"row":"{ts,wave,emit_new_candidate_count_14d,reject_count_14d,promoted_count_14d}"}'; exit 0 ;;
  --examples) echo '{"examples":[{"command":".flywheel/scripts/w3-skillos-on-candidate-cadence-tick.sh tick"}]}'; exit 0 ;;
  health|doctor)
    [[ -f "$SKILLOS_FEEDBACK" ]] && status=ok || status=warn
    printf '{"command":"%s","status":"%s","skillos_feedback":"%s"}\n' "${1}" "$status" "$SKILLOS_FEEDBACK"
    exit 0 ;;
esac

mkdir -p "$(dirname "$LEDGER")"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Scan skillos feedback ledger for last-14d decisions (read-only, no cross-repo write)
result="$(python3 -c "
import json
from datetime import datetime, timezone, timedelta
from pathlib import Path
path = Path('$SKILLOS_FEEDBACK')
if not path.exists():
    print(json.dumps({'emit':0,'reject':0,'promote':0,'total':0}))
    exit(0)
cutoff = datetime.now(timezone.utc) - timedelta(days=14)
counts = {'emit_new_candidate':0,'rejected':0,'promoted':0}
total = 0
for line in path.read_text().splitlines():
    line=line.strip()
    if not line: continue
    try: row=json.loads(line)
    except: continue
    ts = row.get('ts','')
    try:
        if datetime.fromisoformat(ts.replace('Z','+00:00')) < cutoff: continue
    except: continue
    total += 1
    d = row.get('decision','')
    if d == 'emit_new_candidate': counts['emit_new_candidate'] += 1
    elif d == 'promoted': counts['promoted'] += 1
    elif d.startswith('reject'): counts['rejected'] += 1
print(json.dumps({'emit':counts['emit_new_candidate'],'reject':counts['rejected'],'promote':counts['promoted'],'total':total}))
" 2>/dev/null || echo '{"emit":0,"reject":0,"promote":0,"total":0}')"

emit="$(echo "$result" | jq -r '.emit')"
reject="$(echo "$result" | jq -r '.reject')"
promote="$(echo "$result" | jq -r '.promote')"
total="$(echo "$result" | jq -r '.total')"

row="$(jq -nc --arg ts "$TS" --argjson e "$emit" --argjson r "$reject" --argjson p "$promote" --argjson t "$total" \
  '{ts:$ts,wave:"W3",emit_new_candidate_count_14d:$e,reject_count_14d:$r,promoted_count_14d:$p,total_decisions_14d:$t}')"
echo "$row" >>"$LEDGER"
echo "$row"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
