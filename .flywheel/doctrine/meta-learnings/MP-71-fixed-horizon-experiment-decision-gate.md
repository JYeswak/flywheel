# MP-71 — Fixed-horizon experiment decision gate

**Discovered:** 2026-05-19T07:12Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Experiment work pre-commits hypothesis, primary metric, sample size, guardrails, decision rule, and tracking schema before looking at results.

## Where it applies

A/B tests, conversion experiments, analytics events, survey analysis, statistical reports, pricing tests, and any optimization that can be distorted by peeking or metric shopping.

## Adoption signal

The skill defines the hypothesis and decision rule upfront, registers tracking dimensions, calculates sample size or power, includes guardrails, and blocks winner claims until the horizon is reached.

## Exemplar skills (≥5)

- `~/.claude/skills/ab-test-setup/SKILL.md:8` — tests must produce statistically valid, actionable results.
- `~/.claude/skills/ab-test-setup/SKILL.md:44` — sample size is pre-determined.
- `~/.claude/skills/ab-test-setup/SKILL.md:324` — peeking before sample size causes wrong decisions.
- `~/.claude/skills/ab-test-setup/SKILL.md:369` — guardrail concerns are part of result interpretation.
- `~/.claude/skills/ab-testing/SKILL.md:78` — experiment config includes name, variants, weights, and segment rules.
- `~/.claude/skills/ab-testing/SKILL.md:179` — skipping sample size calculation creates under-powered false negatives.
- `~/.claude/skills/statistical-analysis/SKILL.md:171` — A/B design defines primary metric and minimum detectable effect.
- `~/.claude/skills/analytics-tracking/SKILL.md:34` — every event should inform a decision.
- `~/.claude/skills/nps-analysis/SKILL.md:111` — segment comparisons must account for power differences.

## Adoption recipes

**Recipe 1 — Pre-register the test:** record hypothesis, primary metric, MDE, guardrails, sample size, runtime, and stopping rule.

**Recipe 2 — Instrument before launch:** register experiment dimensions and conversion events before traffic is assigned.

**Recipe 3 — Decide by rule:** ship, stop, or iterate only after the planned horizon and with practical significance stated.

## Compliance test

```bash
grep -E "(hypothesis|sample size|MDE|primary metric|guardrail|experiment_variant|stopping rule|power)" SKILL.md || fail
```
