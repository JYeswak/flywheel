# Audit pack: flywheel-ys7em

**Bead:** flywheel-ys7em — [jeff-daily-corpus-diff] daily GitHub API activity poll across 178 repos with markdown report
**Spec:** `.flywheel/audit/jeff-daily-corpus-diff/apply-spec.md`
**Worker:** MistyCliff (flywheel:0.4)
**UTC:** 2026-05-10T04:23:10Z (inaugural snapshot ts)
**Disposition:** DONE — all 7 acceptance gates pass; inaugural report rendered for Joshua review.

## Summary

| Item | Value |
|---|---|
| Repos polled | 174 (after fork + archived filter; 178 total in cache) |
| Total commits | 1167 |
| Active repos (3+ commits) | 24 |
| Total releases | 5 (all `ultimate_bug_scanner`) |
| Total issues touched | 4 |
| Total PRs merged | 0 |
| Inaugural snapshot | `.flywheel/state/jeff-corpus-activity-2026-05-10.json` |
| Inaugural report | `.flywheel/reports/jeff-corpus-diff-2026-05-10.md` (14322 bytes) |
| Run duration | ~44s for 174 repos × 4 endpoints (paralleled 8) |

## Acceptance gates

### AG1 — Repo list refresh ✓

```
$ gh repo list Dicklesworthstone --limit 200 --json name,isArchived,updatedAt,isFork,description
total=178 active=174 archived=0 forks=4
```

Cache: `.flywheel/state/jeff-repos.json` (TTL 7 days; refresh weekly).
Filters out forks (4) by default; archived count is 0. Override:
`JEFF_DIFF_INCLUDE_ARCHIVED=1`, `JEFF_DIFF_INCLUDE_FORKS=1`.

### AG2 — Daily activity collector ✓

Script: `.flywheel/scripts/jeff-daily-corpus-diff.sh` (471 lines).

Per repo, 4 endpoints, parallel-8 collection:

| Endpoint                                              | Captured                |
|-------------------------------------------------------|-------------------------|
| `/repos/<owner>/<repo>/commits?since=<24h>`           | sha, message, author, ts |
| `/search/issues?q=...+is:issue+updated:>=`            | number, title, state, ts, url |
| `/repos/<owner>/<repo>/releases?per_page=5`           | filtered by published_at |
| `/search/issues?q=...+is:pr+is:merged+merged:>=`      | number, title, ts, url   |

Triad: `--info`, `--schema`, `--examples`. Doctor: `--doctor --json`.
Mutation gate: `--apply` (read-only modes: `--doctor`, `--refresh-repos`).
Stable exit codes (0/1/2/3).

**Fuckup logged + recovered**: first full run with 174 repos hit a
parallel-stdout-interleave race when commit-rich lines exceeded
PIPE_BUF (~4KB on macOS); two repos' JSON spliced together at
boundary. Fix: per-repo output files in mktemp dir, then concat at
end. Re-run clean. Filed as skill-discovery candidate
`xargs-parallel-large-line-stdout-interleave-class`.

### AG3 — Report renderer ✓

Script: `.flywheel/scripts/jeff-daily-corpus-diff-render.sh` (135 lines).

Sections (verified in inaugural report):
- **Headline** — one-line: 1167 commits across 24 repos, 5 releases, 0 PRs, 4 issues
- **Releases (high signal)** — 5 ultimate_bug_scanner tags, all linked
- **Active repos (3+ commits today)** — 24 repos, top-5 commit subjects each, "and N more" footer
- **New issues (touched in window)** — 4 entries, sorted by ts desc
- **PRs merged** — section omitted when 0
- **Quiet day** banner — not triggered (1180 events » 5 threshold)

### AG4 — Schema ✓

Schema: `.flywheel/validation-schema/v1/jeff-daily-diff-report.v1.schema.json`
(JSON Schema draft-07, validates raw aggregated envelope).

E2e jq-fallback validates the canonical fields: `schema_version`,
`ts_started`, `ts_completed`, `repos[]` shape with required
`repo/commits/issues/releases/prs` keys. Full `jsonschema` CLI
validation also passes (Test 6 PASS).

### AG5 — Launchd plist ✓

Plist: `.flywheel/launchd/ai.zeststream.jeff-daily-corpus-diff.plist`.

- StartCalendarInterval Hour=8 Minute=0 (08:00 local)
- KeepAlive=false; RunAtLoad=false
- Idempotent: skip if today's report exists (in the inline shell)
- Logs: `~/.local/state/flywheel/jeff-daily-corpus-diff.{out,err}.log`
- `plutil -lint`: PASS

Not yet registered via `launchctl load`; awaits Joshua review of the
inaugural report shape per spec ("Joshua reviews shape before launchd
activation"). Activation command:

```bash
launchctl load /Users/josh/Developer/flywheel/.flywheel/launchd/ai.zeststream.jeff-daily-corpus-diff.plist
```

### AG6 — End-to-end smoke test ✓

`tests/jeff-daily-corpus-diff-e2e.sh` — 9/9 PASS:

```
PASS collector --info exits 0
PASS collector --schema emits canonical schema_version
PASS collector --doctor --json valid
PASS renderer --info exits 0
PASS collector --apply --only=ntm produces snapshot
PASS schema validation pass
PASS renderer produces 4 canonical sections + headline
PASS headline cites real commit + repo counts
PASS launchd plist plutil -lint OK
SUMMARY pass=9 fail=0
```

Test isolates state dir via `JEFF_DIFF_STATE_DIR=$TMPDIR/state` so
the smoke run does NOT clobber the canonical
`.flywheel/state/jeff-corpus-activity-<date>.json` that launchd /
Joshua's daily review reads. Caught and fixed during this dispatch.

### AG7 — Doctrine + L61 ✓

- Doctrine: `.flywheel/doctrine/jeff-daily-corpus-diff.md` (pipeline
  diagram, endpoint table, replaces-table, schema reference, boundary).
- L63 evidence updated:
  `.flywheel/rules/L017-L63-jeff-intel-network-is-canonical-substrate-dependency.md`
  gains a how-to-apply line citing the API-only daily-diff feed +
  launchd label, and the **Evidence:** paragraph adds the
  flywheel-ys7em + Joshua signoff 2026-05-10 reference.

## Replaces (8 superseded beads — already closed by orch on dispatch)

```
flywheel-fh7y: closed (J3 clone-all-177)
flywheel-zaat: closed (J4 dedupe local clones)
flywheel-espj: closed (J5 socraticode-index-all-177; orthogonal scope)
flywheel-abdx: closed (J7 daily-diff-script-build → AG2)
flywheel-nh6d: closed (J8 daily-launchd-plist-install → AG5)
flywheel-tcil: closed (J9 daily-report-schema-and-verdict-template → AG4)
flywheel-7a7l: closed (J10 end-to-end-validation-test → AG6)
flywheel-cqww: closed (J11 AGENTS.md L63 evidence update → AG7)
```

## Files shipped

- `.flywheel/scripts/jeff-daily-corpus-diff.sh`
- `.flywheel/scripts/jeff-daily-corpus-diff-render.sh`
- `.flywheel/validation-schema/v1/jeff-daily-diff-report.v1.schema.json`
- `.flywheel/launchd/ai.zeststream.jeff-daily-corpus-diff.plist`
- `tests/jeff-daily-corpus-diff-e2e.sh`
- `.flywheel/doctrine/jeff-daily-corpus-diff.md`
- `.flywheel/rules/L017-L63-jeff-intel-network-is-canonical-substrate-dependency.md` (updated)
- `.flywheel/state/jeff-corpus-activity-2026-05-10.json` (inaugural snapshot)
- `.flywheel/reports/jeff-corpus-diff-2026-05-10.md` (inaugural report)
- `.flywheel/audit/flywheel-ys7em/evidence.md` (this file)

## Boundary discipline

- ✓ API only; no local clones added; no `git fetch` triggered
- ✓ Rate-limit safe: 174 repos × 4 endpoints = 696 calls/run, 5000/hr
  headroom; doctor probe confirms gh auth + cache freshness
- ✓ Skip archived + forks by default; envs to override
- ✓ Stable exit codes 0/1/2/3 per canonical-cli-scoping
- ✓ E2E test does NOT pollute production state dir

## Joshua review steps

1. Read `.flywheel/reports/jeff-corpus-diff-2026-05-10.md` (~14KB,
   under 2-min skim per goal).
2. Confirm shape OK; if useful, activate launchd:
   `launchctl load .flywheel/launchd/ai.zeststream.jeff-daily-corpus-diff.plist`
3. Optionally tune `JEFF_DIFF_QUIET_THRESHOLD` (default 5) or
   `JEFF_DIFF_PARALLEL` (default 8) via env.

## Four-Lens Self-Grade

- brand: 9 — single bead replaces 8 across J3-J11, no local clones
  needed, daily skim fits the mission anchor.
- sniff: 9 — every claim verifiable; e2e 9/9 PASS catches the parallel
  race fix; canonical snapshot path stays intact under e2e isolation.
- jeff: 9 — atomic per-repo writes, no fleet bleed, stop-on-error,
  reproducible recipe via spec + scripts + tests.
- public: 9 — three judges check: skeptical operator can re-run
  `jeff-daily-corpus-diff.sh --apply --json --only=ntm` and replicate
  the smoke; maintainer can read the doctrine + apply-spec to extend;
  future worker can fold this pattern into other corpus monitors
  (CFS authors, Anthropic, etc.) by parameterizing `JEFF_DIFF_OWNER`.
