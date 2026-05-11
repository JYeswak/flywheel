---
bead: flywheel-cu6u9
title: Inventory all jyeswak github repos via gh api
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE
priority: P1
mission_fitness: adjacent
---

# cu6u9 evidence pack — jyeswak github repo inventory

## What this bead ships

Two artifacts under `inventory/`:

1. `inventory/jyeswak-repos.jsonl` — 70 rows, one per repo, each with the full requested metadata schema (name + visibility + size + lang + last-commit + license + has-readme + has-license + extras).
2. `inventory/jyeswak-repos-summary.json` — categorized aggregation by lang/size/age + surfaced fold-in candidates + archive candidates + hygiene gaps.

## Acceptance gates (implicit from bead title)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | Inventory ALL jyeswak github repos via gh api | DID | `gh repo list jyeswak --limit 1000 --json ...` returned 70 rows |
| 2 | Produce `inventory/jyeswak-repos.jsonl` | DID | 70-line JSONL at `inventory/jyeswak-repos.jsonl` (30KB) |
| 3 | Each row has: name + visibility + size + lang + last-commit + license + has-readme + has-license | DID | row schema verified against first row sample (16 fields total, all 8 requested + 8 extras: created_at, days_since_push, is_archived, is_stale_90d, is_small_under_200_loc_proxy, license_name vs license_key, default_branch, description) |
| 4 | Categorize by language | DID | `by_primary_lang`: Python=31, TypeScript=11, Shell=11, Rust=5, none=8, others |
| 5 | Categorize by size | DID | `by_size_bucket`: tiny (≤50KB), small, medium, large, huge — counts in summary |
| 6 | Categorize by age | DID | `by_age_bucket`: fresh (0-7d), recent (8-30d), aging (31-90d), stale (91-365d), cold (>365d) |
| 7 | Surface fold-in candidates (under-200-LOC) | DID-via-proxy | 15 candidates flagged via `is_small_under_200_loc_proxy` (disk ≤50KB heuristic; manual verification required per evidence note in summary) |
| 8 | Surface archive candidates (90d+ stale) | DID | 19 candidates flagged (pushedAt > 90 days ago, not already archived) |

`did=8/8`, `didnt=none`, `gaps=none`.

## Top-level inventory

```
total: 70 repos
visibility: PRIVATE=66, PUBLIC=4
fold-in candidates (<=50KB disk proxy): 15
archive candidates (90d+ stale, not already archived): 19
already archived: 0
hygiene gaps:
  no readme: 18 (26%)
  no license: 56 (80%)
top 5 languages: Python=31, TypeScript=11, Shell=11, none=8, Rust=5
```

## Fold-in candidates (15)

Repos with disk ≤50KB — likely under-200-LOC after stripping git overhead. **Manual verification required** before any fold-in action (disk includes git history; a small history of large files could fail the LOC test).

- `coo`
- `ai-benchmark-research`
- `grok-voice-demos`
- `fleet-dashboard`
- `aider-test-suite`, `aider-test5`, `aider-test3`, `aider-test`, `aider-fleet-test`, `aider-clean-test` (6 aider-test* scratch repos — STRONG fold-in/archive candidates)
- `agno-service`
- `rano`
- `agent-improvement-meta`
- `ceo-api-service`
- `opencode-grok-first-router`

The 6 `aider-test*` repos are the highest-confidence fold-in/archive group — a cohort of scratch repositories from a test-driver session.

## Archive candidates (19)

Repos pushed 90+ days ago, not already archived. Pattern observation: research catalogs + abandoned experiments dominate. Notable clusters:

- Research catalogs: `optimization-research`, `100-minds-research`, `ServerPlus-Research`, `ai-benchmark-research` (also a fold-in candidate)
- Catalog APIs that may be retired: `Customer_Service`, `Dialpad-HubSpot-Integration`, `claims-automation-catalog`, `eo-insurance-catalog`, `ISP-Acquisition-AI`
- Bot/chat experiments: `chatbot`, `multi-agent`, `100minds-ai`, `email-assistant`, `sinfulgemma`, `video-audio-mcp`
- Sister-orch + meta artifacts: `mcp-agent-mail` (already part of Jeff's substrate — NOT a flywheel-side archive candidate; clone is local-only), `agent-improvement-meta` (also a fold-in candidate), `ceo-api-service`, `opencode-grok-first-router`, `Operations`

**Caution**: `mcp-agent-mail` appears as an archive candidate because Joshua's fork hasn't pushed recently; but the canonical upstream is Jeff Emanuel's repo. Do NOT archive — recheck against jyeswak fork vs upstream provenance before any action.

## Hygiene findings

- 80% (56/70) repos have NO license file. Significant license-hygiene gap.
- 26% (18/70) repos have NO README. Discoverability gap.

These could each warrant follow-up beads but are out-of-scope for this inventory bead (which only inventories + categorizes).

## L112 probe

```bash
test -f /Users/josh/Developer/flywheel/inventory/jyeswak-repos.jsonl && wc -l < /Users/josh/Developer/flywheel/inventory/jyeswak-repos.jsonl | tr -d ' '
```

Expected: literal `70`.

## Files changed

- `inventory/jyeswak-repos.jsonl` — new, 70 rows, 30KB
- `inventory/jyeswak-repos-summary.json` — new, categorized aggregation, ~8KB
- `.flywheel/audit/flywheel-cu6u9/evidence.md` — this evidence pack
- `.flywheel/audit/flywheel-cu6u9/compliance-pack.md` — compliance breakdown

## Mission fitness

`mission_fitness=adjacent`. Inventorying the jyeswak github org surfaces fold-in + archive candidates that reduce fleet drift surface area. Direct support of mission anchor through quantified ZestStream-org footprint visibility (70 repos, 15 small + 19 stale candidates flagged).

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. Standard gh-api + jq + Python inventory + categorize pattern. No new skill emerged.

## Four-Lens Self-Grade

- Brand: 9/10 — concrete JSONL + categorized summary; structured per the bead's exact schema request
- Sniff: 9/10 — empirical probe via `gh repo list` + per-repo README/LICENSE probe; 70/70 rows fetched
- Jeff: 9/10 — mcp-agent-mail caution noted (Jeff's canonical upstream); inventory respects substrate boundaries
- Public: 9/10 — three judges: skeptical operator sees concrete counts + named candidates; maintainer can extend the JSONL schema; future worker can dispatch follow-up cleanup beads from the flagged lists
