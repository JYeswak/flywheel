# MP-09 — Info-source watchtower

**Discovered:** 2026-05-19T01:00Z
**Skills exemplifying:** 5+

## Essence

Any first-class info source (vendor changelog, regulatory body, library release feed, peer-repo state) MUST have a watchtower that polls + classifies + surfaces; otherwise it's a discovery-latency bomb.

## Where it applies

Vendor monitoring, regulatory monitoring, dependency tracking, peer-orch drift detection, market signals.

## Adoption signal

Repo has a `watchtower.{sh,py,yaml}` script OR cron/launchd entry that polls + classifies an external source.

## Exemplar skills (≥5)

- `~/.claude/skills/info-source-watchtower/SKILL.md:1` — direct exemplar
- `~/.claude/skills/codex-watchtower/SKILL.md:1` — OpenAI Codex CLI surveillance
- `~/.claude/skills/zs-counsel-regulatory-watchtower/SKILL.md:1` — regulatory watchtower
- `~/.claude/skills/regulatory-monitoring/SKILL.md:1` — broader regulatory class
- `~/.claude/skills/dicklesworthstone-stack/SKILL.md:1` — pattern source (Jeff's stack watchtower)
- `~/.claude/skills/skill-autoresearch/SKILL.md:1` — autoresearch as watchtower-of-skills

## Adoption recipes

**Recipe 1 — Watchtower per critical source:** for every external dependency (vendor, library, regulator, peer-repo), spawn or adopt a watchtower script.

**Recipe 2 — Cadence + receipt:** watchtower runs on launchd cron with explicit cadence; emits receipt per run.

**Recipe 3 — Classification:** every poll output classified (no-change / drift-detected / breaking-change / action-required) with mechanical thresholds.

## Compliance test

```bash
# Repos with external dependencies MUST have at least one *watchtower* script.
find . -name "*watchtower*" -type f | head -1 | grep -q . || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
