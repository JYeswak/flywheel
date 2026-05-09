## L98 — ARCHITECTURE-HEALTH-MEASURED-NOT-INDIVIDUALS

---
id: L98
title: Architecture health measured not individuals
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: agent-shaming-vs-system-improvement
---

Fleet performance reports MUST measure system-level architecture health:
reliability, faithfulness, leverage, reuse, coordination, and drift-authoring
trends joined to known-worker manifests. Individual agent names may appear only
as tuple-bound identity pointers needed to aggregate the fleet; rankings,
leaderboards, and performance-review language are forbidden. Findings route to
doctrine, skill, probe, or dispatch-template changes, never to individual-agent
action items.

**Why:** The 2026-05-04 mission lock frames flywheel as the command center for a
company outgrowing its founder. Surveillance theater and agent-shaming destroy
that system goal: they move attention from architecture changes to named-agent
judgment. Donella #2, #3, and #6: encode the system goal, measure the actual
goal, and make information flows trigger structural learning. Canonical anchor:
`~/.claude/projects/-Users-josh-Developer-flywheel/memory/project_self_sustaining_company_paradigm_2026_05_04.md`.

**How to apply:**
- `.flywheel/scripts/architecture-health-rollup.sh` writes 24h, 7d, 30d, and
  90d JSON to `~/.flywheel/fleet-perf/`.
- Every rollup metric has trend, cohort, and counterfactual context; missing
  pairings increment `architecture_health_metric_unpaired_count`.
- Agent-shaming artifacts increment `agent_shaming_report_detected` and are
  non-compliant with the report policy.
- `/flywheel:status` surfaces only the compact architecture-health line.
- `/flywheel:weeklyreflection` must emit `learning_loop_closed=yes|no` and at
  least one architectural change or explicit no-change-warranted rationale.
- `founder_dispose_pct` trending down quarterly is paradigm-success; flat or
  rising trend is paradigm-failure until paired with a structural change.

**Forbidden outputs:**
- Leaderboards of best or worst agents without architecture context.
- Vanity throughput counts without leverage-tier weighting.
- Surveillance metrics that drive no doctrine, skill, or probe change in 30d.
- Goodhart-prone single metrics without a paired quality probe.
- Dashboards demanding daily founder attention for operational state.
- Performance reviews of named agents.
- One-shot dashboards without trend, cohort, and counterfactual.

**Cross-references:** L61 (ecosystem wire-in), L71
(validate-and-redispatch), L85 (idle-state-class-canonical), L91
(dispatch-delivery-receipt), L97 (orch-dispatches-only-to-known-workers), L99
(worker-recovery-slo-180s), L100 (identity primary key is tuple), and the
self-sustaining-company paradigm memory path above.

