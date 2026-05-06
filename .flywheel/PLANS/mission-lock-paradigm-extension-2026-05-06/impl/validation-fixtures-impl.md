# Validation Fixtures + Golden Replay Implementation

Bead: `flywheel-mission-lock-validation-fixtures-golden-replay-2026-05-06`

Status: shipped 2026-05-06

## Artifacts

- Fixtures:
  `.flywheel/tests/fixtures/mission-lock-paradigm-extension-2026-05-06/`
- Runner:
  `.flywheel/scripts/golden-fixture-replay-runner.sh`
- Golden test:
  `.flywheel/tests/test_golden_fixture_replay_runner.sh`

## Fixture Map

| Fixture | Finding | Expected replay signal | Producer exercised |
|---|---|---|---|
| `secret-negative-fixture.json` | `SEC-004` | `secret_value_literal_present` | Wave 2 dispatch-author contract probe |
| `duplicate-dispatch-replay-fixture.json` | `IDEM-001` | `refuse_in_flight` | Wave 3 dispatch self-test delivery identity |
| `duplicate-close-replay-fixture.json` | `IDEM-003` | `duplicate_reconciled` | Wave 2 close-validator contract probe |
| `parallel-state-merge-fixture.json` | `IDEM-005` | both lens rows preserved | Wave 2 plan-state lens merge helper |
| `stale-skill-route-fixture.json` | `CSR-001` | `stale_or_blocked_skill_route` | Wave 2 close-validator contract probe |
| `false-positive-self-test-fixture.json` | `CSR-004` | `false_positive_skill_claim` | Wave 3 dispatch identity pretest plus fixture route evidence |
| `cross-cutting-coverage-fixture.json` | `CSR-006` | `required_overlay_missing` | Wave 2 dispatch-author contract probe |

## Invariant Check

`verify-invariants` checks:

- at least seven fixtures exist;
- the seven final audit findings are covered:
  `SEC-004`, `IDEM-001`, `IDEM-003`, `IDEM-005`, `CSR-001`,
  `CSR-004`, and `CSR-006`;
- each fixture has `fixture_id`, `finding_id`, `mode`, and `expected`;
- Wave 1/2/3 producer artifacts exist:
  negative-invariant validator, idempotency replay guard, dispatch-author
  probe, close-validator probe, plan-state lens merge, scaffold validator,
  readiness doctor, and dispatch self-test delivery identity.

## Golden Strategy

The runner canonicalizes each fixture replay down to stable fields:

- `fixture_id`
- `finding_id`
- `observed_verdict`
- `codes`
- `status`

The shell test compares those stable fields against each fixture's `expected`
block. Temporary paths, timestamps, and per-run lock directories are excluded
from the golden comparison.

## Wave 4 #2 Integration

The Phase 5 polish-preflight quality gate can consume this runner through:

```bash
bash .flywheel/scripts/golden-fixture-replay-runner.sh replay-all --json
bash .flywheel/scripts/golden-fixture-replay-runner.sh verify-invariants --json
```

The gate should treat `status != pass`, fixture count below seven, missing
findings, or missing Wave producer artifacts as a preflight block.

## Validation

```bash
bash .flywheel/tests/test_golden_fixture_replay_runner.sh
```

Observed:

```text
RESULT pass=16 fail=0 test_cases=9
```
