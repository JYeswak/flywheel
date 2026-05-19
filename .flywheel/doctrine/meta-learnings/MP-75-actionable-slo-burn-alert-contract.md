# MP-75 — Actionable SLO burn alert contract

**Discovered:** 2026-05-19T07:12Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Monitoring only helps when alerts map to user-facing SLIs, error-budget burn, deduplicated severity, and a runbook action someone can take immediately.

## Where it applies

Observability stacks, uptime monitoring, SLA compliance, incident response, log aggregation, status pages, system-health recovery, and production support rotations.

## Adoption signal

The skill defines SLIs, SLOs, error budgets, burn-rate thresholds, alert grouping, actionability tests, linked runbooks, and post-incident feedback into thresholds.

## Exemplar skills (≥5)

- `~/.claude/skills/observability-platform/SKILL.md:38` — agent services define SLOs, SLIs, and error budgets.
- `~/.claude/skills/observability-platform/SKILL.md:191` — alerts use burn rate, not raw error rate.
- `~/.claude/skills/uptime-monitoring/SKILL.md:93` — every alert must be actionable.
- `~/.claude/skills/uptime-monitoring/SKILL.md:111` — alert-to-action ratio tunes thresholds monthly.
- `~/.claude/skills/sla-monitoring/SKILL.md:20` — each SLA metric needs definition, measurement, threshold, detection, credit, and remediation.
- `~/.claude/skills/sla-monitoring/SKILL.md:136` — burn-rate alerts catch trends before budget exhaustion.
- `~/.claude/skills/incident-response/SKILL.md:201` — every alerting rule links to a runbook.
- `~/.claude/skills/log-aggregation/SKILL.md:193` — alerts that should be ignored should be deleted.
- `~/.claude/skills/observability-designer/SKILL.md:88` — every alert must have a clear response action.

## Adoption recipes

**Recipe 1 — SLI first:** define the user-facing measure and error budget before writing alert rules.

**Recipe 2 — Burn-rate page:** page only on sustained, budget-consuming symptoms with severity and grouping rules.

**Recipe 3 — Runbook loop:** every alert links to a runbook, and every incident updates the alert, threshold, or runbook.

## Compliance test

```bash
grep -E "(SLI|SLO|error budget|burn rate|actionable|runbook|dedup|severity|alert-to-action)" SKILL.md || fail
```
