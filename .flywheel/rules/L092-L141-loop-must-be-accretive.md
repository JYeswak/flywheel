## L141 — LOOP-MUST-BE-ACCRETIVE

---
id: L141
title: Tick body must produce accretion, not just ceremony
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: loop-non-accretive
---

A `/flywheel:tick` body MUST execute one of these accretive paths each tick:

1. **Dispatch path** — call `/flywheel:dispatch` for at least one WAITING
   worker if ready beads exist.
2. **Reap path** — process at least one callback from dispatch-log since
   last tick.
3. **Local-lane path** — make a scoped change to repo state.
4. **Audit path** (fallback) — run a probe that produces a finding bead.

If NONE of 1-4 happen AND `br ready` reports a ready bead AND
`ntm --robot-activity` reports a WAITING worker, the tick MUST emit a
`tick_non_accretive` row to dispatch-log AND ScheduleWakeup at 600s
(not 1800s). Three consecutive non-accretive ticks for the same project
trigger doctor warn; five trigger doctor fail.

**Why:** Discovered 2026-05-08T15:30Z — Joshua observed 9-hour fleet idle
despite cc loop pulse "active". Tick body audited beads (closed 2 stale)
without invoking `/flywheel:dispatch`. Workers stayed WAITING. Receipt
validated `receipt_ok=true` while loop produced no work-flow accretion.

**Receipt v2 extension:** `accretive_signals` (counts of dispatches_sent,
callbacks_reaped, beads_closed_via_callback, commits_with_substrate_change,
findings_filed); `accretion_path` enum
(dispatch | reap | local_lane | audit | non_accretive); `non_accretive_reason`
required when accretion_path=non_accretive.

**Evidence:** doctrine
`.flywheel/doctrine/loop-non-accretive-trauma-class.md`; memory
`feedback_orch_punt_is_l70_failure_dispatch_dont_ask`; LOOP.md step 4.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L70, L101, L130, L140.

