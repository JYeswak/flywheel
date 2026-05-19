# MP-88 - Content-addressed evidence pack

**Discovered:** 2026-05-19T07:36Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Claims that need to survive handoff should be sealed into content-addressed, schema-versioned packs that can be verified offline and replayed deterministically.

## Where it applies

Incident bundles, audit evidence, memory writes, API migrations, lifecycle transitions, receipt mining, changelogs, and compliance handoffs.

## Adoption signal

The artifact has a manifest with hashes, schema_version constants, append-only lineage, deterministic replay or verification, and a refusal path for missing or malformed pack members.

## Exemplar skills (>=5)

- `~/.claude/skills/all-the-receipts/SKILL.md:26` - structural compatibility is checked before receipt generation.
- `~/.claude/skills/all-the-receipts/SKILL.md:28` - receipt packs are sealed into content-addressed evidence.
- `~/.claude/skills/all-the-receipts/SKILL.md:188` - pack verification works from disk without network or catalog trust.
- `~/.claude/skills/incident-replay-bundle/SKILL.md:12` - replay bundles are signed, content-addressed directories with a validated manifest.
- `~/.claude/skills/incident-replay-bundle/SKILL.md:18` - manifest schema pins `schema_version` as a const.
- `~/.claude/skills/incident-replay-bundle/SKILL.md:61` - replay tests include determinism and unsupported schema rejection.
- `~/.claude/skills/agent-memory/SKILL.md:36` - every memory mutation appends audit events with schema_version and content hash.
- `~/.claude/skills/api-design-patterns/SKILL.md:124` - API audit rows are append-only and never rewrite history.
- `~/.claude/skills/agent-lifecycle/SKILL.md:132` - lifecycle transitions append audit rows and corrections supersede rather than rewrite.

## Adoption recipes

**Recipe 1 - Seal the evidence:** write a manifest listing every member, hash, schema version, source, and expected replay order.

**Recipe 2 - Verify cold:** provide a command that validates the pack without network access or producer trust.

**Recipe 3 - Correct by supersession:** never rewrite old evidence; append a correction, tombstone, or supersession row.

## Compliance test

```bash
grep -E "(manifest|schema_version|sha256|content-address|pack verify|replay|append-only|supersedes)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-42-independent-evidence-convergence.md`
