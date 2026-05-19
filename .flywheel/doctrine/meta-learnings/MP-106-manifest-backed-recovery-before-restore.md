# MP-106 - Manifest-backed recovery before restore

**Discovered:** 2026-05-19T07:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Recovery is only trustworthy when it begins from a validated manifest or full-family snapshot, runs read-only diagnosis first, and emits a restore receipt separating restored, already-present, skipped, and failed items.

## Where it applies

Fleet recovery, SQLite corruption handling, session restore, compact reminders, parity contracts, token rotation coordination, WAL-backed stores, and any operation that might destroy evidence while repairing state.

## Adoption signal

The procedure creates or validates a manifest, snapshots every required file family, performs dry-run diagnosis, requires explicit apply authorization for destructive repair, and writes a final machine-readable receipt.

## Exemplar skills (>=5)

- `~/.claude/skills/flywheel-recovery/SKILL.md:16` - every recovery operation starts with a manifest.
- `~/.claude/skills/flywheel-recovery/SKILL.md:29` - manifest beats prose and freshness is explicit.
- `~/.claude/skills/flywheel-recovery/SKILL.md:114` - restore checks current state and emits restored, already-present, failed, and skipped categories.
- `~/.claude/skills/sqlite-page-corruption-recovery/SKILL.md:28` - diagnosis is read-only first, then full-family snapshot, JSONL evidence, and dry-run repair.
- `~/.claude/skills/sqlite-page-corruption-recovery/SKILL.md:83` - database, WAL, and SHM files are copied together.
- `~/.claude/skills/parity-contract-markdown-json/SKILL.md:3` - Markdown fenced JSON and sibling JSON must validate as byte-identical.
- `~/.claude/skills/post-compact-reminder/SKILL.md:20` - marker files bridge compaction because the agent cannot rely on remembered state.
- `~/.claude/skills/infisical-rotation-ops/SKILL.md:107` - secret rotation is not automatic without coordination.

## Adoption recipes

**Recipe 1 - Manifest first:** write or validate a manifest before any restore or repair step.

**Recipe 2 - Evidence-preserving snapshot:** copy the whole state family and quarantine broken material instead of deleting it.

**Recipe 3 - Categorized closeout:** emit restored, already-present, skipped, failed, validation, and freshness fields in a receipt.

## Compliance test

```bash
grep -E "(manifest|snapshot|WAL|SHM|dry-run|restore|receipt|already_present|quarantine|validate)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-83-portable-session-recovery-ladder.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-92-reversible-recovery-ladder.md`
