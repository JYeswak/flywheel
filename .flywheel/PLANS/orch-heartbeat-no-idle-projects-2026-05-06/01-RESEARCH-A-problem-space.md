---
title: "Phase 1 Research A - Problem-Space Inventory"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 1 Research A - Problem-Space Inventory

Primary input: `/tmp/overnight-velocity-report/SUMMARY.md`.

## 1. Problem Statement

The fleet already had many active observation flows overnight, but lacked a
composition-and-delivery loop. The failure was not "no telemetry." The failure
was "telemetry did not reach the idle orchestrator as a concrete next action."

Evidence from the primary report:

| Signal | Overnight count | Meaning |
|---|---:|---|
| Beads created across flywheel/skillos/alps/mobile-eats | 0 | Work stock did not replenish. |
| Beads closed across same sessions | 1 | Outflow nearly stopped. |
| Cross-orch rows | 33 | Coordination substrate was alive. |
| Fuckup-log rows | 330 | Trauma substrate was alive. |
| Post-callback-reminder recoveries | 262 | Watchers were firing on one class. |
| Codex stuck-detector rows | 441 | Worker liveness substrate was firing. |
| Capacity-halt detections | 0 in report histogram | A live class was invisible to the classifier path. |

The stock that needs control is not "number of logs." It is "orchestrator
attention attached to a current next-action packet."

## 2. Existing Producers

### Work and Backlog Producers

| Producer | Current role | Synthesis needs |
|---|---|---|
| `br ready --json` | Ready bead queue. | Top 3 dispatchable beads by priority/age. |
| `.beads/issues.jsonl` | Append-only issue truth during br fallback. | Created/closed/update velocity by window; open P0/P1 count. |
| `.flywheel/dispatch-log.jsonl` | Dispatch lifecycle. | Stale dispatches, callbacks due, recently closed work. |
| `low-bead-threshold-detector.sh` | Detects too-few ready beads. | If ready count low, propose bead creation/triage, not idle. |
| `gap-hunt-probe.sh` | Finds unconverted gaps. | Convert top findings into repair beads. |
| `josh-request-tick-promote.sh` | Promotes captured Joshua requests. | Surface unread P0/P1 requests as work sources. |
| `inbox-check-tick-step.sh` | Agent Mail inbox work. | Reply/actionable message count and sender/session. |

### Pane and Liveness Producers

| Producer | Current role | Synthesis needs |
|---|---|---|
| `ntm --robot-activity` | Canonical pane state/capacity. | Whether orch pane is idle and workers are waiting or active. |
| `ntm-fleet-health.sh` | Fleet health heartbeat ledger. | Dead/degraded session status and source freshness. |
| `idle-state-probe.sh` | Worker idle-state class. | `dispatching`/`light_queue` counts and threshold age. |
| `codex-template-stuck-detector.sh` | Codex stuck subclass detection. | Current stuck class histogram and recovery action pending. |
| `worker-auto-respawn-watchdog.sh` | Worker auto-respawn/auto-continue recovery. | Recent recoveries, budget exhaustion, unrecovered panes. |
| `peer-orch-freeze-monitor.sh` | Peer orchestrator freeze detection. | Peer orch health and recovery needed. |
| `peer-orch-respawn-permit.sh` | Recovery authorization. | Permit/refuse trace for cross-session recovery. |

### Orchestrator Productivity Producers

| Producer | Current role | Synthesis needs |
|---|---|---|
| `continuous-productivity-detector.sh` | Detects idle orch with work. | Fleet-level stale sessions and work source summary. |
| `peer-orch-productivity-watch.sh` | Classifies peer productivity and composes escalation packets. | Reuse classification and packet shape as source adapter. |
| `peer-orch-blocker-watch.sh` | Finds stale flywheel-class peer blockers. | Include flywheel-owned blocker packets older than 300s. |
| `l70-ticks-punted-counter.sh` | Detects no-punt violations. | If previous tick named action and did not act, repeat action. |
| Stop hooks `orch-no-punt` and `orch-donella-trace` | Output gates. | Validate heartbeat prose does not ask Joshua or omit Donella trace. |

### Validation and Delivery Producers

| Producer | Current role | Synthesis needs |
|---|---|---|
| `dispatch-delivery-verify.sh` | Verifies prompt crossed input boundary. | Heartbeat delivery must have equivalent receipt. |
| `callback-receipt-validator.sh` | Reruns L112 from worker callback. | Do not summarize stale DONE claims as work. |
| `orchestrator-callback-artifact-validator.sh` | Checks required artifacts before summary. | Use to rank validation debt. |
| `tick-hook-firing-verifier.sh` | Proves tick primitives fired. | Heartbeat primitive must register and fire like other tick hooks. |
| `tick-receipt-validator.sh` | Tick receipt validation. | Heartbeat closeout must be machine-verifiable. |

### Learning and Doctrine Producers

| Producer | Current role | Synthesis needs |
|---|---|---|
| `fuckup-log.jsonl` | Durable trauma events. | Top classes by window; new high severity rows. |
| `memory-rule-gate-parity-ledger.jsonl` | META-RULE structural parity. | Unwired/partial rules become work. |
| `cross-orch-coordination.jsonl` | Cross-session messages. | Unacknowledged blocker/request rows. |
| `substrate-loop-contract.jsonl` | Contract declarations. | Missing consumer/auto-fire/drain receipt fields. |

## 3. Ledger Inventory

Sample ledgers with meaningful current stock:

| Ledger | Recent observed role |
|---|---|
| `codex-stuck-detector.jsonl` | 1811 rows, last updated 2026-05-06T04:34Z. |
| `fuckup-log.jsonl` | 1640 rows, last updated 2026-05-06T04:34Z. |
| `josh-requests.jsonl` | 1175 rows, request backlog stock. |
| `ntm-fleet-health.jsonl` | 1000 rows, fleet health history. |
| `loop-driver-runs.jsonl` | 840 rows, driver firing evidence. |
| `tick-driver.jsonl` | 189 rows, tick primitive firing evidence. |
| `peer-orch-freeze-monitor.jsonl` | 186 rows, peer orch monitor evidence. |
| `cross-orch-coordination.jsonl` | 145 rows, cross-session packet history. |
| `l70-ticks-punted.jsonl` | 194 rows, no-punt violations/receipts. |
| `low-bead-threshold-detector-ledger.jsonl` | 34 rows, ready-stock warnings. |
| `gap-hunt.jsonl` | 22 rows, gap backlog. |
| `dispatch-delivery-verify-ledger.jsonl` | 2 rows, transport receipt history. |
| `callback-receipt-validator-ledger.jsonl` | 2 rows, callback validation history. |
| `orchestrator-callback-artifact-validator-ledger.jsonl` | 1 row, artifact validation history. |

The ledgers exist, but they do not converge into a single current action packet.
Several are also stale relative to their expected cadence, which should itself
be an input to heartbeat synthesis.

## 4. Failure-Mode Table

| Failure mode | Overnight symptom | Required heartbeat response |
|---|---|---|
| Observer-only automation | 441 stuck-detector rows, 330 fuckup rows, near-zero bead velocity. | Compose and deliver a next-action packet when orch is idle. |
| Classifier coverage gap | Capacity-halt observed by Joshua but not in histogram. | Treat detector unknown/stale class spikes as work sources, not as OK. |
| Recovery without throughput | 262 recovery rows for post-callback reminder, but no bead movement. | Include "recovery fired but no work moved" as a stale-loop signal. |
| Cross-orch coordination without action | 33 rows but peer velocity flat. | Pull unacknowledged or flywheel-owned blocker rows into the packet. |
| Prompt delivery mistaken for work | Prior L91 trauma. | Every heartbeat injection needs delivery and work-started receipt. |
| Founder bottleneck fallback | Asking Joshua to interpret logs. | Packet names orchestrator actions only; no Joshua ask unless TRUE blocker. |
| Duplicate prompt spam | Repeated cron sends same prose. | Idempotency hash over action triplet + source offsets. |
| Cross-session overreach | Flywheel injects into peer pane while peer is active. | Per-session local heartbeat first; cross-session only behind permit and topology. |

## 5. Synthesis Requirements

The heartbeat composer needs source adapters that emit a common shape:

```json
{
  "source": "codex-stuck-detector",
  "stock": "stuck_workers",
  "count": 3,
  "severity": "high",
  "freshness_seconds": 60,
  "examples": ["flywheel:2 model_at_capacity_halt"],
  "recommended_action": "dispatch recovery verifier or continue budget audit",
  "source_ref": "~/.local/state/flywheel/codex-stuck-detector.jsonl#offset"
}
```

The composer must then select the top three actions by priority:

1. Recovery needed to restore workers or orchestrators.
2. Ready P0/P1 work with idle capacity.
3. Work-source creation when ready stock is low.
4. Validation debt that blocks trust in closed or active work.
5. Learning/doctrine stock that has crossed threshold.

## 6. Research-A Conclusion

Build no new detector first. The first implementation bead should build a
read-only composer that consumes existing producer outputs and produces one
heartbeat packet plus a machine-readable decision row. Delivery should remain
off until idempotency and pane-state gates are proven by fixtures.
