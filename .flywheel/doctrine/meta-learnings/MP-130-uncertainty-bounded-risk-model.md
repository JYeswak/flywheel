# MP-130 - Uncertainty-bounded risk model

**Discovered:** 2026-05-19T07:56Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Forecasts, fraud scores, and risk recommendations must expose assumptions, uncertainty, validation metrics, false-positive costs, and human review gates before they drive action.

## Where it applies

Financial models, demand forecasts, fraud detection, predictive maintenance, anomaly scoring, capacity planning, investment cases, inventory recommendations, and regulated triage.

## Adoption signal

The workflow avoids single-point claims, decomposes drivers, validates against holdout or historical data, reports confidence intervals or scenarios, tracks precision or bias, and blocks real-world action until reviewed by the responsible human.

## Exemplar skills (>=5)

- `~/.claude/skills/financial-modeling/SKILL.md:16` - financial models must be auditable, assumption-explicit, and stress-testable.
- `~/.claude/skills/financial-modeling/SKILL.md:20` - the value of a model is explicit assumptions, bounded uncertainty, and sensitivity.
- `~/.claude/skills/financial-modeling/SKILL.md:139` - bear, base, and bull scenarios are mandatory.
- `~/.claude/skills/financial-modeling/SKILL.md:147` - single-scenario forecasting is an anti-pattern.
- `~/.claude/skills/demand-forecasting/SKILL.md:27` - forecasts require confidence intervals, accuracy metrics, and actionable recommendations.
- `~/.claude/skills/demand-forecasting/SKILL.md:108` - model selection uses holdout and rolling-origin validation.
- `~/.claude/skills/demand-forecasting/SKILL.md:142` - accuracy measurement uses multiple complementary metrics.
- `~/.claude/skills/fraud-detection/SKILL.md:15` - fraud systems balance detection rate against false positives.
- `~/.claude/skills/fraud-detection/SKILL.md:47` - a score is a lead, not a fraud finding.
- `~/.claude/skills/predictive-maintenance/SKILL.md:16` - maintenance recommendations need failure probability, confidence bounds, prioritized actions, and ROI.
- `~/.claude/skills/predictive-maintenance/SKILL.md:121` - validation requires time-ordered splits and precision/recall thresholds.

## Adoption recipes

**Recipe 1 - Assumption ledger:** list drivers, data sources, exclusions, ranges, and uncertainty before showing a recommendation.

**Recipe 2 - Validation packet:** include holdout method, bias, precision, recall, MAPE, confidence interval, or scenario table as appropriate.

**Recipe 3 - Action gate:** route scores and forecasts to review, triage, or planning; never label them as findings or execute live action directly.

## Compliance test

```bash
grep -E "(assumption|scenario|confidence|holdout|precision|recall|bias|false positive|review|score|forecast)" SKILL.md || exit 1
```
