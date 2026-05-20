# MP-21 — Decision-matrix routing

**Discovered:** 2026-05-19T06:21Z
**Skills exemplifying:** 6+

## Essence

When several valid implementation paths exist, route by an explicit decision matrix or selection tree before recommending a pattern; "best practice" without criteria is under-specified.

## Where it applies

API/versioning choices, deployment modes, queues, conformance harnesses, audit depth selection, caching layers, dependency update strategy.

## Adoption signal

Skill or repo doctrine includes a decision tree, comparison matrix, or pattern-selection table with criteria and tradeoffs.

## Exemplar skills (≥5)

- `~/.claude/skills/deployment-strategy/SKILL.md:27` — pattern selection table chooses blue-green, canary, rolling, or feature flags by rollback and exposure criteria.
- `~/.claude/skills/background-jobs/SKILL.md:41` — queue technology selection is an explicit choice framework.
- `~/.claude/skills/testing-conformance-harnesses/SKILL.md:52` — conformance approach starts with a decision tree.
- `~/.claude/skills/api-versioning/SKILL.md:259` — versioning strategy has a decision framework.
- `~/.claude/skills/api-versioning/SKILL.md:296` — versioning options are compared in a matrix.
- `~/.claude/skills/codebase-audit/SKILL.md:14` — audit scope begins with "when to use what" routing.

## Adoption recipes

**Recipe 1 — Strategy surface:** add `## Decision Matrix` before implementation steps for any skill with multiple viable paths.

**Recipe 2 — CLI doctor:** expose `choose --json` or `recommend --json` that returns selected path, rejected alternatives, and criteria.

**Recipe 3 — Receipt field:** every recommendation receipt includes `decision_matrix_used: true`, `selected_option`, and `rejected_options`.

## Compliance test

```bash
grep -E "(Decision Framework|Decision Tree|Comparison Matrix|Pattern Selection|When to Use What)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-04 — receipt-and-callback envelope contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md` for the canonical pattern.
- **MP-20 — cross-orch handoff:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md` for the canonical pattern.
- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
