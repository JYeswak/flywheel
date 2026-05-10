---
title: "jeff-daily-corpus-diff doctrine"
type: doctrine
created: 2026-05-09
frontmatter_source: scaffold-doc-frontmatter
---

# jeff-daily-corpus-diff doctrine

**Bead origin:** flywheel-ys7em (replaces J3-J11 local-clone chain).
**Mission anchor:** continuous-orchestrator-uptime-self-sustaining-fleet — "see the
diffs of Jeffrey's corpus daily instead of having it all waiting locally."

## What it is

A daily GitHub-API poll of all 178 (currently 174 active after fork/archived
filtering) repos in `Dicklesworthstone/*`, rendered as a single markdown
report Joshua can skim in under two minutes.

No local clones. No socraticode index of the full corpus. The substrate is
the GitHub REST/Search API surface, accessed via the authenticated `gh` CLI.

## Pipeline

```
.flywheel/state/jeff-repos.json                  (weekly refresh)
        │
        ▼
.flywheel/scripts/jeff-daily-corpus-diff.sh
   --apply [--only=<repo>] [--since=<iso>]      (collector — 4 endpoints/repo, parallel 8)
        │
        ▼
.flywheel/state/jeff-corpus-activity-<UTC-date>.json  (raw snapshot, 90-day retention)
        │
        ▼
.flywheel/scripts/jeff-daily-corpus-diff-render.sh
   --apply --in=<snap> [--out=<report.md>]      (renderer — markdown for human skim)
        │
        ▼
.flywheel/reports/jeff-corpus-diff-<UTC-date>.md
```

## Endpoints polled per repo (24h window)

| Endpoint                                         | What it captures             |
|--------------------------------------------------|------------------------------|
| `/repos/<owner>/<repo>/commits?since=<iso>`      | commits with author + sha    |
| `/search/issues?q=repo:<o>/<r>+is:issue+updated` | issues touched in window     |
| `/repos/<owner>/<repo>/releases?per_page=5`      | last 5 releases (filter ts)  |
| `/search/issues?q=...+is:pr+is:merged+merged:>=` | merged PRs in window         |

Authenticated rate limit is 5000/hr; 178 repos × 4 endpoints = 712 calls/day.
Plenty of headroom even with weekly cache refresh.

## Report sections (AG3)

- **Headline** — one-line: commits / active repos / releases / PRs / issues.
- **Releases (high signal)** — any tag published in the window, with link.
- **Active repos** — 3+ commits today; first 5 commit subjects per repo.
- **New issues** — last 15 issues touched, sorted by ts desc.
- **PRs merged** — appended only when `total_prs > 0`.
- **Quiet day** — banner when total events < 5 (configurable).

## Cadence

- Collector: launchd `ai.zeststream.jeff-daily-corpus-diff` at 08:00 local daily.
- Idempotent: re-running on the same UTC date skips if today's report exists.
- Cache refresh: collector reads `.flywheel/state/jeff-repos.json` (TTL 7 days);
  weekly run of `--refresh-repos` keeps it current.

## Replaces (now obsolete)

| Old bead              | What it was                 | Where it went    |
|-----------------------|-----------------------------|------------------|
| flywheel-fh7y (J3)    | clone all 177 repos         | obsolete (no clone) |
| flywheel-zaat (J4)    | dedupe local clones         | obsolete (no clone) |
| flywheel-espj (J5)    | socraticode-index-all-177   | not in scope here  |
| flywheel-abdx (J7)    | daily-diff-script-build     | replaced by AG2    |
| flywheel-nh6d (J8)    | launchd plist install       | replaced by AG5    |
| flywheel-tcil (J9)    | report schema + verdict     | replaced by AG4    |
| flywheel-7a7l (J10)   | end-to-end validation       | replaced by AG6    |
| flywheel-cqww (J11)   | AGENTS.md L63 evidence      | replaced by AG7    |

## CLI doctrine (canonical-cli-scoping triad on each script)

Both `jeff-daily-corpus-diff.sh` and `jeff-daily-corpus-diff-render.sh` ship:
- `--info` — the help screen
- `--schema` — emit JSON shape the script reads/writes
- `--examples` — curated usage snippets
- `--apply` (mutation gate) vs `--doctor` / `--refresh-repos` (read-only)
- Stable exit codes: 0 success, 1 internal, 2 bad arg / missing dep, 3 gh auth/rate-limit

## Boundary

- **API only** — no local clones, no `git fetch` against remote tarballs.
- Skip archived + forks by default; `JEFF_DIFF_INCLUDE_ARCHIVED=1` /
  `JEFF_DIFF_INCLUDE_FORKS=1` envs to override.
- If gh hits rate limits, the per-repo result envelope's `errors[]` field
  carries the failure; collector continues with the rest.

## Schema

Raw snapshot validates against
`.flywheel/validation-schema/v1/jeff-daily-diff-report.v1.schema.json`
(schema_version: `jeff-daily-diff-collector.v1`). Markdown report is
human-only — no schema.
