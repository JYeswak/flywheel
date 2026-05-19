# MP-53 — Idempotent delivery replay

**Discovered:** 2026-05-19T08:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Event delivery is reliable only when retries, replay, acknowledgements, and idempotency keys are designed together; reconnecting or retrying without identity creates duplicates or loss.

## Where it applies

Payment webhooks, subscription ledgers, push notifications, WebSocket/SSE streams, service meshes, queues, and provider event processors.

## Adoption signal

Skill names event IDs, signature verification, retry/backoff rules, replay buffers, acknowledgement or dedup policy, and non-idempotent retry exclusions.

## Exemplar skills (≥5)

- `~/.claude/skills/stripe-checkout/SKILL.md:11` — database is the single source of truth synced by webhooks.
- `~/.claude/skills/stripe-checkout/SKILL.md:110` — Stripe webhooks require signature verification.
- `~/.claude/skills/stripe-checkout/SKILL.md:112` — event processing must be idempotent.
- `~/.claude/skills/websocket-sse-patterns/SKILL.md:137` — `Last-Event-ID` enables replay after reconnect.
- `~/.claude/skills/websocket-sse-patterns/SKILL.md:155` — replay requires an event buffer.
- `~/.claude/skills/websocket-sse-patterns/SKILL.md:294` — lack of acknowledgements causes silent message loss.
- `~/.claude/skills/service-mesh/SKILL.md:248` — retrying non-idempotent operations can duplicate orders or charges.
- `~/.claude/skills/saas-customer-analytics/SKILL.md:85` — provider event ID acts as the idempotency key.

## Adoption recipes

**Recipe 1 — Event identity:** store provider, event ID, logical operation ID, and processing status before side effects.

**Recipe 2 — Replay lane:** streams include monotonically ordered IDs plus a replay buffer or persistent log.

**Recipe 3 — Retry filter:** retry only idempotent operations, or require dedup keys and side-effect guards.

## Compliance test

```bash
grep -E "(idempotent|Last-Event-ID|replay|signature verification|acknowledg|retry.*idempotent)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-100-contention-shaped-state-owner.md`
