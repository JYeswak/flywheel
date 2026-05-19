# MP-12 — Three-spaces reasoning (plan / bead / code)

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 5+

## Essence

Think globally in plans, operationally in beads, locally in code. Each space has its own mistake cost (plan ~1×, bead ~5×, code ~25×). Don't answer plan-space in code-space or vice versa.

## Where it applies

Every multi-phase project, every architecture decision, every refactor, every audit.

## Adoption signal

Skill explicitly identifies its space OR cites the 3-spaces taxonomy.

## Exemplar skills (≥5)

- `~/.claude/skills/planning-workflow/SKILL.md:1` — plan-space
- `~/.claude/skills/beads-workflow/SKILL.md:1` — bead-space
- `~/.claude/skills/beads-br/SKILL.md:1` — bead-space tooling
- `~/.claude/skills/beads-bv/SKILL.md:1` — bead-space triage
- `~/.claude/skills/spec-driven-workflow/SKILL.md:1` — full pipeline (plan→bead→code)
- `~/.claude/skills/multi-pass-bug-hunting/SKILL.md:1` — code-space deep work
- `~/.claude/skills/agentic-coding-flywheel-setup/SKILL.md:1` — three-spaces flywheel

## Adoption recipes

**Recipe 1 — Skill self-classification:** every skill declares which space it operates in (plan/bead/code/multi).

**Recipe 2 — Cross-space gates:** beads cannot be created from un-converged plans; code cannot be written without an active bead.

**Recipe 3 — Mistake-cost weighting:** plan-space artifacts get higher review cadence (multi-model triangulation per MP-07) than code-space artifacts.

## Compliance test

```bash
# Workflow skills MUST cite their reasoning space.
grep -E "(plan.space|bead.space|code.space|three.space)" SKILL.md || fail
```
