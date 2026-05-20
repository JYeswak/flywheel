# MP-11 — Operationalizing expertise (Track A pattern)

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 5+

## Essence

Convert domain expertise into substrate via 6 Track A levels: corpus → quote bank → triangulated kernel → operator library → validators → self-application meta-doc. Don't ship advice as prose; ship it as composable operators.

## Where it applies

Skill authoring, doctrine, audit playbooks, taste-encoding for plan-space work, any "captured expertise" that needs to be reused mechanically.

## Adoption signal

Skill has a `references/methodology/OPERATIONALIZING-EXPERTISE-TRACK-A.md` file OR documents the 6-level mapping.

## Exemplar skills (≥5)

- `~/.claude/skills/operationalizing-expertise/SKILL.md:1` — direct exemplar
- `~/.claude/skills/agent-ergonomics-cli/SKILL.md:541` — references the Track A pattern
- `~/.claude/skills/skill-builder/SKILL.md:1` — skill-creation framework
- `~/.claude/skills/self-improving-agent/SKILL.md:1` — substrate that improves itself
- `~/.claude/skills/agentic-coding-flywheel-setup/SKILL.md:1` — substrate accretion framework
- `~/.claude/skills/agent-fungibility-philosophy/SKILL.md:1` — fungible expertise via substrate

## Adoption recipes

**Recipe 1 — Six-file scaffold:** every operationalized skill ships with corpus/quote-bank/kernel/operator-library/validators/self-app docs.

**Recipe 2 — Validator gate:** skill output validated mechanically against the operator library before claim-of-completion.

**Recipe 3 — Self-application:** skill applies its own rubric to itself at least once; emits self-score receipt.

## Compliance test

```bash
# Track A skills MUST reference the 6-level scaffold.
ls references/methodology/OPERATIONALIZING-EXPERTISE-TRACK-A.md 2>/dev/null || grep -q "Track A" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
