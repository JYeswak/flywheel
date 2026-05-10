---
title: "Phase 3 Audit R1 - Idempotency Lens"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 Audit R1 - Idempotency Lens

```text
plan=orch-monitor-recovery-auto-act-2026-05-04
artifact=03-AUDIT-r1-idempotency.md
lens=idempotency
mode=plan-space-read-only
date=2026-05-04
scope=orchmon-core-post-split-B1-B14
task_id=orchmon-core-audit-idempotency-477345
```

## 1. Verdict

Disposition: pass with Phase 4 hardening gates.

Self-grade: Y.

Composite score: 7.1 / 10.0.

Critical findings: 0.

High findings: 4.

Medium findings: 5.

Low findings: 2.

Findings total: 11. TRUE blocker classes triggered: none.

L110 idempotency verdict: yes, provided B28/B29 keep the r2 acceptance gates for
deterministic fixture rows and no-duplicate relay apply.

The r2 plan is directionally idempotent: it names deduped Joshua-notify,
append-only action ledgers, replay/idempotency fixtures, doctor/status
consequences, and a split Plan A/Plan B boundary. The residual risk is that
many of those terms are still contractual labels, not mechanical keys.

No finding duplicates the cross-cutting audit. That audit already covered L110
materialization, cap split, primitive traceability, Agent Mail recurrence
framing, WOE ownership, cross-orch scope table, and canonical CLI surface
coverage (`03-AUDIT-r1-cross-cutting.md:96-104`). This lens only asks whether
reruns, duplicate ticks, crashes, dry-runs, and peer races converge to one
truth.

## 2. Evidence Read

Required sources read:

1. `02-REFINE-r2.md` for the post-split 14+15 plan.
2. `02-REFINE-r1.md` for predecessor comparison.
3. `03-AUDIT-r1-cross-cutting.md` to avoid duplicate findings.
4. `.flywheel/PARADIGM-substrate-self-organization-2026-05-04.md` for L110.
5. `../wire-or-explain-tick-gate-2026-05-04/03-AUDIT-r1-idempotency.md`.
6. `~/.claude/commands/flywheel/plan.md` for auto-advance and TRUE blockers.
7. `AGENTS.md` L60, L75, and L91 for live-loop, peer coordination, and dispatch
   receipt idempotency.

Skills applied: `donella-meadows-systems-thinking`,
`simplify-and-refactor-code-isomorphically`, `lean-formal-feedback-loop`,
`multi-pass-bug-hunting`, and `gate-truth-separation`.

Pre-flight substrate survey:

```text
socraticode_queries=3
indexed_chunks_observed=30
file_reservation_attempted=yes
file_reservation_result=blocked_existing_identity_requires_token_in_mcp_session
raw_token_used=no
commits_total=0
```

Core source anchors: r2 mechanism and tick rhythm (`02-REFINE-r2.md:16-22`,
`:135-145`), ledgers and idempotent action-key language (`02-REFINE-r2.md:147-177`),
Plan A core B1-B14 (`02-REFINE-r2.md:326-355`), L110/B28/B29 replay obligations
(`02-REFINE-r2.md:403-441`; `PARADIGM:918-936`, `:984-996`), WOE boundary
(`02-REFINE-r2.md:459-493`), idempotency audit scope (`02-REFINE-r2.md:570-586`),
r1 predecessor beads (`02-REFINE-r1.md:284-302`), auto-advance/TRUE blockers
(`plan.md:105-123`, `:165-198`), L60 live-loop signals (`AGENTS.md:602-619`),
L75 peer coordination (`AGENTS.md:1357-1381`), and L91 dispatch receipts
(`AGENTS.md:2184-2208`).

## 3. Audit Frame

This lens treats idempotency as four separable gates:

1. Event identity: duplicate observations reduce to one current condition.
2. Action identity: duplicate decisions reduce to one intended action.
3. Mutation authority: dry-run and apply do not share side effects.
4. Replay truth: ledgers, doctor JSON, status, and observatory surfaces rebuild
   to the same state from the same rows.

Gate-truth separation:

```text
flow_gate=observation_to_action
not_code_correctness_gate=yes
not_deploy_approval_gate=yes
not_permission_to_recover_protected_sessions=yes
not_WOE_artifact_truth_gate=yes
```

Donella frame:

```text
SYSTEM: flywheel-owned cross-orchestrator supervision
STOCK: unacted supervision debt plus duplicate action/notify/claim rows
INFLOW: repeated ticks, launchd retries, duplicate probes, peer reports
OUTFLOW: one stable action receipt or explicit no-touch/no-auto-repair receipt
LOOP: observation -> classify -> action key -> receipt -> verification -> status
LEVERAGE: Meadows #5 rules and #4 self-organization, supported by #6 information
MEASURE: duplicate_action_suppressed_count, replay_digest, unacted_actionable_count
```

The sibling WOE idempotency audit is the useful pattern: "stable" or
"append-only" is insufficient without exact ID bytes, lock boundaries,
canonical hashes, and replay reducers (`WOE 03-AUDIT-r1-idempotency.md:51-59`,
`:63-76`). Orch-monitor has the same mechanical risk, but against live
orchestrator actions instead of artifact rows.

## 4. Findings Table

| ID | Severity | Beads affected | One-line finding | Required mitigation |
|---|---:|---|---|---|
| IDEMP-OM-01 | high | B1,B2,B5,B7,B9,B11,B12,B14 | No canonical `observation_id` / `action_id` schema is named for duplicate ticks. | Define `observation_id/v1`, `action_id/v1`, and latest-state reducer. |
| IDEMP-OM-02 | high | B6,B9,B11,B12,B14 | Five notify classes need one dedupe key and cooldown semantics. | Add `notify_key/v1`, TTL, equality boundary, and one receipt per condition. |
| IDEMP-OM-03 | high | B5,B6,B8,B10,B12 | Recovery and rehearsal can double-act unless leases bind target generation. | Require dry-run no-mutation proof, lease CAS, and target generation checks. |
| IDEMP-OM-04 | high | B10,B11,B12 | Peer first-responder claim/release lacks explicit CAS and split-brain reducer. | Add mesh claim lock, holder check, release idempotency, and conflict rows. |
| IDEMP-OM-05 | medium | B1,B2,B11,B12 | Live-truth freshness can create timestamp-skew duplicate observations. | Bucket probe windows and key by source generation, not wall-clock alone. |
| IDEMP-OM-06 | medium | B3,B4,B7,B12 | Mission-licensed dispatch can re-dispatch the same tactical action. | Add `mission_action_key` plus L91 four-state receipt join. |
| IDEMP-OM-07 | medium | B1,B7,B11,B12,B14 | L60 signal emission/reception dedupe is unspecified. | Key loop signals by loop interval, signal name, session, and source row. |
| IDEMP-OM-08 | medium | B11,B14 | Doctor/status/observatory must be pure derived views. | Define stable field set, sort order, and byte-stable replay digest. |
| IDEMP-OM-09 | medium | B12,B13 | B12 needs replay tests for every high-risk duplicate path. | Add fixtures for double tick, double notify, double recovery, claim race, B28/B29. |
| IDEMP-OM-10 | low | B8,B1,B11 | Launchd safety net can become a second driver without a shared tick key. | Share `tick_evaluation_id` between tick handler and launchd safety net. |
| IDEMP-OM-11 | low | B13,B14 | Three-surface doctrine may drift from reducer semantics. | Require doctrine examples to cite same reducer/schema used by doctor/status. |

Severity count:

```text
critical=0
high=4
medium=5
low=2
total=11
```

## 5. Detailed Findings

### IDEMP-OM-01 - Stable observation/action identity is underspecified

Severity: high.

Affected beads: B1, B2, B5, B7, B9, B11, B12, B14.

Evidence: B1 is root supervision handler and ledger bead
(`02-REFINE-r2.md:338-343`); the rhythm writes a ledger row after
act/notify/no-touch (`02-REFINE-r2.md:135-145`); the plan says actions are
idempotent by action key but does not name key bytes (`02-REFINE-r2.md:170-177`).

Risk: the same condition observed twice in 60 seconds can append a second
semantic action row. The most dangerous cases are frozen recovery, blocker
routing, and notify decisions.

Required gate:

```text
observation_id/v1 = sha256(source_kind, canonical_session, pane_or_repo,
  failure_class, source_generation_or_window, condition_hash, schema_version)
action_id/v1 = sha256(observation_id, action_class, target_identity,
  action_version, policy_hash)
```

### IDEMP-OM-02 - Notify dedupe semantics are not mechanical yet

Severity: high.

Affected beads: B6, B9, B11, B12, B14.

Evidence: B6 is notify-only for protected sessions unless authorized
(`02-REFINE-r2.md:346-350`); B9 owns five notify classes and sparse alerts
(`02-REFINE-r2.md:347-351`); r2 says Joshua-notify is sparse and class-gated
(`02-REFINE-r2.md:624-626`).

Risk: repeated protected-session, blocker-stuck, or storm evidence can produce
repeated Joshua notifications if dedupe only happens at the notify binary or
only at emit.

Required gate:

```text
notify_key/v1 = sha256(notify_class, canonical_target, condition_hash,
  owner, escalation_threshold, policy_hash)
```

Rules: one active notify receipt per key inside cooldown; valid iff
`now < expires_at`; repeated attempts append `duplicate_suppressed`, not alerts.

### IDEMP-OM-03 - Recovery rehearsal and apply need target-generation leases

Severity: high.

Affected beads: B5, B6, B8, B10, B12.

Evidence: B5 owns frozen/dead/queued recovery handlers (`02-REFINE-r2.md:342-348`);
B6 blocks protected recovery without authorization (`02-REFINE-r2.md:346-350`);
B8 is a safety net, not primary driver (`02-REFINE-r2.md:349-355`); r2 says
mutating actions are dry-run first (`02-REFINE-r2.md:170-177`).

Risk: a dry-run can look like an applied receipt, or apply can use stale
classification after the pane state changes. A launchd retry can also apply
while the tick handler applies.

Required gate: dry-run writes only a read-only plan receipt; apply requires
`action_id`, target generation, live-truth freshness, and a held recovery lease;
same `action_id` returns the first apply receipt.

### IDEMP-OM-04 - Peer mesh claims need explicit CAS semantics

Severity: high.

Affected beads: B10, B11, B12.

Evidence: B10 is peer first-responder claim/release (`02-REFINE-r2.md:350-352`);
L75 requires structured cross-orch rows and doctor fields (`AGENTS.md:1366-1381`);
r2 lists `orch-mesh-claims.jsonl` as a supporting ledger
(`02-REFINE-r2.md:153-157`).

Risk: if flywheel:1 itself is down, two peers can both claim first responder,
notify, or dispatch repair. Append-only JSONL alone is not a CAS.

Required gate: claim acquisition must lock latest-holder check plus append;
`claim_id = sha256(target_session, target_pane, failure_class, epoch_window)`;
only current holder may side-effect or release; conflicting same-window claims
become `mesh_split_brain_detected` before side effects.

### IDEMP-OM-05 - Freshness windows can duplicate observations

Severity: medium.

Affected beads: B1, B2, B11, B12.

Evidence: B2 requires live probe <=60s and stale ledger cannot trigger recovery
(`02-REFINE-r2.md:342-344`); L60 requires five live output signals within the
loop interval (`AGENTS.md:604-615`); stale-ledger misread must block recovery
(`02-REFINE-r2.md:230-231`).

Risk: two probes in the same minute can have different timestamps but identical
truth. Timestamp identity duplicates rows; ignoring timestamp entirely merges
stale rows with current truth.

Required gate:

```text
source_generation = max(source_row_offset, pane_state_since_epoch, probe_window_id)
probe_window_id = floor(probe_started_at / configured_window_seconds)
```

### IDEMP-OM-06 - Mission-licensed actions can duplicate dispatch

Severity: medium.

Affected beads: B3, B4, B7, B12.

Evidence: B3 is mission-license permit/refuse (`02-REFINE-r2.md:343-345`); B4
executes phantom blockers inside lock and does not notify (`02-REFINE-r2.md:345-346`);
L91 says dispatch is not active work until four states are proven
(`AGENTS.md:2184-2208`).

Risk: if transport is accepted but work-start is delayed, the next tick can
re-dispatch the same tactical action.

Required gate:

```text
mission_action_key/v1 = sha256(repo, mission_anchor_hash, vendor_or_platform,
  intended_action, target_resource, blocker_row_id)
```

Only `retry_required` after the L91 grace window permits another dispatch.

### IDEMP-OM-07 - L60 signal dedupe is unspecified

Severity: medium.

Affected beads: B1, B7, B11, B12, B14.

Evidence: L60 defines five loop signals as an AND contract (`AGENTS.md:609-619`);
r2 says doctor/status must show last-N actions and unacted-actionable counts
(`02-REFINE-r2.md:172-177`); B11/B14 own doctor and last-action surfacing
(`02-REFINE-r2.md:350-355`).

Risk: repeated emission of the same signal can falsely mark the loop healthy if
the receiver counts rows rather than distinct signal intervals.

Required gate:

```text
loop_signal_id/v1 = sha256(session, loop_interval_id, signal_name,
  signal_source, source_generation)
```

Dedupe at receive. Emitters may be noisy; reducer owns one truth per signal
interval.

### IDEMP-OM-08 - Doctor/status must be pure derived views

Severity: medium.

Affected beads: B11, B14.

Evidence: B11 is `orch-supervision-doctor-fields` (`02-REFINE-r2.md:350-353`);
B14 is `fleet-observatory-last-actions-surface` (`02-REFINE-r2.md:353-355`);
r2 says the fleet observatory remains a surface, not decision owner
(`02-REFINE-r2.md:620-623`).

Risk: if doctor/status calls append "last viewed" rows, refresh caches, or
reorder fields accidentally, repeated read-only calls change state or output.

Required gate: `doctor --json` and status are read-only, consume the same
reducer, have stable field sets, stable array order, and expose
`replay_digest = sha256(canonical_json(reduced_state))`.

### IDEMP-OM-09 - B12 replay fixture coverage must be explicit

Severity: medium.

Affected beads: B12, B13.

Evidence: B12 is the fault-injection harness (`02-REFINE-r2.md:350-354`); r2 says
B12 verifies B28/B29 with replay/idempotency fixtures (`02-REFINE-r2.md:423-425`);
B13 documents the rule only after B28 proves the mechanical contract
(`02-REFINE-r2.md:425-426`).

Risk: action classification tests can pass without replay safety. That repeats
the original failure shape: observe/report without executable drain discipline.

Required gate: B12 must include fixtures for double tick, double notify, double
recovery, peer claim race, launchd/tick collision, B28 replay, and B29 relay
dry-run/apply replay.

### IDEMP-OM-10 - Launchd safety net needs shared tick identity

Severity: low.

Affected beads: B8, B1, B11.

Evidence: B8 is secondary driver only (`02-REFINE-r2.md:349-350`); r2 says tick
handler is primary and launchd is safety net (`02-REFINE-r2.md:620-621`).

Risk: the safety net becomes a second authority if it does not share B1's
`tick_evaluation_id` and input high-watermark.

Required gate:

```text
tick_evaluation_id/v1 = sha256(session, tick_interval_id, handler_version,
  input_high_watermarks, policy_hash)
```

### IDEMP-OM-11 - Three-surface doctrine must cite reducer semantics

Severity: low.

Affected beads: B13, B14.

Evidence: B13 is doctrine after mechanics (`02-REFINE-r2.md:353-355`); L110
requires tick/status consequences as part of the contract (`PARADIGM:920-936`).

Risk: B13 can record a prose rule that does not cite the reducer/schema used by
B11/B14, letting doctrine and doctor/status drift.

Required gate: B13 examples cite `observation_id/v1`, `action_id/v1`, reducer
name, doctor/status fields, and at least one B12 replay fixture.

## 6. Cross-Bead Findings

| ID | Beads | Cross-bead concern | Required invariant |
|---|---|---|---|
| CBF-1 | B1,B2,B5,B7,B9,B11,B12,B14 | Several ledgers and surfaces exist (`02-REFINE-r2.md:147-160`); one reducer must own current truth. | `same_input_ledgers + same_policy_hash -> same_reduced_state + same_replay_digest` |
| CBF-2 | B1,B6,B7,B9,B10,B11,B14 | L60 signals, peer rows, notify triggers, and dispatch receipts repeat. | Dedupe at supervision decision boundaries, not only emitters. |
| CBF-3 | B5,B6,B8,B10,B12 | Dry-run/apply must share planner but separate side effects. | Dry-run mutates zero; apply is lease-bound and returns first receipt on replay. |
| CBF-4 | B1,B11,B12,B13,B14 plus B28/B29 | Plan A needs placeholders before Plan B internals land. | Placeholder schemas replay the same once B28 becomes real. |

## 7. TRUE-Blocker Class Evaluation

Per `/flywheel:plan`, the six TRUE blocker classes are the only legitimate
pauses (`plan.md:165-198`). This audit triggers none.

| Class | Triggered? | Evaluation |
|---|---:|---|
| `new-platform-or-vendor-not-in-mission-lock` | no | The audit proposes no new vendor or platform. |
| `secret-rotation-or-new-credential-creation` | no | No credential creation or rotation is proposed. |
| `financial-commitment-above-mission-budget` | no | No paid resource is proposed. |
| `legal-or-compliance-decision` | no | No ToS, DPA, or legal choice is proposed. |
| `destructive-irreversible-on-shared-state` | no | Mitigations are plan-space gates, dry-runs, fixtures, or reducers. |
| `paradigm-conflict-with-active-mission` | no | Findings reinforce r2's action-loop paradigm and L110. |

```text
audit_disposition=auto_advance_with_phase4_hardening
true_blocker_classes_triggered=none
blocker_class_evaluations=6/6
```

## 8. Replay-Test Scenarios

### RTS-1 - Double tick in one cadence window

Sequence: same pane emits same `frozen-orch` evidence twice within 60 seconds;
B1 evaluates twice; B2 returns same source generation; B5 plans recovery;
B11/B14 render status twice.

Expected:

```text
current_observations=1
current_actions=1
duplicate_action_suppressed_count>=1
replay_digest_identical=yes
```

### RTS-2 - Protected-session notify repeated

Sequence: protected session remains frozen across two ticks; B6 refuses
auto-recovery twice; B9 notify policy fires twice.

Expected:

```text
notify_visible_to_joshua_count=1
notify_duplicate_suppressed_count=1
active_notify_receipts=1
```

### RTS-3 - Recovery rehearsal no side effects

Sequence: B5 recovery dry-run executes twice; target state remains unchanged;
apply executes twice with same `action_id`.

Expected:

```text
dry_run_mutations=0
apply_mutations=1
second_apply_status=already_applied
```

### RTS-4 - Peer first-responder race

Sequence: flywheel:1 is down; two peer orchestrators claim first responder in
the same window; both attempt a side effect.

Expected:

```text
claims_attempted=2
claim_winners=1
loser_side_effects=0
```

### RTS-5 - Mission-licensed dispatch retry

Sequence: B4 classifies phantom blocker as mission-licensed; B7 dispatches;
transport accepts but no work-start receipt lands; next tick evaluates same
action.

Expected:

```text
same_mission_action_key=yes
state=dispatch_transport_accepted_not_started
retry_allowed=yes_after_grace
duplicate_dispatch_before_grace=0
```

### RTS-6 - L60 duplicate signal rows

Sequence: one loop interval writes two rows for one signal; one required signal
is missing; doctor reduces L60 state.

Expected:

```text
distinct_signals_present=4
duplicate_signal_rows=1
verdict=LIMPING
healthy_false_pass=no
```

### RTS-7 - Doctor/status repeated reads

Sequence: B11 `doctor --json` called twice; B14 status called twice; no source
ledger changes.

Expected:

```text
state_mutations_from_reads=0
field_set_identical=yes
sort_order_identical=yes
replay_digest_identical=yes
```

### RTS-8 - L110 B28/B29 replay

Sequence: B28 validates a `skill-candidate` fixture row twice; B29 relay
dry-run consumes row twice; B29 relay apply consumes row twice.

Expected:

```text
B28_fixture_row_pattern_identical=yes
B29_dry_run_mutations=0
B29_apply_handoff_receipts=1
B29_second_apply_status=already_relayed
l110_idempotent=yes
```

## 9. L110 Idempotency Check

Question: does B28+B29 close the L110 loop idempotently?

Answer: yes, if Phase 4 treats r2 wording as acceptance criteria rather than
background prose.

Evidence:

1. L110 requires every durable observation/finding/artifact to declare stock,
   class, consumer or deferral, owner, action ledger, verification probe, and
   tick/status consequence (`PARADIGM:1018-1024`).
2. B28 materializes the universal validator (`02-REFINE-r2.md:398-401`).
3. B29 materializes the `skill-candidate` consumer (`02-REFINE-r2.md:398-402`).
4. The paradigm artifact requires B29 apply to write one `skill_handoff_sent`
   receipt and not duplicate on rerun (`PARADIGM:988-991`).
5. The r2 matrix says B12 verifies B28/B29 with replay/idempotency fixtures
   (`02-REFINE-r2.md:423-425`).

Required hold:

```text
B28_validator_is_pure=yes
B28_fixture_replay_byte_identical=yes
B29_dry_run_read_only=yes
B29_apply_idempotency_key=wire_or_explain_row_id_or_artifact_id
B29_second_apply_duplicate_receipt=no
B11_status_consequence_reads_B29_state=yes
l110_idempotent=yes
```

## 10. Composite Score

| Dimension | Score | Rationale |
|---|---:|---|
| Stable event/action identity | 6.4 | The plan names action keys but not exact schemas. |
| Notify and recovery dedupe | 6.8 | Correct owner beads exist; cooldown/lease semantics need gates. |
| Replay and reducer determinism | 7.0 | B12/B11/B14 cover the surface but need exact reducer contract. |
| Dry-run/apply separation | 7.2 | r2 names dry-run first; target generation proof still missing. |
| Cross-pane atomicity | 6.5 | B10 exists but needs CAS/split-brain proof. |
| L110 idempotency | 7.8 | B28/B29 wording is strong if fixture gates are preserved. |
| TRUE-blocker hygiene | 8.0 | No Joshua blocker class fires; mitigations are autonomous. |

```text
composite_score=7.1
pass_threshold=7.0
pass=yes
```

Why not higher: Phase 4 must convert "deduped", "idempotent by action key",
"replay fixture", and "sparse alerts" into stable keys, reducers, leases,
cooldowns, and exact replay scenarios.

Why not lower: the right owners already exist: B1 root handler, B9 notify
dedupe, B10 peer claims, B11 doctor fields, B12 fixtures, B13 doctrine after
mechanics, B14 action surfaces, plus Plan B B28/B29 for L110.

## 11. Phase 4 Required Mitigation Mapping

| Finding | Primary mitigation bead | Secondary bead(s) |
|---|---|---|
| IDEMP-OM-01 | B1 | B2,B11,B12,B14 |
| IDEMP-OM-02 | B9 | B6,B11,B12,B14 |
| IDEMP-OM-03 | B5 | B6,B8,B10,B12 |
| IDEMP-OM-04 | B10 | B11,B12 |
| IDEMP-OM-05 | B2 | B1,B11,B12 |
| IDEMP-OM-06 | B3 | B4,B7,B12 |
| IDEMP-OM-07 | B11 | B1,B7,B12,B14 |
| IDEMP-OM-08 | B11 | B14 |
| IDEMP-OM-09 | B12 | B13 |
| IDEMP-OM-10 | B8 | B1,B11 |
| IDEMP-OM-11 | B13 | B14 |

No new Plan A beads are required. Add acceptance gates to existing B1-B14. Plan
B B28/B29 already carry L110 replay obligations.

## 12. Callback Metrics

```text
DONE orchmon-core-audit-idempotency output=.flywheel/plans/orch-monitor-recovery-auto-act-2026-05-04/03-AUDIT-r1-idempotency.md self_grade=Y findings_total=11 findings_by_severity={critical:0,high:4,medium:5,low:2} composite_score=7.1 true_blocker_classes_triggered=none blocker_class_evaluations=6/6 replay_scenarios_count=8 l110_idempotent=yes commits_total=0 callback_delivery_verified=true
```
