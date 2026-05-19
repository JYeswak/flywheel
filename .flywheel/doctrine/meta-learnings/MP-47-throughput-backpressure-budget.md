# MP-47 — Throughput backpressure budget

**Discovered:** 2026-05-19T08:05Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Reliability improves when throughput is budgeted at each scope and overload turns into explicit backpressure, queues, or degradation instead of hidden retry storms.

## Where it applies

Rate limits, message queues, autoscaling, offline sync, background workers, LLM APIs, long-horizon pipelines, and client SDK retry behavior.

## Adoption signal

Skill names throughput scopes, queue behavior, retry headers, capacity metrics, cost budgets, and lag/degradation routes before adding workers.

## Exemplar skills (≥5)

- `~/.claude/skills/rate-limiting/SKILL.md:27` — rate limiting protects reliability and retry storms, not only security.
- `~/.claude/skills/rate-limiting/SKILL.md:40` — hard 429 without retry information makes clients retry in a tight loop.
- `~/.claude/skills/rate-limiting/SKILL.md:136` — LLM endpoints need token-per-minute limits as well as request counts.
- `~/.claude/skills/rate-limiting/SKILL.md:163` — queue writes instead of rejecting them when approaching capacity.
- `~/.claude/skills/message-queuing/SKILL.md:26` — queue patterns cover delivery guarantees, DLQs, idempotency, backpressure, and monitoring.
- `~/.claude/skills/message-queuing/SKILL.md:35` — consumer lag must be treated as backpressure.
- `~/.claude/skills/horizontal-scaling/SKILL.md:21` — stateless design is a prerequisite for adding instances.
- `~/.claude/skills/horizontal-scaling/SKILL.md:186` — queue depth and custom metrics can drive event autoscaling.
- `~/.claude/skills/offline-first-sync/SKILL.md:21` — local writes happen immediately and sync asynchronously.

## Adoption recipes

**Recipe 1 — Scope budget:** define per-user, per-endpoint, per-token, per-queue, and global limits where relevant.

**Recipe 2 — Backpressure contract:** every rejection includes retry timing or a queue/degradation route.

**Recipe 3 — Lag metric:** autoscaling and alerts use queue depth, consumer lag, and sustained 429 rate rather than CPU alone.

## Compliance test

```bash
grep -E "(Retry-After|queue|backpressure|consumer lag|token.*minute|queue depth|429)" SKILL.md || fail
```
