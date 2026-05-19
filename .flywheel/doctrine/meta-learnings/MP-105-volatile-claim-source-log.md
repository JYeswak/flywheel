# MP-105 - Volatile claim source log

**Discovered:** 2026-05-19T07:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

When a domain changes quickly, recommendations must carry a source log with checked date, primary source, confidence, volatility, and rollback or monitoring path.

## Where it applies

Agent SDK recommendations, SEO and search policy work, competitive intelligence, launch plans, provider clients, model IDs, API endpoints, and any advice that rots faster than the repository.

## Adoption signal

The answer or artifact cites current primary sources, records when each claim was checked, labels uncertainty, rejects stale secondary sources, and defines how drift will be detected or rolled back.

## Exemplar skills (>=5)

- `~/.claude/skills/agent-sdk-landscape/SKILL.md:12` - agent SDK knowledge rots in days.
- `~/.claude/skills/agent-sdk-landscape/SKILL.md:16` - LATEST.md is checked before recommending an SDK.
- `~/.claude/skills/agent-sdk-landscape/SKILL.md:37` - tracked sources include releases, blogs, and changelogs.
- `~/.claude/skills/seo-for-saas-businesses/SKILL.md:21` - recommendations carry hypothesis, impact, tracking, and rollback.
- `~/.claude/skills/seo-for-saas-businesses/SKILL.md:109` - volatile claims are checked against primary sources with source, date, and claim.
- `~/.claude/skills/seo-for-saas-businesses/SKILL.md:120` - current evidence beats guide material and discrepancies are logged.
- `~/.claude/skills/competitive-intelligence/SKILL.md:70` - competitive data has a 90-day half-life and must be timestamped.
- `~/.claude/skills/launch-strategy/SKILL.md:277` - releases and changelog updates continue after launch.

## Adoption recipes

**Recipe 1 - Freshness row:** record source URL/path, checked timestamp, claim, and volatility class for each changing recommendation.

**Recipe 2 - Primary-source preference:** use vendor docs, changelogs, release notes, or live probes before guides and old blog posts.

**Recipe 3 - Drift response:** attach monitoring cadence, rollback path, or revalidation trigger to the claim.

## Compliance test

```bash
grep -E "(LATEST|changelog|source|checked|timestamp|volatile|rollback|monitor|primary source|confidence)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
