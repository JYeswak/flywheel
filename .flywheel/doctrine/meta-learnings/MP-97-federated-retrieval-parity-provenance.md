# MP-97 - Federated retrieval parity provenance

**Discovered:** 2026-05-19T08:02Z
**Discovered by:** skillos:2
**Skills exemplifying:** 7+

## Essence

Multi-source retrieval only works when every source declares embedding parity, source timeouts, score normalization, provenance, and freshness controls.

## Where it applies

Cross-collection Qdrant search, RAG, knowledge graphs, watchtowers, source routing, vector migrations, contextual retrieval, and multi-agent memory.

## Adoption signal

The retrieval layer records model and dimension per collection, enforces per-source timeout, merges with rank normalization, tracks provenance on facts, and fails loudly on ingest-count drift.

## Exemplar skills (>=5)

- `~/.claude/skills/cross-collection-fanout/SKILL.md:15` - federated query uses parallel per-collection queries then merge and global rerank.
- `~/.claude/skills/cross-collection-fanout/SKILL.md:19` - one slow collection must not block fan-out.
- `~/.claude/skills/cross-collection-fanout/SKILL.md:20` - all collections must share embedding model and dimension.
- `~/.claude/skills/cross-collection-fanout/SKILL.md:21` - raw cosine scores across collections require rank normalization.
- `~/.claude/skills/nomic-embeddings/SKILL.md:25` - each collection records embedding model and dimension.
- `~/.claude/skills/qdrant-ops/SKILL.md:52` - count checks after upsert can be stale unless `wait=true` or retried.
- `~/.claude/skills/udr-rag-hybrid/SKILL.md:54` - ingest count verification prevents silent document loss.
- `~/.claude/skills/knowledge-graph/SKILL.md:176` - every triple stores source provenance and extraction timestamp.
- `~/.claude/skills/info-source-watchtower/SKILL.md:34` - daily ingest writes durable records rather than a dashboard-only view.

## Adoption recipes

**Recipe 1 - Collection contract:** store embedding model, dimension, truncation, distance metric, payload indexes, and freshness SLA.

**Recipe 2 - Partial-result receipt:** record which sources timed out, returned counts, and were excluded from merge.

**Recipe 3 - Provenance on every fact:** include source, timestamp, confidence, extractor version, and access partition.

## Compliance test

```bash
grep -E "(embedding|dimension|collection|timeout|RRF|normalization|provenance|freshness|count)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-76-authority-ranked-retrieval-maintenance.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
