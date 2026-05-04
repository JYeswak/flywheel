# Phase 3 AUDIT r1 Lens C: Doctrine, Learning Loop, and No-Punt Wire-In

Plan: `validate-everything-we-build-2026-05-03`
Lens: `doctrine-learning-no-punt`
Auditor: flywheel:3 / Codex
Date: 2026-05-03
Verdict: `zero_round=no`

## Skills Baseline

Requested slash surface:

```bash
/flywheel:skills-best-practices "doctor signal doctrine wire-in learn loop no punt orchestration" --top=10 --include-content
```

Result: local CLI returned `ERR: unknown command: skills-best-practices`, so I used the skill-search MCP fallback.

Relevant surfaced skills:

| skill | use in this audit |
|---|---|
| `flywheel-doctor-author` | Adopted for L60 producer / measurement / consumer / promotion framing. |
| `loop-enforcement` | Adopted for loop / tick / no-punt mechanics. |
| `socraticode` | Used for doctrine and plan precedent search. |
| `agent-orchestration` / `agent-governance` / `agent-memory` | Evaluated as supporting doctrine context. |

`skills_library_gap=none_for_doctor_or_loop_patterns; partial_for_validation_discipline_skill_until_B10`

## Socraticode Ledger

Queries run against `/Users/josh/Developer/flywheel`:

1. `doctor validation signals producer measurement consumer promotion ticks_punted surfaces_unwired validation_events_unrouted`
2. `L70 no-punt chain_if_capacity ticks_punted_count same tick BEADS DISPATCH LEARN`
3. `flywheel learn validation routing duplicate positive outcome fuckup INCIDENTS L-rule skill extension`

Observed indexed chunks covered AGENTS L56/L60/L61/L69/L70, INCIDENTS no-punt entries, josh-request consumers, and learn/promotion doctrine.

## Acceptance Gate Results

| gate | result | evidence |
|---|---|---|
| 1. Doctor signals have producer, measurement, consumer, threshold, promotion | `partial` | Final plan defines signal names and some behavior in `02-REFINE-r4.md:54`, but B04 lacks concrete threshold/gate behavior for all signals in `04-BEADS-PREDRAFT.md:277`. |
| 2. Doctrine includes AGENTS, README, memory, INCIDENTS/fuckup evidence, skill update/no-skill reason | `partial` | B10 covers most surfaces in `04-BEADS-PREDRAFT.md:554`, but its proof dependency set is stale and omits B13/B14. |
| 3. `/flywheel:learn` routes validation events exactly once and separates failures from positives | `pass` | B09 acceptance gates cover failed validation, positive validation, duplicate scan, and review surface in `04-BEADS-PREDRAFT.md:509`. |
| 4. L70 chain-forward is mechanical in B08 | `pass` | B08 requires `chain_if_capacity`, `chain_blocked_reason`, `ticks_punted_count`, and same-tick chain tests in `04-BEADS-PREDRAFT.md:462`. |
| 5. Meadows #3/#5 represented, not only #6 info flow | `pass with follow-up` | Final plan explicitly adds B13/B14 to land goal/rule machinery in `02-REFINE-r4.md:85`, but those beads are not fully pre-drafted. |
| 6. B14 makes every surface finite and auditable | `missing in pre-draft` | Final plan requires B14 in `02-REFINE-r4.md:101`, but `04-BEADS-PREDRAFT.md` contains no B14 body. |
| 7. Joshua-disposes decisions explicit | `pass` | Tradeoffs are preserved for Joshua in `02-REFINE-r4.md:198`; Phase 3 pause shape is defined in audit prep. |
| 8. Doctrine does not land before executable proof | `partial` | B10 says proof from B03-B09, while final plan now requires B13/B14 before doctrine landing. |

## Findings

| id | severity | criticality | component/bead | file:line | finding | evidence | recommended change | decision_needed |
|---|---|---|---|---|---|---|---|---|
| WIRE-001 | high | must_fix_before_beads | B14 / three-Q surface registry | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:1` | The final plan depends on B14 to make “every surface” finite and auditable, but the pre-draft artifact has no B14 bead body. | `02-REFINE-r4.md:85` says B13/B14 were added after Meadows analysis; `02-REFINE-r4.md:101` defines B14; `02-REFINE-r4.md:123` and `:166` put B14 in the DAG/waves. `04-BEADS-PREDRAFT.md` only pre-drafts B01-B12. | Add a full B14 pre-draft or Phase 4 create body with acceptance gates for finite surface inventory, Q1/Q2/Q3 evidence refs, unwired-surface output, and doctor/learn handoff. | no |
| WIRE-002 | high | must_fix_before_beads | B10 / doctrine-memory-wire | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:556` | B10 is stale relative to the converged DAG and can land L71 / VALIDATE-CALLBACK / THREE-Q doctrine before the executable proof beads exist. | B10 acceptance says doctrine lands only after executable proof from B03-B09. Final plan adds B13 capture-goal alignment and B14 three-Q registry before B10 in `02-REFINE-r4.md:140`; B10 row in `02-REFINE-r4.md:98` now includes L71 and THREE-Q doctrine. | Update B10 dependencies and gates to require B13 and B14 proof before doctrine landing, or mark any earlier doctrine as explicit candidate/temporary doctrine. | no |
| WIRE-003 | high | must_fix_before_beads | B04 / doctor signal taxonomy | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:277` | B04 does not yet specify complete L60 threshold/gate behavior for every planned doctor signal. | Final signal set in `02-REFINE-r4.md:54` includes callbacks, punted ticks, capture gaps, unwired surfaces, missing artifacts, invalid receipts, context drift, and unrouted events. B04 only states one explicit strict threshold for `callbacks_unvalidated_count` and leaves several signals conditional with “if those producers exist.” | Add a per-signal table to B04 covering source, producer, measurement, consumer, threshold, gate behavior, and promotion path for every signal named in r4, including B13/B14-driven signals. | no |

## Findings Register Rows

| id | lens | criticality | component/bead | file:line | finding | evidence | recommended action | owner phase | decision_needed | status |
|---|---|---|---|---|---|---|---|---|---|---|
| WIRE-001 | doctrine-learning-no-punt | must_fix_before_beads | B14 / three-Q surface registry | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:1` | Final plan requires B14 but no B14 pre-draft exists. | `02-REFINE-r4.md:85`, `:101`, `:123`, `:166`; no B14 body in `04-BEADS-PREDRAFT.md`. | Add full B14 bead body before Phase 4 creation. | Phase 4 prep | no | open |
| WIRE-002 | doctrine-learning-no-punt | must_fix_before_beads | B10 / doctrine-memory-wire | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:556` | B10 proof gates omit B13/B14 despite final DAG requiring them before doctrine landing. | `04-BEADS-PREDRAFT.md:556`; `02-REFINE-r4.md:98`, `:140`. | Update B10 dependencies and acceptance gates before creating bead. | Phase 4 prep | no | open |
| WIRE-003 | doctrine-learning-no-punt | must_fix_before_beads | B04 / doctor signal taxonomy | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:277` | B04 lacks complete L60 threshold/gate behavior for every signal. | `02-REFINE-r4.md:54`; `04-BEADS-PREDRAFT.md:277`. | Add per-signal L60 table covering all r4 signals. | Phase 4 prep | no | open |

## Passing Coverage Notes

- B08 is the strongest no-punt mechanism: it names `chain_if_capacity`, `chain_blocked_reason`, same-tick chaining tests, callback-driven next-phase chaining, and `ticks_punted_count`.
- B09 has sufficient shape for `/flywheel:learn` exactly-once routing: failed validations become learn/fuckup events, positive validations become outcome receipts or explicit ignore reasons, and duplicate detection is required.
- The converged plan correctly promotes Meadows #3/#5 work by adding B13/B14. The remaining issue is pre-draft and dependency alignment, not conceptual absence.
- Joshua-disposes pause remains explicit; I found no place where the plan silently converts Joshua decisions into beads before review.

## Convergence Verdict

`zero_round=no`

Counts:

- `findings=3`
- `critical=0`
- `high=3`

This lens reaches zero after a reread confirms B14 exists, B10 depends on B13/B14 proof, and B04 has complete per-signal L60 threshold/gate rows.
