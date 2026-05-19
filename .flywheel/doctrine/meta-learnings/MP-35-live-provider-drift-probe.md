# MP-35 — Live-provider drift probe

**Discovered:** 2026-05-19T06:27Z
**Skills exemplifying:** 7+

## Essence

For vendor/provider surfaces, live probe beats docs, examples, and memory; provider IDs and endpoints rot too fast to hardcode.

## Where it applies

Image/video providers, GitHub extensions, MCP servers, cloud coding agents, model catalogs, agent detection, Codex CLI tracking.

## Adoption signal

Skill requires latest provider snapshot, release probe, drift probe, or live model list before client code changes.

## Exemplar skills (≥5)

- `~/.claude/skills/generating-images-multi-provider/SKILL.md:38` — provider matrix is explicitly live-probed.
- `~/.claude/skills/generating-images-multi-provider/SKILL.md:40` — model IDs change frequently and must be refreshed from provider snapshots.
- `~/.claude/skills/generating-videos-multi-provider/SKILL.md:37` — video provider matrix is live truth from probes.
- `~/.claude/skills/generating-videos-multi-provider/SKILL.md:76` — runtime behavior beats docs and forum threads.
- `~/.claude/skills/gh-models/SKILL.md:39` — latest GitHub Models release is probed.
- `~/.claude/skills/gh-mcp-server/SKILL.md:65` — GitHub MCP server pins version plus drift probe.
- `~/.claude/skills/frankenagent-detection/SKILL.md:55` — agent-detection skill has a version pin and drift-probe command.
- `~/.claude/skills/asset-library-curator/SKILL.md:171` — curator requires provider probe freshness before runs.

## Adoption recipes

**Recipe 1 — Snapshot gate:** provider skills refuse to author clients unless a fresh snapshot is present.

**Recipe 2 — Drift ledger:** each probe writes timestamp, endpoint, account/key scope, and observed models.

**Recipe 3 — Code comment ban:** generated clients cite snapshot files, not stale docs URLs, as the immediate source.

## Compliance test

```bash
grep -E "(live truth|drift probe|provider snapshot|NEVER hardcode|probe first|latest release)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites earlier MP lessons directly.

- **MP-16 — search tool routing doctrine:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-16-search-tool-routing.md` for the canonical pattern.
- **MP-24 — boundary validation fail-closed:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-24-boundary-validation-fail-closed.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
