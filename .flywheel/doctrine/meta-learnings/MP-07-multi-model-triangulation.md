# MP-07 — Multi-model triangulation

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 5+

## Essence

For consequential decisions, get independent reads from 3+ models (Claude/Grok/Gemini/GPT) and surface disagreements; never trust a single model's judgment alone on plan-space or load-bearing analysis.

## Where it applies

Architecture decisions, code review, idea generation, brand-positioning, plan convergence (MP-06), audit phases.

## Adoption signal

Skill invokes 2+ models OR documents a multi-model phase in its workflow.

## Exemplar skills (≥5)

- `~/.claude/skills/multi-model-triangulation/SKILL.md:1` — direct exemplar
- `~/.claude/skills/idea-wizard/SKILL.md:1` — multi-LLM idea generation
- `~/.claude/skills/dueling-idea-wizards/SKILL.md:1` — adversarial multi-model
- `~/.claude/skills/world-class-doctor-mode-for-cli-tools/SKILL.md:271` — Phase 4 + Phase 7 multi-model
- `~/.claude/skills/grok-review/SKILL.md:1` — Grok-side review
- `~/.claude/skills/code-review-gemini-swarm-with-ntm/SKILL.md:1` — Gemini swarm code review

## Adoption recipes

**Recipe 1 — Decision phase:** any "consequential decision" gate includes "multi-model review" sub-phase. Record disagreements; resolution requires explicit acknowledgement.

**Recipe 2 — Receipt envelope:** decision receipts include `models_consulted: [claude, grok, gemini]` and `disagreements: [...]` fields.

**Recipe 3 — CI gate:** PR template asks "did a 2nd model review this?" Required for changes affecting plan-space artifacts.

## Compliance test

```bash
# Decision-class skills MUST cite ≥2 distinct model namespaces.
grep -cE "(claude|opus|grok|gemini|gpt|sonnet)" SKILL.md | awk '$1 >= 2 || (print "fail" && exit 1)'
```

## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-4 so every skillos doctrine file cites the relevant MP lessons directly.

- **MP-05 — multi-pass saturation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-05-multi-pass-saturation.md` for the canonical pattern.
- **MP-06 — plan-space convergence:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-06-plan-space-convergence.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
