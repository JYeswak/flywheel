## L90 — PANE-ACTION-PLAN-REQUIRES-LIVE-CAPTURE

---
id: L90
title: Pane action plan requires live capture
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: orchestrator-pane-action-without-live-truth
---

Before any destructive, interrupting, or recovery pane action, the orchestrator
MUST produce a pane-action receipt from fresh live capture. Robot activity,
stale error text, pane title, old health JSON, or capacity math are hints, not
authority. Clean agent prompt means dispatch/no-op; active work means wait;
unknown means classify unknown and do not destroy.

Required receipt fields are `session`, `pane`, `capture_ts`,
`capture_provenance`, `visible_prompt_class`, `activity_state`,
`target_action`, `allowed_by_rule`, `forbidden_actions_checked`, and
`recovery_postcondition`. A valid probe should fail unless
`capture_provenance == "live"`, `capture_ts` is within the freshness window,
and destructive actions are blocked unless `visible_prompt_class` proves a
recoverable shell or confirmed-dead state.

**Why:** Last-24h fuckup-log evidence shows 38 rows across pane/capacity action
classes: `worker_capacity_gate_failed` 12 rows
`~/.local/state/flywheel/fuckup-log.jsonl#L312-L327`,
`mobile-eats-dispatch-health-gate-fail` 11 rows `#L455-L467`,
`worker-pane-not-waiting-integrate-blocker` 6 rows `#L399-L414`,
`worker_capacity_gate_false_block` 5 rows `#L328-L344`, and
`integrate_worker_not_waiting` 4 rows `#L351-L359`. Memory cross-ref:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrator_is_the_killer_not_codex.md`.

**How to apply:** enforce a pane-action receipt schema and validator before any
pane-touching action; the validator should expose a machine check equivalent to
`jq -e '.capture_provenance == "live" and (.forbidden_actions_checked | length) > 0 and .allowed_by_rule == true'`.

**Cross-references:** L29 (NTM-only pane I/O), L57 (loop marker is not driver),
L67 (truth source must be live), L71 (validate-and-redispatch), L85 (idle state
class canonical), L87 (stale error auto-ping recovery), and
`feedback_probe_shape_ambiguity_is_not_joshua_gate.md`.

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

## L92 — AUDIT-FINDINGS-ROUTE-BY-DATA

---
id: L92
title: Audit findings route by data
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: audit-findings-joshua-gated-after-data-verdict
---

Audit findings are routed by severity, confidence, coverage, and disposition.
Confirmed critical/high findings halt or create first-wave mitigation beads;
medium/low findings route to refine, polish, or follow-up beads. Zero new
critical/high findings plus converged coverage advances automatically.

Joshua decides product intent, business priority, explicit override,
destructive ops, and security/secret/PHI only. A plan/audit pipeline must not
turn already-scored findings into a new Joshua-disposes pause when the audit
lenses have produced a converged verdict and mechanical routing data.

**Why:** Last-24h evidence includes `three_q_surface_gap` 6 rows
`~/.local/state/flywheel/fuckup-log.jsonl#L376-L476`,
`daily-report-missing-integrate-blocker` 4 rows `#L402-L413`, and
`daily_report_missing_dispatch_gate` 4 rows `#L445-L448`. Memory cross-ref:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_audit_findings_are_data_decided_not_joshua_gated.md`.

**How to apply:** route Phase 3 audit outputs with a severity/composite matrix;
the validator should expose a machine check equivalent to
`jq -e '(.critical_count == 0) and (.composite >= 7) and ((.lens_disagreement // 0) < 2) and (.coverage_converged == true)'` for auto-advance, while critical/high blockers emit mitigation beads instead of prose questions.

**Cross-references:** L52 (issues become beads or no-bead receipts), L56
(promotion ladder), L70 (same-tick chain-forward), L71
(validate-and-redispatch), L80 (closed-bead audit mining), L88 (three-judges
publishability bar), and `feedback_probe_shape_ambiguity_is_not_joshua_gate.md`.
