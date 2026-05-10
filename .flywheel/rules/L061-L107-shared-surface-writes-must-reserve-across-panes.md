## L107 — SHARED-SURFACE-WRITES-MUST-RESERVE-ACROSS-PANES

---
id: L107
title: Shared-surface writes must reserve across panes
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: coordination-collision-shared-surface
---

Workers committing to shared surfaces (`flywheel-loop`, doctor-author files,
`AGENTS.md`, `README.md`, `scripts/`, `.flywheel/scripts/`, and dispatch
templates) MUST reserve with
`.flywheel/scripts/shared-surface-reservation-check.sh --reserve <path>
--pane=<N> --task-id=<task>` before `git add`, then release after commit or
before any BLOCKED/DECLINED callback. Cross-pane collisions auto-detect and
log fuckup-log class `coordination-collision-detected`; doctor exposes
`coordination_collision_count_24h` so the trend has a visible decay target.
Never trust pane-local mtime alone.

**How to apply:**
- Check or reserve a path before staging:
  `.flywheel/scripts/shared-surface-reservation-check.sh --reserve <path> --pane=<N> --task-id=<task> --json`
- If another pane holds it, stop before `git add` and callback
  `BLOCKED <task> reason=coordination-collision-detected need="holder pane release or cross-pane coordination"`.
- **The lifecycle is `--reserve → write → git add → git commit → --release`**,
  in that exact order. Releasing before `git add+commit` opens a race window:
  a peer pane can acquire the reservation, append, and release in the gap; your
  subsequent `git add <path>` then stages BOTH appends and your commit message
  claims authorship of work you did not do. Concrete instance: commit
  `37d0de7` (2026-05-09T20:30:30Z) bundled pane 2's
  `mobile-eats-dispatch-health-gate-fail` entry into pane 3's wwinm
  cross-reference commit. Surfaced by `flywheel-y4e47`.
- Release every held path **AFTER `git commit` exits 0** (NOT after the
  in-memory write):
  `.flywheel/scripts/shared-surface-reservation-check.sh --release <path> --pane=<N> --task-id=<task> --json`
- For BLOCKED/DECLINED paths (no commit will land), release immediately
  before sending the callback so peers aren't queued behind a dead
  reservation.
- Worker callbacks for shared-surface edits include
  `shared_surface_reservations_checked=yes` and
  `shared_surface_reservations_released=yes`.

**Forbidden outputs:**
- Staging or committing shared surfaces without an active same-pane reservation.
- **Releasing the reservation before `git commit` exits 0** — opens the
  release-then-stage race window (per `flywheel-y4e47`).
- Treating an Agent Mail file reservation as sufficient for shared surfaces;
  L51 prevents codebase file races, L107 prevents pane-level staging races.
- Retrying after a collision without holder evidence, release evidence, or a
  cross-pane coordination packet.
- Reporting the fleet clean while `coordination_collision_count_24h > 0`.

**Evidence:** checker `.flywheel/scripts/shared-surface-reservation-check.sh`;
tests `tests/shared-surface-reservation-check.sh`; dispatch contract
`~/.claude/commands/flywheel/_shared/dispatch-template.md`; doctor field in
`~/.claude/skills/.flywheel/bin/flywheel-loop`.

**Cross-references:** L51 (dispatch file reservations), L75 (peer orchestrator
blocker coordination), L91 (dispatch delivery receipt), L104 (comms measured),
L105 (process gaps measured), and L106 (fleet observatory health).

