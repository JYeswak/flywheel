---
title: "Phase 3 AUDIT r1 - Lens B: Evidence Contract and Closeout Integrity"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 AUDIT r1 - Lens B: Evidence Contract and Closeout Integrity

Plan: `validate-everything-we-build-2026-05-03`
Lens: `evidence-contract-closeout`
Auditor: flywheel:4 worker context for nominal flywheel:3 dispatch
Zero round: no

## Preconditions and Baseline

- Capacity gate run: `.flywheel/scripts/dispatch-capacity-gate.sh flywheel 3` returned `blocked` with `reason=activity_THINKING`; audit continued in the receiving worker context because this pane was already assigned the dispatch.
- Skills library baseline used skill-search fallback for `validation schema idempotency closeout artifact evidence audit`.
- Skills surfaced and applied: `data-quality-validation`, `codebase-audit`, `jeff-convergence-audit`, `request-validation`.
- Socraticode survey run against `/Users/josh/Developer/flywheel` for `validation receipt schema missing artifact callback no bead reason tick punt closeout integrity`; hits included AGENTS L67/L70, josh-request schema invalid closure notes, and dispatch contract surfaces.

## Summary

The converged plan has the right mechanical shape: B01 defines a receipt schema and fixture corpus, B03 gates callbacks before integration, B06/B07 are dry-run first with idempotency/deduplication requirements, and B04/B05/B09/B12 give the producer -> consumer path needed by L60.

The audit found 4 issues: 0 critical, 2 high, 2 medium. The high issues should be fixed before Phase 4 bead creation because the final plan and the pre-draft bead packet currently disagree about the bead set and B12 does not yet name every synthetic closeout failure required by the final test plan.

## Findings

| id | severity | criticality | component/bead | file:line | finding | evidence | recommended change | decision_needed |
|---|---|---|---|---|---|---|---|---|
| EV-001 | high | blocks_phase4 | B04/B09/B10/B11/B12, missing B13/B14 bead bodies | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r4.md:85`; `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:688` | Final plan adds B13/B14 as load-bearing dependencies, but the Phase 4 pre-draft artifact still contains only B01-B12 and creation notes for that older DAG. | R4 says B13/B14 were added and B04/B09/B10/B11/B12 depend on them (`02-REFINE-r4.md:85`, `:101`, `:102`, `:129`, `:130`, `:138`, `:139`, `:143`, `:144`, `:146`, `:153`, `:154`). The pre-draft DAG has only B01-B12 (`04-BEADS-PREDRAFT.md:70`-`:91`) and Phase 4 creation notes say to add dependencies from that artifact (`04-BEADS-PREDRAFT.md:688`-`:696`). | Before Phase 4, add B13 and B14 pre-draft bodies with acceptance gates, DOD, dependencies, and close reasons, or explicitly remove them from the final DAG and replace their signals with a no-bead reason. | yes |
| EV-002 | high | must_fix_before_beads | B12 e2e smoke harness + rollout | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:650`; `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r4.md:183` | B12 does not explicitly include every required synthetic closeout-integrity case. | B12 covers missing artifact, fix-bead dry-run, doctor count, VALIDATE blocking, learn routing, L70, Codex parity, rollout modes, and final receipt (`04-BEADS-PREDRAFT.md:650`-`:658`). R4 test plan additionally requires invalid no-bead/L52 failure, BLOCKED without fuckup/L53 failure, and tick punt (`02-REFINE-r4.md:183`-`:188`). B01 has fixtures for those cases (`04-BEADS-PREDRAFT.md:138`-`:140`), but B12 is the final rollout gate and does not name them. | Add B12 gates for invalid no-bead reason, BLOCKED without `fuckups_logged`, closed bead artifact missing, and tick punt, with expected validator/doctor/learn outputs. | no |
| EV-003 | medium | must_fix_before_beads | B03 validate-callback primitive + reaper | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:230`; `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r4.md:62` | B03 does not explicitly state that malformed or schema-invalid receipts are treated as no receipt before summary/integration. | B03 validates missing artifact, timeout, valid DONE, ledger write, failed remediation routing, and `--why` (`04-BEADS-PREDRAFT.md:230`-`:237`). R4 doctor taxonomy says `validation_receipts_schema_invalid_count` means invalid receipt equals no receipt in strict mode (`02-REFINE-r4.md:62`). That rule should be enforced at the callback validator/reaper, not only observed by doctor. | Add a B03 acceptance gate: malformed/free-text/schema-invalid receipt returns non-zero, records `failure_class=invalid_receipt` or equivalent, is treated as no receipt, and blocks summary/integration. | no |
| EV-004 | medium | can_polish | B04 doctor validation signals | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:277`; `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r4.md:56` | B04 allows some signals only "if those producers exist," which can preserve silent-darkness unless final rollout requires producer proof or an explicit no-signal reason. | B04 requires core callback/tick/surface signals but marks schema-invalid, context-drift, and unrouted-event signals conditional (`04-BEADS-PREDRAFT.md:277`-`:285`). R4 classifies those signals as part of the doctor taxonomy (`02-REFINE-r4.md:56`-`:64`) and L60 requires producer, measurement, consumer, and promotion. | Keep warn-only rollout if needed, but require B12 final receipt to prove every B04 signal has a producer and fixture or an explicit no-signal/no-bead reason. | yes |

## Findings Register Rows

| id | lens | criticality | component/bead | file:line | finding | evidence | recommended action | owner phase | decision_needed | status |
|---|---|---|---|---|---|---|---|---|---|---|
| EV-001 | evidence-contract-closeout | blocks_phase4 | B04/B09/B10/B11/B12, missing B13/B14 bead bodies | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/02-REFINE-r4.md:85` | Final plan adds B13/B14 as load-bearing dependencies, but Phase 4 pre-draft remains B01-B12. | R4 B13/B14 dependency edges conflict with B01-B12-only pre-draft DAG and creation notes. | Add B13/B14 bead bodies or remove them from final DAG with explicit no-bead reason. | Phase 4 DECOMPOSE | yes | open |
| EV-002 | evidence-contract-closeout | must_fix_before_beads | B12 e2e smoke harness + rollout | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:650` | B12 does not explicitly include every required synthetic closeout-integrity case. | R4 test plan names invalid no-bead, BLOCKED without fuckup, and tick punt; B12 omits some of these final e2e gates. | Add B12 gates for invalid no-bead reason, BLOCKED without `fuckups_logged`, closed bead artifact missing, and tick punt. | Phase 4 DECOMPOSE | no | open |
| EV-003 | evidence-contract-closeout | must_fix_before_beads | B03 validate-callback primitive + reaper | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:230` | B03 does not explicitly treat malformed/schema-invalid receipts as no receipt. | R4 doctor taxonomy states invalid receipt equals no receipt, but B03 gates omit the validator/reaper behavior. | Add malformed/schema-invalid receipt fixture and reaper block behavior to B03. | Phase 4 DECOMPOSE | no | open |
| EV-004 | evidence-contract-closeout | can_polish | B04 doctor validation signals | `.flywheel/plans/validate-and-redispatch-foundational-2026-05-03/04-BEADS-PREDRAFT.md:282` | Conditional producer wording can preserve silent-darkness for schema/context/learn-route signals. | B04 says some signals emit if producers exist; R4 and L60 require producer/measurement/consumer/promotion. | Require B12 final receipt to prove producer existence or explicit no-signal/no-bead reason for every B04 signal. | Phase 5 POLISH | yes | open |

## Acceptance Gate Check

| gate | verdict | notes |
|---|---|---|
| 1. B01 schema represents pass/fail/unknown/missing artifact/invalid callback/context drift/no-bead/tick punt | pass | B01 names required fields and fixture corpus including valid DONE, missing artifact, BLOCKED without fuckup, runtime unresponsive, context drift, valid/invalid no-bead, closed bead missing artifact, and tick-punted (`04-BEADS-PREDRAFT.md:138`-`:144`). |
| 2. B02 dispatch template validation fields and rejects missing fields | pass | B02 requires validation block fields, template audit fixture, and valid Claude/Codex worker packet fixtures (`04-BEADS-PREDRAFT.md:184`-`:190`). |
| 3. B03 validates callbacks before summary/integration and malformed receipts as no receipt | partial | B03 gates validation before integrate and refusal to summarize failed callbacks (`04-BEADS-PREDRAFT.md:230`-`:237`), but malformed/schema-invalid receipt handling is only explicit in R4 doctor taxonomy (`02-REFINE-r4.md:62`). Finding EV-003. |
| 4. B06 auto-open fix-bead behavior is idempotent and dry-run/apply separated | pass | B06 requires dry-run payload, duplicate detection, idempotency key, apply mode, audit receipt, repo-local proof, and tests (`04-BEADS-PREDRAFT.md:371`-`:377`). |
| 5. B07 auto-reopen distinguishes deterministic missing artifact from ambiguous evidence and starts candidate-first | pass | B07 requires deterministic missing/smoke/schema failures to create candidates, ambiguous evidence to remain unknown, and dry-run default (`04-BEADS-PREDRAFT.md:417`-`:423`). |
| 6. B12 includes synthetic e2e tests for required closeout failures | partial | B12 covers core missing-artifact flow but does not explicitly include all final-plan synthetic failure cases. Finding EV-002. |
| 7. Every mutating path has rollback/no-op safety | pass with watch | B06 and B07 require dry-run/apply separation, duplicate detection, idempotency, audit receipts, and repo-local scope. B09 also has one-event/dedup routing. EV-004 adds final producer/no-signal proof for doctor rollout. |
| 8. Flag "documented/should" language substituting for mechanical gate | found | EV-001 is the main substitution risk: final R4 documents B13/B14 but the Phase 4 pre-draft does not yet create mechanical bead bodies for them. |

## Callback Counts

- findings=4
- critical=0
- high=2
- zero_round=no
