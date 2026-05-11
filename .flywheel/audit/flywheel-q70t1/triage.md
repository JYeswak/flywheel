# B12_AG4 17 inner failures triage — flywheel-q70t1

**Date**: 2026-05-11
**Bead**: flywheel-q70t1 [validation-e2e-calibration]
**Memory rule applied**: `feedback_calibrate_test_to_actual_contract_before_filing_upstream` — when a flywheel test fails because upstream behavior diverges, calibrate test to upstream's actual current contract first.

## Root cause: ONE unified calibration class (all 17 failures)

`tests/validate-tick-phase.sh` sends DONE-style callbacks via the `run_case` helper:
```bash
run_case "<label>" "DONE task-pending evidence=evidence.md" "INTEGRATE" "<jq-filter>"
```

These callbacks were valid under the older `validate-callback.py` contract but the validator evolved to require:
1. `evidence_redacted=<yes|no|n/a>` field (per L120 evidence-redaction META-RULE)
2. `beads_filed=` / `beads_updated=` / `no_bead_reason=` field (per L52 bead-receipt META-RULE, required when status fails for remediation route)

Without `evidence_redacted=`, the validator short-circuits with failure_class `evidence_redaction_missing` BEFORE doing the artifact_missing / evidence_missing checks the test expected. Without bead routing, `remediation_missing` fires for fail-path tests.

## Classification per failure (all 17 → CALIBRATION, none REGRESSION)

| # | Test label | Failure mode | Class |
|---|------------|--------------|-------|
| 1 | B05_AG3 failed validation blocks INTEGRATE without remediation | expects `failure_classes ∋ artifact_missing` but validator emits `["evidence_redaction_missing","remediation_missing"]` because evidence_redacted field missing | CALIBRATION |
| 2 | B05_AG5 clean validation proceeds to INTEGRATE with receipt ref | expects `status==pass`; gets `fail` because evidence_redacted missing | CALIBRATION |
| 3 | B05_AG7 tick receipt includes doctor/learn validation summary fields | cascade from AG5 — phase ends at VALIDATE not INTEGRATE | CALIBRATION |
| 4 | vnsw tick receipt includes scheduled probe fields | cascade — phase blocked at VALIDATE so INTEGRATE-only fields missing | CALIBRATION |
| 5 | 3mmp tick receipt includes tick-contract registry fields | cascade | CALIBRATION |
| 6 | kaqr tick receipt includes Phase A checks, SOFT mode, and hold reason | cascade | CALIBRATION |
| 7 | kaqr unread autoloop receipt emits substrate-read SOFT violation | cascade | CALIBRATION |
| 8 | kaqr three unprocessed fuckups without review emits learn-review violation | cascade | CALIBRATION |
| 9 | kaqr raw transport evidence emits NTM discipline violation class | cascade | CALIBRATION |
| 10 | kaqr bounded runtime reports tick budget exceeded with handoff receipt | cascade | CALIBRATION |
| 11 | 3mmp graduation fixture 0 rows computes SOFT | cascade | CALIBRATION |
| 12 | 3mmp graduation fixture 3 rows computes WARN | cascade | CALIBRATION |
| 13 | 3mmp graduation fixture 6 rows computes HALT | cascade | CALIBRATION |
| 14 | wxth tick receipt includes leverage ceiling measurement fields | cascade | CALIBRATION |
| 15 | i8rd tick receipt includes detector v2 stale/unknown/recovery-suppressed counts and L60 5-signal check | cascade | CALIBRATION |
| 16 | i8rd frozen detector blocks dispatch while preserving detector counts | cascade | CALIBRATION |
| 17 | i8rd unknown detector state blocks dispatch and surfaces missing L60 signal | cascade | CALIBRATION |

**17/17 = calibration; 0/17 = regression**. Single unified fix because all 17 failures share the same upstream-evolved validator contract precondition.

## Fix applied

Two `Edit --replace_all` operations on `tests/validate-tick-phase.sh`:

```diff
- "DONE task-pending evidence=missing.md"
+ "DONE task-pending evidence=missing.md evidence_redacted=n/a"

- "DONE task-pending evidence=evidence.md"
+ "DONE task-pending evidence=evidence.md evidence_redacted=n/a beads_updated=task-pending"
```

The fail-path test (B05_AG3, evidence=missing.md) only needs `evidence_redacted=n/a` — once the precondition passes, the validator surfaces `artifact_missing` exactly as the test asserts.

The pass-path tests (B05_AG5 etc, evidence=evidence.md which actually exists in the fixture) need both `evidence_redacted=n/a` (precondition) AND `beads_updated=task-pending` (remediation-route precondition). With both, `validation_summary.status=="pass"` and phase advances to INTEGRATE.

## Test result

**25/25 PASS, 0 failed** in `tests/validate-tick-phase.sh` (jumped from `8 passed, 17 failed`).

## B12_AG4 e2e-smoke gate result

```
{
  "gate": "B12_AG4",
  "status": "pass",
  "label": "VALIDATE phase blocks integration without remediation route",
  "artifact": ".../validate-tick-phase.log",
  "detail": "cd '$ROOT' && bash tests/validate-tick-phase.sh"
}
```

## Out of scope (preserved as separate work)

- **B12_AG2** + **B12_AG7** (different gates with different calibration classes) — dispatch packet explicitly excluded these.
- **B12_AG7** is still failing in the e2e-smoke run (agent-context-parity-probe) — separate followup, not this bead's concern.

## Acceptance gates

- ✅ **AG1**: triaged 17 inner failures → all classified as CALIBRATION (single unified class)
- ✅ **AG2**: fix applied via 2 string-replacements; no genuine regressions surfaced; no sub-beads needed
- ✅ **AG3**: B12_AG4 gate passes (verified in final-receipt)
- ✅ **AG4**: this document is the mapping of inner-failure classes to disposition

