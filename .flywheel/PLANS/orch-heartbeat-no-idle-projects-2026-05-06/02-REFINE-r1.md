# Phase 2 Refine r1 - Integrated Plan

Primary input remains `/tmp/overnight-velocity-report/SUMMARY.md`.

## 1. Thesis

The overnight failure was a missing action-information loop. The fleet had
detectors, ledgers, and watchers, but no recurring composer that converted those
signals into a concrete, delivered, receipt-backed orchestrator prompt while the
orchestrator was idle.

The plan is therefore not "build another watcher." It is:

1. Compose existing watcher/ledger outputs into ranked action candidates.
2. Gate delivery by live orchestrator idleness and idempotency.
3. Inject one concise Donella/Jeff packet through NTM.
4. Verify delivery with a four-state receipt.
5. Measure whether bead velocity and idle-with-work improve.

## 2. System Boundary

Initial implementation boundary:

- Repo: `/Users/josh/Developer/flywheel`.
- Session: `flywheel` local orchestrator first.
- Source ledgers: read-only.
- Pane writes: only to the target orchestrator pane and only after live-state
  proof.

Expansion boundary:

- Peer sessions `skillos`, `alpsinsurance`, `mobile-eats`, and `vrtx` after
  per-session allowlist/config ships.
- Cross-session delivery stays behind topology, live-state proof, and an
  authorization/refusal contract.

## 3. Core Contract

### Candidate

Source adapters produce normalized candidate rows. A candidate is not a prompt;
it is a data-backed possible action with source refs.

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

### Snapshot

The composer groups candidates into a snapshot:

- source freshness table
- velocity table
- pane capacity table
- ranked candidate list
- suppressed candidate list with reasons

### Decision

The delivery gate emits a decision:

- `deliver|suppress|error`
- target session/pane
- idempotency hash
- refusal reason if suppressing
- candidate triplet hash
- source offsets

### Delivery Receipt

If delivered, the verifier records:

- `transport_accepted`
- `prompt_visible_in_target`
- `prompt_submitted`
- `work_started|not_started|unknown`

## 4. Source Set For First Ship

First ship should intentionally start with a narrow high-signal source set:

1. Bead velocity and ready P0/P1 queue.
2. NTM robot activity for target session.
3. Codex stuck-detector subclass histogram and unrecovered panes.
4. Fuckup-log top classes and new high-severity rows.
5. Cross-orch flywheel-class blockers older than threshold.
6. L70/no-punt and dispatch-delivery debts.

This is enough to reproduce the overnight report's causal finding without
building a broad manager-loop clone.

## 5. Delivery Policy

Default cadence: 300 seconds. Faster 60-second cadence is too aggressive for
orchestrator prose until duplicate suppression and delivery receipts prove
quietness. A 300-second tick matches existing no-idle thresholds and gives
enough time to observe work-started.

Initial target: `flywheel:1` only.

Allowed delivery:

- target orch pane idle/waiting for at least 300 seconds
- at least one candidate blocks velocity
- no same packet hash delivered in the last 30 minutes
- session budget below 3 deliveries/hour
- source freshness within allowed windows

Suppressed delivery:

- target orch pane active/thinking/generating
- no work candidates
- same packet recently delivered
- candidate requires TRUE Joshua blocker
- target is not allowlisted
- source freshness is stale enough to risk false action

## 6. Packet Semantics

The prompt must be short enough to act on and structured enough to validate.

Required sections:

- `PHASE: ORCH_HEARTBEAT`
- Donella trace
- data summary
- next-action triplet
- skills/source citation
- fail-safe instructions

The packet must never end with "should I" or ask Joshua to choose. If there is
a TRUE Joshua blocker class, delivery should suppress normal action and route to
the existing notify/ledger path with class citation.

## 7. Metrics

Primary SLOs:

- No allowlisted orchestrator idle with work available for >10 minutes.
- Heartbeat duplicate suppression rate stays high enough to avoid prompt spam.
- Delivery success rate >95% where target pane is idle.
- Work-started after heartbeat >80% within one cadence.
- Bead velocity rises above 0 created or 0 closed per overnight window when work
  sources exist.

Doctor fields:

- `orch_heartbeat_last_fire_ts`
- `orch_heartbeat_last_delivery_ts`
- `orch_heartbeat_idle_with_work_count`
- `orch_heartbeat_duplicate_suppressed_count_24h`
- `orch_heartbeat_stale_source_count`
- `orch_heartbeat_delivery_not_started_count_24h`
- `orch_heartbeat_work_started_rate_24h`

## 8. Implementation Bead Preview

1. HB-B0 schema and fixtures.
2. HB-B1 read-only composer.
3. HB-B2 idempotency and idle gate.
4. HB-B3 delivery verifier and dry-run/apply.
5. HB-B4 tick-driver/doctor registration.
6. HB-B5 morning report projection.
7. HB-B6 per-session config and peer allowlist.
8. HB-B7 cross-session refusal fixtures.
9. HB-B8 manager-state integration.

## 9. r1 Open Risks

- Need to prove the composer does not become a second manager-state authority.
- Need to define stale-source thresholds per source.
- Need to test prompt collision when pane is visually idle but input buffer
  contains queued text.
- Need to choose exact source-ref format for JSONL offsets.
- Need to decide whether peer delivery is separate binary/script or same CLI
  with config.
