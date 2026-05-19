# MP-125 - Constraint-scored operations control tower

**Discovered:** 2026-05-19T07:56Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Operational automation should join upstream data, model constraints, score alternatives, escalate exceptions, and require human approval before mutating live operational systems.

## Where it applies

Supply chain control towers, logistics routing, procurement workflows, production scheduling, vendor scoring, exception dashboards, risk playbooks, and capacity-constrained operations.

## Adoption signal

The skill enumerates data inputs, validates quality, names hard and soft constraints, scores options, classifies exception severity, supplies mitigation playbooks, and blocks ERP/TMS/WMS/vendor/payment mutations without approval.

## Exemplar skills (>=5)

- `~/.claude/skills/supply-chain-control-tower/SKILL.md:15` - control towers integrate suppliers, logistics, warehouses, demand, risk dashboards, scorecards, and mitigations.
- `~/.claude/skills/supply-chain-control-tower/SKILL.md:35` - live ERP, TMS, WMS, supplier, carrier, or inventory mutation requires human approval.
- `~/.claude/skills/supply-chain-control-tower/SKILL.md:37` - the data layer spans ERP, TMS, WMS, supplier, IoT, external, and financial sources.
- `~/.claude/skills/supply-chain-control-tower/SKILL.md:88` - exception taxonomy and escalation matrix are explicit.
- `~/.claude/skills/supply-chain-control-tower/SKILL.md:140` - disruption response playbooks are part of the workflow.
- `~/.claude/skills/logistics-optimization/SKILL.md:37` - logistics optimization follows a six-stage pipeline.
- `~/.claude/skills/logistics-optimization/SKILL.md:119` - carrier scoring and freight audit are explicit scoring surfaces.
- `~/.claude/skills/procurement-automation/SKILL.md:71` - procurement uses a vendor score matrix and formula.
- `~/.claude/skills/production-scheduling/SKILL.md:117` - production scheduling separates hard and soft constraints.

## Adoption recipes

**Recipe 1 - Data spine:** normalize source systems, freshness, quality checks, and ownership before optimization.

**Recipe 2 - Constraint and score model:** encode hard constraints, soft preferences, scoring formulas, and exception thresholds.

**Recipe 3 - Approval and playbook gate:** route every live mutation through an owner-approved action and attach the matching mitigation playbook.

## Compliance test

```bash
grep -E "(ERP|TMS|WMS|constraint|score|exception|escalation|playbook|approval|vendor|carrier)" SKILL.md || exit 1
```
