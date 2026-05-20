# MP-89 - Mode-scoped phase workspace

**Discovered:** 2026-05-19T07:36Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Complex workflows stay bounded when the first artifact names the mode, phase map, included bundles, skipped bundles, write scope, and stop conditions.

## Where it applies

Billing hardening, doctor-mode passes, legal audits, changelog rebuilds, dashboard panel additions, skill authoring, and any multi-phase workflow that could expand into adjacent domains.

## Adoption signal

The workflow starts with a scope decision artifact or probe, chooses the smallest valid mode, lists phases and activated bundles, marks out-of-scope adjacent work, and emits expected output paths before mutation.

## Exemplar skills (>=5)

- `~/.claude/skills/saas-billing-patterns-for-stripe-and-paypal/SKILL.md:47` - Phase 0 writes a scope decision artifact.
- `~/.claude/skills/saas-billing-patterns-for-stripe-and-paypal/SKILL.md:55` - default to the smallest mode that fully covers the request.
- `~/.claude/skills/saas-billing-patterns-for-stripe-and-paypal/SKILL.md:75` - scope decision includes included bundles, skipped bundles, and adjacent work out of scope.
- `~/.claude/skills/world-class-doctor-mode-for-cli-tools/SKILL.md:594` - doctor mode is explicitly one of add, upgrade, audit-only, rescore, or absorb-playbook.
- `~/.claude/skills/zs-counsel-surface-inventory/SKILL.md:204` - probe mode validates scope before browser sessions or file writes.
- `~/.claude/skills/zs-counsel-gap-analysis/SKILL.md:120` - dry-run confirms regime set, inventory binding, and consolidation scope before materializing a scorecard.
- `~/.claude/skills/add-dashboard-panel/SKILL.md:20` - four governance gates must clear before the first file is written.
- `~/.claude/skills/changelog-md-workmanship/SKILL.md:106` - changelog work chooses a size class and intended history window.

## Adoption recipes

**Recipe 1 - Phase 0 artifact:** write mode, phase list, included/skipped bundles, owner, write scope, tests, and stop conditions before implementation.

**Recipe 2 - Smallest valid mode:** resist upgrading a bounded feature into full audit-and-fix unless it crosses shared primitives.

**Recipe 3 - Probe before writes:** for high-cost or regulated workflows, emit expected paths and abort triggers without touching state.

## Compliance test

```bash
grep -E "(scope decision|mode|phase|bundle|probe|expected_output|out of scope|gate)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-77-isolated-worktree-dispatch-contract.md`
