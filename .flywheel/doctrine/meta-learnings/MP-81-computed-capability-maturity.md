# MP-81 - Computed capability maturity

**Discovered:** 2026-05-19T07:36Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

A durable capability is promoted by observed use, validation, and self-test evidence, not by author confidence or frontmatter claims.

## Where it applies

Skill publishing, agent rollout, CLI doctor surfaces, quality gates, governance registries, and any reusable operator capability that can silently rot.

## Adoption signal

The artifact has trigger coverage, a structural validator, a self-test or replay fixture, a maturity or quality score computed from telemetry, and a rule that promotion cannot be done by editing metadata alone.

## Exemplar skills (>=5)

- `~/.claude/skills/skill-builder/SKILL.md:15` - requires at least ten trigger phrases before a skill ships.
- `~/.claude/skills/skill-builder/SKILL.md:21` - refuses skills that fail validation or lack a self-test.
- `~/.claude/skills/skill-builder/SKILL.md:170` - lifecycle stage is computed from telemetry, not declared in frontmatter.
- `~/.claude/skills/jsm/SKILL.md:55` - `jsm validate` checks frontmatter, name format, and description length.
- `~/.claude/skills/jsm/SKILL.md:56` - the grader is a seven-gate quality rubric.
- `~/.claude/skills/find-skills/SKILL.md:66` - recommendation flow includes quality verification before suggesting a skill.
- `~/.claude/skills/agent-lifecycle/SKILL.md:227` - lifecycle metadata is structurally validated before release.
- `~/.claude/skills/world-class-doctor-mode-for-cli-tools/SKILL.md:755` - the meta-doctor validates frontmatter length, citation integrity, cross-references, and scripts.

## Adoption recipes

**Recipe 1 - Promotion by evidence:** store usage outcomes, helpfulness, harmfulness, and validation receipts; derive maturity from that ledger instead of a markdown field.

**Recipe 2 - Validate before publish:** block registration, recommendation, or rollout unless structural validators and self-tests pass.

**Recipe 3 - Regress maturity:** let recent harmful or failed outcomes demote even long-lived capabilities.

## Compliance test

```bash
grep -E "(validate|self-test|trigger|quality|rubric|telemetry|maturity|computed)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-73-score-triggered-lifecycle-playbook.md`
