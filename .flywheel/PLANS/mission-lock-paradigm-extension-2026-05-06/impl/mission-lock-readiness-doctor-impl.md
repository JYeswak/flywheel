# Mission-Lock Readiness Doctor Implementation

Bead: `flywheel-mission-lock-readiness-doctor-2026-05-06`

Status: shipped 2026-05-06

## Artifacts

- Doctor: `.flywheel/scripts/mission-lock-readiness-doctor.sh`
- Golden test: `.flywheel/tests/test_mission_lock_readiness_doctor.sh`
- Upstream producers consumed read-only:
  - Wave 2 #4: `.flywheel/scripts/mission-lock-output-schema-validator.sh`
  - Wave 2 #3: `.flywheel/scripts/plan-state-lens-merge.sh`
  - Wave 3 #2: `.flywheel/scripts/mission-lock-scaffold-validator.sh`

## Doctor-Field Contract

The probe emits the canonical doctor field set:

- `mission_lock_readiness_health_score`
- `blocked_surfaces`
- `phase0_scaffold_bead_suggestions`
- `repair_receipt_identity_fields`

Per `/flywheel-doctor-author`, each invariant has a producer, measurement,
consumer, and promotion path:

| Invariant | Producer | Measurement | Consumer | Promotion |
|---|---|---|---|---|
| Output schema is valid | Wave 2 #4 schema validator | `schema_validator_verdict` | `flywheel-loop doctor` | `mission-lock-output-schema` suggestion |
| Legacy scaffold is ready | Wave 3 #2 scaffold validator | `scaffold_validator_verdict` and blocker list | `flywheel-loop doctor` | `mission-lock-scaffold` or `mission-lock-scaffold-backfill` suggestion |
| Parallel lens state is consistent | Wave 2 #3 lens merge validator | `lens_merge_consistent` | `flywheel-loop doctor` | `plan-state-lens-merge` suggestion |
| Readiness is replay-safe | This doctor | deterministic `repair_idempotency_key` | downstream repair beads | repair receipts cite expected surfaces resolved |

## Finding Mitigation

| Finding | Mitigation |
|---|---|
| SEC-006 | The doctor refuses full health when the mission-lock output schema fails, so security negative invariants and principal metadata cannot be skipped silently. |
| IDEM-004 | The doctor consumes `plan-state-lens-merge.sh validate` and drops health below 0.6 when lens merge rows are malformed. |
| IDEM-006 | `repair_receipt_identity_fields.repair_idempotency_key` is deterministic from mission hash, upstream verdicts, lens consistency, and blocked surfaces. |
| CSR-005 | Phase 0 suggestions name the specific blocked surface and the repair class, giving future scaffold beads a bounded input instead of prose-only handoff. |

## Health Scoring

The score starts at `1.0` and subtracts bounded penalties:

- Schema fail: `-0.55`
- Schema skip: `-0.20`
- Scaffold blocked: `-0.35`
- Scaffold incomplete, skipped, or failed: `-0.15`
- Lens merge inconsistent: `-0.45`

The score is clamped to `[0.0, 1.0]`. Any score below `1.0` emits at least one
Phase 0 suggestion and exits with status `1`; healthy state exits `0`.

## Audit-Only Behavior

Default mode is audit-only. The doctor calls upstream validators, reads the
mission file and plan state, and writes only temporary files under `mktemp`.
The golden test verifies mission fixture mtime and SHA stability.

## Test Coverage

`test_mission_lock_readiness_doctor.sh` covers:

1. Healthy MISSION plus valid lens state.
2. Schema failure.
3. Scaffold failure.
4. Lens merge inconsistency.
5. Multiple simultaneous blocks surfaced in `blocked_surfaces[]`.
6. Audit-only no-mutation behavior.
7. Deterministic repair receipt identity fields.

L112:

```bash
test -x /Users/josh/Developer/flywheel/.flywheel/scripts/mission-lock-readiness-doctor.sh && \
  bash /Users/josh/Developer/flywheel/.flywheel/scripts/mission-lock-readiness-doctor.sh --info > /dev/null 2>&1 && \
  bash /Users/josh/Developer/flywheel/.flywheel/tests/test_mission_lock_readiness_doctor.sh > /dev/null 2>&1 && \
  test -f /Users/josh/Developer/flywheel/.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/mission-lock-readiness-doctor-impl.md && \
  grep -q "Phase 4 Wave 3 #3 shipped: mission-lock readiness doctor" /Users/josh/Developer/flywheel/INCIDENTS.md && \
  echo OK_wave3_mission_lock_readiness_doctor_shipped
```
