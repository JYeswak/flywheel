# FM-4: callback Monitor not armed

**Class:** dispatch (silent-deaf risk; callback channel unguarded)
**Test mode:** SKIPPED-fixture-ready (no `_flywheel_loop_fm4_detect_fix` function in flywheel-loop; detect lives in dispatch-surface upstream)
**MEMORY source:** `feedback_dispatch_post_send_verify_for_silent_deaf.md` — ntm send "Sent to pane N" is transport ack, not worker-processed; Monitor MUST be armed on dispatch.

## Detect predicate
- Read dispatch row
- If `dispatch_sent == true` AND `monitor_armed == false` AND `callback_received == false` → UNGUARDED (silent-deaf risk)

## Fix strategy
- Arm Monitor on dispatch-log.jsonl tail filtered to `task_id`
- Update row with `monitor_armed=true` + `monitor_armed_at`
- Silent-deaf risk transitions from `high` → `mitigated`

## Fixture files
- `corrupt-dispatch-no-monitor.jsonl` — dispatch row with monitor_armed=false (silent-deaf risk)
- `expected-monitor-armed.jsonl` — monitor armed with arm-ts
- `undo-original.bak` — byte-exact baseline
