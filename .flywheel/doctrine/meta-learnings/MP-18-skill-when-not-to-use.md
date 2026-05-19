# MP-18 — Skill-when-not-to-use discipline

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 4+

## Essence

Every skill MUST declare negative triggers (when NOT to activate). Without negative triggers, skills cross-fire and produce noise; with them, skill routing is clean.

## Where it applies

Every skill in the skill library that has a frontmatter `description` field with auto-trigger phrases.

## Adoption signal

SKILL.md has a `## Negative Triggers` section OR SELF-TEST.md lists "should NOT activate" cases.

## Exemplar skills (≥4)

- `~/.claude/skills/skill-when-not-to-use-discipline/SKILL.md:1` — direct exemplar
- `~/.claude/skills/agent-ergonomics-cli/SELF-TEST.md:1` — explicit negative triggers
- `~/.claude/skills/testing-conformance-harnesses/SELF-TEST.md:1` — negative triggers section
- `~/.claude/skills/multi-pass-bug-hunting/SELF-TEST.md:1` — negative triggers
- `~/.claude/skills/multi-model-triangulation/SELF-TEST.md:1` — negative triggers

## Adoption recipes

**Recipe 1 — SELF-TEST.md mandatory:** every skill ships a SELF-TEST.md with positive + negative triggers.

**Recipe 2 — Cross-skill routing:** negative triggers point to the correct sibling skill (e.g., "use /testing-fuzzing instead").

**Recipe 3 — Validation script:** a meta-test asserts every skill's negative-trigger list is non-empty.

## Compliance test

```bash
# Skills MUST have SELF-TEST.md with negative triggers.
test -f SELF-TEST.md && grep -qiE "(should NOT activate|negative trigger|not.your.area)" SELF-TEST.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-15 — canonical CLI scoping:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-15-canonical-cli-scoping.md` for the canonical pattern.
- **MP-24 — boundary validation fail-closed:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-24-boundary-validation-fail-closed.md` for the canonical pattern.
- **MP-27 — exact prompt/output template:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-27-exact-prompt-output-template.md` for the canonical pattern.
