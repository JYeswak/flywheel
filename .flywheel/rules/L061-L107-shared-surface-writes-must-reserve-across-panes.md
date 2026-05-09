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
- Release every held path after commit:
  `.flywheel/scripts/shared-surface-reservation-check.sh --release <path> --pane=<N> --task-id=<task> --json`
- Worker callbacks for shared-surface edits include
  `shared_surface_reservations_checked=yes` and
  `shared_surface_reservations_released=yes`.

**Forbidden outputs:**
- Staging or committing shared surfaces without an active same-pane reservation.
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

