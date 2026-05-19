# MP-02 — Verification-first conformance fixtures

**Discovered:** 2026-05-18 (original investigation)
**Skills exemplifying:** 5+

## Essence

Fixtures need PROVENANCE.md. Divergences need DISCREPANCIES.md. Completion claims require independent re-run with stdout+stderr+exit-code capture — never trust self-reported test pass.

## Where it applies

Test fixtures, golden files, conformance harnesses, schema validators, audit pipelines.

## Adoption signal

PROVENANCE.md exists in every fixture directory; DISCREPANCIES.md at repo root.

## Exemplar skills (≥5)

- `~/.claude/skills/testing-conformance-harnesses/SKILL.md:1` — direct exemplar
- `~/.claude/skills/testing-conformance-harnesses/references/FIXTURE-PATTERNS.md:1` — mandatory PROVENANCE
- `~/.claude/skills/testing-golden-artifacts/SKILL.md:1` — golden-test mechanism
- `~/.claude/skills/beads-compliance-and-completion-verification/SKILL.md:1` — never-trust-self-report
- `~/.claude/skills/testing-metamorphic/SKILL.md:1` — metamorphic relations

## Adoption recipes

**Recipe 1 — PROVENANCE per fixture dir:** generator + version + date + regen command.

**Recipe 2 — DISCREPANCIES at root:** documented divergences (ACCEPTED/INVESTIGATING/WILL-FIX) with XFAIL tests.

**Recipe 3 — Re-run discipline:** completion claims require captured stdout+stderr+exit-code, not just "tests pass" assertion.

## Compliance test

```bash
find fixtures tests/fixtures -type d 2>/dev/null | while read d; do
  test -f "$d/PROVENANCE.md" || fail
done
```
