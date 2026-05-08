# Failure Taxonomy Receipt Contract

## Required Fields

Every failure-bearing receipt includes:

- `schema_version`
- `status`
- `surface`
- `failure_class`
- `reason_code`
- `retry_policy`
- `recovery_hint`
- `owner_route`
- `evidence`
- `bead_route`
- `fuckup_route`

## Retry Policy Matrix

| retry_policy | Meaning | Required fields |
|---|---|---|
| `none` | Terminal or intentionally closed gate | reason, evidence |
| `exponential` | Transient uncertainty | max attempts, next probe, last result |
| `manual` | Another owner must act | owner route, exact resume evidence |
| `permanent` | Do not retry without new input or repair | repair bead/update route |

## Validator Fixture Matrix

Minimum fixtures for a validator generated from this skill:

| fixture_id | Expected result |
|---|---|
| `callback-valid-done-pass-v1` | pass with null failure class |
| `callback-missing-evidence-fail-v1` | `missing_artifact`, manual |
| `callback-missing-required-field-fail-v1` | `invalid_callback`, manual |
| `substrate-timeout-unknown-v1` | `transient`, exponential |
| `reservation-conflict-blocked-v1` | `file_reservation_conflict`, manual |
| `retry-budget-exhausted-fail-v1` | `retry_budget_exhausted`, permanent |
| `unknown-unclassified-fail-v1` | `unknown_unclassified`, manual |

## Callback Preservation

When the surface is a flywheel callback, the validator rejects receipts that
omit DID/DIDNT/GAPS, `mission_fitness`, `josh_request_id`,
`br_close_executed`, or `callback_delivery_verified`.

