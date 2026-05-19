# MP-100 - Contention-shaped state owner

**Discovered:** 2026-05-19T08:02Z
**Discovered by:** skillos:2
**Skills exemplifying:** 7+

## Essence

Shared mutable state should be shaped by contention class: single writer for contested durable state, actors for ownership, backoff for long waits, and transaction-style swaps for partial failure.

## Where it applies

SQLite-backed tools, file reservations, multi-agent ledgers, distributed agents, batch writes, concurrency bug fixes, state machines, and retry-heavy systems.

## Adoption signal

The implementation identifies the shared resource, assigns one write owner or transactional boundary, chooses a wait strategy by expected duration, and proves idempotent retry behavior.

## Exemplar skills (>=5)

- `~/.claude/skills/deadlock-finder-and-fixer/SKILL.md:116` - retry-on-BUSY without backoff creates livelock.
- `~/.claude/skills/deadlock-finder-and-fixer/SKILL.md:127` - millisecond-scale operations require exponential backoff with jitter.
- `~/.claude/skills/deadlock-finder-and-fixer/SKILL.md:129` - contested resources can be serialized through one owner.
- `~/.claude/skills/deadlock-finder-and-fixer/SKILL.md:155` - write transactions acquire the SQLite write lock up front.
- `~/.claude/skills/deadlock-finder-and-fixer/SKILL.md:245` - critical sections should build local state then swap atomically.
- `~/.claude/skills/distributed-systems/SKILL.md:101` - retries require idempotency.
- `~/.claude/skills/distributed-systems/SKILL.md:121` - immutable event logs enable deterministic state reconstruction.
- `~/.claude/skills/accretive-cron-orchestration/SKILL.md:166` - mutations require idempotency keys or target hashes.
- `~/.claude/skills/etl-pipeline/SKILL.md:216` - idempotent writes use upsert or merge with dedup keys.

## Adoption recipes

**Recipe 1 - Owner map:** list every shared mutable resource and its single writer, transaction boundary, or actor owner.

**Recipe 2 - Wait-class table:** pick spin, yield, sleep, backoff, or queueing from expected contention duration.

**Recipe 3 - Retry proof:** demonstrate duplicate idempotency keys, repeated requests, and crash resume produce one logical mutation.

## Compliance test

```bash
grep -E "(single writer|idempot|backoff|SQLite|transaction|actor|shared state|retry|dedup)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-53-idempotent-delivery-replay.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-95-data-contract-reconciliation-ledger.md`
