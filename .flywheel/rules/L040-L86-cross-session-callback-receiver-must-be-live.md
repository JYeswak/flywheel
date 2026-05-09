## L86 — CROSS-SESSION-CALLBACK-RECEIVER-MUST-BE-LIVE

---
id: L86
title: Cross-session callback receiver must be live
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: cross-session-dispatch-no-callback-closure
---

Cross-session work selection is allowed; cross-session worker dispatch is not
allowed unless the remote orchestrator and callback receiver are live and
processing loop work. A dispatch that sends work to a peer session worker while
the peer orchestrator is dead creates invisible callback debt and leaves beads
stuck `in_progress`.

**How to apply:**
- Prefer local flywheel workers for fleet-wide infrastructure work. File or
  update peer-repo beads when the finding belongs there, but do not bypass the
  peer orchestrator's closure loop.
- If a cross-session worker dispatch is unavoidable, first prove
  `remote_session_orch_alive=true` with all three facts: session visible in
  current NTM state, orchestrator/callback pane reachable, and that pane has a
  live loop/callback-processing receipt newer than two cadence windows.
- Dispatch packets MUST record the callback receiver session/pane and the
  liveness proof path. Missing proof means no dispatch.
- `/flywheel:supervisor` MUST model this as
  `cross_session_callback_orphan` and expose `callback_orphan_count` or
  `cross_session_callback_orphan_count` when a cross-session dispatch has no
  matching processed callback before deadline.
- When this class is found after the fact, file an orphan/no-bead receipt that
  names the remote beads and asks the owning orchestrator to close or reopen
  them.

**Forbidden outputs:**
- Sending work directly to another session's worker pane because the task is
  infrastructure-deployment or fleet-wide.
- Treating `ntm send` success to a remote worker as proof the remote
  orchestrator will receive, validate, and close the callback.
- Reporting cross-session watcher health without checking callback receiver
  liveness and orphaned remote `in_progress` beads.
- Asking Joshua why a peer session is idle before checking whether the remote
  orchestrator/callback receiver was alive when work was dispatched.

**Evidence:** bead `flywheel-b8zm`; fuckup forensic
`.flywheel/fuckup-log/2026-05-04T04-00Z-skillos-cross-session-no-callback-closure.md`;
Lane A addendum
`.flywheel/PLANS/orchestrator-workforce-supervision-2026-05-04/01-RESEARCH-A-ADDENDUM.md`;
Phase 2 synthesis
`.flywheel/PLANS/orchestrator-workforce-supervision-2026-05-04/02-REFINE-r2.md`;
no-bead receipt
`.flywheel/validation-receipts/no-bead-cross-session-callback-closure-skillos-20260504T0400Z.json`.

**Companion rules:** L29 (NTM-only pane I/O), L52 (bead or no-bead receipt),
L57 (loop marker is not driver), L61 (doctrine wire-in), L70 (same-tick
chain-forward), L75 (peer orchestrator coordination), L80 (DID/DIDNT/GAPS), and
L85 (idle state class canonical).

