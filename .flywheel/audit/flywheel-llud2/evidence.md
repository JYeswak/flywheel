# Evidence Pack — flywheel-llud2

**Bead:** flywheel-llud2 — `[5ke66.9-followup] triage 7 pre-existing fleet test failures surfaced by 5ke66.9 fleet-coherence-alert canonical-cli baseline (zero delta — pre-existed)`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11

## Disposition: TRIAGED + FIXED — 7/7 failures resolved via test calibration

The 5ke66.9 worker's evidence pack flagged 7 pre-existing failures in `tests/fleet-coherence-alert.sh` as "fixture-length drift + send-mode integration drift". This bead's triage:

- **All 7 failures are stale test assertions** (not script bugs).
- **Root cause:** the script schema + canonical fixture both evolved post-test-authoring; assertions were never updated.
- **Fix:** test calibration to current canonical contract — exactly the META-RULE 2026-05-09 pattern (`feedback_calibrate_test_to_actual_contract_before_filing_upstream.md`): when a test fails because upstream behavior diverges, calibrate test to upstream's actual current contract first.

| Test | Pre-fix | Post-fix |
|---|---|---|
| 14 PASS / 7 FAIL | 21 PASS / 0 FAIL |

## Triage by failure class

### Group A (4 tests): fixture-length drift

| Test | Old assertion | New assertion | Fix rationale |
|---|---|---|---|
| `doctor_surface` | `(.fixture_cases\|length) == 5` | `(.fixture_cases\|length) == 6` | Canonical fixture `.flywheel/fixtures/fleet-coherence-alerts.jsonl` expanded to 6 cases (`success`, `agent_mail_fails`, `ntm_fails`, `both_legs_fail`, `resend_suppressed`, `stale_callback_pane`); the original `== 5` predates the `stale_callback_pane` case addition |
| `health_surface` | same | same | same root cause (loop covers all 4 modes) |
| `validate_surface` | same | same | same |
| `audit_surface` | same | same | same |

Single-line fix at `tests/fleet-coherence-alert.sh:115` plus 3-line comment explaining the calibration. Loop iterates `for mode in doctor health validate audit`, so one edit fixes all 4 surface tests.

### Group B (3 tests): l61_pairing_status enum schema drift

The script's canonical enum (per scaffold L171, fleet-coherence-alert.sh):
```
l61_pairing_status: ["not_attempted","complete","degraded","failed","suppressed"]
```

The original test asserted deprecated enum values `ntm_only` / `mail_only` that the script no longer emits. The semantic those values carried is now in the `degraded_reason` field (which the tests already inspect — so post-fix the assertion remains semantically equivalent):

| Test | Old assertion | New assertion |
|---|---|---|
| `mail_failure_degrades_ntm_only` | `.l61_pairing_status == "ntm_only"` | `.l61_pairing_status == "degraded"` |
| `ntm_failure_degrades_mail_only` | `.l61_pairing_status == "mail_only"` | `.l61_pairing_status == "degraded"` |
| `stale_callback_degrades` | `.l61_pairing_status == "mail_only"` | `.l61_pairing_status == "degraded"` |

Each fix preserves the discriminating `degraded_reason` assertion (`agent_mail_send_failed`, `ntm_send_failed`, `stale_callback_pane`). Test names retained for diff readability — the names refer to the FAILURE MODE being tested, not the literal enum value.

## Verification

| Metric | Before | After |
|---|---|---|
| `tests/fleet-coherence-alert.sh` | pass=14 fail=7 | pass=21 fail=0 |
| Failures cleared | — | doctor_surface + health_surface + validate_surface + audit_surface + mail_failure_degrades_ntm_only + ntm_failure_degrades_mail_only + stale_callback_degrades |
| Script behavior | unchanged | unchanged (test calibration only) |

Evidence: `test-run-before.txt` + `test-run-after.txt` + `test-calibration.diff`.

## What was NOT changed

- `.flywheel/scripts/fleet-coherence-alert.sh` — untouched (script's current schema IS the canonical truth)
- `.flywheel/fixtures/fleet-coherence-alerts.jsonl` — untouched (fixture's current 6 cases are the canonical truth)
- `.flywheel/scripts/canonical-cli-lint.sh` — untouched (lint clean before + after)
- Anything else — pure test-side calibration

## AG receipt

Implicit acceptance criteria from bead title:
- AG1: triage 7 pre-existing failures — DONE (Group A fixture-length × 4, Group B enum-schema-drift × 3)
- AG2: zero delta verified (script behavior unchanged) — DONE
- AG3: surface a fix path — DONE (test calibration, no upstream issue needed)
- AG4: ship the fix or document why deferred — SHIPPED (7/7 failures cleared in this tick)

did=4/4

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | n/a | test calibration only; no CLI surface change |
| rust-best-practices | n/a | bash test |
| python-best-practices | n/a | bash test |
| readme-writing | n/a | no README |

## Doctrine reference

`feedback_calibrate_test_to_actual_contract_before_filing_upstream.md` (META-RULE 2026-05-09): "when a flywheel test fails because upstream behavior diverges, calibrate test to upstream's actual current contract first; 'our test fails' is not 'upstream bug'; cite contract or file documentation issue, not 'fix it'."

This bead is a clean instance of that META-RULE — the "upstream" here is the script itself (which evolved) and the canonical fixture (which expanded). Both were correct at their current states; the test was stale.

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| All 7 failures triaged | 200/200 | 4 fixture-length + 3 enum-schema-drift, root cause identified |
| All 7 failures fixed | 300/300 | 21/0 PASS post-fix (was 14/7) |
| Test calibration discipline (no script change) | 200/200 | only `tests/fleet-coherence-alert.sh` touched; script + fixture untouched |
| META-RULE 2026-05-09 cited inline | 50/50 | `feedback_calibrate_test_to_actual_contract_before_filing_upstream` referenced in commit + evidence |
| Diff has explanatory inline comments | 100/100 | each fix carries 1-3 line rationale comment |
| Reservations released; no peer collisions | 50/50 | L107 release receipts |
| Zero blast radius | 100/100 | 4 line edits + comments; no other files touched |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
bash tests/fleet-coherence-alert.sh 2>&1 | grep -E '^SUMMARY'
```
Expected: `grep:pass=21 fail=0`. Timeout 30s.
