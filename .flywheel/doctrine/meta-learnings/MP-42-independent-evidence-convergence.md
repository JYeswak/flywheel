# MP-42 — Independent-evidence convergence

**Discovered:** 2026-05-19T08:05Z
**Discovered by:** skillos:2
**Skills exemplifying:** 3+

## Essence

Convergence only counts when independent methods reach the same finding from distinct evidence; agreement from one reasoning style is monoculture, not proof.

## Where it applies

Idea selection, project analysis, swarm audits, research rubrics, model arbitration, and any decision where taste or a single evaluator can overfit.

## Adoption signal

Skill requires independent generation, opposing scores, different evidence methods, or explicit disagreement handling before declaring consensus.

## Exemplar skills (≥5)

- `~/.claude/skills/dueling-idea-wizards/SKILL.md:13` — two models generate independently and score each other.
- `~/.claude/skills/dueling-idea-wizards/SKILL.md:15` — disagreement is treated as signal, not noise.
- `~/.claude/skills/dueling-idea-wizards/SKILL.md:242` — output includes a score matrix.
- `~/.claude/skills/dueling-idea-wizards/SKILL.md:244` — consensus winners require high scores from all agents.
- `~/.claude/skills/modes-of-reasoning-project-analysis/SKILL.md:456` — methodological monoculture can create false convergence.
- `~/.claude/skills/modes-of-reasoning-project-analysis/SKILL.md:470` — 3+ modes agreeing via different evidence becomes a kernel.
- `~/.claude/skills/modes-of-reasoning-project-analysis/SKILL.md:693` — convergent findings need at least two distinct evidence methodologies.
- `~/.claude/skills/idea-wizard/SKILL.md:82` — ideas are evaluated against explicit robustness and reliability criteria.

## Adoption recipes

**Recipe 1 — Method column:** every consensus table includes `method`, `evidence_source`, and `failure_mode_checked`.

**Recipe 2 — Disagreement lane:** preserve high-self/low-opponent findings as contested items instead of deleting them.

**Recipe 3 — Anti-monoculture check:** before claiming convergence, require at least two independent evidence classes and one adversarial challenge.

## Compliance test

```bash
grep -E "(independent|disagreement|score matrix|distinct evidence|methodological monoculture)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-07-multi-model-triangulation.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
