# MP-90 - Adjacent-skill boundary router

**Discovered:** 2026-05-19T07:36Z
**Discovered by:** skillos:2
**Skills exemplifying:** 8+

## Essence

Skill ecosystems scale when each skill declares neighboring tools, confusion cases, handoff rules, and negative routes with the same specificity as positive triggers.

## Where it applies

JSM-managed skill libraries, legal practice groups, UI skills, agent-fleet operations, performance/cost tools, tax workflows, and any domain with overlapping expert skills.

## Adoption signal

The skill has a smell-test matrix, "if not, use" column, explicit boundaries against siblings, companion-skill references, and handoff outputs that match the next skill's input shape.

## Exemplar skills (>=5)

- `~/.claude/skills/zs-counsel-surface-inventory/SKILL.md:52` - uses a smell-test table to choose the skill or route elsewhere.
- `~/.claude/skills/zs-counsel-surface-inventory/SKILL.md:75` - boundaries distinguish inventory from gap analysis.
- `~/.claude/skills/zs-counsel-gap-analysis/SKILL.md:51` - gap-analysis has an explicit "use this skill? if not, use" router.
- `~/.claude/skills/zs-counsel-regulatory-watchtower/SKILL.md:73` - watchtower boundaries distinguish monitoring from sibling regulatory/compliance work.
- `~/.claude/skills/zs-counsel-gtm-audit/SKILL.md:64` - general tracker inventory is routed back to surface-inventory.
- `~/.claude/skills/cfs-zustand-discipline/SKILL.md:22` - server state, local component state, routing state, and render-once server data are out of scope.
- `~/.claude/skills/interactive-visualization-creator/SKILL.md:14` - static charts, decoration, and backend dashboards are excluded.
- `~/.claude/skills/agent-fleet-management/SKILL.md:52` - high token spend composes with cost optimization and usage tracking.
- `~/.claude/skills/jsm/SKILL.md:20` - JSM-safe paths are validate, push, pin, or fork rather than ad hoc edits.

## Adoption recipes

**Recipe 1 - Positive and negative trigger table:** include user wording, whether the skill applies, and the exact sibling to route to when it does not.

**Recipe 2 - Boundary essays for common confusions:** write short sibling comparisons for structurally similar skills.

**Recipe 3 - Handoff shape:** define the output path, receipt, or data shape the next skill consumes.

## Compliance test

```bash
grep -E "(Smell test|Use this skill\\?|If not|Boundaries|vs `|handoff|route|See also)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-16-search-tool-routing.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-18-skill-when-not-to-use.md`
