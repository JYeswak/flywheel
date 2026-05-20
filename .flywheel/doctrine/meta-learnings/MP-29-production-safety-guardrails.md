# MP-29 — Production-safety guardrails

**Discovered:** 2026-05-19T06:21Z
**Skills exemplifying:** 6+

## Essence

Any workflow that can touch real users, money, credentials, or production data must mechanically prove it is in a safe environment before it runs.

## Where it applies

Real-service tests, deploys, environment config, container release, auth credential class checks, caching sensitive data, security probes.

## Adoption signal

Workflow has production URL blocklists, staging/prod parity checks, test-key assertions, immutable image pins, or explicit production readiness checks.

## Exemplar skills (≥5)

- `~/.claude/skills/testing-real-service-e2e-no-mocks/SKILL.md:303` — production safety guards are a first-class pattern.
- `~/.claude/skills/testing-real-service-e2e-no-mocks/SKILL.md:305` — test infra must block production URLs.
- `~/.claude/skills/testing-real-service-e2e-no-mocks/SKILL.md:333` — payment tests assert `sk_test_*`, not live keys.
- `~/.claude/skills/environment-configuration/SKILL.md:154` — secret rotation is tested in staging before production.
- `~/.claude/skills/environment-configuration/SKILL.md:217` — staging and production config drift is explicitly monitored.
- `~/.claude/skills/deployment-strategy/SKILL.md:116` — migrations are tested against a copy of production data.
- `~/.claude/skills/containerization/SKILL.md:151` — production images pin base image digests.
- `~/.claude/skills/authentication-authorization/SKILL.md:245` — dev credentials must not be promoted to prod without tenant confirmation.

## Adoption recipes

**Recipe 1 — Env guard:** tests and scripts refuse prod URLs, live payment keys, and `NODE_ENV=production` unless specifically designed for prod.

**Recipe 2 — Parity check:** deploy receipts compare staging and production config differences and mark expected drift.

**Recipe 3 — Credential-class assertion:** auth/secret workflows verify tenant and credential class before use.

## Compliance test

```bash
grep -E "(production URL|sk_test|staging.*production|production readiness|pin base image|credential class)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
