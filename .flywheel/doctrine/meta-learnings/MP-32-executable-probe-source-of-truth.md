# MP-32 — Executable probe source of truth

**Discovered:** 2026-05-19T06:27Z
**Skills exemplifying:** 7+

## Essence

When runtime truth can drift, make a probe command or script the source of truth and cite its output before acting.

## Where it applies

Provider availability, MCP servers, ML portability, dispatch readiness, GitHub extension drift, schema validators, goal validation.

## Adoption signal

Skill names a probe, validator, health command, or smoke command that must pass before implementation or dispatch.

## Exemplar skills (≥5)

- `~/.claude/skills/apple-silicon-ml-porting/SKILL.md:59` — `preflight_mps_audit.sh` is the executable blocker scan.
- `~/.claude/skills/apple-silicon-ml-porting/SKILL.md:63` — the blocklist is executable source of truth.
- `~/.claude/skills/dispatch-tool-contracts/SKILL.md:111` — wait gates use `git log`, `br show`, artifact existence, or live probes.
- `~/.claude/skills/artifact-schema-envelope/SKILL.md:29` — artifacts are validated by a concrete `envelope-validate` command.
- `~/.claude/skills/gh-models/SKILL.md:36` — GitHub Models skill has a drift-probe section.
- `~/.claude/skills/gh-mcp-server/SKILL.md:27` — latest release tag is probed through `gh api`.
- `~/.claude/skills/codex-watchtower/SKILL.md:29` — watchtower doctor/summary commands are the operational probe.
- `~/.claude/skills/goal-build/SKILL.md:86` — goal shape is validated by a command.

## Adoption recipes

**Recipe 1 — Probe field:** every drift-prone skill documents `probe_command`.

**Recipe 2 — Receipt binding:** callbacks include the probe command and result, not just "checked".

**Recipe 3 — Fail closed:** if the probe is unavailable or red, stop before authoring runtime-dependent code.

## Compliance test

```bash
grep -E "(probe|doctor --json|validate .*--json|health|smoke|drift probe)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites earlier MP lessons directly.

- **MP-10 — codebase archaeology before mutation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-10-codebase-archaeology.md` for the canonical pattern.
- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
