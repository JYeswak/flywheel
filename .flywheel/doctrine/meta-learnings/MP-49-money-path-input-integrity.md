# MP-49 — Money-path input integrity

**Discovered:** 2026-05-19T08:05Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Any workflow that moves money must prove input integrity, provenance, idempotency, and server-side authority before execution safety is debated.

## Where it applies

Trading gates, payment intents, refunds, subscriptions, commission plans, tax-sensitive forms, billing webhooks, and any money-adjacent form submission.

## Adoption signal

Skill names each money input, producer, writer, provenance ID, idempotency key, server validation boundary, and deterministic audit output.

## Exemplar skills (≥5)

- `~/.claude/skills/money-path-input-integrity/SKILL.md:15` — broken inputs flowed downstream after a process gate passed.
- `~/.claude/skills/money-path-input-integrity/SKILL.md:18` — gate money-decision inputs, not just execution envelopes.
- `~/.claude/skills/money-path-input-integrity/SKILL.md:31` — enumerate probability, price, fee, edge, side, size, API, and provenance ID.
- `~/.claude/skills/money-path-input-integrity/SKILL.md:34` — telemetry needs writer round-trip tests.
- `~/.claude/skills/payment-processing/SKILL.md:72` — never trust client-side payment confirmation.
- `~/.claude/skills/payment-processing/SKILL.md:82` — retrying payment creation without idempotency can double-charge.
- `~/.claude/skills/payment-processing/SKILL.md:104` — idempotency key must remain the same across retries of one logical operation.
- `~/.claude/skills/form-validation/SKILL.md:32` — server-side validation is the security and data integrity boundary.
- `~/.claude/skills/commission-calculation/SKILL.md:16` — commission calculations must be deterministic, auditable, and per-deal.

## Adoption recipes

**Recipe 1 — Input ledger:** list each amount/probability/price/fee/side/input with producer, writer, type, bounds, and provenance.

**Recipe 2 — Retry invariant:** define logical operation IDs and idempotency keys before calling money APIs.

**Recipe 3 — Round-trip audit:** persist representative money events and select them back to prove columns, cents, signs, and provenance survive.

## Compliance test

```bash
grep -E "(idempotency|provenance|server-side validation|round-trip|deterministic.*auditable|money decision)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-41-gate-class-separation.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-72-reconciled-financial-exception-ledger.md`
