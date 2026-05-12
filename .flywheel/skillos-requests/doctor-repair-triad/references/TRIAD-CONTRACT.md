# Triad Contract

## Doctor

Doctor is the full read-only diagnostic surface. It answers:

- What was checked?
- Did each check pass, warn, or fail?
- Which failure class applies?
- What evidence supports the classification?
- Who owns the next action?
- Is repair currently safe?

Doctor output is machine JSON by default when agents consume it. It carries
`schema_version` and stable exit codes so tick drivers, close gates, and worker
dispatch validators can fail closed.

## Health

Health is a compact readiness summary. It should be cheap enough for frequent
polling and small enough for dashboards. Health references doctor for detail
instead of repeating full diagnostics.

Required shape:

- status
- freshness
- failing check count
- repair availability
- repair safety
- top counters

## Repair

Repair is split into dry-run and apply:

1. `repair --dry-run --json` validates the source of truth, computes actions,
   proves rollback when possible, and emits a plan hash.
2. `repair --apply --json` accepts the same idempotency key and dry-run plan
   hash, mutates only the declared paths, and appends a receipt.
3. Refusal is a valid outcome when source truth is corrupt, rollback is absent,
   or a prior failed repair artifact must be inspected first.

Repairs that touch network services, credentials, or human-owned external
systems are owner routes, not autonomous repairs.

## Exit Codes

| Code | Meaning |
|---:|---|
| 0 | healthy or repair applied/no-op |
| 1 | unhealthy but classified |
| 2 | unsafe to repair or refused |
| 3 | invalid invocation |
| 4 | substrate unavailable |

## Receipt

Repair receipts are append-only. Minimum fields:

- `schema_version`
- `surface`
- `mode`
- `idempotency_key`
- `dry_run_plan_hash`
- `actions`
- `result`
- `rollback_available`
- `audit_row`
- `failure_class`
- `evidence`
