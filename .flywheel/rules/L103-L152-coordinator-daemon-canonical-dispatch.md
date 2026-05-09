## L152 — COORDINATOR-DAEMON-CANONICAL-DISPATCH

---
id: L152
title: NTM coordinator daemon is canonical dispatch substrate
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: dispatch-substrate-drift
---

**Rule:** Worker dispatch substrate is the **NTM coordinator daemon**.
Auto-dispatch via the pinned-wrapper coordinator daemon
(launchd label `ai.zeststream.flywheel-coordinator-daemon`) is the
**canonical** path for new work to reach worker panes. The
operator-fired `/flywheel:dispatch` slash command becomes the
**manual override** path for cases where the daemon's automated
selection is wrong, the work needs operator-pinned routing, or the
daemon is intentionally halted for safety.

**Why:** 2026-05-07 coordinator activation: ntm#122 + ntm#124 closed
upstream (`c0f8f222` plumbed `AutoReassignOptions.DryRun` through
`runWatchMode`/`PerformAutoReassignment`/`WatchLoop.handleCompletion`;
`3e44fe9e` added `robot.IsLiveBusy()` defensive override against
busy-pane dispatch). Daemon installed via
`.flywheel/scripts/install-coordinator-daemon.sh`; bleed-immunity
verified at 4/4 CWDs identical (no working-dir cross-contamination
between worker spawns); first end-to-end auto-dispatched bead
`flywheel-olhg` closed cleanly 2026-05-07. Before this rule, the
session held memory `feedback_ntm_assign_watch_unsafe_pending_124`
as a daemon-halt; that doctrine is now superseded.

**How to apply:**
- Default path: the coordinator daemon picks ready beads from
  `<repo>/.beads/issues.jsonl` and dispatches them to idle worker
  panes via the `assign --watch --auto` chain. Ready-bead selection
  honors `br ready` semantics and the L60 5-signal liveness
  contract.
- Override path: invoke `/flywheel:dispatch` (or
  `.flywheel/scripts/dispatch-and-verify.sh`) when the operator
  needs to pin a specific bead → pane assignment, when the daemon's
  selection is wrong, or when the daemon is intentionally halted.
- Halt path: when ntm or coordinator emits a safety signal, halt
  the daemon via `launchctl bootout
  gui/501/ai.zeststream.flywheel-coordinator-daemon` and switch to
  override-only operation until the upstream issue is named and
  remediated. Record the halt in
  `~/.local/state/flywheel/coordinator-daemon-install.jsonl`.
- Health check: `.flywheel/scripts/coordinator-daemon-health.sh
  --json` returns `status:pass`, `coordinator_daemon_alive:true`,
  and a non-zero `coordinator_daemon_uptime_seconds`. Before
  trusting auto-dispatch, this probe must pass.

**Forbidden outputs:**
- Treating the daemon as down when health probe returns
  `status:pass` — that's ignoring measured truth.
- Treating `/flywheel:dispatch` as the canonical primary path —
  that's substrate inversion. It's the override, not the default.
- Re-enabling the daemon while ntm has an open safety issue
  blocking auto-assign — defaults must respect upstream contract.
- Bypassing the coordinator's `assign --watch --auto` planner with
  raw `tmux send-keys` — the planner enforces busy-pane defense
  (`robot.IsLiveBusy()`); raw send bypasses that.

**Evidence:**
- Daemon installer: `.flywheel/scripts/install-coordinator-daemon.sh`
- Health probe: `.flywheel/scripts/coordinator-daemon-health.sh`
- Install ledger:
  `~/.local/state/flywheel/coordinator-daemon-install.jsonl`
- launchd plist:
  `templates/flywheel-install/launchd/ai.zeststream.flywheel-coordinator-daemon.plist`
- launchctl label: `ai.zeststream.flywheel-coordinator-daemon`
- Memory: `feedback_ntm_assign_watch_unsafe_pending_124` (RESOLVED
  2026-05-08 — old halt obsolete; daemon canonical)
- Upstream commits: ntm `c0f8f222` (DryRun plumbing) + `3e44fe9e`
  (`robot.IsLiveBusy()` busy-pane defense)
- Bead: `flywheel-olhg` (first end-to-end auto-dispatched bead,
  closed cleanly 2026-05-07) — proof of canonical path
- Bleed-immunity: 4/4 worker CWDs identical (per 2026-05-07
  activation receipts)

**Companion rules:**
- L60 (5-signal liveness contract — coordinator's selection
  honors driver-output signals)
- L70 (orch-no-punt — override path used when daemon's pick
  needs same-tick redirect)
- L91 (dispatch delivery receipt — every coord auto-dispatch
  produces a v2 receipt)
- L120 (br-close-executed in callback — applies whether dispatch
  came from coord daemon or `/flywheel:dispatch` override)
