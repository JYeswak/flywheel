# FM-5: stale-prompt time-heartbeat

**Class:** audit-only-retraction (Shape D phantom-requirement)
**Test mode:** RUN — `flywheel-loop doctor fm5 --row <PATH> --prior-row <PATH> --apply` (.2.3 ship)
**MEMORY source:** `feedback_orch_wake_event_driven_not_time_based.md` (META-RULE 2026-05-08)

## Detect predicate
- Compute cur SHA from row's `tick_prompt_sha256`
- Compare to prior row's `tick_prompt_sha256`
- If identical AND `wake_class == "heartbeat"` → STALE (re-shipped frozen prompt)

## Fix strategy (audit-only retraction)
- Append retraction row to `~/.local/state/flywheel/fm5-retractions.jsonl` (sandboxed via `FLYWHEEL_FM5_RETRACTIONS` env for tests)
- No substrate mutation (cadence ignores retracted rows)

## Round-trip protocol
1. Read `corrupt-tick-row.jsonl` + `corrupt-prior-row.jsonl`
2. Invoke `flywheel-loop doctor fm5 --row "$ROW_JSON" --prior-row "$PRIOR_JSON" --apply --json`
3. Expect rc=1 + `detected=true`
4. Verify retraction ledger has 1 row matching `expected-retraction.jsonl` shape (timestamps dynamic; class + sha must match)

## Fixture files
- `corrupt-tick-row.jsonl` — heartbeat tick with stale prompt SHA
- `corrupt-prior-row.jsonl` — prior heartbeat tick with same SHA
- `expected-retraction.jsonl` — retraction ledger row shape (DYNAMIC_TS placeholder)
- `undo-original.bak` — byte-exact baseline (audit-only; not used for undo)
