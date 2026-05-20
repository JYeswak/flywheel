# MP-68 — Schema executable validator pair

**Discovered:** 2026-05-19T06:53Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Schemas are incomplete until paired with executable validation that enforces parsing, structural shape, cross-field semantics, JSON behavior, fixtures, and server-side trust boundaries.

## Where it applies

Form validation, package metadata, API payloads, state envelopes, config files, migration receipts, public manifests, and any artifact consumed by humans and machines.

## Adoption signal

The skill ships a schema, version marker, validator command, valid and invalid fixtures, cross-field checks, and a rule that client validation cannot be the authority.

## Exemplar skills (≥5)

- `~/.claude/skills/schema-validator-duo/SKILL.md:12` — every schema ships with a paired executable validator.
- `~/.claude/skills/schema-validator-duo/SKILL.md:29` — schema surfaces include a constant version marker.
- `~/.claude/skills/schema-validator-duo/SKILL.md:31` — validators include scripts and tests.
- `~/.claude/skills/schema-validator-duo/SKILL.md:55` — validation includes cross-field invariants.
- `~/.claude/skills/schema-validator-duo/SKILL.md:69` — validators cover parse, schema, semantics, JSON, exit behavior, and fixtures.
- `~/.claude/skills/form-validation/SKILL.md:32` — never trust the client; validate server-side.
- `~/.claude/skills/form-validation/SKILL.md:221` — reuse the same schema from client surfaces.
- `~/.claude/skills/saas-cli-auth-flow/SKILL.md:127` — replay-prone auth exchange failures should fail permanently.

## Adoption recipes

**Recipe 1 — Versioned schema:** define the schema and `SCHEMA_VERSION` or equivalent constant in the producing package.

**Recipe 2 — Validator command:** add a command that reads files, returns stable exit codes, and emits JSON diagnostics.

**Recipe 3 — Fixture matrix:** include valid, invalid, cross-field, malformed JSON, and boundary fixtures in tests.

## Compliance test

```bash
grep -E "(schema|validator|SCHEMA_VERSION|fixture|cross-field|server-side|exit code|JSON)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-95-data-contract-reconciliation-ledger.md`
