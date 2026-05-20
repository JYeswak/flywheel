# MP-22 — Negative-constraint tables

**Discovered:** 2026-05-19T06:21Z
**Skills exemplifying:** 10+

## Essence

Every operational method needs a negative-space table: name the tempting wrong move, why it fails, and the safe replacement.

## Where it applies

Security, testing, CORS, caching, dependency management, background jobs, auth, container builds, backward compatibility.

## Adoption signal

Skill has `## Anti-Patterns`, `## Gotchas`, `## Hard Constraints`, or a `Never / Why / Fix` table.

## Exemplar skills (≥5)

- `~/.claude/skills/testing-conformance-harnesses/SKILL.md:454` — anti-patterns are marked as hard constraints.
- `~/.claude/skills/testing-conformance-harnesses/SKILL.md:456` — negative table format is `Never / Why / Fix`.
- `~/.claude/skills/testing-real-service-e2e-no-mocks/SKILL.md:421` — mock-free testing has hard-constraint anti-patterns.
- `~/.claude/skills/cors-configuration/SKILL.md:100` — CORS policy includes explicit anti-patterns.
- `~/.claude/skills/authentication-authorization/SKILL.md:47` — auth guidance carries an anti-pattern section.
- `~/.claude/skills/dependency-management/SKILL.md:318` — dependency management records anti-patterns near the implementation checklist.
- `~/.claude/skills/background-jobs/SKILL.md:176` — queue design has anti-patterns for retries, idempotency, and DLQs.

## Adoption recipes

**Recipe 1 — Table standard:** every skill adds `| Never | Why | Fix |` for operational hazards.

**Recipe 2 — Doctor lint:** skill-lint fails mature skills with no anti-pattern or hard-constraint section.

**Recipe 3 — Incident promotion:** repeated mistakes become new negative rows before they become long prose.

## Compliance test

```bash
grep -E "(Anti-Patterns|Hard Constraints|Never \\| Why \\| Fix|Gotchas)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
