# MP-108 - Triangulated expertise kernel

**Discovered:** 2026-05-19T07:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Expertise becomes operational only after primary sources are converted into a quote bank, consensus kernel, disputed edges, operator cards, and validators with auditable provenance.

## Where it applies

Expert method capture, multi-model review, prompt design, evaluator construction, knowledge curation, high-impact decisions, and any workflow that would otherwise compress expert judgment into unverifiable summary.

## Adoption signal

The corpus keeps raw sources and quotes, identifies agreement and disagreement, turns consensus into operator cards with triggers and failure modes, and validates outputs against explicit gates.

## Exemplar skills (>=5)

- `~/.claude/skills/operationalizing-expertise/SKILL.md:18` - expertise is operationalized as corpus, quote bank, triangulated kernel, operator library, and validators.
- `~/.claude/skills/operationalizing-expertise/SKILL.md:39` - required corpus structure includes primary sources, quote bank, kernel, operator library, prompts, and validators.
- `~/.claude/skills/operationalizing-expertise/SKILL.md:50` - evidence-first parsing keeps consensus and disputed unique claims separate.
- `~/.claude/skills/multi-model-triangulation/SKILL.md:12` - different models have different blind spots and consensus increases confidence.
- `~/.claude/skills/multi-model-triangulation/SKILL.md:97` - synthesis captures consensus, disagreements, and unique insights.
- `~/.claude/skills/evaluation-framework/SKILL.md:20` - without evaluation, output quality degrades silently.
- `~/.claude/skills/prompt-engineering-science/SKILL.md:26` - prompt engineering should be evidence-based.
- `~/.claude/skills/prompt-engineering-science/SKILL.md:178` - hallucination checks are part of prompt validation.

## Adoption recipes

**Recipe 1 - Quote bank:** preserve source excerpts and IDs before distilling principles.

**Recipe 2 - Kernel split:** separate consensus claims, disputed claims, and model/source-specific unique insights.

**Recipe 3 - Operator card:** convert each stable principle into trigger, action, failure mode, validation, and provenance.

## Compliance test

```bash
grep -E "(quote bank|triangulat|consensus|disagreement|operator|validator|provenance|evaluation|hallucination)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-07-multi-model-triangulation.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-11-operationalizing-expertise.md`
