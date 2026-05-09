## L91 — DISPATCH-DELIVERY-IS-A-FOUR-STATE-RECEIPT

---
id: L91
title: Dispatch delivery is a four-state receipt
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: dispatch-transport-ack-mistaken-for-work-started
---

`ntm send` proves transport acceptance only. Dispatch is not counted as active
work until a receipt proves four states: `transport_accepted`,
`prompt_visible_in_target`, `prompt_submitted`, and `work_started`. If any
state is false or unknown after the grace window, classify `not_started`, repair
or re-dispatch, and do not count the worker as busy.

The receipt must name the session, pane, dispatch id, send command, capture
proof, and classification source. A valid probe should fail unless transport was
accepted, a fresh target-pane capture or log proves the prompt crossed the input
boundary, and post-send output indicates the worker began processing the new
dispatch rather than merely echoing queued text.

**Why:** Last-24h evidence includes `mobile-eats-dispatch-health-gate-fail` 11
rows `~/.local/state/flywheel/fuckup-log.jsonl#L455-L467`,
`daily_report_missing_dispatch_gate` 4 rows `#L445-L448`, plus individual
transport/callback rows including `codex-queued-not-submitted` `#L290`,
`worker-callback-composed-not-submitted` `#L329`,
`dispatch-callback-missed` `#L340`, `ntm_dispatch_pasted_but_worker_idle`
`#L368`, and `dispatch_transport_prompt_aborted` `#L371`. Memory cross-ref:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dispatch_delivery_validation_required.md`.

**How to apply:** wrap worker dispatch and callback sends in a four-state
receipt validator; the validator should expose a machine check equivalent to
`jq -e '.transport_accepted and .prompt_visible_in_target and .prompt_submitted and .work_started'`.

**Cross-references:** L50 (Socraticode dispatch contract), L57 (driver proof),
L60 (doctor signal shape), L70 (same-tick chain-forward), L71
(validate-and-redispatch), L80 (DID/DIDNT/GAPS), L86 (callback receiver live),
and `feedback_worker_verify_callback_delivered.md`.

