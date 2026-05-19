# MP-25 — Staged sunset migration

**Discovered:** 2026-05-19T06:21Z
**Skills exemplifying:** 6+

## Essence

Breaking change work is not a single deploy; it is a staged lifecycle with coexistence, warnings, metrics, sunset dates, and removal only after evidence.

## Where it applies

API versions, SDK/library upgrades, dependency deprecations, database expand-contract migrations, feature flag rollouts, mock-to-real test migrations.

## Adoption signal

Migration plan includes phases, deprecation/sunset headers or dates, compatibility window, owner, metrics, and cleanup trigger.

## Exemplar skills (≥5)

- `~/.claude/skills/backward-compatibility/SKILL.md:57` — compatibility work follows a four-phase deprecation process.
- `~/.claude/skills/backward-compatibility/SKILL.md:60` — phase 1 announces deprecation in docs, OpenAPI, and response headers.
- `~/.claude/skills/backward-compatibility/SKILL.md:62` — phase 3 sunsets with 410 or fallback.
- `~/.claude/skills/api-versioning/SKILL.md:176` — API versions carry deprecation and sunset headers.
- `~/.claude/skills/api-versioning/SKILL.md:212` — fully sunset versions are blocked.
- `~/.claude/skills/deployment-strategy/SKILL.md:92` — DB schema must support old and new application versions during rollout.
- `~/.claude/skills/environment-configuration/SKILL.md:162` — feature flags roll out from 1% to 10% to 100%.
- `~/.claude/skills/dependency-management/SKILL.md:297` — dependency deprecation has an explicit handling process.

## Adoption recipes

**Recipe 1 — Migration lifecycle doc:** record `announce`, `warn`, `sunset`, `remove`, each with owner and date.

**Recipe 2 — Compatibility test:** CI proves old and new clients both pass during the coexistence window.

**Recipe 3 — Cleanup gate:** stale flags/endpoints/dependencies cannot remain without an expiry or tracked deferral.

## Compliance test

```bash
grep -E "(deprecat|sunset|expand-contract|gradual rollout|feature flags.*expiration)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-04 — receipt-and-callback envelope contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md` for the canonical pattern.
- **MP-20 — cross-orch handoff:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md` for the canonical pattern.
- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
