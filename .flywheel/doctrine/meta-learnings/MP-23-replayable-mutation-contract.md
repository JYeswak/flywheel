# MP-23 — Replayable mutation contract

**Discovered:** 2026-05-19T06:21Z
**Skills exemplifying:** 6+

## Essence

Any mutation that can be retried, rolled back, double-fired, or resumed must be idempotent and replayable before it is trusted in production.

## Where it applies

Background jobs, cron, schema migrations, deployment smoke tests, real-service tests, concurrent writes, agent reservations.

## Adoption signal

Mutating workflow documents idempotency keys, dry-run/apply split, replay proof, rollback plan, or DLQ replay tooling.

## Exemplar skills (≥5)

- `~/.claude/skills/background-jobs/SKILL.md:21` — jobs are designed to be idempotent, observable, and recoverable.
- `~/.claude/skills/background-jobs/SKILL.md:92` — every queue needs a dead-letter destination.
- `~/.claude/skills/background-jobs/SKILL.md:96` — DLQs need tooling to inspect, replay, or discard dead letters.
- `~/.claude/skills/database-modeling/SKILL.md:188` — destructive/data-affecting migrations require dry-run, idempotency key, replay proof, and rollback note.
- `~/.claude/skills/database-modeling/SKILL.md:216` — migrations should replay twice to prove idempotency.
- `~/.claude/skills/deployment-strategy/SKILL.md:181` — smoke tests must be idempotent and safe to run repeatedly.
- `~/.claude/skills/testing-real-service-e2e-no-mocks/SKILL.md:36` — real tests isolate with transaction rollback per test.

## Adoption recipes

**Recipe 1 — Mutation envelope:** destructive commands require `--dry-run` and `--apply`, plus `idempotency_key`, `rollback_plan`, and `replay_status`.

**Recipe 2 — Replay test:** CI runs the mutation twice against fixtures or a disposable environment and compares hashes/counts.

**Recipe 3 — Dead-letter surface:** async systems expose inspect/replay/discard tooling for exhausted work.

## Compliance test

```bash
grep -E "(idempot|replay|rollback|dead letter|DLQ|dry-run)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-15 — canonical CLI scoping:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-15-canonical-cli-scoping.md` for the canonical pattern.
- **MP-24 — boundary validation fail-closed:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-24-boundary-validation-fail-closed.md` for the canonical pattern.
- **MP-27 — exact prompt/output template:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-27-exact-prompt-output-template.md` for the canonical pattern.
