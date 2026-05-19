# MP-112 - Durable event replay envelope

**Discovered:** 2026-05-19T07:46Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Event-driven side effects need a receipt envelope before business logic, with verified identity, schema version, idempotency key, durable raw event, and dry-run replay path.

## Where it applies

Webhooks, Nango/OAuth callbacks, file uploads, push notifications, event buses, queue workers, callback URLs, and any public receiver that can duplicate, replay, or forge inputs.

## Adoption signal

The handler verifies signature or endpoint posture, validates schema, reserves idempotency before mutation, stores the raw event, queues durable work, and exposes doctor/repair replay in dry-run mode.

## Exemplar skills (>=5)

- `~/.claude/skills/webhook-automation/SKILL.md:27` - production webhooks require retries, idempotency, signature verification, routing, and failure management.
- `~/.claude/skills/webhook-automation/SKILL.md:52` - ingestion includes TLS, rate limiting, IP allowlisting, and signature verification before validation.
- `~/.claude/skills/webhook-automation/SKILL.md:58` - validation checks idempotency before processing.
- `~/.claude/skills/webhook-automation/SKILL.md:168` - inbound webhooks emit a machine-readable receipt before business logic runs.
- `~/.claude/skills/webhook-automation/SKILL.md:193` - unsigned, unknown-schema, or duplicate events fail closed before mutation.
- `~/.claude/skills/nango-integrations/SKILL.md:12` - Nango recovery probes first, mutates minimally, verifies deterministically, and emits a receipt.
- `~/.claude/skills/nango-integrations/SKILL.md:149` - PASS requires deployment health, callback reachability, domain verification, DNS alignment, and auth posture.
- `~/.claude/skills/file-upload-storage/SKILL.md:69` - direct upload flows confirm the object exists before database mutation.

## Adoption recipes

**Recipe 1 - Receipt-before-logic:** write provider, event ID, signature status, schema version, idempotency key, and raw-event pointer before mutation.

**Recipe 2 - Idempotency reserve:** reserve the dedup key before enqueueing or updating domain state.

**Recipe 3 - Replay repair:** default replay tooling to dry-run and require explicit apply for DLQ or callback repair.

## Compliance test

```bash
grep -E "(webhook|event|signature|idempot|receipt|schema_version|raw event|DLQ|replay|dry_run)" SKILL.md || exit 1
```
