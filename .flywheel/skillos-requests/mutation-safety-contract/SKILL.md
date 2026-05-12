---
name: mutation-safety-contract
description: "Use when 'mutation safety', 'idempotency key', 'request fingerprint', 'fail closed', 'dry-run apply', 'repair apply', 'lock file', 'stale lock', 'append-only audit', 'lineage receipt', 'rollback receipt', 'backup before write', 'no-op safety', 'conflict receipt', 'shared state write', 'beads write lane', 'host mutation', or 'mutation gate'."
license: MIT
distribution: forbidden
version: 0.1.0
status: skillos-request
---

# Mutation Safety Contract

## Status

Draft for skillos review. This file is a flywheel-local request artifact for
bead `flywheel-2gvl`; it is not installed as a live skill and is not published
to JSM.

## Hard Rules

1. Every mutating surface has an explicit apply gate: default behavior is
   read-only, `--dry-run`, `--plan`, or `--explain`.
2. Every apply-mode mutation requires an `idempotency_key` and request
   fingerprint derived from intended inputs, target paths, and operation class.
3. Reusing the same idempotency key with the same fingerprint returns the prior
   receipt; reusing it with a different fingerprint fails closed.
4. Lock files include owner, PID when meaningful, target path, created time,
   timeout, and stale-lock diagnosis instructions.
5. Stale locks are diagnosed before removal; removal requires owner proof,
   expired timeout, or a repair receipt that records why the lock was safe to
   clear.
6. Append-only ledgers record `schema_version`, actor, operation, target,
   fingerprint, idempotency key hash, before/after refs, result, and failure
   class.
7. Backup-before-write is required for local file or database mutation unless
   the receipt carries `no_backup_reason` and an explicit rollback/no-op proof.
8. Apply receipts include the dry-run plan hash they executed and fail if the
   current plan hash differs from the reviewed dry-run plan.
9. Mutations that cross host, credential, billing, production, or external API
   boundaries require an owner route unless the substrate already encodes the
   repair as Tier 2 with a tested rollback path.
10. Secret-shaped values never appear in dry-run plans, audit rows, conflict
    receipts, or callback evidence.
11. Flywheel Beads mutations use the serial write lane; workers do not manually
    append `.beads/issues.jsonl` or hold long-lived reservations on Beads
    substrate files.
12. Callback evidence extends flywheel DONE/BLOCKED contracts; it never
    replaces `DID/DIDNT/GAPS`, `mission_fitness`, or delivery verification.

## THE EXACT PROMPT

```text
Create or revise a skill named mutation-safety-contract for <surface>. Define
the idempotency key and fingerprint shape, fail-closed conflict behavior,
dry-run/apply receipt contract, lock metadata and stale-lock diagnosis,
append-only audit ledger, backup-before-write rule, rollback/no-op safety, and
host/external-boundary refusal policy. Include an executable self-test that
rejects drafts missing idempotency_key, request_fingerprint, --dry-run,
--apply, lock_owner, stale_lock, append-only audit, rollback receipt, and
no_backup_reason handling. Cite Jeff corpus evidence and preserve flywheel
DID/DIDNT/GAPS callback contracts. Do not mutate live skills or run jsm push
until Joshua approves publication.
```

## Decision Tree

| Situation | Required posture |
|---|---|
| New command can mutate files or state | Default to `--dry-run` or `--explain`; require `--apply` for writes |
| Same request is retried | Return prior receipt when fingerprint matches |
| Same key maps to different fingerprint | Fail closed with conflict receipt |
| Lock exists but owner is active | Do not clear; report owner and wait or route |
| Lock exists and owner is gone | Diagnose timeout, target, and stale criteria before clearing |
| Source of truth is corrupt | Refuse mutation and route to recovery owner |
| Backup impossible | Require `no_backup_reason` plus rollback/no-op proof |
| Host or external API boundary appears | Route to owner unless tested Tier 2 repair exists |

## Idempotency Contract

Minimum dry-run plan:

```json
{
  "schema_version": "mutation-safety-contract/plan/v1",
  "mode": "dry-run",
  "surface": "example-substrate",
  "operation": "update|repair|close|prune|migrate",
  "idempotency_key": "operator-supplied-or-generated",
  "request_fingerprint": "sha256:...",
  "target_refs": ["path/or/resource"],
  "plan_hash": "sha256:...",
  "actions": [{"id": "write_row", "mutates": ["ledger.jsonl"]}],
  "backup_plan": {"required": true, "available": true},
  "rollback_plan": {"available": true}
}
```

Minimum apply receipt:

```json
{
  "schema_version": "mutation-safety-contract/receipt/v1",
  "mode": "apply",
  "surface": "example-substrate",
  "operation": "update",
  "idempotency_key_hash": "sha256:...",
  "request_fingerprint": "sha256:...",
  "dry_run_plan_hash": "sha256:...",
  "result": "applied|noop|refused|failed|conflict",
  "audit_row": "path/to/audit.jsonl#L42",
  "rollback_available": true,
  "no_backup_reason": null
}
```

## Lock Contract

Lock metadata:

```json
{
  "schema_version": "mutation-safety-contract/lock/v1",
  "lock_path": "path/to/resource.lock",
  "target": "path/or/resource",
  "owner": "session:pane-or-process",
  "pid": 12345,
  "created_at": "2026-05-08T20:00:00Z",
  "timeout_seconds": 600,
  "operation": "repair",
  "idempotency_key_hash": "sha256:..."
}
```

Stale-lock diagnosis checks owner liveness, timeout, target match, and active
write evidence before any clear operation. Clearing a stale lock emits the same
apply receipt shape as any other mutation.

## Append-Only Audit Ledger

Mutation rows are append-only JSONL:

```json
{
  "schema_version": "mutation-safety-contract/audit/v1",
  "ts": "2026-05-08T20:00:00Z",
  "actor": "CloudyMill",
  "surface": "example-substrate",
  "operation": "repair",
  "target": "path/or/resource",
  "idempotency_key_hash": "sha256:...",
  "request_fingerprint": "sha256:...",
  "before_ref": "sha256-or-path-or-null",
  "after_ref": "sha256-or-path-or-null",
  "result": "applied|noop|refused|failed|conflict",
  "failure_class": null
}
```

## Source Evidence

- `.flywheel/jeff-corpus/v1/learnings/06-skill-enhancement-matrix.md:39-45`
  names `mutation-safety-contract` as a new sibling skill candidate and defines
  the exact cluster: idempotency keys, stale lock diagnosis, dry-run/apply
  receipts, append-only ledgers, and rollback/no-op safety.
- `.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md:62-78` describes
  idempotency, dry-run, and fail-closed mutation posture.
- `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:51-69` says to adopt
  key+fingerprint+TTL semantics and conflict outcomes that fail closed.
- `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:175-193` says to
  extend append-only lineage logs with doctor checks, retention rules, and
  receipt references.
- `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:196-203` deduplicates
  the pattern: locks and schema migrations overlap with doctor on state safety;
  callbacks are transient while audit logs are durable receipts.

## Flywheel Adaptation Notes

- This skill is staged for skillos because mutation safety spans CLI, ops,
  cron, repair, and Beads surfaces; no single live skill owns the whole
  reusable contract.
- L137 changes Beads closeout posture: use `br`/serial write lane, not manual
  JSONL appends or long-lived reservations on `.beads/`.
- Host-tier cleanup, credential mutation, and external provider mutation remain
  owner-routed unless a specific Tier 2 tool and rollback path already exists.
- JSM publication is staged only. Validate first; Joshua decides whether
  skillos runs `jsm push`.

## Executable Self-Test

Run:

```bash
bash scripts/self_test.sh .
```

Expected pass output:

```json
{"checks":12,"status":"pass"}
```

## Publication Staging

After skillos review and Joshua approval:

```bash
jsm validate /path/to/mutation-safety-contract --json --offline
jsm push /path/to/mutation-safety-contract
```

No `jsm push` is authorized by this draft.

## Anti-Patterns

| Anti-pattern | Why it fails | Required replacement |
|---|---|---|
| Apply is default | A typo or ambient agent action mutates state without review | Read-only or dry-run default plus explicit `--apply` |
| Idempotency key without fingerprint | Retries can hide mismatched requests under the same key | Pair key with request fingerprint and fail closed on mismatch |
| Deleting a stale lock by age only | A slow but live owner can lose its write guard | Check owner liveness, target, timeout, and active write evidence |
| Audit row after best-effort mutation | Failure between write and audit loses causality | Plan audit path before write and append receipt atomically where possible |
| Backup omitted silently | Rollback cannot be proven after a bad mutation | Backup-before-write or explicit `no_backup_reason` with no-op proof |
| Secret values in receipts | Pane/search/callback substrate turns receipts into exposure | Store redacted classes and references only |
| Manual JSONL append for Beads | Bypasses `br` consistency and serial write lane | Use bounded `br` mutation with lock timeout or queue to owner |
| Callback replaced by mutation receipt | Dispatch validators lose DID/DIDNT/GAPS evidence | Attach receipt as evidence while preserving callback contract |
