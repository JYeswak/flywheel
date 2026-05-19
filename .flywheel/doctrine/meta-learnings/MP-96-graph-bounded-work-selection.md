# MP-96 - Graph-bounded work selection

**Discovered:** 2026-05-19T08:02Z
**Discovered by:** skillos:2
**Skills exemplifying:** 8+

## Essence

When work items have dependencies or relationships, selection and scheduling should be computed from a bounded graph, not intuition or FIFO order.

## Where it applies

Bead planning, swarm dispatch, agent orchestration, dependency migrations, knowledge graph traversal, RAG expansion, incident chains, and any backlog with dependencies.

## Adoption signal

The system validates cycles, proves traversal bounds, ranks bottlenecks, schedules DAG-ready work, and caches expensive graph metrics until mutation.

## Exemplar skills (>=5)

- `~/.claude/skills/beads-bv/SKILL.md:12` - backlogs are directed graphs where PageRank and betweenness identify priorities.
- `~/.claude/skills/beads-bv/SKILL.md:109` - cycles mean the graph is broken and must be fixed immediately.
- `~/.claude/skills/graph-algorithms/SKILL.md:14` - every graph operation needs proven complexity bounds.
- `~/.claude/skills/graph-algorithms/SKILL.md:21` - DAG scheduling uses critical path and topological sort.
- `~/.claude/skills/graph-algorithms/SKILL.md:225` - traversals require depth and breadth limits.
- `~/.claude/skills/agent-orchestration/SKILL.md:150` - tasks are defined as a DAG with dependencies and per-task timeouts.
- `~/.claude/skills/agent-orchestration/SKILL.md:186` - dependency graphs must be validated for cycles and missing dependencies.
- `~/.claude/skills/multi-agent-swarm-workflow/SKILL.md:60` - swarm launch requires dependency cycles to be empty.
- `~/.claude/skills/knowledge-graph/SKILL.md:195` - graph quality metrics include connectivity, completeness, and freshness.

## Adoption recipes

**Recipe 1 - Cycle gate:** run cycle detection before any DAG-dependent schedule or dispatch.

**Recipe 2 - Bottleneck rank:** compute centrality or critical path to find the next work item that unblocks the most downstream value.

**Recipe 3 - Traversal budget:** set depth, breadth, node, and latency limits for every graph query.

## Compliance test

```bash
grep -E "(graph|cycle|DAG|topological|PageRank|betweenness|critical path|bounded|traversal)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-10-codebase-archaeology.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-16-search-tool-routing.md`
