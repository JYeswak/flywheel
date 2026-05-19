# MP-06 — Plan-space convergence

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 5+

## Essence

Most intelligence belongs in plan-space (architecture, intent, tradeoffs) — not code-space (implementation). A converged plan costs ~25× less to revise than converged code.

## Where it applies

Project initiation, refactors, multi-phase work, milestone planning, holding-co reframes.

## Adoption signal

Skill produces a converged plan artifact (markdown, not code) BEFORE proposing implementation. Plan has explicit "ready for beads" gate.

## Exemplar skills (≥5)

- `~/.claude/skills/planning-workflow/SKILL.md:1` — comprehensive markdown planning
- `~/.claude/skills/plan-space-convergence/SKILL.md:1` — direct exemplar
- `~/.claude/skills/jeff-planning-enhanced/SKILL.md:1` — Jeff's planning methodology
- `~/.claude/skills/spec-driven-workflow/SKILL.md:1` — SPEC→PRD→Beads pipeline
- `~/.claude/skills/beads-workflow/SKILL.md:1` — plan-to-beads bridge
- `~/.claude/skills/prd/SKILL.md:1` — PRD layer

## Adoption recipes

**Recipe 1 — Doctrine:** every multi-phase skill names a plan artifact path BEFORE referencing implementation steps. Plan converges via multi-pass (MP-05).

**Recipe 2 — Gate:** `ready_for_beads` boolean in skill's state file; cannot dispatch beads until gate fires.

**Recipe 3 — Phase ordering:** RESEARCH → REFINE → AUDIT → DECOMPOSE → POLISH (5 phases before code).

## Compliance test

```bash
# Skills doing multi-phase work MUST cite a plan artifact path before any code-step.
grep -E "plan.{0,5}\.md|RESEARCH.md|REFINE.md" SKILL.md || fail
```
