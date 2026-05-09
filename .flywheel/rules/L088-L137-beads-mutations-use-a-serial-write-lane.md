## L137 — BEADS-MUTATIONS-USE-A-SERIAL-WRITE-LANE

---
id: L137
title: Beads mutations use a serial write lane
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: file-reservation-conflict
---

Repo-local Beads mutation is a single-writer lane. Workers do not reserve
`.beads/issues.jsonl` or `.beads/beads.db` as ordinary edit files around normal
`br create`, `br update`, or `br close` calls. Those files are Beads substrate,
not shared prose. `br` owns SQLite transactions, WAL/busy-timeout behavior, and
atomic JSONL export; Agent Mail reservations coordinate agents but are not the
database lock.

**How to apply:**
- If a worker needs a bead mutation, it either runs one bounded `br` mutation
  while holding the repo's Beads write lane or queues the request to the
  orchestrator/owner with reason `beads_write_lane_queued`.
- Use `br --lock-timeout 10000 ...` for automation when the installed `br`
  supports it; do not hold long-lived exclusive reservations on `.beads/`.
- Normal workers never manually append to `.beads/issues.jsonl`; L124 still
  applies.
- If multiple panes need bead writes in the same minute, serialize them through
  the lane and report queue depth instead of fail-closing on file reservation
  conflict.

**Why:** `flywheel-0cm9`, `flywheel-0e50`, and `flywheel-chbo` exposed the same
operator-pain class: lock contention masquerading as a new bug every time a
worker wanted to create or close beads. Joshua's 25-year ops lens rejects that
shape because it burns small-team attention on lock diagnosis instead of work.
A real ops team needs one visible queue and one owner, not three agents holding
exclusive reservations on the same substrate files.

**Evidence:** bead `flywheel-chbo`; `br` source in `beads_rust` uses SQLite
WAL/busy timeout plus mutation retries and atomic JSONL rename; Agent Mail
documents file reservations as coordination only. Git history showed no
committed `.beads/issues.jsonl` writes inside the 60-second incident windows,
which points to live reservation contention rather than committed JSONL churn.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

