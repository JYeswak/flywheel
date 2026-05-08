---
schema_version: flywheel-chbo-rca/v1
task_id: flywheel-chbo
created_ts: 2026-05-08T02:53:00Z
---

# flywheel-chbo RCA and Doctrine Wire-In

did=5/5 didnt=none gaps=none tests=PASS

## RCA Locking Model

`br` uses its own SQLite and JSONL safety model. In `beads_rust`, storage opens
SQLite directly and applies WAL mode plus busy timeout:

- `/Users/josh/Developer/beads_rust/src/storage/schema.rs:232` sets WAL mode.
- `/Users/josh/Developer/beads_rust/src/storage/schema.rs:246` sets
  `busy_timeout = 5000`.
- `/Users/josh/Developer/beads_rust/src/storage/sqlite.rs:237` starts
  mutations with `BEGIN CONCURRENT`.
- `/Users/josh/Developer/beads_rust/src/storage/sqlite.rs:283` retries
  `BusySnapshot` commits with backoff.
- `/Users/josh/Developer/beads_rust/src/sync/mod.rs:1476` uses atomic JSONL
  rename after writing and syncing a temp file.

Agent Mail file reservations are a separate coordination layer. The
`agent-mail` skill says reservation conflicts should wait, coordinate, or share
via `exclusive=false`; it does not make MCP reservations the Beads database
lock. Conclusion: `br` has SQLite/atomic-file locking; Agent Mail reservations
are pane coordination; today we were stacking both and treating `.beads/` like
ordinary editable prose.

## Concurrency Measurement

I measured committed `.beads/issues.jsonl` writes around the three trauma
windows:

```bash
git log --since='2026-05-04T05:29:00Z' --until='2026-05-04T05:31:00Z' -- .beads/issues.jsonl
git log --since='2026-05-04T06:33:49Z' --until='2026-05-04T06:35:49Z' -- .beads/issues.jsonl
git log --since='2026-05-08T02:40:00Z' --until='2026-05-08T02:50:00Z' -- .beads/issues.jsonl
```

Result: `0` committed writes in each 60-second incident window. Wider same-day
history did show `.beads/issues.jsonl` bursts later on 2026-05-04, including
two commits 11 seconds apart at 17:40:11 and 17:40:22 MDT. The incident-window
measurement points to live reservation contention before commit, not committed
JSONL churn.

## Recommended Mitigation

Recommended fix: a repo-local Beads write lane, not longer reservations.

Why this one:

- Longer TTL would make the conflict worse by holding `.beads/` longer.
- Retry-with-backoff helps SQLite contention, and `br` already has a local
  busy timeout and BusySnapshot retry path.
- A Beads write lane matches the actual boundary: one owner runs one bounded
  `br` mutation at a time; everyone else queues `beads_write_lane_queued`.

Joshua-lens: lock contention masquerading as the bug of the week is the same
operator-experience pattern as a queue depth metric ignored until the storm
hits. It burns a small team because every worker has to become a lock expert
instead of closing work. The serial lane is first-90-days senior-ops-hire
shippable: it turns a hidden conflict into a visible queue with one owner.

## Wire-In

- `~/.claude/skills/beads-workflow/SKILL.md:199` adds the Shared Beads Write
  Lane rule for workers.
- `AGENTS.md:3756` adds L137 for the local repo.
- `.flywheel/AGENTS-CANONICAL.md:4120` adds L137 to canonical doctrine.
- `templates/flywheel-install/AGENTS.md:3743` propagates L137 through the
  flywheel install template.

## Fleet Propagation Check

I did not hand-edit ALPS, mobile-eats, or skillos AGENTS files. Per the
no-ad-hoc-doctrine rule, propagation is through the install template and
canonical doctrine. I verified those repos have flywheel-installed canonical
AGENTS surfaces:

- `/Users/josh/Developer/alpsinsurance/.flywheel/AGENTS-CANONICAL.md`
- `/Users/josh/Developer/mobile-eats/.flywheel/AGENTS-CANONICAL.md`
- `/Users/josh/Developer/skillos/.flywheel/AGENTS-CANONICAL.md`

`templates/flywheel-install/AGENTS.md` now carries L137, so the next install or
canonical doctrine sync moves the fix through the same path as prior L-rules.
