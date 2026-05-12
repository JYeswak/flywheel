# Mutation Contract

## Idempotency

Every apply-mode mutation has two identity fields:

- `idempotency_key`: caller-visible retry key.
- `request_fingerprint`: hash of operation class, target refs, intended inputs,
  and relevant options.

Allowed replay outcomes:

| Condition | Outcome |
|---|---|
| Same key, same fingerprint, prior success | Return prior receipt or no-op receipt |
| Same key, same fingerprint, prior failure | Return prior failure and recovery hint |
| Same key, different fingerprint | Fail closed with conflict receipt |
| Missing key in apply mode | Refuse mutation |

## Dry-Run / Apply

Dry-run emits the exact plan and `plan_hash`. Apply must cite that hash. If the
current plan differs, apply refuses because the reviewed plan is stale.

Apply receipts include:

- `schema_version`
- `mode`
- `surface`
- `operation`
- `idempotency_key_hash`
- `request_fingerprint`
- `dry_run_plan_hash`
- `result`
- `audit_row`
- `rollback_available`
- `no_backup_reason`

## Lock Files

Locks protect shared state, not agent pride. A useful lock records owner,
target, timeout, operation, and idempotency identity. Stale-lock handling is a
mutation and needs its own receipt.

Minimum stale-lock checks:

1. Owner process/session liveness.
2. Timeout exceeded.
3. Lock target matches requested operation.
4. No active write evidence on the target.
5. Recovery owner or command is known.

## Append-Only Audit

Audit rows are durable lineage and are never rewritten for cleanup. Corrections
are new rows. If an audit row cannot be appended, apply mode fails unless the
surface has a stronger transactional receipt.

## Backup And Rollback

Local mutation needs backup-before-write unless the operation is provably
no-op/append-only and the receipt records why rollback is unnecessary. Host,
provider, credential, and billing mutations are not local rollback-safe by
default.
