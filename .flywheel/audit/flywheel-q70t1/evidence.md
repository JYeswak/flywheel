# Evidence: flywheel-q70t1 — B12_AG4 validate-tick-phase 17 inner failures triage

**Bead**: flywheel-q70t1 (P2) | **Task ID**: flywheel-q70t1-96d166 | **Identity**: MistyCliff
**Surface**: `tests/validate-tick-phase.sh`
**Memory rule applied**: `feedback_calibrate_test_to_actual_contract_before_filing_upstream`

## Triage result

All 17 inner failures classified as **CALIBRATION** (none REGRESSION). Single unified class: validator contract evolved to require `evidence_redacted=` and bead-routing fields; test callbacks pre-dated this evolution. See `triage.md` for per-test classification.

## Fix

Two string-replacement edits to `tests/validate-tick-phase.sh`:
- `"DONE task-pending evidence=missing.md"` → `+ evidence_redacted=n/a`
- `"DONE task-pending evidence=evidence.md"` → `+ evidence_redacted=n/a beads_updated=task-pending`

## Test result

`bash tests/validate-tick-phase.sh` → **25 passed, 0 failed** (was 8 passed, 17 failed).

## B12_AG4 e2e-smoke verdict

`bash .flywheel/scripts/validation-e2e-smoke.sh` → B12_AG4 status=pass (final-receipt.json `.gates[] | select(.gate=="B12_AG4").status == "pass"`).

## Files changed

- `tests/validate-tick-phase.sh` (~5 lines changed via 2 replace_all operations)

## Acceptance gates (all 4 passed)

- ✅ AG1 triage: all 17 → CALIBRATION
- ✅ AG2 fix: 2 string-replacements, no regressions
- ✅ AG3 B12_AG4 gate passes
- ✅ AG4 mapping documented (this evidence + triage.md)

## L112 verify probe

`bash tests/validate-tick-phase.sh 2>&1 | tail -1`
Expected: `grep:Summary: 25 passed, 0 failed`
