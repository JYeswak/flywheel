# MP-50 — Formal feedback friction loop

**Discovered:** 2026-05-19T08:05Z
**Discovered by:** skillos:2
**Skills exemplifying:** 3+

## Essence

Friction from proofs, rubrics, reviews, and gap checks is evidence; route it into a bounded feedback loop with one lever changed per iteration and a proof-carrying artifact at closure.

## Where it applies

Formal verification, research rubrics, project reality checks, performance reviews, media grading, documentation demos, and any workflow where evaluation should change the work.

## Adoption signal

Skill classifies feedback signals, declares an iteration budget, changes one lever, reruns the evaluator, and emits an artifact that carries the before/after evidence.

## Exemplar skills (≥5)

- `~/.claude/skills/lean-formal-feedback-loop/SKILL.md:12` — proof friction is high-signal evidence.
- `~/.claude/skills/lean-formal-feedback-loop/SKILL.md:39` — treat proof friction as evidence, not tactic debt.
- `~/.claude/skills/lean-formal-feedback-loop/SKILL.md:40` — change one lever per iteration, then rerun proof and conformance.
- `~/.claude/skills/lean-formal-feedback-loop/SKILL.md:53` — every loop emits a proof-carrying artifact record.
- `~/.claude/skills/lean-formal-feedback-loop/SKILL.md:91` — frog ranking budgets impact, bug prior, runtime reach, proof cost, and model cost.
- `~/.claude/skills/grading-intro-outro-by-research-rubric/SKILL.md:42` — read JSON evidence before making a taste call.
- `~/.claude/skills/reality-check-for-project/SKILL.md:258` — repeat refinement rounds until a pass finds nothing to change.
- `~/.claude/skills/reality-check-for-project/SKILL.md:366` — proof gaps are code that exists without tests proving it works.

## Adoption recipes

**Recipe 1 — Friction classifier:** route each blocker as code defect, model drift, scope mismatch, proof debt, rubric miss, or missing evidence.

**Recipe 2 — Single-lever loop:** change one lever, rerun the evaluator, and record whether the signal moved.

**Recipe 3 — Closure artifact:** no closure without before signal, after signal, changed lever, budget consumed, and artifact hash/path.

## Compliance test

```bash
grep -E "(proof friction|one lever|proof-carrying|rubric|gap analysis|refinement rounds)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-08-trauma-class-promotion.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-98-customer-signal-to-root-cause-loop.md`
