## L95 — WORKER-STALL-RECOVERY-PROTOCOL

---
id: L95
title: Worker stall recovery protocol
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: l70-worker-stall-undetected
---

When a dispatched worker remains classified `THINKING` across consecutive orchestrator ticks but its live pane output has not advanced and no callback has landed, the orchestrator MUST run a graduated stall-recovery receipt before declaring work in-flight, idling, or respawning. `THINKING` is not enough truth by itself: it can mean real work, submit lag, a stalled agent, or stale classifier state.

The recovery order is fixed: first capture fresh live pane tail through the canonical NTM pane-capture surface, then send a lightweight non-empty NTM status probe, then wait a 60-90 second grace window for Codex submit lag, then re-capture live tail and recompute robot activity. Only if the pane shows no output advancement and no response after probe plus grace may the orchestrator respawn. After respawn, it MUST relaunch the agent with the canonical bare command, then redispatch the same bead or task id with the same acceptance gates.

Required L95 receipt fields are `stall_detection_ts`, `session`, `pane`, `task_id`, `last_output_hash`, `fresh_output_hash`, `fresh_output_advanced`, `callback_delivered`, `probe_attempted`, `probe_response_ts`, `grace_window_seconds`, `checkpoint_capture_ts`, `robot_activity_before`, `robot_activity_after`, and `resolution`. Allowed `resolution` values are `progressed`, `respawned`, or `redispatched`. A valid receipt should satisfy `jq -e '(.probe_attempted == true) and (.checkpoint_capture_ts != null) and (["progressed","respawned","redispatched"] | index(.resolution))'`.

False-respawn is as bad as false-no-action. If live capture shows active output, preserve the worker and wait. If live capture shows a clean prompt, send the original dispatch or status probe through the normal NTM path. If live capture shows a shell after respawn, relaunch Codex with exactly `codex --dangerously-bypass-approvals-and-sandbox`, with no model or reasoning flags. If the same worker stalls after redispatch, file or update a bead/fuckup route instead of repeating blind probes.

Doctor should expose `worker_stall_count`, `worker_stall_oldest_age_seconds`, and `.worker_stalls[]` with the receipt fields above. A pre-callback-emit gate should warn when any worker has been `THINKING` beyond the configured threshold with unchanged output and no callback. Cross-session stall events should be fleet-mailed or ledgered so mobile-eats, flywheel, skillos, and client sessions aggregate the same trauma class.

**Why:** Mobile-eats pane 2 stayed `THINKING` on `mobile-eats-7wc` after the 2026-05-04T18:01:39Z dispatch while output stopped advancing and pane 1 kept recording in-flight status. Flywheel pane 4 hit the same shape on `idle-pane-mechanical-hook`: a 434-line draft existed, but no report or callback landed until a recovery nudge. Two independent rediscoveries in one day make this canonical doctrine, not local watcher tuning.

**How to apply:** every INTEGRATE/status loop that reports worker work in-flight must compare current live tail hash and callback state against the prior tick. If no advancement crosses the threshold, emit an L95 stall receipt and run the recovery ladder. Do not skip straight from `THINKING` to respawn, and do not keep emitting in-flight receipts after the no-advancement threshold has been crossed.

**Forbidden outputs:**
- Reporting a worker as healthy in-flight when `THINKING` is unchanged across the stall threshold and no fresh output hash or callback proves advancement.
- Respawning a worker before live capture, non-empty probe, grace wait, and checkpoint capture are all recorded.
- Treating robot activity as the sole truth source for stall or recovery decisions.
- Redispatching a different bead after respawn when the stalled bead remains the active obligation and is still safe to retry.

**Cross-references:** L29 (canonical pane I/O), L70 (same-tick chain-forward), L86 (callback receiver live), L87 (stale error auto-ping recovery), L90 (live capture before pane action), L91 (dispatch delivery receipt), L95 receipt fields above, `feedback_orchestrator_is_the_killer_not_codex.md`, `feedback_dispatch_delivery_validation_required.md`, and `feedback_codex_relaunch_command_canonical.md`.

