# FM-1: loop-state-without-driver

**Class:** substrate-config drift (Shape A substrate-without-version-probe)
**Test mode:** SKIPPED-fixture-ready (no `_flywheel_loop_fm1_detect_fix` function in flywheel-loop; detect lives in `flywheel-loop wire-status` upstream surface)
**MEMORY source:** `feedback_loop_state_without_driver.md` — ~/.flywheel/loops/<project>.json `active=true` is a marker, not a driver. Actual ticking needs launchd/cron driver bound at `plist`.

## Detect predicate
- Parse loop config JSON
- If `active == true` AND `plist` field absent OR not pointing at a readable launchd plist → DRIFTED (state-without-driver)

## Fix strategy
- Either degrade `active` to `false` until driver is wired (graceful degradation)
- OR install canonical plist + set `plist` + `plist_label` + `dispatch_mode` + `driver_resolved_at` (recovery)

## Fixture files
- `corrupt-loop-state.json` — `active=true` without `plist` (the FM-1 signature)
- `expected-fix.json` — driver bound (recovery path)
- `undo-original.bak` — byte-exact baseline (= corrupt; pending undo class definition)
