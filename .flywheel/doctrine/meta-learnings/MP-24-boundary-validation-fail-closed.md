# MP-24 — Boundary validation fail-closed

**Discovered:** 2026-05-19T06:21Z
**Skills exemplifying:** 7+

## Essence

Validate at trust boundaries and fail closed there; scattered internal checks are weaker than one typed, audited boundary gate.

## Where it applies

Auth middleware, CORS origin handling, config loading, API version negotiation, TypeScript route inputs, container runtime env, production test guards.

## Adoption signal

Boundary code has a central validator, schema, allowlist, middleware, or startup gate; failure defaults to deny or crash-before-serving.

## Exemplar skills (≥5)

- `~/.claude/skills/authentication-authorization/SKILL.md:44` — auth is enforced at middleware and data-access layers, never a single gate.
- `~/.claude/skills/authentication-authorization/SKILL.md:151` — auth middleware must fail closed on error.
- `~/.claude/skills/cors-configuration/SKILL.md:71` — origin validation uses exact matching or URL parsing.
- `~/.claude/skills/cors-configuration/SKILL.md:105` — reflecting `Origin` without validation is rejected in favor of allowlists.
- `~/.claude/skills/environment-configuration/SKILL.md:24` — required configuration is validated at startup rather than request time.
- `~/.claude/skills/environment-configuration/SKILL.md:98` — config validation should use schema libraries.
- `~/.claude/skills/api-versioning/SKILL.md:102` — version negotiation middleware extracts and validates request version.
- `~/.claude/skills/containerization/SKILL.md:160` — containers validate required env vars at startup.

## Adoption recipes

**Recipe 1 — Boundary inventory:** list every trust boundary and point each to one owning validator.

**Recipe 2 — Fail-closed assertion:** tests assert malformed inputs deny, crash at boot, or return typed errors rather than falling through.

**Recipe 3 — Schema module:** centralize environment/input parsing in one module imported by runtime entrypoints.

## Compliance test

```bash
grep -E "(fail closed|allowlist|schema|middleware|validate.*startup|origin validation)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
