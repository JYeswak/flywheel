# MP-76 — Authority-ranked retrieval maintenance

**Discovered:** 2026-05-19T07:12Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Search and research systems need authority-aware retrieval plus maintenance: route the query, retrieve broadly, rerank for relevance, cite sources, detect duplicates, and prune stale or low-authority content.

## Where it applies

RAG systems, knowledge bases, research CLIs, code search, doc maintenance, text-to-SQL examples, help centers, and any agent workflow that answers from a corpus.

## Adoption signal

The skill records query routing, source authority, retrieval metrics, reranking, citations, duplicate detection, freshness checks, and a maintenance cadence.

## Exemplar skills (≥5)

- `~/.claude/skills/information-retrieval/SKILL.md:18` — generation quality is capped by retrieval quality.
- `~/.claude/skills/information-retrieval/SKILL.md:73` — sparse and dense retrieval are combined.
- `~/.claude/skills/information-retrieval/SKILL.md:121` — first-stage retrieval optimizes recall and reranking optimizes precision.
- `~/.claude/skills/information-retrieval/SKILL.md:151` — minimum evaluation uses Recall@10, MRR, and NDCG@10.
- `~/.claude/skills/multi-document-rag/SKILL.md:27` — document maintenance includes authority scoring and duplicate detection.
- `~/.claude/skills/multi-document-rag/SKILL.md:240` — code alignment drops authority when referenced code is gone.
- `~/.claude/skills/research-triad/SKILL.md:75` — research scoring combines recency, authority, and cluster relevance.
- `~/.claude/skills/research-software/SKILL.md:117` — code wins over docs for actual defaults.
- `~/.claude/skills/knowledge-base-management/SKILL.md:26` — article quality includes completeness, freshness, and resolution metrics.

## Adoption recipes

**Recipe 1 — Route by corpus:** choose keyword, semantic, code, web, or authority-index retrieval based on the question.

**Recipe 2 — Rerank with citations:** retrieve wide, rerank narrow, and cite source path, timestamp, or commit for every claim.

**Recipe 3 — Maintain the corpus:** run duplicate, freshness, broken-reference, and authority checks on a cadence.

## Compliance test

```bash
grep -E "(authority|rerank|Recall@10|MRR|NDCG|duplicate|freshness|citation|query routing)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-16-search-tool-routing.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-55-source-of-truth-hierarchy.md`
