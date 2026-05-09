## L99 — WORKER-RECOVERY-SLO-180S

---
id: L99
title: Worker recovery SLO 180s
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: silent-frozen-worker-undetected-by-fleet
---

Frozen or failed workers MUST be detected and respawned within 180 seconds. This is the canonical recovery SLO. Detection mechanisms (`frozen-pane-detector` v2, `idle-state-probe`, L95 stall protocol, L91 four-state receipt) are tuned to this budget. The SLO is measured continuously via doctor probe and surfaced in `/flywheel:status`.

**Why:** 2026-05-04 — alps:2 froze and Joshua manually detected it before any flywheel automation flagged it. Default detector thresholds were 300s freeze plus 120s poll, about 7 minutes worst case. The company-outgrowing-founder paradigm requires the system to detect failures faster than the founder can. This aligns with the architecture-health mission anchor: SLOs measure the system, not individuals.

**How to apply:**
- `frozen-pane-detector` v2 thresholds are 90s detect and 30s cadence; timer-identical fast path drops to about 30s for that class.
- Doctor exposes `recovery_latency_p95_seconds_24h` and `recovery_slo_breach_count_24h`.
- `/flywheel:status` surfaces SLO color and breach count.
- `/flywheel:weeklyreflection` consumes the 7d trend; consecutive breaches escalate to substrate change per L98 architecture-health, never to agent shaming.
- Joshua-detected-before-fleet-detected creates an INCIDENTS row plus a structural fix bead.

**Forbidden outputs:**
- Tuning thresholds higher to "reduce noise" without paired SLO measurement.
- Reporting recovery success without latency.
- Agent-level recovery scoring; this is an architecture-level SLO only per L98.
- Threshold tuning that violates per-pane budget caps or creates recovery storms.

**Cross-references:** L85 (idle-state-class), L87 (stale-error-auto-ping), L91 (dispatch-delivery-receipt), L95 (worker-stall-recovery), L98 (architecture-health-measured-not-individuals).

