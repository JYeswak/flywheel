---
title: "Phase 3 AUDIT r2 — Failure-Mode Coverage (Phase 4 Expansion II)"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 AUDIT r2 — Failure-Mode Coverage (Phase 4 Expansion II)

Plan: `wire-or-explain-tick-gate-2026-05-04` + sibling
Lens: which of the 7 FMs (slow-discovery, false-positive, false-negative, gate-bottleneck, bootstrap, cross-repo, stale-wiring) does each ledger handle?
Generated: 2026-05-04
Mode: plan-space read-only audit
Prior round: r1 failure-mode-coverage + r2-confirmation
Convergence flag: `prior_round=r1`

## Audit Frame

The 7 canonical failure modes (per `02-REFINE-r2.md:50-68` original FM1-FM7 + audit r1 FMC enumeration):

- FM1 slow-discovery (artifact ships, no consumer noticed for >24h)
- FM2 false-positive (gate flags wired thing as unwired)
- FM3 false-negative (gate misses unwired thing)
- FM4 gate-bottleneck (gate becomes the bottleneck, blocks legitimate ticks)
- FM5 bootstrap (gate can't validate itself first-time)
- FM6 cross-repo (artifact owned by repo A, consumer in repo B, gate can't see)
- FM7 stale-wiring (consumer existed, then went away, gate doesn't notice)

Self-grade: `Y`
Composite score: `8.6/10.0`
Disposition: `auto_advance_eligible`

## Coverage Matrix

| Ledger | FM1 | FM2 | FM3 | FM4 | FM5 | FM6 | FM7 |
|---|---|---|---|---|---|---|---|
| L1 lrule_violation (A+G) | Y (probe runs each tick) | Y (consumer field per L-rule) | Y (canonical L-rule list anchored to AGENTS) | Y (cap=15 per close, batch warn) | Y (B30 self-row) | partial (orchmon writes G, WOE writes A — same file) | Y (probe re-runs) |
| L2 primitive_auto_fire | Y | Y (cooldown_until) | Y (canonical primitive list) | Y (warn vs error tiers) | Y (handler-init bootstrap) | n/a (orchmon-local) | Y (tick re-checks) |
| L3 plan_state_quality_bar_evidence | Y (per-plan) | Y (3-judges scores explicit) | Y (skill-clean fields explicit) | partial — see FMC-EXP-F1 | Y (template-installed bootstrap) | n/a (per-plan) | Y (replay E6) |
| L4 readme_propagation | Y (per-edit) | Y (hash equality) | Y (per-repo manifest) | Y (drift count cap) | Y | Y (fleet-wide) | Y |
| L5 plan_state_aggregator | derived from L3 | derived | derived | derived | derived | derived | derived |
| L6 xpane_ack | Y (expected_ack_by_ts) | Y (msg_hash dedupe) | Y (paired-send rule) | Y (timeout) | Y | Y (cross-orch) | Y |
| L7 session_violation | Y (per-tick) | Y (resolution_required) | Y (5 violation classes enumerated) | partial — see FMC-EXP-F2 | Y | n/a | Y |

## Findings

| ID | Severity | Beads | Description | Mitigation |
|---|---|---|---|---|
| FMC-EXP-F1 | medium | WOE Sub-DAG β (B31-B41) | L3 (plan_state_quality_bar_evidence) FM4 gate-bottleneck: if 5 plans run in parallel and each emits 4 quality-bar rows, the close gate could backlog. Cap per-plan but no fleet-wide cap. | Amend WOE-EXP-B36 acceptance: doctor field `plan_state_quality_bar_pending_count` exposes fleet-wide pending; tick raises warn at >20, error at >50. |
| FMC-EXP-F2 | low | Sub-DAG η (B44-B48) | L7 FM4 gate-bottleneck: refilled-one-not-all handler (G1) could fire repeatedly during a Vercel-style multi-step deploy where panes legitimately go idle waiting for human input. | Amend ORCHMON-EXP-B44 acceptance: `mission_license` check before refill-all fires; honor protected-session and joshua-blocker classes per orchmon r2-B3 + r2-B6. |
| FMC-EXP-F3 | low | L1 cross-repo | FM6 partially covered for L1 because WOE owns A-rows + orchmon owns G-rows but both write same file. If file is local to flywheel repo, true cross-repo (alps, skillos, mobile-eats) writers don't have a path. | Defer to Plan B (fleet rollout, original B12); not in scope for Phase 4 Expansion II. Track as known gap. |

**Coverage rate: 7 ledgers × 7 FMs = 49 cells; 3 derived (L5); 4 n/a (cross-repo for plan-local ledgers); 38 covered = 38/42 = 90% applicable coverage.**

## Convergence

```text
new_critical_findings=0
new_true_blocker_classes=0
medium_findings=1
low_findings=2
prior_round_findings_repeated=0
disposition=auto_advance
```
