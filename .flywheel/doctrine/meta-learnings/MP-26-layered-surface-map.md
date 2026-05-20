# MP-26 — Layered surface map

**Discovered:** 2026-05-19T06:21Z
**Skills exemplifying:** 7+

## Essence

Before optimizing or securing a system, map the layers and assign each concern to the layer that owns it.

## Where it applies

Codebase archaeology, error handling, caching, auth, containers, API middleware, frontend boundaries.

## Adoption signal

Skill or repo artifact names layers (entry, handler, service, storage, boundary, runtime, build, cache tier) and maps checks or responsibilities to them.

## Exemplar skills (≥5)

- `~/.claude/skills/codebase-archaeology/SKILL.md:87` — archaeology has a dedicated "The Layers" section.
- `~/.claude/skills/codebase-archaeology/SKILL.md:82` — data flow is traced from entry to handler to service to storage.
- `~/.claude/skills/error-handling-patterns/SKILL.md:51` — errors are caught at boundaries rather than in the middle.
- `~/.claude/skills/error-handling-patterns/SKILL.md:70` — error handling is organized by layer.
- `~/.claude/skills/caching-strategy/SKILL.md:38` — caching is ordered by browser, CDN, app, and database layers.
- `~/.claude/skills/containerization/SKILL.md:27` — build and runtime stages are separated.
- `~/.claude/skills/authentication-authorization/SKILL.md:42` — authentication and authorization are separate concerns in separate layers.
- `~/.claude/skills/typescript-best-practices/SKILL.md:166` — route-level components need error boundaries.

## Adoption recipes

**Recipe 1 — Layer map:** every architecture report includes `Entry -> Boundary -> Service -> Storage -> Output`.

**Recipe 2 — Responsibility table:** each invariant names the layer that enforces it and the layer that observes it.

**Recipe 3 — Cross-layer audit:** doctor checks flag duplicated checks in random layers and missing checks at the owning layer.

## Compliance test

```bash
grep -E "(The Layers|by Layer|entry.*storage|Build != Runtime|browser.*CDN.*application)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
