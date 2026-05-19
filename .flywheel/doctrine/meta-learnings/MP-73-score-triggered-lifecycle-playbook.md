# MP-73 — Score-triggered lifecycle playbook

**Discovered:** 2026-05-19T07:12Z
**Discovered by:** skillos:2
**Skills exemplifying:** 7+

## Essence

Lifecycle operations turn raw signals into scored tiers, then bind each tier to a specific playbook, owner, SLA, and escalation trigger.

## Where it applies

Lead qualification, onboarding, customer health, churn prevention, renewals, upsells, sales pipeline hygiene, support operations, and customer-success dashboards.

## Adoption signal

The skill defines score inputs, time decay or calibration, tier thresholds, required reasoning, and concrete actions for each score band.

## Exemplar skills (≥5)

- `~/.claude/skills/lead-qualification/SKILL.md:72` — lead scores combine four dimensions.
- `~/.claude/skills/lead-qualification/SKILL.md:166` — score segments map to route and SLA.
- `~/.claude/skills/lead-qualification/SKILL.md:192` — a score handoff includes reasoning.
- `~/.claude/skills/customer-onboarding/SKILL.md:55` — every milestone has owner, target day, success criterion, and escalation trigger.
- `~/.claude/skills/customer-health-scoring/SKILL.md:26` — account health scores classify risk tiers and trigger interventions.
- `~/.claude/skills/renewal-management/SKILL.md:143` — renewal risk score determines downstream action.
- `~/.claude/skills/churn-prediction/SKILL.md:184` — risk tiers must tie to campaign actions.
- `~/.claude/skills/upsell-identification/SKILL.md:82` — expansion score combines signal weight, strength, and recency decay.
- `~/.claude/skills/pipeline-management/SKILL.md:38` — stages require objective entry and exit criteria.

## Adoption recipes

**Recipe 1 — Score card:** list signal inputs, weights, decay, exclusions, and calibration source.

**Recipe 2 — Tier table:** map score bands to status, owner, SLA, customer action, internal action, and escalation.

**Recipe 3 — Reasoned handoff:** every score output includes top drivers, negative signals, missing data, and next action.

## Compliance test

```bash
grep -E "(score|tier|stage|SLA|playbook|trigger|owner|recency|reasoning)" SKILL.md || fail
```
