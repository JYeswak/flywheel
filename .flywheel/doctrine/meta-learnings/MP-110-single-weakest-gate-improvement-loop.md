# MP-110 - Single weakest-gate improvement loop

**Discovered:** 2026-05-19T07:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Quality improvement loops should baseline the artifact, identify the single weakest gate, make one targeted change, re-score the same rubric, and revert if any protected gate regresses.

## Where it applies

Skill autoresearch, prompt tuning, eval frameworks, SEO experiments, multi-model review, provider recommendations, and any iterative improvement system that can overfit or mask regressions.

## Adoption signal

Each iteration records baseline score, weakest gate, intended change, post-change score, protected-regression checks, decision, and rollback result in a machine-readable receipt.

## Exemplar skills (>=5)

- `~/.claude/skills/skill-autoresearch/SKILL.md:8` - the skill uses a closed-loop optimization process.
- `~/.claude/skills/skill-autoresearch/SKILL.md:40` - grade, target the weakest gate, enhance, re-grade, and revert on regression.
- `~/.claude/skills/skill-autoresearch/SKILL.md:65` - the grader script is the single source of truth.
- `~/.claude/skills/skill-autoresearch/SKILL.md:168` - improvements require strict score gain and no regression.
- `~/.claude/skills/evaluation-framework/SKILL.md:20` - evaluation catches bad outputs and compares model or prompt changes.
- `~/.claude/skills/evaluation-framework/SKILL.md:83` - human feedback feeds continuous learning.
- `~/.claude/skills/prompt-engineering-science/SKILL.md:150` - guardrails are measured with an eval suite and documented prompt version.
- `~/.claude/skills/seo-for-saas-businesses/SKILL.md:34` - every recommendation emits a decision card.

## Adoption recipes

**Recipe 1 - Baseline receipt:** record current score, gate breakdown, evaluator version, and protected gates.

**Recipe 2 - One-gate patch:** change only the weakest gate's supporting artifact so causality is inspectable.

**Recipe 3 - Regression decision:** re-run the same evaluator and either accept with evidence or revert with reason.

## Compliance test

```bash
grep -E "(baseline|weakest|gate|re-grade|regression|revert|rubric|evaluator|decision card|score)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-41-gate-class-separation.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-87-binding-constraint-capacity-score.md`
