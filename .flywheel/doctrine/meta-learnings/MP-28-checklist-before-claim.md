# MP-28 — Checklist-before-claim gate

**Discovered:** 2026-05-19T06:21Z
**Skills exemplifying:** 11+

## Essence

Do not claim work is ready until a checklist tied to the domain has been completed; completion is a gate, not a vibe.

## Where it applies

Production deploys, migrations, auth, queues, containers, cache configuration, concurrency, config, dependency updates, real-service tests.

## Adoption signal

Skill has a `Checklist`, `Verification Checklist`, `Before Shipping`, or `Implementation Checklist` section with concrete checkboxes.

## Exemplar skills (≥5)

- `~/.claude/skills/authentication-authorization/SKILL.md:198` — auth has an implementation checklist.
- `~/.claude/skills/background-jobs/SKILL.md:191` — queue design has an implementation checklist.
- `~/.claude/skills/concurrency-patterns/SKILL.md:262` — concurrency has a verification checklist.
- `~/.claude/skills/containerization/SKILL.md:146` — containers have a security checklist.
- `~/.claude/skills/deployment-strategy/SKILL.md:230` — deployment has an implementation checklist.
- `~/.claude/skills/testing-real-service-e2e-no-mocks/SKILL.md:436` — mock-free suites have a before-shipping checklist.
- `~/.claude/skills/dependency-management/SKILL.md:335` — dependency management closes with an implementation checklist.
- `~/.claude/skills/environment-configuration/SKILL.md:255` — environment config has an implementation checklist.

## Adoption recipes

**Recipe 1 — Domain checklist:** every skill ending in implementation guidance ships checkboxes for the final claim.

**Recipe 2 — Receipt mirror:** closeout receipt records checklist items and pass/fail state.

**Recipe 3 — Doctor enforcement:** mature repos fail doctor if a domain workflow has no checklist or no checklist receipt.

## Compliance test

```bash
grep -E "(Implementation Checklist|Verification Checklist|Before Shipping|Migration Checklist|Rollback Checklist)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
