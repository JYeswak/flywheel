# MP-87 - Binding constraint capacity score

**Discovered:** 2026-05-19T07:36Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Scaling decisions should name the current binding stock and optimize the minimum capacity, not the easiest metric to buy or average.

## Where it applies

Agent fleets, token budgets, cost monitoring, cloud infrastructure, model routing, account rotation, SaaS usage metering, and dispatch capacity planning.

## Adoption signal

The workflow measures accounts, machines, tokens, queue, driver proof, spend, quota, and budget thresholds, then recommends the intervention that changes the lowest limiting stock.

## Exemplar skills (>=5)

- `~/.claude/skills/agent-fleet-management/SKILL.md:11` - fleets are constrained by accounts, machines, and token budget.
- `~/.claude/skills/agent-fleet-management/SKILL.md:15` - workers must not be scaled before the binding constraint is measured.
- `~/.claude/skills/agent-fleet-management/SKILL.md:31` - current binding constraint is classified as accounts, machines, tokens, queue, or driver.
- `~/.claude/skills/agent-fleet-management/SKILL.md:115` - leverage score is the minimum normalized stock.
- `~/.claude/skills/coding-agent-usage-tracker/SKILL.md:121` - quota-aware dispatch depends on provider usage checks.
- `~/.claude/skills/coding-agent-usage-tracker/SKILL.md:166` - usage data is point-in-time and must be re-fetched before critical decisions.
- `~/.claude/skills/agent-cost-optimization/SKILL.md:59` - every token consumed is attributed to customer, agent, task, and category.
- `~/.claude/skills/agent-cost-optimization/SKILL.md:224` - cheapest model can cost more when quality failures cause reruns.
- `~/.claude/skills/cost-monitoring-infra/SKILL.md:174` - budget alerts have threshold semantics.
- `~/.claude/skills/cost-attribution/SKILL.md:20` - unattributed cost cannot be optimized, priced, or justified.

## Adoption recipes

**Recipe 1 - Minimum-stock report:** calculate account, machine, token, queue, and driver availability; report the minimum as the capacity ceiling.

**Recipe 2 - Attribute before optimize:** attach cost and usage to customer, agent, task, model, and retry/failure class.

**Recipe 3 - Avoid average comfort:** never summarize capacity as an average when one red stock blocks all useful work.

## Compliance test

```bash
grep -E "(binding constraint|accounts|machines|tokens|quota|budget|attribut|minimum|threshold)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-47-throughput-backpressure-budget.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-60-measured-performance-budget-loop.md`
