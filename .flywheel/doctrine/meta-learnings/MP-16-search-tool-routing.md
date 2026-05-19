# MP-16 — Search tool routing doctrine

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 4+

## Essence

Before grep/read/cat, use socraticode (semantic search) + research-triad (external triangulation). K≥10 per query, Q≥2 phrasings, before any code claim. Routing wrong = wasted context.

## Where it applies

Any task involving code reading, file location, claim verification, prior-art research.

## Adoption signal

Skill cites socraticode-first or research-triad-first; uses K≥10 minimum.

## Exemplar skills (≥4)

- `~/.claude/skills/search-tool-routing-doctrine/SKILL.md:1` — direct exemplar
- `~/.claude/skills/socraticode/SKILL.md:1` — semantic-search-first
- `~/.claude/skills/research-triad/SKILL.md:1` — external triangulation
- `~/.claude/skills/skill-search-mcp/SKILL.md:1` — skill catalog search
- `~/.claude/skills/find-skills/SKILL.md:1` — skill location helper

## Adoption recipes

**Recipe 1 — Pre-action search:** every Read/Edit/Write tool call preceded by ≥1 socraticode_search or research-triad query.

**Recipe 2 — K + Q discipline:** queries use limit≥10 and at least 2 phrasings per concept.

**Recipe 3 — Receipt envelope:** action receipts include `socraticode_queries: [...]` + `indexed_chunks_observed: N`.

## Compliance test

```bash
# Search-routing skills MUST cite K and Q discipline.
grep -E "(K.{0,4}10|socraticode|research.triad|Q.{0,4}[23])" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
