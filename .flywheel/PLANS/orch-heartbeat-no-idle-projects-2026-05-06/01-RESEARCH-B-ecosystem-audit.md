---
title: "Phase 1 Research B - Ecosystem Audit"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 1 Research B - Ecosystem Audit

Primary input: `/tmp/overnight-velocity-report/SUMMARY.md`.

## 1. Source-A Skills Library

Query used: `orchestration heartbeat tick driver agent monitoring fleet observability no idle projects`.

| Skill | Posture | Applied rule |
|---|---|---|
| `agent-monitoring` | ADOPT | Track heartbeat freshness, task completion, queue depth, cascade indicators. |
| `loop-enforcement` | ADOPT | Heartbeat ticks must be a guarded decision protocol, not log appends. |
| `observability-platform` | ADOPT | Use structured rows with bounded fields and source refs. |
| `uptime-monitoring` | EXTEND | Use liveness/readiness distinction for orch panes. |
| `socraticode` | ADOPT | K>=10 preflight completed before plan claims. |
| `jeff-convergence-audit` | ADOPT | Audit idempotency, founder-bottleneck, and cross-session authorization before code. |

No skill gap was found for the general monitoring pattern. The local flywheel
gap is composition-specific: existing monitoring skills do not know the repo's
30 ledgers and NTM pane topology.

## 2. ADOPT

| Primitive | Why adopt |
|---|---|
| `session-topology.jsonl` latest-wins lookup | Already canonical for orchestrator/callback/worker pane roles. Prevents hardcoded pane drift. |
| `ntm --robot-activity` | Canonical capacity and pane-state source. Avoids stale scrollback-only decisions. |
| `ntm send --file --no-cass-check` | Canonical prompt delivery surface for long generated packets. |
| L91 dispatch-delivery receipt shape | Delivery is not enough; heartbeat must prove prompt visible and work started or classify `not_started`. |
| `peer-orch-productivity-watch.sh` packet shape | Already composes productivity escalation packet from work sources. Reuse as input or sibling. |
| `tick-driver-manifest.json` | Any recurring heartbeat primitive must be registered as process substrate. |
| `loop-driver-runs.jsonl` and `tick-driver.jsonl` | Driver proof and source freshness should be direct inputs. |
| Stop hooks `orch-no-punt` and `orch-donella-trace` | Heartbeat prose must pass existing output gates before injection. |

## 3. EXTEND

| Primitive | Extension |
|---|---|
| `continuous-productivity-detector.sh` | Feed its "idle with work" result into heartbeat priority instead of only surfacing status. |
| `low-bead-threshold-detector.sh` | Convert low ready-stock signal into "file/triage work-source bead" action. |
| `gap-hunt-probe.sh` | Convert top gap rows into heartbeat work-source candidates. |
| `codex-template-stuck-detector.sh` | Treat unknown/stable spikes and recovery budgets as action candidates. |
| `worker-auto-respawn-watchdog.sh` | Include recent recoveries and budget exhaustion so recovery without velocity is visible. |
| `manager-loop` plan A0 read model | Heartbeat should eventually consume manager-state, but must not wait for it. First ship can build a narrow read model that is later folded into manager-state. |
| `ntm-fleet-health.sh` | Use fleet health as readiness input, not as a restart authority. |

## 4. AVOID

| Anti-pattern | Reason |
|---|---|
| Cross-session central injector first | Raises authorization and false-interrupt risk before local loop is proven. |
| Reusing `notify` as normal heartbeat outflow | Converts missing information flow into founder attention demand. |
| Sending while orch pane is THINKING | Interrupts valid work and creates prompt collision. |
| Re-injecting identical prose every cron | Creates alert fatigue inside the pane. |
| Raw text-only heartbeat with no ledger row | Recreates marker-only loop trauma. |
| Composer that asks Joshua to choose | Violates L70/L101 and existing no-punt gates. |
| New monolithic source of truth | Duplicates manager-loop authority work and risks replacing owned ledgers prematurely. |

## 5. Donella Map By Existing Primitive

| Existing primitive | Meadows leverage point | Stock/flow affected |
|---|---|---|
| `low-bead-threshold-detector.sh` | #6 information flows | Ready-work stock visibility. |
| `l70-ticks-punted-counter.sh` | #5 rules | Same-tick action rule enforcement. |
| `peer-orch-productivity-watch.sh` | #4 self-organization + #6 information | Peer sessions route idle-with-work to action packets. |
| `worker-auto-respawn-watchdog.sh` | #4 self-organization | Workers recover without Joshua. |
| `tick-driver-manifest.json` | #5 rules | Recurring primitives must be registered and verified. |
| `dispatch-delivery-verify.sh` | #6 information | Transport acceptance becomes prompt-visibility truth. |
| `callback-receipt-validator.sh` | #5 rules | Done claims are checked before summary. |
| `fuckup-log.jsonl` | #4 self-organization | Events can promote into doctrine, tests, beads. |

## 6. Ecosystem Decision

Use a single composer contract with many source adapters. Do not make each
producer send its own prose. Producer-owned scripts remain authoritative for
their facts; the heartbeat layer owns only ranking, idempotency, and delivery.

Recommended first implementation sequence:

1. Read-only composer over a small source set: bead velocity, robot activity,
   stuck-detector histogram, fuckup top classes, cross-orch blockers.
2. Idempotency/delivery ledger.
3. Flywheel-local injection only.
4. Doctor/status fields.
5. Peer-session rollout behind per-session config and topology checks.

## 7. Cross-Cutting Findings

- Driver proof is non-negotiable: L57 says plist/state markers are not drivers.
- Delivery proof is non-negotiable: L91 says transport accepted is not work.
- The heartbeat must be quiet when the orchestrator is active.
- The heartbeat must be opinionated when the orchestrator is idle and work
  exists.
- The packet should include a skills citation so the next action inherits
  source-a doctrine.
