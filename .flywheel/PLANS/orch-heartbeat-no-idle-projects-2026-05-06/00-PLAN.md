# Orch Heartbeat No Idle Projects - Canonical Plan

Status: converged through Phase 2, audited through Phase 3 in this plan arc.

Primary empirical input: `/tmp/overnight-velocity-report/SUMMARY.md`.

## Mission

Create an orchestrator-heartbeat synthesis loop that prevents allowlisted
orchestrator sessions from going stale when existing ledgers show work,
recovery debt, validation debt, or peer blockers.

The loop converts existing telemetry into a concise next-action packet and
delivers it only when the target orchestrator is idle and safe to prompt.

## Why

The overnight report showed active observation without throughput:

- 441 codex stuck-detector rows.
- 330 fuckup-log rows.
- 262 post-callback-reminder recovery rows.
- 33 cross-orch coordination rows.
- 0 created beads and only 1 closed bead across the tracked fleet.

That is not a detector shortage. It is a broken information/action flow.

## Meadows Diagnosis

Boundary: flywheel-controlled NTM sessions and orchestrator panes.

Stock: orchestrator attention attached to current next-action context.

Inflow: synthesized action packets derived from current ledgers and robot state.

Outflow: dispatches, repair beads, validation reruns, and cross-orch responses.

Broken loop: observations accumulate but do not reach idle orchestrators as
actionable prompts.

Leverage: Meadows #6 information flows, with #5 rules for delivery/idempotency
and #4 self-organization for source adapter extensibility.

## First-Ship Boundary

First implementation is flywheel-local:

- target `flywheel:1` only,
- no peer-session prompt injection,
- read existing ledgers and robot surfaces,
- write only heartbeat-owned snapshot/decision/delivery ledgers,
- no mutation of producer scripts,
- no normal-path Joshua notification.

Peer rollout happens only after the local loop proves quietness and delivery
truth.

## Architecture

```text
source adapters
  -> normalized candidates
  -> heartbeat snapshot
  -> ranker/composer
  -> idle + idempotency + authorization gate
  -> packet renderer
  -> ntm delivery
  -> four-state delivery receipt
  -> doctor/status metrics
```

## Candidate Sources

First source set:

1. Bead velocity and ready P0/P1 queue.
2. NTM robot activity for target session.
3. Codex stuck-detector histogram and unrecovered panes.
4. Fuckup-log top classes and new high-severity rows.
5. Cross-orch flywheel-class blockers older than threshold.
6. L70/no-punt and dispatch-delivery/callback validation debt.

## Candidate Schema

Required fields:

- `schema_version`
- `session`
- `source`
- `source_ref`
- `stock`
- `severity`
- `count`
- `freshness_seconds`
- `summary`
- `recommended_action`
- `blocks_velocity`

## Delivery Gate

Deliver only when:

- latest topology/config names the target orch pane,
- live robot state says idle/waiting,
- idle age >=300s,
- at least one ranked candidate blocks velocity,
- no same action-triplet hash in the last 30 minutes,
- delivery budget below 3 per session per hour,
- source freshness passes thresholds.

Suppress when:

- target pane is active/thinking/generating,
- no work exists,
- duplicate packet exists,
- source freshness is stale,
- target is not allowlisted,
- action maps to a TRUE Joshua blocker.

Error when:

- topology is missing/ambiguous,
- robot activity is unavailable,
- packet render fails,
- delivery verification cannot classify after retry.

## Packet Template

Required sections:

1. `PHASE: ORCH_HEARTBEAT`.
2. Donella trace: stock, flow break, leverage point.
3. Data summary: velocity, ready work, worker/orch state, top trauma classes,
   cross-orch blockers.
4. Next-action triplet: three actions max, each with source ref.
5. Skills citation: source-a skill or explicit no-gap note.
6. Fail-safe: verify live state and write no-action receipt if stale.

Forbidden:

- asking Joshua to choose,
- status-only prose,
- source-free action claims,
- counting delivery as work-started.

## Driver Contract

The recurring primitive must be process substrate:

- registered in `tick-driver-manifest.json`,
- writes a fire row each tick,
- supports dry-run and apply,
- exposes doctor fields,
- uses NTM for delivery,
- verifies four-state delivery.

This follows L57 and L116: marker files and plist presence are not enough.

## Metrics

Primary:

- `orch_idle_with_work_age_seconds_max`.

Secondary:

- `orch_heartbeat_delivery_success_rate_24h`
- `orch_heartbeat_work_started_rate_24h`
- `orch_heartbeat_duplicate_suppressed_count_24h`
- `orch_heartbeat_source_stale_count`
- `fleet_bead_velocity_created_overnight`
- `fleet_bead_velocity_closed_overnight`
- `post_recovery_no_velocity_count`

Targets:

- No allowlisted orch idle-with-work >10 minutes.
- Delivery success >95% for idle targets.
- Work-started >80% within one cadence.
- Duplicate packets are suppressed, not resent.

## Bead DAG Preview

| ID | Priority | Title | Depends on |
|---|---:|---|---|
| HB-B0 | P0 | heartbeat schemas and fixtures | none |
| HB-B1 | P0 | read-only composer | HB-B0 |
| HB-B2 | P0 | idle/idempotency gate | HB-B1 |
| HB-B3 | P0 | flywheel-local delivery verifier | HB-B2 |
| HB-B4 | P1 | tick driver and doctor fields | HB-B3 |
| HB-B5 | P1 | morning report projection | HB-B1 |
| HB-B6 | P1 | per-session config and peer allowlist | HB-B4 |
| HB-B7 | P1 | cross-session authorization/refusal tests | HB-B6 |
| HB-B8 | P2 | manager-state integration | HB-B5 |

Phase 4 must convert this preview into real beads, incorporating the Phase 3
audit findings below.

## Audit Status

Phase 3 audit disposition: `auto_advance`.

No TRUE Joshua blocker class fires. Audit findings are implementation-quality
beads for Phase 4, not pause conditions.
