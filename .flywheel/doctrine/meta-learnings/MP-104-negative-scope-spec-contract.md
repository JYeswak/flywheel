# MP-104 - Negative scope spec contract

**Discovered:** 2026-05-19T07:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

The spec is not complete until it says what is out of scope, what is unknown, which acceptance criteria fail the work, and when ambiguity stops implementation.

## Where it applies

PRDs, requirements workshops, RFP analysis, proposal scoping, feature specs, test plans, and any project where unstated negative space becomes scope creep.

## Adoption signal

The spec uses numbered testable requirements, visible Won't items, negative/error acceptance criteria, N/A justifications, and stop conditions for ambiguity or cross-team dependency.

## Exemplar skills (>=5)

- `~/.claude/skills/spec-driven-workflow/SKILL.md:13` - the spec is the contract and traces code/tests to requirements and acceptance criteria.
- `~/.claude/skills/spec-driven-workflow/SKILL.md:30` - implementation does not begin before the spec is reviewed and approved.
- `~/.claude/skills/spec-driven-workflow/SKILL.md:50` - explicit exclusions prevent scope creep.
- `~/.claude/skills/spec-driven-workflow/SKILL.md:73` - scope creep, severe ambiguity, security unknowns, and cross-team dependencies are stop conditions.
- `~/.claude/skills/requirements-gathering/SKILL.md:82` - each story needs acceptance criteria including negative or error cases.
- `~/.claude/skills/requirements-gathering/SKILL.md:115` - MoSCoW distinguishes Must, Should, Could, and Won't.
- `~/.claude/skills/requirements-gathering/SKILL.md:148` - solution masquerading as requirement and missing negative cases are anti-patterns.
- `~/.claude/skills/rfp-response/SKILL.md:48` - every RFP receives a bid/no-bid decision before resources are committed.

## Adoption recipes

**Recipe 1 - Negative space pass:** write Won't, N/A, excluded users, unsupported workflows, and non-goals as first-class rows.

**Recipe 2 - Failure acceptance:** add at least one negative or error acceptance criterion to each story or requirement group.

**Recipe 3 - Stop gate:** define ambiguity, security, compliance, and dependency thresholds that block implementation.

## Compliance test

```bash
grep -E "(out of scope|Won.t|negative|error case|acceptance criteria|stop condition|N/A|scope creep|bid/no-bid)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-80-scope-token-operation-matrix.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-94-risk-proportional-human-gate.md`
