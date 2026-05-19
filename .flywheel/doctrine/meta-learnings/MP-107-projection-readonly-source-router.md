# MP-107 - Projection read-only source router

**Discovered:** 2026-05-19T07:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Search, doctor, and projection tools should declare the source of truth they read, the projection they query, and the mutations they refuse, then route exact and semantic questions to different tools.

## Where it applies

Skill search, semantic code search, doctor CLIs, qdrant projections, registry projections, MCP servers, validators, and automation that could confuse cached projection state with canonical state.

## Adoption signal

The tool states its canonical source, projection source, read/write boundary, freshness stamps, routing rules, and failure mode when the projection is stale or unavailable.

## Exemplar skills (>=5)

- `~/.claude/skills/skill-search-mcp/SKILL.md:14` - the MCP reads a qdrant projection and returns ranked skills with freshness and source stamps.
- `~/.claude/skills/skill-search-mcp/SKILL.md:18` - the server remains read-only and never rebuilds indexes or mutates config.
- `~/.claude/skills/skill-search-mcp/SKILL.md:22` - SKILL.md is truth source, qdrant is projection, and flywheel DB supplies stamps.
- `~/.claude/skills/flywheel-doctor-author/SKILL.md:9` - doctor invariants measure real substrate and report through a real consumer.
- `~/.claude/skills/flywheel-doctor-author/SKILL.md:20` - halt-on-breach requires an executable test proving the consumer reads the metric.
- `~/.claude/skills/search-tool-routing-doctrine/SKILL.md:14` - exact symbols and paths route to `rg`; architecture questions route to semantic search.
- `~/.claude/skills/search-tool-routing-doctrine/SKILL.md:37` - broad semantic search is the wrong tool for exact lookup.
- `~/.claude/skills/skill-when-not-to-use-discipline/SKILL.md:13` - durable skills require refusal envelopes with negative triggers and alternate routing.

## Adoption recipes

**Recipe 1 - Truth/projection declaration:** name the canonical source, projection, index freshness, and owner.

**Recipe 2 - Refusal envelope:** document when the tool must not be used and where the request routes instead.

**Recipe 3 - Consumer proof:** add a test or doctor row proving a real consumer uses the measured substrate.

## Compliance test

```bash
grep -E "(read-only|source of truth|projection|freshness|route|refusal|doctor|consumer|rg|semantic)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-55-source-of-truth-hierarchy.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-76-authority-ranked-retrieval-maintenance.md`
