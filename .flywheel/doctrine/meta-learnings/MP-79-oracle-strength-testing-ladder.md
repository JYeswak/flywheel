# MP-79 — Oracle-strength testing ladder

**Discovered:** 2026-05-19T07:12Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Hard-to-test systems choose the strongest practical oracle: schema, invariant, differential, metamorphic, sanitizer, fuzz, or visual evidence instead of defaulting to byte goldens or crash-only checks.

## Where it applies

Parsers, generated artifacts, JSON contracts, unsafe Rust, visual QA, document extraction, model outputs, optimization rewrites, and any domain where expected outputs are incomplete.

## Adoption signal

The skill names the oracle problem, ranks oracle strength, uses property or schema fixtures, validates against planted bugs or counterexamples, and keeps fuzz or oracle dependencies out of production.

## Exemplar skills (≥5)

- `~/.claude/skills/testing-metamorphic/SKILL.md:14` — output relations under transformations replace guessed oracles.
- `~/.claude/skills/testing-metamorphic/SKILL.md:24` — mutation testing validates that relations catch planted bugs.
- `~/.claude/skills/testing-metamorphic/SKILL.md:317` — each planted mutation should be caught by at least one relation.
- `~/.claude/skills/testing-schema-pinned-fixtures/SKILL.md:24` — schema validation is the oracle, not byte equality.
- `~/.claude/skills/testing-schema-pinned-fixtures/SKILL.md:27` — fixtures are split into valid and invalid directories.
- `~/.claude/skills/testing-fuzzing/SKILL.md:85` — fuzz harnesses assert invariants and use the strongest oracle available.
- `~/.claude/skills/testing-fuzzing/SKILL.md:354` — crash-only harnesses are acceptable only when no stronger oracle exists.
- `~/.claude/skills/testing-fuzzing/SKILL.md:580` — fuzz dependencies must not leak into production builds.
- `~/.claude/skills/rust-undefined-behavior-exorcist/SKILL.md:191` — dynamic sweep combines Miri, sanitizers, fuzz, loom, and shuttle evidence.

## Adoption recipes

**Recipe 1 — Name the oracle:** state why exact expected output is unavailable or insufficient.

**Recipe 2 — Climb the ladder:** prefer schema, invariant, differential, metamorphic, or sanitizer oracles over crash-only checks.

**Recipe 3 — Prove the test bites:** plant a mutation, counterexample, or invalid fixture and verify the oracle fails.

## Compliance test

```bash
grep -E "(oracle|metamorphic|invariant|schema|fixture|fuzz|mutation|sanitizer|counterexample)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-66-golden-sidecar-conformance.md`
