## mobile-eats-dispatch-health-gate-fail — already covered by L91+L92 (2026-05-09 cross-reference)

Date: 2026-05-09

Class: `mobile-eats-dispatch-health-gate-fail`

Event Count: 11 events on 2026-05-04 (clustered 04:49-05:37Z, mobile-eats session, pane 1, agent claude); zero recurrence in the 5 days since.

Severity: low (high in raw fuckup-log because the event family was severity:high; class-level severity is low because the contract has been reframed and recurrence is zero)

Cost: dispatcher refused 11 mobile-eats dispatches over 48 minutes because doctor errors contained `beads_db_health_failed`, `daily_report_missing`, `agent_mail_fd_doctor_fail`, and at one point `storage_low_headroom` — all while pane 2 was visibly WAITING. Same trauma family as `daily_report_missing_dispatch_gate` (4 events on 2026-05-04 04:06-04:21Z, immediately preceding this 11-event cluster on the same session/pane). The pattern is dispatch_gate treating telemetry-class doctor signals (beads-db freshness, daily-report freshness, agent-mail FD pressure, storage headroom) as hard structural blockers rather than non-blocking warnings.

Root Cause: same as `daily_report_missing_dispatch_gate` — dispatch_gate's error-class predicate did not partition between structural blockers (br-db corruption, pane unhealthy, identity drift) and telemetry-class signals. A WAITING worker was therefore gated by operational telemetry errors rather than true substrate faults. The 04:49-05:37Z cluster is the same 2026-05-04 morning's continuation: the `daily_report_missing` signal merged with sibling telemetry classes (`beads_db_health_failed`, `agent_mail_fd_doctor_fail`, `storage_low_headroom`) under the umbrella name `mobile-eats-dispatch-health-gate-fail` once that became the louder symptom.

Forever-Rule (already shipped, 2026-05-04): L91 (`dispatch-delivery-is-a-four-state-receipt`, `.flywheel/rules/L045-L91-dispatch-delivery-is-a-four-state-receipt.md`) and L92 (`audit-findings-route-by-data`, `.flywheel/rules/L046-L92-audit-findings-route-by-data.md`) reframed dispatch decisions to use machine-readable four-state receipts plus data-routed disposition rather than treating any non-zero doctor signal as a hard block. The same rules cover this trauma class as cover its sibling `daily_report_missing_dispatch_gate`.

Fix Applied/Status: Doctrine landed 2026-05-04 in L91+L92 (same day as the 11 events). No source-code change to dispatch-capacity-gate.sh was needed because the L91 contract reframed dispatch decisions: a worker is dispatchable if the four-state receipt (transport_accepted + prompt_visible_in_target + prompt_submitted + work_started) is achievable, irrespective of telemetry-class doctor noise. Zero recurrence since 2026-05-04T05:37:18Z (newest event timestamp) confirms the gate refinement took. This is the same fix that closed `daily_report_missing_dispatch_gate`; this entry is the parallel cross-reference for the broader `mobile-eats-dispatch-health-gate-fail` umbrella class.

Recurrence Prevention: The L56 ladder probe (`doctrine-ladder-promote.sh`) inspects `~/.claude/skills/.flywheel/INCIDENTS.md`, `~/.claude/skills/*/references/INCIDENTS.md`, `$REPO/INCIDENTS.md`, and `$REPO/AGENTS.md` for class-name coverage but still does NOT scan `.flywheel/rules/` (verified 2026-05-09 against `default_incident_paths()` at `.flywheel/scripts/doctrine-ladder-promote.sh:39-50`). This is the same gap noted in the `daily_report_missing_dispatch_gate` cross-reference 5 hours earlier. This INCIDENTS.md entry closes the loop for `mobile-eats-dispatch-health-gate-fail` so the ladder finds coverage on its next sweep. Donella leverage point #5 (rules) is wired to leverage point #6 (information flow) by giving the ladder probe a discoverable INCIDENTS surface.

Evidence:
- Trauma rows: `~/.local/state/flywheel/fuckup-log.jsonl` 11 rows on 2026-05-04 (04:49:25Z, 04:52:02Z, 04:57:18Z, 05:01:35Z, 05:06:37Z, 05:11:39Z, 05:16:42Z, 05:21:44Z, 05:26:47Z, 05:31:49Z, 05:37:18Z); all session=mobile-eats pane=1 agent=claude commit_sha=2c02e29.
- Sibling incident: `INCIDENTS.md` entry for `daily_report_missing_dispatch_gate` (line 7514, dated 2026-05-09); same trauma family, immediately preceding fuckup-log cluster (04:06-04:21Z).
- L91 rule: `.flywheel/rules/L045-L91-dispatch-delivery-is-a-four-state-receipt.md`.
- L92 rule: `.flywheel/rules/L046-L92-audit-findings-route-by-data.md`.
- Promote script: `.flywheel/scripts/doctrine-ladder-promote.sh` (`default_incident_paths` at L39-50 still omits `.flywheel/rules/`).
- Bead: `flywheel-wb6oc` (this dispatch).
- Memory cross-ref: `feedback_dispatch_delivery_validation_required.md`, `feedback_audit_findings_are_data_decided_not_joshua_gated.md`.

Follow-up Bead Filed (separate dispatch): None — the underlying class is already covered by L91+L92 (same as for the sibling cross-reference). The `default_incident_paths()` extension to scan `.flywheel/rules/*.md` remains a future improvement that is documented in this entry and the sibling but intentionally not filed (per `feedback_calibrate_test_to_actual_contract_before_filing_upstream`: when L56 ladder's known-good coverage surface is doctrine, calibrate the gate to that coverage rather than treat the known-good state as a bug).

