# MP-52 — Streaming data roundtrip boundary

**Discovered:** 2026-05-19T08:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Large data surfaces must stream through validated boundaries and prove round-trip integrity; loading everything, trusting file extensions, or omitting cursor semantics turns scale into silent corruption.

## Where it applies

CSV import/export, list APIs, database-backed CLIs, Supabase/Postgres schema work, bulk migrations, and admin downloads.

## Adoption signal

Skill requires streaming parsers/cursors, schema validation, stable pagination cursors, memory budgets, transaction policy, and an export-then-import round-trip check.

## Exemplar skills (≥5)

- `~/.claude/skills/csv-export-import/SKILL.md:48` — large exports stream from a database cursor.
- `~/.claude/skills/csv-export-import/SKILL.md:67` — imports start with preview validation before full import.
- `~/.claude/skills/csv-export-import/SKILL.md:93` — file extension is not trusted; MIME and delimiter are validated.
- `~/.claude/skills/csv-export-import/SKILL.md:200` — importing a file exported by the same system confirms round-trip integrity.
- `~/.claude/skills/pagination-filtering/SKILL.md:77` — cursor values are opaque to clients and validated server-side.
- `~/.claude/skills/pagination-filtering/SKILL.md:126` — filter and sort fields are whitelisted server-side.
- `~/.claude/skills/rust-cli-with-sqlite/SKILL.md:187` — export/import to a temp store and compare counts.
- `~/.claude/skills/supabase/SKILL.md:249` — schema is pulled and migrations are explicit.

## Adoption recipes

**Recipe 1 — Stream first:** use database cursors, streaming parsers, and bounded memory budgets for bulk data.

**Recipe 2 — Boundary schema:** validate MIME, delimiter, columns, filters, sort fields, and cursor payloads before mutation.

**Recipe 3 — Round-trip proof:** export a representative dataset, import into a temp store, and compare counts plus key fields.

## Compliance test

```bash
grep -E "(stream|cursor|round-trip|MIME|delimiter|whitelist|memory budget)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-53-idempotent-delivery-replay.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-95-data-contract-reconciliation-ledger.md`
