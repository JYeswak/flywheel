# MP-38 — Automation ROI threshold

**Discovered:** 2026-05-19T06:27Z
**Skills exemplifying:** 5+

## Essence

Automation is justified by measured frequency, time saved, error rate, cost, or blast radius; do not automate merely because a workflow is annoying.

## Where it applies

Shell-history mining, capacity planning, cost optimization, asset curation, pattern extraction, commission plans, goal design.

## Adoption signal

Automation proposal includes measured baseline, score formula, threshold, expected savings, and post-automation validation.

## Exemplar skills (≥5)

- `~/.claude/skills/automating-your-automations/SKILL.md:13` — command history is mined as the fossil record of automation opportunities.
- `~/.claude/skills/automating-your-automations/SKILL.md:27` — candidates score frequency x time_saved x error_rate.
- `~/.claude/skills/automating-your-automations/SKILL.md:107` — automation only proceeds above a score threshold.
- `~/.claude/skills/automating-your-automations/SKILL.md:146` — automation must be at least 3x faster than manual.
- `~/.claude/skills/capacity-planning/SKILL.md:20` — capacity planning refuses estimates without measured baseline, demand model, latency SLO, and cost ceiling.
- `~/.claude/skills/asset-library-curator/SKILL.md:124` — variance checks catch suspicious constant outcomes in curator cost rows.
- `~/.claude/skills/commission-calculation/SKILL.md:20` — plans are judged by rational actor behavior, not intent.
- `~/.claude/skills/codebase-pattern-extraction/SKILL.md:381` — ignoring session-history mining is an anti-pattern.

## Adoption recipes

**Recipe 1 — Baseline first:** record current manual duration, frequency, and failure rate before automating.

**Recipe 2 — Threshold gate:** require a numeric score or savings threshold before implementation.

**Recipe 3 — Post-run measurement:** automation closeout includes measured speedup and error-rate change.

## Compliance test

```bash
grep -E "(frequency.*time_saved|Score >=|measured baseline|cost ceiling|3x faster|ROI)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites earlier MP lessons directly.

- **MP-12 — three-spaces reasoning:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-12-three-spaces-reasoning.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
