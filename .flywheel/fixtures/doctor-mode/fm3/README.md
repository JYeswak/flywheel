# FM-3: stale-error preflight bypass

**Class:** gating (preflight should block but bypasses)
**Test mode:** SKIPPED-fixture-ready (no `_flywheel_loop_fm3_detect_fix` function in flywheel-loop; detect lives in preflight scope)
**MEMORY source:** preflight conservatism — error states older than threshold MUST block until cleared.

## Detect predicate
- Read error-state file
- If `error_age_seconds > preflight_block_threshold_seconds` AND `preflight_action == "ALLOW"` → BYPASSED (stale error should have blocked)

## Fix strategy
- Set `preflight_action=BLOCK` + emit `block_reason` + `remediation_required`
- Surface to operator; do not auto-clear error state

## Fixture files
- `corrupt-error-state.json` — 122400s-old error with preflight ALLOW (above 86400s threshold)
- `expected-preflight-block.json` — preflight BLOCK with remediation guidance
- `undo-original.bak` — byte-exact baseline
