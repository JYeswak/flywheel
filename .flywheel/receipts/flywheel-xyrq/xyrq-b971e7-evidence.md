# flywheel-xyrq Evidence

Task: `flywheel-xyrq-b971e7`

## Changes

- Added `.flywheel/scripts/dicklesworthstone-signal-gate.py`.
- Added `tests/dicklesworthstone-signal-gate.sh`.
- Added `/flywheel:tick` Step 4m in `/Users/josh/.claude/commands/flywheel/tick.md`.

## Validation

```bash
tests/dicklesworthstone-signal-gate.sh
# dicklesworthstone signal gate tests passed

python3 -m py_compile .flywheel/scripts/dicklesworthstone-signal-gate.py

.flywheel/scripts/dicklesworthstone-signal-gate.py schema --json
# schema_version=dicklesworthstone-signal-gate/v1

.flywheel/scripts/dicklesworthstone-signal-gate.py tick --dry-run --json
# active_signal_count=6
# advanced_today_count=0
# ranked_promotion_bead.recommended=true
# doctrine_drift_bead.recommended=true
# no_advance_reason="no extract/archive decision made in this tick"
```

## L112 Probe

```bash
/Users/josh/Developer/flywheel/.flywheel/scripts/dicklesworthstone-signal-gate.py tick --dry-run --json | jq -e '.schema_version == "dicklesworthstone-signal-gate/v1" and .counts.active_signal_count >= 0 and ((.daily_quota.advanced_today_count >= 1) or ((.daily_quota.no_advance_reason // "") | length > 0))'
```

Expected: `jq:true`
