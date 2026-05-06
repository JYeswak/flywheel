# Phase 2 Refine r2 - Converged Plan

Primary empirical input: `/tmp/overnight-velocity-report/SUMMARY.md`.

Diff from r1: under 5% conceptual change. r2 keeps the same architecture and
tightens the boundaries: flywheel-local first, source adapters read-only,
delivery gated by live idle state, and peer rollout deferred behind config and
authorization tests.

## 1. Converged Thesis

The fleet's overnight idle state was not caused by lack of detector activity.
The primary report shows detector and recovery flows were active:
441 stuck-detector rows, 330 fuckup rows, 262 post-callback-reminder recovery
rows, and 33 cross-orch rows. Yet bead velocity across flywheel/skillos/alps/
mobile-eats was effectively zero.

The missing component is an orchestrator-heartbeat synthesis loop:

```text
existing ledgers + robot state
  -> ranked action candidates
  -> idle/idempotency/authorization gate
  -> Donella/Jeff next-action packet
  -> NTM delivery
  -> four-state delivery receipt
  -> velocity and work-started measurement
```

## 2. First-Ship Boundary

First implementation must be flywheel-local and read-mostly:

- Target only `flywheel:1`.
- Read existing ledgers and robot surfaces.
- Write only new heartbeat snapshot/decision/delivery ledgers.
- Do not mutate existing producer scripts.
- Do not install peer-session delivery.
- Do not notify Joshua for ordinary idle-with-work.

This avoids cross-session authorization risk while proving the core information
flow on the session that owns the substrate.

## 3. Source Adapter Set

First source set:

| Source | Candidate role |
|---|---|
| Bead velocity + ready queue | Names dispatchable work and detects no new work stock. |
| `ntm --robot-activity` | Names orchestrator/worker capacity and protects active panes. |
| `codex-stuck-detector.jsonl` | Names stuck classes, unknown spikes, recovery misses. |
| `fuckup-log.jsonl` | Names repeated trauma classes crossing action thresholds. |
| `cross-orch-coordination.jsonl` | Names stale flywheel-owned peer blockers. |
| `l70-ticks-punted.jsonl` and delivery ledgers | Names prior no-punt or prompt-delivery debt. |

Each adapter must emit normalized candidates with source refs and freshness.

## 4. Gate Policy

Delivery decision is `deliver`, `suppress`, or `error`.

Deliver only when:

- target pane comes from latest topology or explicit local config,
- live robot state says idle/waiting,
- idle age >=300s,
- ranked candidate triplet has at least one `blocks_velocity=true`,
- no duplicate triplet hash in 30 minutes,
- session budget under 3 deliveries/hour,
- source freshness passes the adapter threshold.

Suppress when:

- target is active/thinking/generating,
- no work exists,
- duplicate packet exists,
- source freshness is stale,
- target is not allowlisted,
- action maps to TRUE Joshua blocker.

Error when:

- topology cannot identify target,
- robot activity cannot be read,
- packet cannot be rendered,
- delivery verifier cannot classify after retry.

## 5. Packet Contract

The packet is action prose, not a report.

Required shape:

1. `PHASE: ORCH_HEARTBEAT`.
2. Donella trace: stock, flow break, leverage point.
3. Data summary: velocity, ready work, worker/orch state, top trauma classes,
   cross-orch blockers.
4. Next-action triplet: three concrete actions max, each with a source ref.
5. Skills citation: at least one source-a skill or explicit `skills_gap=none`.
6. Fail-safe: verify live state and write a no-action receipt if stale.

Forbidden shape:

- Asking Joshua to decide.
- Naming "monitoring fired" as success when work did not move.
- Omitting source refs.
- Sending generic motivation or status prose without actions.

## 6. Driver And Receipt Contract

The recurring process must follow L57/L116:

- registered in `tick-driver-manifest.json`,
- writes a heartbeat driver row on every fire,
- exposes doctor freshness,
- renders dry-run packet before apply,
- delivery uses NTM only,
- delivery verifier records four-state receipt.

Success is not "plist exists." Success is fresh driver row plus visible prompt
plus work-started or explicit no-action receipt.

## 7. Metrics

Primary metric: `orch_idle_with_work_age_seconds_max`.

Secondary metrics:

- `orch_heartbeat_delivery_success_rate_24h`
- `orch_heartbeat_work_started_rate_24h`
- `orch_heartbeat_duplicate_suppressed_count_24h`
- `orch_heartbeat_source_stale_count`
- `fleet_bead_velocity_created_overnight`
- `fleet_bead_velocity_closed_overnight`
- `post_recovery_no_velocity_count`

Target:

- No allowlisted orch idle-with-work >10 minutes.
- Duplicate delivery suppressed, not repeated.
- Delivery success >95% for idle targets.
- Work-started >80% within one cadence.

## 8. Bead DAG Preview

| ID | Priority | Title | Acceptance |
|---|---:|---|---|
| HB-B0 | P0 | heartbeat schemas and fixtures | Candidate/snapshot/decision/delivery schemas validate fixtures. |
| HB-B1 | P0 | read-only composer | Reproduces overnight velocity summary classes from fixtures. |
| HB-B2 | P0 | idle/idempotency gate | Deliver/suppress/error fixture matrix passes. |
| HB-B3 | P0 | flywheel-local delivery verifier | Four-state receipt validates success and not-started cases. |
| HB-B4 | P1 | tick driver and doctor fields | Manifest registration and doctor freshness pass. |
| HB-B5 | P1 | morning report projection | Regenerates overnight report from snapshot contract. |
| HB-B6 | P1 | per-session config and peer allowlist | Peer delivery disabled by default, explicit allowlist required. |
| HB-B7 | P1 | cross-session authorization/refusal tests | Active pane, protected session, stale topology all refuse. |
| HB-B8 | P2 | manager-state integration | Composer can consume manager-state when A0 is available. |

## 9. Convergence Decision

Phase 2 is converged. r2 makes no architectural reversal from r1; it only
clarifies the first-ship boundary and acceptance metrics. Proceed to Phase 3
audit.
