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

## L93 — JEFF-ISSUE-REQUIRES-WORKAROUND-RESEARCH-FIRST

---
id: L93
title: Jeff issue requires workaround research first
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: upstream-escalation-without-workaround-research
---

Before proposing or filing any Jeff upstream issue, the orchestrator MUST prove workaround research first. The receipt must show indexed-source mining across the failing repo and relevant Jeff dependency repos with at least 2-3 query phrasings and K>=10 results per query, at least five ranked workaround candidates with source citations, and copy-test receipts for the top two candidates on a disposable copy of the affected substrate. A Jeff issue is warranted only when all five or more workarounds fail copy-test, or when the bug is foundational and no workaround exists.

If a reversible workaround passes copy-test, apply the workaround through the repo's normal validation path and document the upstream evidence instead of filing. If filing is warranted, the issue body must include full repro steps, copy-test evidence for every failed workaround, environment factors such as concurrency, version, and live-vs-copy differences, and a fix direction framed as an observed contract gap rather than a prescriptive patch. L93 extends L66; L66's source-probe/rubric/submission gates are necessary but not sufficient without the workaround-research precondition.

**Why:** v2a1 REINDEX repair rolled back after only shallow attempts, and Joshua corrected the reflex to file a Jeff issue with the question: what workarounds do we have in indexed Jeff sources? The Jeff corpus is already load-bearing substrate, and prior issues show this distinction matters: frankensqlite#85 was intentional behavior with a workaround, while beads_rust#270 was a true upstream repair case only after evidence and dogfood receipt existed.

**How to apply:** any dispatch, callback, or draft containing `jeff issue`, `file upstream`, `Jeff-worthy`, or `escalate to Jeff` must link a preceding `*-workarounds-research-*` task or receipt from the last 24 hours. A mechanical validator may treat the receipt as eligible only when this predicate passes: `jq -e '(.socraticode_queries >= 2 and .socraticode_k_per_query >= 10) and (.workarounds_ranked >= 5) and (.top_workarounds_copy_tested >= 2) and ((.jeff_issue_warranted == false) or (.all_workarounds_failed == true or .foundational_no_workaround == true))'`. Doctor should expose `jeff_issue_pending_without_workaround_research_count`, target `0`, and the issue-filing hook should block when no qualifying workaround-research callback exists.

**Cross-references:** L48 (substrate exhaustion before escalation), L63 (Jeff intel network), L64 (Jeff as mentor), L66 (outbound Jeff issue phased gate), L71 (validate-and-redispatch), L78 (Jeff corpus accretive ingestion), `feedback_jeff_issue_chain.md`, `feedback_jeff_issue_requires_full_workaround_research_first.md`, `reference_jeff_substrate_inventory.md`, `reference_upstream_issues.md`, and the `jeff-issue-chain` skill.

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
