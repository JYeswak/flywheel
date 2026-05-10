# jeff-daily-corpus-diff apply spec

Replaces the J3-J11 local-clone chain with a GitHub-API-based daily activity feed.
Joshua signoff 2026-05-10: "see the diffs of jeff's corpus daily instead of having
it all waiting locally."

## Goal

Produce a daily report that summarizes Jeffrey Emanuel's corpus activity across
all 177 of his GitHub repos in one digestible markdown surface. No local clones.
GitHub API poll is the substrate.

## Scope (single bead, replaces 7-bead chain)

### AG1: repo list refresh

- Source-of-truth: `gh repo list Dicklesworthstone --limit 200 --json name,isArchived,updatedAt,isFork,description`
- Cache: `.flywheel/state/jeff-repos.json` (ttl 7 days; refresh weekly)
- Filter out archived and forks (configurable via `JEFF_DIFF_INCLUDE_ARCHIVED=1`)
- Expected count: ~177 (today)

### AG2: daily activity collector

- Script: `.flywheel/scripts/jeff-daily-corpus-diff.sh`
- Per repo (parallel batches of 8 to avoid rate-limiting):
  - Commits in last 24h: `gh api /repos/Dicklesworthstone/<repo>/commits?since=<UTC-24h>`
  - Issues opened or updated: `gh api /search/issues?q=repo:Dicklesworthstone/<repo>+updated:>=<UTC-24h>`
  - Releases tagged: `gh api /repos/Dicklesworthstone/<repo>/releases?per_page=5` then filter by published_at
  - PRs merged: `gh api /search/issues?q=repo:Dicklesworthstone/<repo>+is:pr+is:merged+merged:>=<UTC-24h>`
- Per-repo result envelope: `{repo, commits[], issues[], releases[], prs[], updated_at}`
- Aggregate raw data: `.flywheel/state/jeff-corpus-activity-<date>.json` (raw daily snapshot, kept 90 days)

### AG3: report renderer

- Script: `.flywheel/scripts/jeff-daily-corpus-diff-render.sh`
- Input: aggregated raw json
- Output: `.flywheel/reports/jeff-corpus-diff-<date>.md`
- Sections:
  - **Headline**: "Jeffrey shipped X commits across Y repos, Z new releases" (one-line at top)
  - **Releases (high signal)**: any new release tagged in last 24h, with link
  - **Active repos** (3+ commits today): repo name + commit count + first-line of last commit message
  - **New issues** (across all repos): truncated list
  - **Quiet day** marker if total activity < 5 events
- Joshua-readable in <2 minutes of skim

### AG4: schema

- File: `.flywheel/validation-schema/v1/jeff-daily-diff-report.v1.schema.json`
- Validates the raw aggregated json envelope; report markdown is human-only

### AG5: launchd plist

- File: `.flywheel/launchd/ai.zeststream.jeff-daily-corpus-diff.plist`
- Schedule: daily at 08:00 local (StartCalendarInterval Hour=8, Minute=0)
- Idempotent: if today's report already exists, skip
- Logs to `~/.local/state/flywheel/jeff-daily-corpus-diff.{out,err}.log`
- KeepAlive false; runs once per day
- Register via `flywheel-watchers register --label ai.zeststream.jeff-daily-corpus-diff --owner flywheel-1`

### AG6: e2e smoke test

- File: `tests/jeff-daily-corpus-diff-e2e.sh`
- Exercises ONE repo (use `Dicklesworthstone/ntm` as test target) end-to-end
- Assertions: collector returns valid JSON; renderer produces markdown with all 4 sections; schema validation passes

### AG7: doctrine + L61

- Add `.flywheel/doctrine/jeff-daily-corpus-diff.md` describing the flow (collector → renderer → report)
- Update AGENTS.md L63 evidence with link to the daily-report directory

## Boundary

- API only; no local clones
- Rate limit: gh CLI handles 5000/hr authenticated; should be fine for 177 repos × 4 endpoints = 708 calls/day
- If rate-limited, fall back to `--per-page=100` paginated listing
- Skip archived repos by default (configurable)

## Today's first run

After AG1-AG7 land, manually run the collector once to produce today's
inaugural report. Joshua reviews shape before launchd activation.

## Replaces

- flywheel-fh7y (J3 clone) — obsolete
- flywheel-zaat (J4 dedupe) — obsolete
- flywheel-espj (J5 socraticode-index-all-177) — obsolete (index work was separate; this isn't replacing it)
- flywheel-abdx (J7 daily-diff-script-build) — replaced by AG2
- flywheel-nh6d (J8 daily-launchd-plist-install) — replaced by AG5
- flywheel-tcil (J9 daily-report-schema-and-verdict-template) — replaced by AG4
- flywheel-7a7l (J10 end-to-end-validation-test) — replaced by AG6
- flywheel-cqww (J11 AGENTS-md-L63-evidence-update) — replaced by AG7

## Canonical structure (post-hoc backfill, flywheel-at83y)

This apply-spec was authored before the F7 canonical structure rule (filesystem-as-rag doctrine).
The body above contains the substantive content; the H2 stubs below satisfy the mechanical lint without rewriting the prose.

## Acceptance gate

See body above (typically near the end, named Acceptance or per-AG numbered).
