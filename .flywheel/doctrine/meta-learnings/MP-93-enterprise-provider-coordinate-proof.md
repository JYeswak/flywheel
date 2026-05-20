# MP-93 - Enterprise-provider coordinate proof

**Discovered:** 2026-05-19T08:02Z
**Discovered by:** skillos:2
**Skills exemplifying:** 9+

## Essence

Enterprise provider work must prove the active coordinate system, identity, scope, async terminal state, and live provider contract before mutation or success claims.

## Where it applies

Adobe, Azure, Canva, ClubReady, Google Cloud agents, Railway, Teams, GitHub, and any multi-tenant SaaS where a 200 response can mean accepted, wrong-scope, or not-yet-done.

## Adoption signal

The workflow checks auth, tenant/project/environment/service, permission scope, official docs or schema, and watches async jobs to terminal state before declaring success.

## Exemplar skills (>=5)

- `~/.claude/skills/adobe-creative-enterprise/SKILL.md:14` - Adobe APIs split across auth, scoped products, sync APIs, and event-driven APIs.
- `~/.claude/skills/adobe-creative-enterprise/SKILL.md:116` - OAuth TTL is validated before every batch.
- `~/.claude/skills/azure-apps/SKILL.md:14` - Azure has multiple scope universes, identity models, auth paradigms, and silent 200 OK failures.
- `~/.claude/skills/azure-apps/SKILL.md:52` - every permission is checked against the accessed resource.
- `~/.claude/skills/canva-enterprise/SKILL.md:14` - Canva operations are async and require polling job IDs.
- `~/.claude/skills/clubready/SKILL.md:18` - endpoints must be validated against official docs before workflows are committed.
- `~/.claude/skills/google-agent-ecosystem/SKILL.md:41` - auth validation confirms project, service account, API enablement, and role grants.
- `~/.claude/skills/gcloud/SKILL.md:148` - mutations require project and account proof first.
- `~/.claude/skills/railway-api/SKILL.md:49` - deploys must be watched until terminal state.
- `~/.claude/skills/teams-sdks/SKILL.md:53` - manifest schema, SDK version, and auth declaration are validated before deployment.

## Adoption recipes

**Recipe 1 - Coordinate header:** every run logs account, tenant, project, environment, service, region, and token class.

**Recipe 2 - Accepted is not done:** any API returning job, deploy, export, or operation IDs must poll to success or failure.

**Recipe 3 - Scope matrix:** list each endpoint and the exact scope, role, manifest field, or subscription key required.

## Compliance test

```bash
grep -E "(project|tenant|environment|service|scope|OAuth|identity|poll|terminal|manifest|official docs)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-76-authority-ranked-retrieval-maintenance.md`
