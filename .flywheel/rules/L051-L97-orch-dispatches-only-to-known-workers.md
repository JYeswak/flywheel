## L97 — ORCH-DISPATCHES-ONLY-TO-KNOWN-WORKERS

---
id: L97
title: Orchestrator dispatches only to known workers
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: orchestrator-dispatched-without-worker-identity
---

Every dispatch MUST resolve target pane through the canonical orch-worker-identity manifest at
`~/.local/state/flywheel/orch-worker-identity/<session>.json`. Dispatch is forbidden when the
target pane is not in the manifest's workers list OR when the worker's `registration_status` is
not `active`. Auto-trigger registration broadcast on `needs_registration` and re-probe before dispatch.

**Why:** 2026-05-04 — orchestrators across alps/mobile-eats/vrtx had `fleet_mail_identity=unrecorded`
and dispatched to worker panes by hardcoded pane number with no identity awareness. Workers MINT
identity ad hoc when not found — violating the read-don't-mint rule. skillos doctor failed local
ticks on cross-session drift it didn't own (L92 violation in doctor logic, fixed in same tick).

**How to apply:**
- Dispatch-template skill loads manifest before send; refuses if target pane not active.
- Doctor probe surfaces `orchestrator_unknown_worker_identity_count` (per-orch local) and
  `fleet_identity_drift_count` (cross-session, surface-only, never halts local tick).
- Auto-registration broadcast on `needs_registration` is idempotent and required before dispatch
  resumes; failed broadcast = BLOCKED dispatch with fleet-mail downtime classification.

**Forbidden outputs:**
- Dispatching to pane number without manifest lookup.
- Halting a local tick on cross-session identity drift.
- Minting identity in worker pane when manifest says unregistered (broadcast-then-read pattern only).

**Cross-references:** L51 (file reservations), L86 (cross-session-callback-receiver-must-be-live),
L91 (dispatch-delivery-four-state-receipt), L92 (audit-findings-route-by-data).

