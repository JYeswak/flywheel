## L85 — IDLE-STATE-CLASS-CANONICAL

---
id: L85
title: Idle state class canonical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: idle-pane-recovery-hidden-in-watcher
---

Idle worker-pane recovery MUST be driven by a doctor-visible state class, not by
logic buried inside a daemon wrapper. The canonical classifier is
`.flywheel/scripts/idle-state-probe.sh`.

**How to apply:**
- `flywheel-loop doctor --json` MUST expose `idle_state_class`,
  `idle_state_summary`, `idle_dispatching_over_threshold_count`,
  `idle_state_config_path`, and `idle_state_config_loaded`.
- The idle watcher may dispatch only from
  `idle_state_class == "dispatching"` rows emitted by the canonical probe.
- A `dispatching` worker pane older than 5 minutes is a readiness failure:
  either dispatch the worker or repair the watcher.
- Per-repo policy is configured by `idle-state-config/v1`; peer orchestrator
  defaults disable `saturated` and keep `dispatching` plus `light_queue` active
  so they escalate to `flywheel:1` through xpane instead of Joshua.
- Tests must cover all four active classes plus pane-not-waiting, disabled
  config, and `classes_active` filtering before changing the watcher or probe.

**Forbidden outputs:**
- Reporting idle-pane recovery as healthy when the watcher has private
  classification logic not surfaced in doctor JSON.
- Dispatching from `/tmp/idle-pane-auto-dispatch.sh` without a matching
  `dispatching` row from `.flywheel/scripts/idle-state-probe.sh`.
- Treating `saturated` as actionable for peer orchestrators unless their local
  config explicitly enables it.

**Evidence:** bead `flywheel-viux`; probe
`.flywheel/scripts/idle-state-probe.sh`; schema
`.flywheel/validation-schema/v1/idle-state-config.schema.json`; watcher
`/tmp/idle-pane-auto-dispatch.sh`; tests `tests/idle-state-probe.sh`.

**Companion rules:** L50 (socraticode survey), L57 (loop state marker is not a
driver), L70 (same-tick chain-forward), L75 (peer orchestrator blocker
coordination), and L80 (DID/DIDNT/GAPS callbacks).

