# MP-48 — Test substrate contamination guard

**Discovered:** 2026-05-19T08:05Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Tests and fixtures are part of the production substrate; fake work, shared state, leaked fixture shapes, and over-mocking must be detected as contamination before trust is assigned.

## Where it applies

Integration tests, pytest dispatches, mock audits, fixture design, CI sharding, E2E suites, form validation tests, and refactors that add placeholders.

## Adoption signal

Skill scans for stubs, isolates test state, redirects unsafe stdout, uses real infrastructure at integration boundaries, and proves fixes with re-scans.

## Exemplar skills (≥5)

- `~/.claude/skills/mock-code-finder/SKILL.md:12` — long-running projects accumulate stubs, mocks, placeholders, and TODO code.
- `~/.claude/skills/mock-code-finder/SKILL.md:99` — behavioral detection catches fake work such as sleep-based simulation.
- `~/.claude/skills/mock-code-finder/SKILL.md:221` — E2E audits found test files that were themselves stubs.
- `~/.claude/skills/mock-code-finder/SKILL.md:260` — verification includes running tests and rescanning for remaining stubs.
- `~/.claude/skills/pytest-stdout-fixture-leak-prevention/SKILL.md:58` — pytest stdout must be redirected so unsafe fixture values do not enter transcripts.
- `~/.claude/skills/pytest-stdout-fixture-leak-prevention/SKILL.md:247` — worker dispatches that run pytest must carry the prevention pattern.
- `~/.claude/skills/integration-testing/SKILL.md:95` — no shared state between tests.
- `~/.claude/skills/integration-testing/SKILL.md:248` — mocking everything makes tests pass while production breaks.

## Adoption recipes

**Recipe 1 — Contamination scan:** run keyword, behavioral, caller-trace, and shallow-test scans before trusting a suite.

**Recipe 2 — Substrate isolation:** every test owns its data, ports, files, and fixture construction; no shared mutable defaults.

**Recipe 3 — Safe output lane:** redirect verbose test output to files and surface only summaries or scrubbed failing IDs.

## Compliance test

```bash
grep -E "(stub|mock|placeholder|shared state|stdout.*redirect|fixture|re-scan|mocking everything)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-66-golden-sidecar-conformance.md`
