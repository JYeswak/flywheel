# MP-19 — Flywheel engagement protocol

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 5+

## Essence

The accretive flywheel runs on: INTENT → PLAN → MULTI-MODEL → SYNTHESIS → REVIEW → BEADS → TRIAGE → SWARM → LEARN. Every cycle improves substrate. Skipping any phase leaks value.

## Where it applies

Every multi-phase work session, every new project, every refactor of substantial scope.

## Adoption signal

Skill or repo references the 9-phase loop OR has `.flywheel/` substrate with phase artifacts.

## Exemplar skills (≥5)

- `~/.claude/skills/flywheel-end-to-end/SKILL.md:1` — full doctrine
- `~/.claude/skills/agentic-coding-flywheel-setup/SKILL.md:1` — setup framework
- `~/.claude/skills/flywheel-doctor-author/SKILL.md:1` — doctor authoring
- `~/.claude/skills/flywheel-recovery/SKILL.md:1` — recovery from broken state
- `~/.claude/skills/flywheel-connectors/SKILL.md:1` — connector patterns
- `~/.claude/skills/.flywheel/CHARTER.md:1` — flywheel charter (skill itself)

## Adoption recipes

**Recipe 1 — `.flywheel/` substrate:** every active-work repo has `.flywheel/` with MISSION.md, doctrine/, scripts/, audit/, fixtures/.

**Recipe 2 — Loop receipt:** every loop tick writes `last_closeout_receipt.json` with schema_version + phase + status + receipt path.

**Recipe 3 — Phase-named artifacts:** plan files in PLAN.md, research in RESEARCH.md, audit in AUDIT-FINDINGS.md — names map to phases.

## Compliance test

```bash
# Active flywheel repos MUST have .flywheel/MISSION.md.
test -f .flywheel/MISSION.md || fail
```
