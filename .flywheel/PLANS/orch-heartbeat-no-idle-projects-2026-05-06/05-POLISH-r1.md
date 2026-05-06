# Phase 5 Polish r1: event-driven orch heartbeat

Task: `phase5-polish-orch-heartbeat-event-driven-2026-05-06`
Bead: `flywheel-orch-heartbeat-phase5-polish-event-driven-2026-05-06`
Scope: plan-space only. No `.flywheel/scripts/` mutation and no mutation of
the nine existing Phase 4 bead rows.

## Input

Primary polish input:

- Cross-orch finding: `mobile-eats:1` row 150,
  class `orch-bash-prompt-state-change-trigger`.
- Finding text: state-transition substrate is now timestamped enough that
  orchestrators do not need to poll; prompt regeneration can fire on state
  change.
- Orchestrator survey from the dispatch packet: K=50 Socraticode preflight
  found the event substrate roughly 80 percent present: JSONL state streams,
  `ntm --robot-activity`, L85 idle classification, L91 delivery receipts,
  JSONL fallback close truth, idle-pane auto-dispatch, watcher-isomorphic probe,
  and sibling four-input probe shape.
- Worker verification: K=10 independent Socraticode search against canonical
  `/Users/josh/Developer/flywheel`, indexed chunks observed by status = 945.

Verified local anchors:

| Anchor | Evidence |
|---|---|
| Current Phase 4 graph | `04-BEADS-DAG.md` has nine beads and Wave A/B/C/D. |
| Idle classifier | L85 references `.flywheel/scripts/idle-state-probe.sh`. |
| Delivery receipt rule | L91 requires transport, visibility, submit, and work-started evidence. |
| Sibling four-input shape | `tests/worker-stall-alert-probe.sh` fixtures topology, activity, tail, and dispatch-log together. |
| Evidence-not-trust precedent | capacity-halt success-measurement records post-send evidence, not transport acknowledgement. |
| JSONL close truth | `.beads/issues.jsonl` is load-bearing while JSONL fallback is active. |

## Donella analysis

System boundary: flywheel-controlled orchestrator panes, worker panes, state
ledgers, and the prompt-delivery substrate.

Stock: actionable orchestrator context waiting to be converted into safe next
actions.

Cron-pull model:

- A driver wakes on cadence and asks "what changed?"
- Most ticks have no new information, so the system spends context on null
  checks.
- The driver can still miss race windows unless every producer and cadence line
  up.
- The tick-driver becomes the apparent owner of information freshness even
  though the producers already know when they changed.

Event-subscribe model:

- Producers append rows with timestamps and state classes.
- A subscriber tails cursor deltas and asks "does this transition need a prompt?"
- The state transition itself becomes the trigger, which moves information flow
  to the first moment truthful state exists.
- Fallback polling remains a recovery path for repos without subscriber
  coverage, not the primary mechanism.

Leverage point: Meadows canonical #6 Information Flows. The intervention gives
the orchestrator timely state it did not have before: compact prompt injections
only when an append-only state surface changed. Meadows #5 Rules still governs
allowlist, idempotency, and refusal. Meadows #4 Self-Organization appears after
the subscriber primitive exists because new ledgers can register as event
sources without adding a new cadence loop.

Conclusion: the Phase 4 cron-heartbeat DAG is directionally correct on evidence
surfaces but too driver-centered. Phase 5 should reconverge around a subscriber
primitive plus a fallback poll path.

## Bead-by-bead reconvergence

| # | Existing bead | Disposition | Rationale | Reconverged landing |
|---|---|---|---|---|
| 0 | `flywheel-orch-heartbeat-candidate-schemas-2026-05-06` | TRANSFORM | Candidate schemas remain needed, but the primary object becomes an event transition plus cursor state, not a periodic snapshot. | `orch-heartbeat-event-schemas-and-cursors-2026-05-06`. |
| 1 | `flywheel-orch-heartbeat-readonly-composer-2026-05-06` | TRANSFORM | Composer stays read-only, but it consumes subscriber transition envelopes and renders a compact prompt only on eligible changes. | Fold into `orch-heartbeat-event-composer-and-gate-2026-05-06`. |
| 2 | `flywheel-orch-heartbeat-idle-idempotency-gate-2026-05-06` | TRANSFORM | Idle/idempotency is still load-bearing, but it gates event-triggered prompts rather than cron candidates. | Fold into `orch-heartbeat-event-composer-and-gate-2026-05-06`. |
| 3 | `flywheel-orch-heartbeat-delivery-verifier-2026-05-06` | KEEP | L91 delivery verification is unchanged and remains required after subscriber emission. | Keep as `orch-heartbeat-event-delivery-verifier-2026-05-06`. |
| 4 | `flywheel-orch-heartbeat-tick-driver-doctor-2026-05-06` | COLLAPSE | The cron driver no longer owns primary cadence. Doctor fields move to subscriber health plus fallback-poll health. | Collapse into subscriber primitive and doctor/report projection. |
| 5 | `flywheel-orch-heartbeat-morning-report-projection-2026-05-06` | COLLAPSE | Projection is useful, but it is a consumer of subscriber health, not a separate Phase 4 implementation bead. | Collapse into `orch-heartbeat-subscriber-doctor-report-2026-05-06`. |
| 6 | `flywheel-orch-heartbeat-session-config-allowlist-2026-05-06` | TRANSFORM | Allowlist becomes subscriber subscription config with peer delivery disabled by default. | Fold into `orch-heartbeat-event-config-and-refusal-2026-05-06`. |
| 7 | `flywheel-orch-heartbeat-cross-session-refusal-tests-2026-05-06` | TRANSFORM | Refusal tests are still required, now proving event transitions cannot inject into protected or non-allowlisted panes. | Fold into `orch-heartbeat-event-config-and-refusal-2026-05-06`. |
| 8 | `flywheel-orch-heartbeat-manager-state-integration-2026-05-06` | COLLAPSE | Manager-state read model is downstream polish. Event subscriber cursors and doctor/report fields are enough for this arc. | Drop from this DAG; file later only after local subscriber is quiet. |
| new | `flywheel-orch-heartbeat-state-change-subscriber-2026-05-06` | NEW | Missing primitive: tails state-change substrates and emits compact prompt-injection candidates. | New Wave A foundation bead. |

Disposition counts over the existing nine: KEEP=1, COLLAPSE=3, TRANSFORM=5.
New beads proposed: 1.

## New subscriber primitive spec

Proposed primitive:
`.flywheel/scripts/orch-state-change-bash-prompt-subscriber.sh`

Purpose: read append-only state transitions, classify eligible orchestrator
prompt injections, and emit compact prompt lines for an existing delivery
verifier. It does not replace L91 delivery verification.

Four-input shape:

| Input class | Concrete source | Use |
|---|---|---|
| Topology and policy | latest session topology plus subscriber allowlist config | target session, pane role, peer-disabled default, protected-pane refusal |
| Robot activity | `ntm --robot-activity=<session>` with `state_since_epoch` and live provenance | prove target orch pane is idle before delivery |
| Pane tail / prompt state | `ntm` tail/copy surface used by the delivery verifier | prove prompt visibility and avoid queued-not-submitted ambiguity |
| Event ledger bundle | five JSONLs: `codex-stuck-detector.jsonl`, `dispatch-log.jsonl`, `.beads/issues.jsonl`, `fuckup-log.jsonl`, `cross-orch-coordination.jsonl` | cursor deltas, close truth, blockers, recovery debt, peer findings |

Cursor state:

- One cursor per ledger path and per session.
- Cursor key is `(repo, session, ledger_name, inode_or_path, last_offset,
  last_row_ts, last_row_hash)`.
- Rows are read append-only. Truncation or hash mismatch returns substrate
  error and refuses delivery until a recovery receipt exists.

Canonical CLI verbs:

| Verb | Behavior |
|---|---|
| `--info --json` | Print schema, mutation defaults, ledgers watched, and fallback-poll status. |
| `--schema --json` | Emit event transition, cursor, decision, and delivery-handoff schemas. |
| `scan --repo <path> --session <name> --json` | Read cursors and ledgers, return eligible transitions without delivery. |
| `render --event-id <id> --json` | Render compact prompt candidate with source refs and action triplet. |
| `apply --repo <path> --session <name> --pane <n> --json` | If safe, hand off to delivery verifier; otherwise write suppress/error receipt. |
| `doctor --repo <path> --json` | Report subscriber lag, malformed rows, stale cursors, duplicate suppressions, and fallback-poll usage. |

Exit codes:

| Code | Meaning |
|---:|---|
| 0 | No eligible transition or dry-run clean. |
| 1 | Eligible prompt candidate emitted or delivered. |
| 2 | Usage, schema, or config error. |
| 3 | Ledger, cursor, or robot-activity substrate error. |
| 4 | Authorization/idempotency refusal; suppress receipt written. |
| 5 | Delivery verifier failed or returned unknown work-started state. |

Sibling shape:

- `worker-stall-alert-probe.sh` combines topology, robot activity, pane tail,
  and dispatch log before deciding whether to alert.
- The subscriber uses the same shape, but replaces "stalled worker alert" with
  "state transition prompt candidate" and expands the ledger input bundle to
  five JSONLs.

Fallback poll:

- Retain a bounded poll mode for bootstrap and repos with no subscriber
  registration.
- Poll mode must write `fallback_poll_used=true` in decision receipts and doctor
  JSON so it cannot masquerade as the primary event path.

## Wave reclassification

### Wave A - Foundation

1. `orch-heartbeat-event-schemas-and-cursors-2026-05-06`
   - Transforms #0.
   - Defines event transition, cursor, suppress/error, and delivery-handoff
     schemas.
2. `orch-heartbeat-state-change-subscriber-2026-05-06`
   - NEW.
   - Implements the subscriber primitive over the four-input shape and includes
     fallback poll as a first-class but non-primary mode.

### Wave B - Integration

3. `orch-heartbeat-event-composer-and-gate-2026-05-06`
   - Transforms and merges #1 and #2.
   - Consumes transition envelopes, renders bounded action triplets, applies
     TRUE-blocker trace, idempotency, live idle state, and budget suppression.
4. `orch-heartbeat-event-delivery-verifier-2026-05-06`
   - Keeps #3.
   - Reuses L91 four-state delivery receipt and evidence-not-transport-ack
     success shape.

### Wave C - Polish

5. `orch-heartbeat-event-config-and-refusal-2026-05-06`
   - Transforms and merges #6 and #7.
   - Peer delivery remains disabled by default; refusal fixtures cover protected
     panes, stale topology, active panes, callback-only panes, and missing live
     robot state.

### Wave D - Cross-fleet

6. `orch-heartbeat-subscriber-doctor-report-2026-05-06`
   - Collapses #4 and #5; defers #8.
   - Doctor/report consumers expose subscriber lag, fallback-poll use,
     stale-source count, duplicate suppressions, idle-with-work age, and
     evidence velocity separate from bead velocity.

## Audit lens (lightweight Phase 3 re-run)

| Lens | Finding | Severity | Required reconverged gate |
|---|---|---:|---|
| Security | Event rows must never carry raw secrets or raw prompt buffers into report/doctor output. | High | Subscriber schema redacts payloads and carries refs/hashes only. |
| Security | Peer prompt injection remains the blast-radius boundary. | High | `event-config-and-refusal` disables peer delivery by default and requires explicit session+role allowlist. |
| Idempotency | Cursor replay can duplicate prompts if action hash ignores cursor identity. | High | Idempotency key includes session, ledger, row hash, action triplet, template version, and delivery mode. |
| Idempotency | Fallback poll can race event mode. | Medium | Fallback writes `fallback_poll_used=true`; suppress receipt dedupes against subscriber action hash. |
| Cross-cutting | Doctor must expose subscriber lag or the system will regress to hidden daemon state. | Medium | `subscriber-doctor-report` exposes lag, malformed rows, fallback-poll count, and stale cursors. |
| Cross-cutting | Capacity-halt precedent shows success must be measured by evidence, not acknowledgement. | Medium | Delivery remains L91 four-state plus post-send evidence; `ntm send` transport is never success. |

Audit lens findings count: 6.

## Net delta

Original Phase 4 DAG: 9 beads.

Reconverged Phase 5 preview: 6 beads.

Delta:

- Kept: 1 existing bead shape.
- Collapsed: 3 existing bead shapes.
- Transformed: 5 existing bead shapes.
- New: 1 subscriber primitive bead.
- Net: 9 -> 6 because the new subscriber primitive replaces the cron-driver
  cluster and lets composer/gate plus config/refusal merge cleanly.

Do not mutate the nine existing bead rows in this dispatch. The follow-up
should either file the six reconverged beads as new rows or append explicit
`dropped` / `revised` receipts for the existing nine after the orchestrator
accepts this polish round.
