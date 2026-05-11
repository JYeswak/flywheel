# FM-2: pulse-stale → DEAD misclassification

**Class:** classifier (false-positive DEAD when pane is alive)
**Test mode:** SKIPPED-fixture-ready (no `_flywheel_loop_fm2_detect_fix` function in flywheel-loop; detect lives in pulse-log classifier upstream)
**MEMORY source:** pulse-log classifier conservatism — 30s pulse-stale ≠ DEAD when grace window is 600s.

## Detect predicate
- Read pulse-log row
- If `class == "DEAD"` AND `(ts - last_pulse_ts) < grace_window_sec` → MISCLASSIFIED (within grace; should be ALIVE)

## Fix strategy
- Append corrected row with `class=ALIVE` + `reclassified_from=DEAD` + `reclassified_reason`
- Audit trail preserves original DEAD row (append-only ledger)

## Fixture files
- `corrupt-pulse-row.jsonl` — DEAD classification with 30s pulse-stale inside 600s grace window
- `expected-fix.jsonl` — ALIVE with reclassification provenance
- `undo-original.bak` — byte-exact baseline
