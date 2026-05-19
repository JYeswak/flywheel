# MP-78 — Phase-gated migration handoff

**Discovered:** 2026-05-19T07:12Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Migrations move safely when each phase emits validated handoff artifacts, rehearses against staging or clones, names rollback ownership, and refuses cutover until gates agree.

## Where it applies

Database migrations, Slack-to-Mattermost migrations, platform moves, library upgrades, infrastructure engine changes, data backfills, and any irreversible state transition.

## Adoption signal

The skill defines phase deliverables, machine-readable handoff, validation scripts, clone or staging rehearsal, rollback owner, and post-cutover verification.

## Exemplar skills (≥5)

- `~/.claude/skills/safe-migrations/SKILL.md:13` — migrations must be revert-able, testable, and backwards-compatible.
- `~/.claude/skills/safe-migrations/SKILL.md:47` — migrations are idempotent.
- `~/.claude/skills/safe-migrations/SKILL.md:192` — results are validated before success is claimed.
- `~/.claude/skills/slack-migration-to-mattermost-phase-1-extraction/SKILL.md:20` — Phase 2 waits for handoff markdown and JSON plus green validation.
- `~/.claude/skills/slack-migration-to-mattermost-phase-1-extraction/SKILL.md:86` — Phase 1 is done only when artifacts, validators, gaps, and handoff agree.
- `~/.claude/skills/slack-migration-to-mattermost-phase-2-setup-and-import/SKILL.md:52` — cutover is blocked without staging rehearsal.
- `~/.claude/skills/slack-migration-to-mattermost-phase-2-setup-and-import/SKILL.md:82` — Phase 2 is done only when validation, staging, readiness, and verification agree.
- `~/.claude/skills/slack-migration-to-mattermost-phase-3-ongoing-maintenance/SKILL.md:128` — every stage writes audit-trail JSON.
- `~/.claude/skills/library-updater/SKILL.md:68` — repeated failure rolls back and logs reason.

## Adoption recipes

**Recipe 1 — Phase receipt:** every phase writes human and machine handoff files with hashes, counts, gaps, and next-phase prerequisites.

**Recipe 2 — Rehearse first:** run against a clone, staging target, or scratch restore before production.

**Recipe 3 — Rollback owner:** name rollback owner and command path before cutover; fail closed if absent.

## Compliance test

```bash
grep -E "(handoff|staging|rehearsal|rollback|idempotent|validate|cutover|audit-trail|phase)" SKILL.md || fail
```
