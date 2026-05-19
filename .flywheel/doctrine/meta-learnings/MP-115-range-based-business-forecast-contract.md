# MP-115 - Range-based business forecast contract

**Discovered:** 2026-05-19T07:46Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Business forecasts and growth decisions should expose assumptions, ranges, confidence, unit economics, source context, and follow-up measurement instead of presenting a single-point wish.

## Where it applies

Sales forecasts, paid acquisition, pricing, conversion optimization, demand planning, launch planning, and any decision that commits budget, revenue expectations, or customer growth targets.

## Adoption signal

The artifact names objective, budget, value metric, conversion target, confidence range, calibration data, hypothesis, and the measurement that will prove or falsify the decision.

## Exemplar skills (>=5)

- `~/.claude/skills/sales-forecasting/SKILL.md:26` - every forecast decomposes into verifiable assumptions, explicit error bounds, and deal-level evidence.
- `~/.claude/skills/sales-forecasting/SKILL.md:30` - forecasts are probability-weighted expectations over bounded horizons, not targets or wishes.
- `~/.claude/skills/sales-forecasting/SKILL.md:45` - forecasts produce commit, best-case, upside ranges, coverage ratios, bias checks, and governance notes.
- `~/.claude/skills/sales-forecasting/SKILL.md:118` - mature forecasts run multiple methods and blend by trailing accuracy.
- `~/.claude/skills/paid-ads/SKILL.md:14` - campaigns start with objective, target CPA or ROAS, budget, and constraints.
- `~/.claude/skills/paid-ads/SKILL.md:32` - current pixel, conversion, funnel, and creative state are gathered before recommendations.
- `~/.claude/skills/pricing-strategy/SKILL.md:26` - pricing work starts from conversion, ARPU, churn, and customer feedback.
- `~/.claude/skills/page-cro/SKILL.md:147` - CRO outputs quick wins, high-impact changes, test ideas, and copy alternatives.

## Adoption recipes

**Recipe 1 - Assumption ledger:** list data source, current state, target, constraint, and confidence for every forecast input.

**Recipe 2 - Range output:** report low/base/high or commit/best-case/upside, never one naked number.

**Recipe 3 - Measurement hook:** define the metric, window, cohort, and decision rule that updates the forecast.

## Compliance test

```bash
grep -E "(forecast|range|confidence|assumption|CPA|ROAS|conversion|ARPU|churn|hypothesis|test)" SKILL.md || exit 1
```
