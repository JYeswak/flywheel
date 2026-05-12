# Jeff Evidence

Source matrix:
`.flywheel/jeff-corpus/v1/learnings/06-skill-enhancement-matrix.md`.

The matrix lists `mutation-safety-contract` under "Needs New Sibling Skill" and
states the gap: mutation safety is fragmented across CLI, ops, and cron skills,
while Jeff patterns treat idempotency, locks, and audit lineage as one contract.

Doctrine cluster evidence:
`.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md` defines
idempotency and dry-run as previewable, repeatable, atomic, explicit mutation
posture. The same document defines append-only audit and lineage as replayable
operational history.

Code pattern evidence:
`.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md` gives:

- `idempotency-key-fail-closed`: ADOPT key+fingerprint+TTL semantics and fail
  closed on conflict.
- `lock-file-convention`: ADOPT lock timeout, PID/owner metadata, stale-lock
  diagnosis, and nested-lock safety.
- `append-only-audit-log`: EXTEND append-only JSONL/lineage logs with doctor
  checks, retention rules, and receipt references.

Flywheel adaptation:
The staged skill keeps mutation receipts as durable evidence while preserving
worker callback fields. It also encodes L137: Beads substrate writes flow
through `br` and the serial write lane, not manual JSONL edits.
