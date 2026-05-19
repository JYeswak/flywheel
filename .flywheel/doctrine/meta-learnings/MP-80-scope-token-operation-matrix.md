# MP-80 — Scope-token operation matrix

**Discovered:** 2026-05-19T07:12Z
**Discovered by:** skillos:2
**Skills exemplifying:** 8+

## Essence

API integrations fail less when every operation is mapped to the exact principal, token type, scope, tenant/project identifier, endpoint, async lifecycle, and verification probe.

## Where it applies

Cloudflare, Supabase, Vercel, SharePoint, YouTube, X, Meta Graph, Nango, Railway, Canva, Azure, and any multi-tenant provider integration.

## Adoption signal

The skill includes a scope matrix, validates the existing token before rotation, distinguishes resource identifiers, avoids operator-token shortcuts, and probes the operation path without leaking secrets.

## Exemplar skills (≥5)

- `~/.claude/skills/cloudflare-api/SKILL.md:27` — Cloudflare has account and zone scope universes plus multiple token types.
- `~/.claude/skills/cloudflare-api/SKILL.md:37` — validate before rotating a token at the first 403.
- `~/.claude/skills/cloudflare-api/SKILL.md:140` — account-scope and zone-scope are different.
- `~/.claude/skills/sharepoint-microsoft/SKILL.md:14` — SharePoint work splits across auth model, scope precision, and tenant/site identifiers.
- `~/.claude/skills/sharepoint-microsoft/SKILL.md:52` — 403 with empty body is usually scope mismatch, not revocation.
- `~/.claude/skills/google-youtube-workspace-oauth/SKILL.md:13` — YouTube publishing requires user-delegated OAuth plus Workspace gates.
- `~/.claude/skills/x-api-saas-posting/SKILL.md:17` — read scopes cannot post.
- `~/.claude/skills/meta-graph-publishing/SKILL.md:55` — every user, Page, IG user, app, and asset ID is proved.
- `~/.claude/skills/supabase-api/SKILL.md:64` — project slugs, branch IDs, and org IDs are different identifiers.
- `~/.claude/skills/vercel-api/SKILL.md:82` — most broken-token reports are scope or environment binding issues.

## Adoption recipes

**Recipe 1 — Matrix before code:** list operation, actor, token type, required scope, tenant/project/site ID, endpoint, and verification probe.

**Recipe 2 — Validate, then mutate:** run read-only token/scope/identifier probes before regenerating credentials or writing integration code.

**Recipe 3 — Model async resources:** if provider uses staging containers, deployment jobs, uploads, or processing states, poll readiness before final action.

## Compliance test

```bash
grep -E "(scope|token|tenant|project|Page|org ID|validate-token|probe|async|poll)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-99-authorized-sandbox-envelope.md`
