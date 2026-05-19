# MP-62 — Converged plan register

**Discovered:** 2026-05-19T06:53Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Non-trivial work starts in a register before it starts in code: intent, alternatives, constraints, risks, debt interest, and convergence criteria are recorded so execution is a chosen path rather than momentum.

## Where it applies

Architecture changes, debt cleanup, territory planning, dispatch preparation, product scoping, portfolio decisions, and any work where the wrong premise is more expensive than delayed implementation.

## Adoption signal

The skill requires an explicit planning artifact, states what evidence changes the plan, ranks tradeoffs by an objective function, and defers dispatch until the plan has converged.

## Exemplar skills (≥5)

- `~/.claude/skills/plan-space-convergence/SKILL.md:18` — convergence flows through intent, plan, reasoning, polish, multi-model review, synthesis, and beads.
- `~/.claude/skills/plan-space-convergence/SKILL.md:39` — dispatch waits until convergence criteria are met.
- `~/.claude/skills/plan-space-convergence/SKILL.md:54` — a different lens must authorize the premise before non-trivial work starts.
- `~/.claude/skills/planning-workflow/SKILL.md:13` — planning tokens are cheaper than implementation.
- `~/.claude/skills/planning-workflow/SKILL.md:94` — hours of planning can avoid days of rework.
- `~/.claude/skills/tech-debt-management/SKILL.md:58` — the debt register is the canonical source.
- `~/.claude/skills/tech-debt-management/SKILL.md:77` — prioritize debt by interest rate, not principal.
- `~/.claude/skills/territory-planning/SKILL.md:19` — territory design is constrained optimization, not negotiation.

## Adoption recipes

**Recipe 1 — Register first:** create or update the planning, debt, territory, or risk register before changing implementation files.

**Recipe 2 — Convergence gate:** define the evidence that makes the plan good enough to dispatch and the evidence that would force replanning.

**Recipe 3 — Objective ranking:** rank choices by expected cost, interest, risk, or throughput instead of preference or ease.

## Compliance test

```bash
grep -E "(register|intent|convergence|criteria|debt|interest rate|objective|tradeoff)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-06-plan-space-convergence.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-70-reviewed-machine-plan-before-apply.md`
