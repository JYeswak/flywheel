# Phase 3 AUDIT r1 - Idempotency Lens

Plan: `wire-or-explain-tick-gate-2026-05-04`

Audit lens: idempotency and atomicity

Generated: 2026-05-04

Mode: plan-space read-only audit

Path note: dispatch named `.flywheel/plans/...`; this repo's active plan tree
is `.flywheel/PLANS/...`, so this report is written under the existing tree.

## 1. Scope

This audit checks whether the 15-bead r2 plan can be retried, replayed,
backfilled, rolled out cross-orch, and resumed after crashes without duplicate
ledger rows, nondeterministic verdicts, unstable evidence hashes, stale derived
state, or repeated incident noise.

Primary source rows:

- `02-REFINE-r2.md:13-19` defines the append-only idempotent ledger plus
  close-hook invariant.
- `02-REFINE-r2.md:23-31` places the primary gate, secondary emitters, stable
  `ship_event_id`, source ledger, and derived cache.
- `02-REFINE-r2.md:37-42` defines resolution states and minimum proof.
- `02-REFINE-r2.md:89-103` defines the 15 beads.
- `02-REFINE-r2.md:245` names this audit lens: append/upsert behavior,
  `ship_event_id`, bundle grouping, reruns, deferred replacement, cache
  regeneration, and duplicate-count resistance.

Socraticode pre-flight:

- Query 1: `wire-or-explain ledger ship_event_id idempotent JSONL append replay cache`
- Query 2: `idempotency-key ledger append flock jsonl replay deterministic cache tests`
- Query 3: `wire-or-explain cross-orch rollout owned rows enforce cross repo pending expiry`
- Query 4: `DCG orphan commit reset mixed worker side branch enforcement idempotency rule check`
- Returned chunks observed: 40. Closest reusable patterns were idempotency-key
  recovery ledgers, Jeff corpus re-run fixtures, validation fix-bead
  idempotency gates, and shared-surface append ledgers.

## 2. Verdict

Composite score: **7.2 / 10.0**.

Disposition: **pass with Phase 4 hardening beads**.

TRUE blocker classes triggered: **none**.

The plan has the right shape: append-only source of truth, derived cache as
non-authority, `flock`, idempotent re-run assertions, dogfood import,
fault-injection tests, and shadow/warn/enforce rollout.

The residual risk is mechanical underspecification. Several beads say "stable",
"idempotent", or "append-only" without yet defining exact keys, reducer order,
crash-tail recovery, evidence normalization, and cross-orch ownership.

None of these are Joshua decisions. All map to existing Phase 4 beads.

## 3. Findings Table

| ID | Sev | Beads | Finding | Mitigation |
|---|---|---|---|---|
| IDEMP-01 | high | B1,B2,B8,B12,B13 | `ship_event_id` is required but canonical hash inputs are underspecified. | Define `ship_event_id/v1`, aliases, supersedes rows, and bundle IDs. |
| IDEMP-02 | high | B1,B6,B8,B9,B12 | JSONL append has no crash-tail and lock-boundary contract. | Add lock, newline, fsync, partial-tail quarantine, duplicate replay gates. |
| IDEMP-03 | high | B3,B4,B5,B6,B9,B11 | `evidence_output_hash` can drift with scan order or volatile output. | Hash canonical sorted JSON, not raw command text. |
| IDEMP-04 | high | B1,B6,B7,B12 | Cross-orch simultaneous writes can race. | Define owner repo, write authority, fleet lock/CAS, and conflict reducer. |
| IDEMP-05 | medium | B6,B7,B9,B12 | Tick-close retries lack an evaluation idempotency key. | Key decisions by tick, mode, config, and ledger high-watermark. |
| IDEMP-06 | medium | B7,B9,B12 | Override expiry equality boundary is undefined. | Valid iff `now < expires_at`; equality is expired. |
| IDEMP-07 | medium | B1,B2,B8,B9 | Dogfood import lacks checkpoint/resume semantics. | Add import source IDs, row hashes, offsets, and crash-resume fixture. |
| IDEMP-08 | medium | B1,B4,B5,B11,B12 | Ledger replay reducer ordering is underspecified. | Define one reducer and byte-stable cache rebuild fixture. |
| IDEMP-09 | medium | B3,B7,B9,B12 | Bootstrap recursion can reopen after session reset. | Persist one-shot bootstrap consumed state and self-test hash. |
| IDEMP-10 | medium | B13,B14,B15 | DCG orphan-reset checks can duplicate receipts across retries. | Key by reset intent hash and sorted orphan commit set. |
| IDEMP-11 | low | B2,B3,B8,B12 | `wired_into=<path:line>` is brittle as identity. | Use stable `consumer_id`; path:line is evidence only. |
| IDEMP-12 | low | docs | r2 file path says r2 but body title says r1. | Add body-level `round_id`, `base_round`, and `delta_kind`. |

Severity count:

- critical: 0
- high: 4
- medium: 6
- low: 2
- total: 12

## 4. Detailed Findings

### IDEMP-01 - Stable event identity is not yet mechanical

Severity: high

Sources: `02-REFINE-r2.md:23-31`, `02-REFINE-r2.md:263-271`,
`02-REFINE-r2.md:277-281`, `02-REFINE-r2.md:390-394`.

The plan requires a stable `ship_event_id`, idempotent same-row re-runs,
stable classifier output, and fleet rows containing `ship_repo` and
`ship_actor`. It does not define the exact bytes included in the ID.

Risk: B2, B8, and B12 can each emit the same shipped artifact with a different
ID basis. One artifact then becomes several unresolved rows.

Phase 4 gate:

```text
ship_event_id = wire/v1:sha256(
  repo_canonical_id,
  artifact_class,
  artifact_identity,
  producer_commit_or_source_row,
  ship_group_id_or_none,
  schema_version
)
```

Add `alias_of_ship_event_id` and `supersedes_ship_event_id[]` for renames.
Collector, close-hook backfill, and dogfood import of the same artifact must
reduce to one latest state.

### IDEMP-02 - Append-only writer needs crash-tail semantics

Severity: high

Sources: `02-REFINE-r2.md:29-31`, `02-REFINE-r2.md:268-271`,
`02-REFINE-r2.md:326-331`, `02-REFINE-r2.md:357-363`.

`flock` and append-only are necessary, but the plan does not define behavior
for partial final rows, interrupted writes, or retry after a failed close-hook
receipt.

Risk: a half-written JSON row can poison replay, or a retry can append a
duplicate semantic event with a new timestamp.

Phase 4 gate:

- Validate compact JSON before taking the lock.
- Append one newline-terminated row while holding the lock.
- Document fsync behavior.
- Quarantine at most one partial tail row during replay.
- Re-running the same row ID must not alter latest state or counts.

### IDEMP-03 - Evidence hashes need canonicalization

Severity: high

Sources: `02-REFINE-r2.md:37`, `02-REFINE-r2.md:287-293`,
`02-REFINE-r2.md:299-305`, `02-REFINE-r2.md:311-319`,
`02-REFINE-r2.md:379-384`.

The plan requires `evidence_output_hash`, detector proof, sorted unresolved
lists, doctor counts, and a read-only wire-status surface. It does not define
which fields are hashed or how volatile output is removed.

Risk: filesystem walk order, shifted line numbers, timestamps, temp paths, or
raw command text can change the hash even when the consumer did not change.

Phase 4 gate:

- Hash canonical JSON.
- Sort consumers by stable `consumer_id`.
- Normalize repo paths and scrub volatile fields.
- Include command identity, not only shell text.
- Fixture: shuffled scan order produces identical hash.

### IDEMP-04 - Cross-orch writes need owner and merge rules

Severity: high

Sources: `02-REFINE-r2.md:25`, `02-REFINE-r2.md:67-68`,
`02-REFINE-r2.md:216-223`, `02-REFINE-r2.md:390-394`,
`02-REFINE-r2.md:494-495`.

B12 says each orch blocks only on owned rows, but does not say which orch may
write which rows or how duplicate cross-orch discoveries merge.

Risk: two orchs append unresolved rows for the same artifact; one resolves its
copy while the other stale row keeps blocking.

Phase 4 gate:

- Add `row_owner_repo` and `enforcement_owner`.
- Local orch writes owned rows; fleet orch backfills with the same
  `ship_event_id/v1`.
- Same ID reduces to one latest state.
- Divergent same-ID rows become conflict evidence, not duplicate blockers.

### IDEMP-05 - Tick-close retry key is missing

Severity: medium

Sources: `02-REFINE-r2.md:23`, `02-REFINE-r2.md:326-331`,
`02-REFINE-r2.md:467-470`.

The gate may fire twice in one cadence because of launchd retry, manual tick,
resume, or closeout retry. The plan does not say when to reuse the prior
decision versus re-evaluate.

Risk: two receipts for the same tick can disagree or duplicate `would_block`
rows.

Phase 4 gate:

```text
gate_evaluation_id = sha256(
  repo_id,
  tick_id,
  mode,
  ledger_high_watermark,
  gate_config_hash,
  code_version
)
```

Same key returns the same receipt. Advanced high-watermark creates a superseding
evaluation.

### IDEMP-06 - Override boundary is undefined

Severity: medium

Sources: `02-REFINE-r2.md:42`, `02-REFINE-r2.md:337-341`,
`02-REFINE-r2.md:496`.

The plan rejects expired overrides but does not define equality at `expires_at`.

Risk: two ticks at the boundary can split pass/fail.

Phase 4 gate:

- Override valid iff `now < expires_at`.
- `now == expires_at` is expired.
- Receipts include `evaluated_at`, `expires_at`, `time_source`, and
  `remaining_seconds`.

### IDEMP-07 - Dogfood import needs crash-resume proof

Severity: medium

Sources: `02-REFINE-r2.md:96`, `02-REFINE-r2.md:233`,
`02-REFINE-r2.md:347-351`.

B8 requires idempotent apply and zero duplicate re-run, but not restart after
half the historical corpus imports.

Risk: a crash after N rows can either skip remaining rows or duplicate the
first N rows.

Phase 4 gate:

- Every source has `import_source_id`.
- Every emitted row has `source_offset` or source-row hash.
- Dry-run and apply share the same planner.
- Crash after N rows then rerun equals one-pass import.

### IDEMP-08 - Replay reducer must be single and deterministic

Severity: medium

Sources: `02-REFINE-r2.md:29-30`, `02-REFINE-r2.md:271`,
`02-REFINE-r2.md:299-305`, `02-REFINE-r2.md:379-384`.

The plan says cache is derived from the ledger, but not how latest state is
reduced.

Risk: doctor, close-hook, and wire-status can disagree about resolved state.

Phase 4 gate:

- Primary order: ledger offset ascending.
- Latest state: highest accepted offset per `ship_event_id`.
- Derived cache output sorted by stable ID and unresolved priority tuple.
- Two cache rebuilds from row 1 must be byte-identical.

### IDEMP-09 - Bootstrap state must survive session reset

Severity: medium

Sources: `02-REFINE-r2.md:66`, `02-REFINE-r2.md:337-341`,
`02-REFINE-r2.md:361`, `02-REFINE-r2.md:563-564`.

Bootstrap rows close after self-test and cannot be reused, but the durable
consumed state is not specified.

Risk: compaction or session restart can make an old bootstrap bypass reusable.

Phase 4 gate:

- Persist `bootstrap_id`, `self_test_evidence_hash`, `consumed_at`,
  `consumed_by_code_version`, and `max_bootstrap_expires_at`.
- Reusing a consumed bootstrap row fails after session reset.
- Cross-repo rollout cannot consume another repo's bootstrap row.

### IDEMP-10 - DCG reset blocker needs duplicate suppression

Severity: medium

Sources: `00-INTENT.md:166-177`, `02-REFINE-r2.md:168-192`,
`02-REFINE-r2.md:411-415`, `02-REFINE-r2.md:421-425`.

B14 blocks reset when local worker commits would become orphaned, but repeated
attempts against the same orphan set need stable receipt behavior.

Risk: one unresolved orphan event can create multiple guard rows, duplicate
fuckup rows, and inconsistent recovery command order.

Phase 4 gate:

- `reset_intent_hash = sha256(target_ref,current_head,sorted_orphan_shas)`.
- Orphan set and recovery commands are sorted.
- Same reset attempted three times produces one active incident receipt.

### IDEMP-11 - Path-line proof is evidence, not identity

Severity: low

Sources: `02-REFINE-r2.md:37`, `02-REFINE-r2.md:563`.

`wired_into=<path:line|consumer-id>` allows line-based proof. That is useful
evidence but unstable identity.

Risk: unrelated edits shift line numbers and make an unchanged consumer look
new or missing.

Phase 4 gate:

- Identity is `consumer_id`.
- `path:line` remains evidence excerpt.
- If no stable semantic anchor exists, classify as `questionably_wired`.

### IDEMP-12 - Plan round identity ambiguity

Severity: low

Sources: `02-REFINE-r2.md:1-5`, `02-REFINE-r2.md:558-572`.

The r2 file path is correct, but the body title says r1 and r2 is only an
appended convergence delta.

Risk: a future resume parser can double-count r1/r2 or treat r2 as stale r1.

Phase 4/process gate:

Add body metadata:

```text
round_id=2.REFINE.r2
base_round=2.REFINE.r1
delta_kind=append-only-convergence-delta
supersedes=02-REFINE-r1.md
```

## 5. TRUE-Blocker Class Evaluation

Source: `/flywheel:plan` defines the six legitimate pause classes at
`plan.md:165-198`, severity mapping at `plan.md:213-224`, and auto-advance
transition at `plan.md:379-391`.

| Class | Triggered? | Evaluation |
|---|---:|---|
| `new-platform-or-vendor-not-in-mission-lock` | no | No new platform or vendor is proposed. |
| `secret-rotation-or-new-credential-creation` | no | No key rotation, credential generation, token regeneration, or account creation. |
| `financial-commitment-above-mission-budget` | no | No paid resource or budget change. |
| `legal-or-compliance-decision` | no | No ToS, DPA, legal, or compliance acceptance. |
| `destructive-irreversible-on-shared-state` | no | This is plan-space hardening; B14 blocks loss rather than authorizing destructive action. |
| `paradigm-conflict-with-active-mission` | no | Findings reinforce the r2 paradigm: artifact utilization and tick-close flow authority. |

Result: `blocker_class_evaluations=6/6`, `true_blocker_classes_triggered=none`.

## 6. Cross-Bead Findings

Cross-bead issue A: event identity is shared infrastructure.

- Findings: IDEMP-01, IDEMP-04, IDEMP-07, IDEMP-08, IDEMP-11.
- Beads: B1, B2, B3, B4, B5, B8, B11, B12, B13.
- Action: B1 owns identity schema; all emitters and readers use its fixtures.

Cross-bead issue B: replay must be the single truth operation.

- Findings: IDEMP-02, IDEMP-03, IDEMP-05, IDEMP-08.
- Beads: B1, B3, B4, B5, B6, B9, B11, B12.
- Action: define one reducer library/fixture; doctor, close-hook, and status
  consume the same reducer.

Cross-bead issue C: temporary permission needs exact boundaries.

- Findings: IDEMP-05, IDEMP-06, IDEMP-09.
- Beads: B6, B7, B9, B12.
- Action: B7 owns mode/override/bootstrap semantics; B6 only evaluates them.

Cross-bead issue D: Finding 9 adds git substrate idempotency.

- Findings: IDEMP-01, IDEMP-04, IDEMP-10.
- Beads: B13, B14, B15, plus B1/B2 for branch artifact rows.
- Action: side-branch proof and reset-intent proof share stable row IDs.

## 7. Replay-Test Scenarios

1. Same commit collected by post-commit collector and tick-open backfill.
   Expected: one `ship_event_id`, one latest state, no duplicate unresolved
   count. Covers IDEMP-01 and IDEMP-02.

2. Ledger with five valid rows and a truncated sixth row.
   Expected: five rows replay, one partial tail quarantined, retry appends one
   valid replacement. Covers IDEMP-02 and IDEMP-08.

3. Same tick closes twice with identical ledger high-watermark.
   Expected: same `gate_evaluation_id`, same receipt, no duplicate
   `would_block` row. Covers IDEMP-05.

4. Same tick closes after ledger high-watermark advances.
   Expected: second decision supersedes first. Covers IDEMP-05 and IDEMP-08.

5. Detector scan order reverses.
   Expected: sorted consumers and identical `evidence_output_hash`. Covers
   IDEMP-03.

6. Override evaluated exactly at `expires_at`.
   Expected: expired; enforce fails, shadow warns. Covers IDEMP-06.

7. Dogfood importer crashes after N rows and reruns.
   Expected: final ledger equals clean one-pass import. Covers IDEMP-07.

8. Two orchs detect the same cross-repo pending row.
   Expected: same `ship_event_id`; reducer shows one latest pending row. Covers
   IDEMP-04 and IDEMP-08.

9. Bootstrap row consumed, then session resets.
   Expected: old bootstrap cannot be reused. Covers IDEMP-09.

10. Same DCG reset attempted three times with unchanged orphan set.
    Expected: same sorted orphan list, same recovery commands, one active
    incident receipt. Covers IDEMP-10.

11. Consumer proof line shifts after unrelated edits.
    Expected: stable `consumer_id`; evidence excerpt changes only. Covers
    IDEMP-03 and IDEMP-11.

12. Derived cache deleted and rebuilt twice from row 1.
    Expected: byte-identical cache; doctor and wire-status agree. Covers
    IDEMP-08.

Replay scenario count: 12.

## 8. Score Rationale

Scoring:

- Identity determinism: 1.6 / 2.5
- Atomic append and replay safety: 1.7 / 2.5
- Retry and mode-boundary safety: 1.4 / 2.0
- Cross-orch and historical import safety: 1.3 / 2.0
- Existing mitigation coverage: 1.2 / 1.0 before normalization because B1,
  B7, B8, and B9 already contain direct idempotency gates.

Composite: **7.2 / 10.0**.

Why this passes:

- B1 already names `flock`, no prior-row rewrite, idempotent same-row re-run,
  and regenerated cache at `02-REFINE-r2.md:263-271`.
- B8 already requires idempotent apply and zero duplicate re-run at
  `02-REFINE-r2.md:347-349`.
- B9 already includes fixtures for recursion, cross-repo expiry, and stale
  consumer supersession at `02-REFINE-r2.md:357-363`.

Why it is not higher:

- Stable IDs, reducer order, evidence canonicalization, crash-tail recovery,
  and cross-orch write ownership need explicit acceptance gates.

## 9. Phase 4 Mapping

| Finding | Owner | Gate addition |
|---|---|---|
| IDEMP-01 | B1+B2 | Define `ship_event_id/v1`; duplicate discovery fixture. |
| IDEMP-02 | B1+B9 | Partial-tail replay and concurrent writer fixture. |
| IDEMP-03 | B3+B9 | Canonical evidence JSON and shuffled scan fixture. |
| IDEMP-04 | B12+B1 | Cross-orch duplicate pending row fixture. |
| IDEMP-05 | B6+B7 | `gate_evaluation_id` high-watermark fixture. |
| IDEMP-06 | B7+B9 | Expiry before/equal/after fixture. |
| IDEMP-07 | B8+B9 | Crash/resume importer fixture. |
| IDEMP-08 | B1+B4+B5+B11 | Shared reducer and byte-stable cache rebuild. |
| IDEMP-09 | B7+B9 | Bootstrap consumed-state fixture. |
| IDEMP-10 | B14+B15 | Reset-intent hash and duplicate incident suppression. |
| IDEMP-11 | B3+B12 | Consumer ID independent of path line number. |
| IDEMP-12 | plan pipeline | Body-level round metadata. |

## 10. Systems Reading

System boundary: flywheel tick close and fleet artifact wiring.

Stock: unresolved shipped artifacts plus duplicate or stale ledger rows.

Flow hazard: retries and concurrent orchs add rows faster than reducers prove a
single latest state.

Feedback loop: the gate is a balancing loop only if replay is stable. If replay
is nondeterministic, the balancing loop becomes noise.

Leverage points:

- Meadows #5, rules: stable IDs, lock semantics, reducer order, and override
  boundaries are system rules.
- Meadows #6, information flows: expose duplicate suppression, partial-tail
  quarantine, and replay counts in doctor/status.
- Meadows #4, self-organization: encode replay scenarios as reusable B9
  fixtures so future beads inherit the contracts.

Gate-truth separation:

- This remains a flow gate.
- It does not prove code correctness, deploy safety, or mission preference.
- Idempotency hardening prevents a flow gate from becoming noisy process truth.

## 11. Final Decision

Audit disposition: **auto-advance eligible for this lens**.

Conditions:

- No critical findings.
- No TRUE Joshua-blocker class triggered.
- All high findings have Phase 4 bead owners and mechanical gates.
- Composite score is above the 7.0 pass threshold.

Callback metrics:

```text
findings_total=12
findings_by_severity={critical:0,high:4,medium:6,low:2}
composite_score=7.2
true_blocker_classes_triggered=none
blocker_class_evaluations=6/6
replay_scenarios_count=12
socraticode_queries=4
indexed_chunks_observed=40
commits_total=0
```
