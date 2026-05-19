---
title: "stale-in-progress-reaper doctrine"
type: doctrine
created: 2026-05-09
frontmatter_source: scaffold-doc-frontmatter
---

# stale-in-progress-reaper doctrine

**Bead origin:** flywheel-8ht5f.
**Donella triage 2026-05-10:** "64 in_progress beads accumulated since
May 4 planning burst with zero activity. The system has no leverage-point-#4
self-organization mechanism to close them."

## Why this exists (Donella leverage point #4 — self-organization)

A bead that sits in `in_progress` with zero callback / commit / assignee
signal is invisible drag. The work might still be load-bearing, or it
might be dead. Either way, the operator is paying the cognitive tax of
a non-converging stock. The reaper is the canonical mechanism: each
Sunday, sweep in_progress beads with >=7 days of no activity, close
them with a structured reason that explicitly invites the operator to
re-file if the work is still live. Stock stays bounded; signal beats
noise.

Sister to `skill-discoveries-aggregator` (flywheel-4s3oy) — both are
leverage-point-#4 mechanisms turning latent state into surfaced
insight or active triage.

## Pipeline

```
.beads/beads.db                          (source of truth for in_progress beads)
  + .flywheel/dispatch-log.jsonl         (signal: recent worker callbacks)
  + git log                              (signal: recent commits citing bead id)
  + assignee field                       (signal: bead has named owner)
        │
        ▼
.flywheel/scripts/stale-in-progress-reaper.sh
   --json [--apply]                      (default: dry-run; --apply closes via br close)
        │
        ▼
JSON envelope: candidates[] + carved_out_preview[] + classified[]
        │
        ▼ (--apply only)
br close --force <id> --reason "..."     (canonical write path; never raw SQL)
        │
        ▼
~/.local/state/flywheel/stale-reaper-ledger.jsonl  (idempotency receipt)
```

## Classification (in priority order)

| Class             | Condition                                              | Action |
|-------------------|--------------------------------------------------------|--------|
| `CARVED_OUT`      | bead has any label in `--carve-out` set                | keep   |
| `ACTIVE`          | assignee set OR recent commit OR recent callback       | keep   |
| `RECENTLY_TOUCHED`| `updated_at` within window but no other signal         | keep   |
| `STALE`           | none of the above                                      | close  |

Carve-out check happens **first** — labels carry intent. A bead labeled
`upstream-tracker` or `joshua-gated` is never auto-closed even if it
has zero activity, because the labels themselves are the reason it's
sitting in_progress.

## Carve-out labels (canonical default)

| Label                | Why it carves out                                     |
|----------------------|-------------------------------------------------------|
| `upstream-tracker`   | Tracks an upstream issue; closes when upstream closes |
| `cross-orch-active`  | Coordinated across multiple orchestrators; async by design |
| `joshua-gated`       | Awaits Joshua decision; not workable by orchestrator  |
| `defer-gated`        | Has explicit `not_before` deadline; closes when deadline passes |

Override via `STALE_REAPER_CARVE_OUTS=lbl1,lbl2,...` env or
`--carve-out=` CSV (selector grammar mirrors
`autoloop-target-selector.sh --allowed-status=`).

## Cadence

- Launchd label: `ai.zeststream.flywheel-stale-reaper`
- Schedule: Sunday 09:30 local (post-Petal-9 review window, 30min after
  the skill-discoveries-aggregator at 09:00 — both are leverage-point-#4
  mechanisms ganged at the same weekly cadence)
- `--apply` mode in the plist (live close); idempotent via ledger
- KeepAlive=false; RunAtLoad=false

**Joshua-gate before first load:** the inaugural-candidates JSON at
`.flywheel/audit/flywheel-8ht5f/inaugural-candidates.json` MUST be
reviewed by Joshua before `launchctl load` is run. Subsequent
weekly runs auto-execute.

## Idempotency

`~/.local/state/flywheel/stale-reaper-ledger.jsonl` carries one row
per closed bead with `{bead_id, reaped_at, prior_status, prior_updated_at,
reaper_run}`. The reaper itself doesn't currently re-check the ledger
on subsequent runs (closures are durable via `br close` so the bead
won't appear in_progress on re-scan), but the ledger is the audit
trail for "what did the Sunday run reap?" reporting.

## Boundary discipline

- READ: `.beads/beads.db` (sqlite3 SELECT only; NEVER raw mutations)
- WRITE: only `br close --force <id> --reason "..."` (canonical path)
- WRITE: ledger jsonl (one append per closure)
- NO: tmux send-keys, ntm send, kill, anything fleet-disturbing
- NO: --apply without --dry-run-first-then-Joshua-review for the FIRST run

## CLI doctrine (canonical-cli-scoping)

- `--info` (help)
- `--schema` (one-line emit schema; documents `mutation_requires:["--apply"]`)
- `--examples`
- `--doctor` / `--health` / `--repair` / `--audit` / `--why`
- `--apply` (mutation gate; default is dry-run)
- `--window-days=N`
- Stable exit codes via the underlying scan + apply paths

## Tests

- `tests/stale-in-progress-reaper.sh` — 16/16 PASS (original
  classification: STALE / ACTIVE-by-commit / ACTIVE-by-callback /
  ACTIVE-by-assignee / RECENTLY_TOUCHED; dry-run no-mutation;
  --apply closes only stale; ledger written; doctor fields)
- `tests/stale-in-progress-reaper-carve-out.sh` — 10/10 PASS
  (NEW for this bead: 4-canonical-label carve-out; only un-labeled
  bead is STALE; matched-label list carried in receipt;
  STALE_REAPER_CARVE_OUTS env override widens or shrinks list;
  ledger remains untouched in dry-run)

## Inaugural candidates (2026-05-10 dry-run)

```
total_in_progress: 66
stale_count:        2  (only 2 beads have crossed the 7-day threshold)
active_count:      62  (commit/callback/assignee signals protect)
recently_touched:   2
carved_out:         0  (no in_progress beads carry carve-out labels yet)

candidates:
  - flywheel-3bk  (dynamic-ntm-session-coverage-heartbeat) updated 2026-05-01
  - flywheel-3ul  (autoloop-anti-monoculture)              updated 2026-05-01
```

The bead body's "64 in_progress accumulated since May 4" cohort is
6 days old today; most are classified `ACTIVE` because they have
recent commit / callback / assignee signals. The 2-bead
inaugural-stale set are May-1 beads (9+ days old) with no signal.

## Cross-references

- Donella leverage point #4 (self-organization)
- Sister bead: flywheel-4s3oy (skill-discoveries-aggregator —
  same leverage-point-#4 paradigm; same Sunday cadence)
- Existing script + 16/16 tests predate this bead (May 4 build);
  this bead's deliverable is: label-based carve-outs + schema +
  plist + carve-out tests + inaugural review + doctrine + Joshua
  gate before first load


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
