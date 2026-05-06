# Phase 1 Research C - Implementation Design

Primary input: `/tmp/overnight-velocity-report/SUMMARY.md`.

## 1. Architecture Overview

Build `orch-heartbeat` as a four-layer loop:

1. Source adapters read existing ledgers and robot surfaces.
2. Composer ranks the current fleet/session action candidates.
3. Idle/idempotency gate decides whether delivery is allowed.
4. Delivery writes a receipt and injects a concise packet into the orchestrator
   pane through `ntm`.

No source adapter becomes authority over its producer. The heartbeat layer owns
only synthesis and delivery.

## 2. Source Adapter Contract

Each adapter emits `candidate` rows:

```json
{
  "schema_version": "orch-heartbeat-candidate/v1",
  "session": "flywheel",
  "source": "codex-stuck-detector",
  "source_ref": "~/.local/state/flywheel/codex-stuck-detector.jsonl#offset",
  "stock": "stuck_worker_panes",
  "severity": "high",
  "count": 2,
  "freshness_seconds": 120,
  "summary": "2 workers classified model_at_capacity_halt",
  "recommended_action": "verify recovery budget then send continue or dispatch fix bead",
  "blocks_velocity": true
}
```

Adapters should be small and read-only. They can wrap current scripts or read
current ledgers directly when script output is too heavy.

## 3. Composer Contract

The composer reads candidates, current session topology, and current pane
activity. It emits:

- `orch-heartbeat-snapshot.json`: all candidates plus source freshness.
- `orch-heartbeat-packet.md`: prose prompt for the orchestrator pane.
- `orch-heartbeat-decision.json`: delivery decision and idempotency hash.

Ranking policy:

1. P0 recovery needed to make workers/orch usable.
2. P0/P1 ready beads with idle worker capacity.
3. Work-source creation when ready bead stock is low.
4. Validation debt blocking trust in completed work.
5. Doctrine/learning stock over promotion threshold.

Tie-breakers: priority, age, source freshness, then lower blast radius.

## 4. Idle And Idempotency Gate

Delivery is allowed only when all are true:

- Latest topology row names the target orchestrator pane.
- `ntm --robot-activity=<session>` says the orchestrator pane is idle or waiting.
- The pane has been idle longer than the configured threshold, default 300s.
- At least one ranked candidate has `blocks_velocity=true`.
- Idempotency ledger lacks the same `session + action_triplet_hash` in the last
  30 minutes.
- Delivery budget for the session is not exhausted, default 3 packets/hour.

Delivery is refused when any are true:

- Pane state is THINKING/GENERATING.
- Target pane is human or callback-only.
- Target session is not in the heartbeat allowlist.
- Source freshness is too stale to justify action.
- Candidate action would require a TRUE Joshua-blocker class.

## 5. Delivery Layer

Delivery uses:

```bash
ntm send <session> --pane=<orchestrator_pane> --file <packet> --no-cass-check
```

Then a heartbeat-specific delivery verifier confirms:

1. `transport_accepted`.
2. `prompt_visible_in_target`.
3. `prompt_submitted`.
4. `work_started` or `not_started` classification after grace window.

This mirrors L91. A heartbeat delivery without the four-state receipt cannot
count as successful.

## 6. Per-Session Versus Fleet-Wide

Recommended path: per-session heartbeat first.

Rationale:

- Existing alps/mobile-eats/skillos loop plists are per-session.
- Cross-session injection has higher authorization risk.
- A local session can decide its own idleness and worker capacity with fewer
  stale topology edges.

Fleet-wide flywheel composer remains useful as a read-only morning report and
as a source of advisory packets. It should not mutate peer panes until the
per-session loop proves safe and a permit/config layer exists.

## 7. Prose Packet Template

```markdown
PHASE: ORCH_HEARTBEAT
Session: <session> pane <orchestrator_pane>
Window: <lookback>

Donella trace:
- Stock: <orch-attention/work-ready/recovery-debt/etc>
- Flow break: <what is accumulating without outflow>
- Leverage: #6 information flow, #5 delivery/idempotency rule

Data summary:
- Bead velocity: created=<n> closed=<n> updated=<n>
- Ready work: P0=<n> P1=<n>
- Workers: waiting=<n> active=<n> stuck=<n>
- Top fuckup classes: <class=count>
- Cross-orch blockers: <n> stale=<n>

Next-action triplet:
1. <concrete action with source ref>
2. <concrete action with source ref>
3. <concrete action with source ref>

Skills/source citation:
- <skill> -> <why relevant>

Fail-safe:
If this packet is stale or contradicts live pane state, run the named verifier
and write a no-action receipt; do not ask Joshua unless a TRUE blocker class is
present.
```

## 8. Morning Report Integration

A daily morning report is a separate projection over the same snapshot contract:

- It covers an overnight window, e.g. 22:00Z to now.
- It compares bead velocity, recovery rows, stuck-detector rows, and
  cross-orch coordination.
- It names "why work did or did not move."
- It does not deliver action to every pane; it is a flywheel:1 summary artifact.

This prevents conflating continuous heartbeat prompts with long-form retros.

## 9. Preliminary Bead DAG Preview

| Bead | Priority | Goal | Depends on |
|---|---:|---|---|
| HB-B0 | P0 | Define candidate/decision/delivery JSON schemas and fixtures. | none |
| HB-B1 | P0 | Implement read-only composer over five sources. | HB-B0 |
| HB-B2 | P0 | Add idle/idempotency gate and ledger. | HB-B1 |
| HB-B3 | P0 | Add flywheel-local delivery verifier and dry-run/apply modes. | HB-B2 |
| HB-B4 | P1 | Register tick-driver manifest and doctor/status fields. | HB-B3 |
| HB-B5 | P1 | Add morning-report projection using same snapshot contract. | HB-B1 |
| HB-B6 | P1 | Add per-session config and peer rollout allowlist. | HB-B4 |
| HB-B7 | P1 | Add cross-session authorization tests and refusal fixtures. | HB-B6 |
| HB-B8 | P2 | Fold narrow snapshot into manager-state read model when A0 lands. | HB-B5 |

Phase 4 should turn this preview into real beads only after audit findings are
integrated.

## 10. Acceptance Signals For Future Implementation

- No code path sends to an orchestrator pane without latest topology and live
  pane-state proof.
- Identical packets dedupe.
- A heartbeat packet can be rendered without sending.
- Every send writes a four-state delivery receipt.
- Doctor exposes last fire, last delivery, stale source count, duplicate
  suppressions, and idle-with-work count.
- The overnight summary that motivated this plan can be regenerated from the
  same source adapters.
