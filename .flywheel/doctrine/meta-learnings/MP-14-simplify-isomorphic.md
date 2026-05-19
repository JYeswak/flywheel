# MP-14 — Simplify isomorphically

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 4+

## Essence

Refactor for clarity while preserving every behavior bit-identical. Use golden-artifact tests to prove isomorphism before/after; never "improve" by accidentally dropping behavior.

## Where it applies

Code simplification, dead-code removal, abstraction extraction, type-hardening, library migrations.

## Adoption signal

Skill references golden-artifact tests OR isomorphic-refactor doctrine.

## Exemplar skills (≥4)

- `~/.claude/skills/simplify-and-refactor-code-isomorphically/SKILL.md:1` — direct exemplar
- `~/.claude/skills/testing-golden-artifacts/SKILL.md:1` — golden-test mechanism
- `~/.claude/skills/code-simplifier/SKILL.md:1` — simplifier framework
- `~/.claude/skills/testing-metamorphic/SKILL.md:1` — metamorphic = behavior-preserving relations
- `~/.claude/skills/refactor-assistant/SKILL.md:1` — refactor helper

## Adoption recipes

**Recipe 1 — Golden-test gate:** every refactor pass runs golden tests; PR blocked if any golden fails without explicit override.

**Recipe 2 — Diff-of-behavior receipt:** refactor receipt includes input/output hashes before+after.

**Recipe 3 — Forbid silent semantic change:** PR template requires "list of intentional semantic changes" field; empty = strict-iso refactor.

## Compliance test

```bash
# Refactor-class skills MUST reference golden tests or metamorphic relations.
grep -E "(golden|isomorphic|metamorphic|UPDATE_GOLDENS)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-04 — receipt-and-callback envelope contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md` for the canonical pattern.
- **MP-20 — cross-orch handoff:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md` for the canonical pattern.
- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
