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

