# 05-POLISH-r0 - Fleet Autonomy Bead Dispatchability Review

Task ID: polish-review-fleet-autonomy-2026-05-05
Mode: /flywheel:worker-tick parity
Scope: read-only polish review
Output artifact: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/05-POLISH-r0.md`
Bead DB writes: 0
Source edits: 0
Unique fleet bead IDs reviewed: 10
Deprecation tombstone overlays reviewed: 2
Total scorecard rows: 12
Review composite: 9.45
Average bead dispatchability score: 9.05
Highest scoring bead: `flywheel-2j1dw` at 9.50, tied with `flywheel-12k9o` at 9.50
Lowest scoring bead: `flywheel-3lslr` at 8.50, tied with `flywheel-iaws7` at 8.50
Systemic gaps count: 6
High-impact recommendations: 5
Proposed edits count: 18
Cross-plan edges valid: 4/4
Deprecation tombstones complete: 2/2
Convergence status: r0 baseline

## 0. Read-Only Receipt

This review did not run `br update`.
This review did not run `br create`.
This review did not run `br close`.
This review did not run `br sync`.
This review did not write `.beads/*`.
This review used `br show <id> --json` only for bead body inspection.
This review used `br dep cycles` as a read-only graph sanity check.
The cycle check returned no dependency cycles.
The target output artifact did not exist before this review.

Dispatch count reconciliation:
The dispatch says "10 beads + 2 deprecation tombstones" and asks for 12 scorecard rows.
The DAG says `total_beads_created: 10` and `deprecation_tombstones: 2` at `04-BEADS-DAG.md:8-12`.
The live fleet list contains 10 unique fleet-autonomy bead IDs.
Two of those 10 unique IDs are tombstones: `flywheel-3lslr` and `flywheel-iaws7`.
To satisfy the 12-row review contract without inventing bead IDs, this artifact scores:
10 live bead body rows.
2 tombstone-completeness overlay rows.

Primary source citations:
`00-PLAN-r2.md:324-454` defines P1 selector and `selector_receipt/v1`.
`00-PLAN-r2.md:456-555` defines P2 same-candidate suppression and `retry_state_receipt/v1`.
`00-PLAN-r2.md:557-603` defines deprecated primitive carry-forward.
`00-PLAN-r2.md:637-669` defines P4/P5/P6 baseline gates.
`02-AUDIT-r2.md:289-315` defines PARTIAL-1 source/freshness underfit.
`02-AUDIT-r2.md:318-343` defines PARTIAL-2 blocker-owner field underfit.
`02-AUDIT-r2.md:345-372` defines PARTIAL-3 mission-delta provenance underfit.
`02-AUDIT-r2.md:374-380` requires Phase 4 to carry partials into bead acceptance.
`04-BEADS-DAG.md:84-96` lists the fleet bead table.
`04-BEADS-DAG.md:114-135` lists live dependency rows.
`04-BEADS-DAG.md:301-343` records the tombstone register.
`04-BEADS-DAG.md:344-383` records the cross-plan edge ledger.
`manager-loop-architecture-2026-05-05/04-BEADS-DAG.md:48-56` names manager-loop nodes.
`manager-loop-architecture-2026-05-05/04-BEADS-DAG.md:69-77` lists manager-loop bead IDs.

Scoring method:
Each row uses ten dimensions from the dispatch.
SC means self-contained.
AG means acceptance gates mechanical.
FT means files-touched estimate honest.
TP means test plan executable.
DP means dependencies wired.
PC means plan-section citation present.
AP means audit-r2 partial mitigation traceable.
SK means skills cited.
DT means deprecation tombstone completeness.
CE means cross-plan-edge integrity.
Scores are 0.0 to 10.0.
N/A dimensions are scored 10 only when the bead is genuinely outside that dimension.

## 1. Per-Bead Polish Scorecard

| row | review_unit | kind | SC | AG | FT | TP | DP | PC | AP | SK | DT | CE | score |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | `flywheel-181e5` | audit-partial contract freeze | 9 | 8 | 9 | 8 | 10 | 10 | 10 | 10 | 10 | 10 | 9.40 |
| 2 | `flywheel-3ctlx` | audit-partial contract freeze | 9 | 8 | 9 | 8 | 10 | 8 | 10 | 10 | 10 | 10 | 9.20 |
| 3 | `flywheel-2j1dw` | audit-partial contract freeze | 9 | 8 | 9 | 9 | 10 | 10 | 10 | 10 | 10 | 10 | 9.50 |
| 4 | `flywheel-2bxry` | retained primitive P1 | 10 | 9 | 9 | 9 | 10 | 10 | 8 | 10 | 10 | 10 | 9.50 |
| 5 | `flywheel-12k9o` | retained primitive P2 | 10 | 9 | 8 | 9 | 10 | 10 | 9 | 10 | 10 | 10 | 9.50 |
| 6 | `flywheel-3lslr` | deprecation.tombstone body | 9 | 7 | 6 | 7 | 10 | 10 | 8 | 10 | 8 | 10 | 8.50 |
| 7 | `flywheel-iaws7` | deprecation.tombstone body | 9 | 7 | 6 | 7 | 10 | 10 | 8 | 10 | 8 | 10 | 8.50 |
| 8 | `flywheel-3nf8t` | retained primitive P4 baseline | 9 | 8 | 9 | 8 | 10 | 10 | 8 | 10 | 10 | 10 | 9.20 |
| 9 | `flywheel-3q54j` | retained primitive P5 baseline | 9 | 8 | 9 | 9 | 10 | 10 | 8 | 10 | 10 | 10 | 9.30 |
| 10 | `flywheel-1ctd2` | retained primitive P6 baseline | 9 | 8 | 9 | 9 | 10 | 10 | 8 | 10 | 10 | 10 | 9.30 |
| 11 | `flywheel-3lslr` overlay | tombstone completeness overlay | 9 | 7 | 6 | 7 | 10 | 10 | 8 | 10 | 9 | 10 | 8.60 |
| 12 | `flywheel-iaws7` overlay | tombstone completeness overlay | 9 | 7 | 6 | 7 | 10 | 10 | 8 | 10 | 9 | 10 | 8.60 |

### Row 1 - `flywheel-181e5`

Title: `[fleet-autonomy] freeze selector source/freshness fields`.
Self-contained: strong.
It explains the PARTIAL-1 problem and names the exact fields to freeze.
It cites `00-PLAN-r2.md:404-454` and `02-AUDIT-r2.md:289-315`.
It captures the audit-required fields from `02-AUDIT-r2.md:302-314`.
Acceptance quality: good but not yet fully L112-shaped.
AG1 depends on DAG text rather than a receipt/schema probe.
AG2 says A0/A2 fixture reads are required but does not name a command.
AG3 is mechanical in principle.
AG4 names concrete tests.
Files are real and specific.
Test plan names `br doctor`, selector fixture tests, and JSON validation.
Recommendation: add an exact `jq` probe over a selector receipt fixture.

### Row 2 - `flywheel-3ctlx`

Title: `[fleet-autonomy] freeze blocker-owner field placement`.
Self-contained: strong.
It names all five blocker-owner fields required by `02-AUDIT-r2.md:323-340`.
It ties the bead to P1 and P2 consumers.
Plan-section citation is weaker than the others.
The bead cites `00-PLAN-r2.md:208-212`, but the work also depends on `00-PLAN-r2.md:421-423`.
Acceptance quality: good but needs exact schema placement.
AG1 permits either selector or retry receipt placement.
AG2 permits Manager-only placement.
That flexibility is valid, but the body should force the worker to choose one placement and record it.
Files are specific and real.
Dependencies are wired to `flywheel-2bxry` and `flywheel-12k9o`.
Recommendation: add a mechanical assertion that callback prose cannot be the only owner source.

### Row 3 - `flywheel-2j1dw`

Title: `[fleet-autonomy] freeze mission-delta provenance aliases`.
Self-contained: strong.
It cleanly maps PARTIAL-3 to three exact fields.
It cites `00-PLAN-r2.md:605-635` and `02-AUDIT-r2.md:345-372`.
Acceptance quality: good.
AG1 names the three missing fields or exact aliases.
AG2 enforces `mission_delta_computed_by=manager`.
AG3 gives A2 degraded scoring behavior.
AG4 names an existing test.
Files are specific and real.
Recommendation: add the exact JSON schema path or fixture path where these fields will be validated.

### Row 4 - `flywheel-2bxry`

Title: `[fleet-autonomy] P1 bv-next selector contract`.
Self-contained: excellent.
It gives background, command boundary, degraded behavior, receipts, and rollback.
It directly implements plan lines `00-PLAN-r2.md:324-454`.
Dependencies are correct: `flywheel-181e5`, `flywheel-3ctlx`, and `flywheel-2j1dw`.
Acceptance gates are close to dispatch-ready.
AG1 prohibits `br ready` as dispatch authority.
AG2 preserves the six semantic fixture classes from `00-PLAN-r2.md:357-367`.
AG3 names `selector_receipt/v1` fields.
AG4 names degraded fixtures.
AG5 names A0/A2 read checks.
AG6 names rollback behavior.
Gap: no exact L112 command is embedded.
Recommendation: add a one-line command that fails if dispatch selection still calls `br ready`.

### Row 5 - `flywheel-12k9o`

Title: `[fleet-autonomy] P2 same-candidate suppression contract`.
Self-contained: excellent.
It maps directly to `00-PLAN-r2.md:456-555`.
It names `(candidate_id, attempt_state_hash)` as the control key.
It distinguishes delivery uncertainty from BLOCKED callback prose.
Dependencies are correct: `flywheel-2bxry` and `flywheel-3ctlx`.
Acceptance gates cover all P2-A through P2-J behaviors from `00-PLAN-r2.md:485-494`.
Files are mostly specific.
`.flywheel/dispatch-log.jsonl` is a shared append-only surface, so the body should say "fixture or append-only test row only" to avoid broad log mutation.
Recommendation: add receipt-schema validation and explicit append-only audit behavior.

### Row 6 - `flywheel-3lslr`

Title: `[fleet-autonomy] tombstone Fleet P3 status brain`.
Self-contained: good.
It names the deprecated surface and replacement owners.
It cites `00-PLAN-r2.md:557-565` and `02-AUDIT-r2.md:144-149`.
The cross-plan dependencies are valid: `flywheel-2s5pv` and `flywheel-27vu5`.
Tombstone rationale is present.
Completeness gap: AG2 says `br list --json` grep rejects active bead titles that use Fleet P3.
That grep will self-match unless it excludes `deprecation-tombstone`.
Completeness gap: Files list `.beads/issues.jsonl`.
Workers should not directly edit `.beads/issues.jsonl`; bead mutation should go through `br`.
Recommendation: rewrite AG2 as a filtered query over non-tombstone labels and remove `.beads/issues.jsonl` from files touched.

### Row 7 - `flywheel-iaws7`

Title: `[fleet-autonomy] tombstone Fleet M measurement surface`.
Self-contained: good.
It names the deprecated Fleet M surface and routes global display to Manager A4.
It cites `00-PLAN-r2.md:566-572` and `02-AUDIT-r2.md:144-149`.
The cross-plan dependencies are valid: `flywheel-3t1e7` and `flywheel-27vu5`.
Tombstone rationale is present.
Completeness gap: AG4 grep can self-match unless it excludes tombstone labels.
Completeness gap: Files list `.beads/issues.jsonl`.
Recommendation: use a filtered active-primitive grep and remove direct `.beads` file editing from the file estimate.

### Row 8 - `flywheel-3nf8t`

Title: `[fleet-autonomy] P4 stale reservation repair baseline gate`.
Self-contained: good.
It correctly gates repair behind P1/P2 baseline evidence.
It cites `00-PLAN-r2.md:637-669` and `02-AUDIT-r2.md:168-173`.
Dependency on `flywheel-12k9o` is correct.
Files are real and specific.
Acceptance gates name baseline receipt JSON but not its schema path.
AG3 names dry-run and apply receipts.
AG4 requires an audit receipt.
Recommendation: define the baseline receipt schema keys and the exact `jq` probe.

### Row 9 - `flywheel-3q54j`

Title: `[fleet-autonomy] P5 hung pane repair baseline gate`.
Self-contained: good.
It correctly gates repair on live liveness proof.
It cites `00-PLAN-r2.md:637-669` and `02-AUDIT-r2.md:168-173`.
Dependency on `flywheel-12k9o` is correct.
Files are real and specific.
Test plan names existing detector, monitor, and permit tests.
Acceptance gap: baseline receipt schema is not named.
Recommendation: add the required liveness fields and exact permit-gate probe.

### Row 10 - `flywheel-1ctd2`

Title: `[fleet-autonomy] P6 manual Josh nudge reduction baseline gate`.
Self-contained: good.
It correctly protects true Joshua blockers.
It cites `00-PLAN-r2.md:637-669` and `02-AUDIT-r2.md:168-173`.
Dependency on `flywheel-12k9o` is correct.
Files are real and specific, including `.flywheel/flywheel-loop-tick`.
Test plan names existing mission-anchor and capture tests.
Acceptance gap: no exact schema for "human-nudge observations" or "avoided nudge".
Recommendation: add a JSON receipt fixture with `human_nudge_observed`, `artifact_answerable`, `true_joshua_blocker`, and `escalation_preserved`.

### Row 11 - `flywheel-3lslr` Tombstone Overlay

Overlay purpose: score deprecation completeness separately from implementation-bead quality.
Deprecated surface is explicit.
Replacement IDs are explicit.
Rationale is explicit.
Dependency edges exist in the DAG at `04-BEADS-DAG.md:348-357`.
Manager replacement IDs exist in manager DAG lines `manager-loop-architecture-2026-05-05/04-BEADS-DAG.md:51-54`.
Completeness is acceptable.
Hardening needed: self-match-safe grep and no direct `.beads/issues.jsonl` editing.

### Row 12 - `flywheel-iaws7` Tombstone Overlay

Overlay purpose: score deprecation completeness separately from implementation-bead quality.
Deprecated surface is explicit.
Replacement IDs are explicit.
Rationale is explicit.
Dependency edges exist in the DAG at `04-BEADS-DAG.md:358-367`.
Manager replacement IDs exist in manager DAG lines `manager-loop-architecture-2026-05-05/04-BEADS-DAG.md:52-54`.
Completeness is acceptable.
Hardening needed: self-match-safe grep and no direct `.beads/issues.jsonl` editing.

## 2. Composite Per-Bead Score

Average score across 12 review rows: 9.05.
Average score across 10 unique bead IDs: 9.09.
Average score across 8 non-tombstone implementation or contract beads: 9.36.
Average score across 2 tombstone bead bodies: 8.50.
Average score across 2 tombstone overlays: 8.60.

Best dispatchable shape:
`flywheel-2j1dw` is narrowly scoped, cites the exact audit partial, names fields, names tests, and preserves ownership.
`flywheel-12k9o` is also strong because it maps directly to P2's receipt semantics and all major same-candidate cases.

Weakest dispatchable shape:
The two tombstones are conceptually complete but mechanically fragile.
Their greps can self-match.
Their file estimates include `.beads/issues.jsonl`, which is a bad worker target.
They need filtered queries and br-only metadata mutation language.

Composite interpretation:
The bead set is dispatchable after a small r1 body polish.
It is not a redesign problem.
No dependency rewrite is needed.
No bead split is needed.
No cross-plan edge rewrite is needed.
The highest leverage r1 work is replacing judgment-language gates with mechanical L112 probes.

## 3. Cross-Bead Patterns

Pattern 1: Acceptance gates are mostly semantic but not always command-shaped.
Several bodies say "validate" or "prove" without giving the future worker an exact command.
This is acceptable for r0 but should be improved before swarm dispatch.
Affected beads: `flywheel-181e5`, `flywheel-3ctlx`, `flywheel-2j1dw`, `flywheel-3nf8t`, `flywheel-3q54j`, `flywheel-1ctd2`.

Pattern 2: Some gates target the DAG artifact instead of the eventual runtime contract.
DAG text is useful plan evidence.
It should not be the primary done artifact for implementation beads.
Affected beads: `flywheel-181e5`, `flywheel-3ctlx`, `flywheel-3nf8t`, `flywheel-3q54j`, `flywheel-1ctd2`.

Pattern 3: Tombstones need self-match-safe validation.
The phrase Fleet P3 or Fleet M appears in the tombstone bead itself.
A naive `br list --json | grep` can fail after the correct tombstone exists.
Affected beads: `flywheel-3lslr`, `flywheel-iaws7`.

Pattern 4: Direct `.beads/issues.jsonl` should not be a worker file target.
Bead metadata should be changed through `br`.
Direct JSONL edits risk bypassing Beads invariants and sync expectations.
Affected beads: `flywheel-3lslr`, `flywheel-iaws7`.

Pattern 5: Baseline gates need receipt schemas before implementation.
P4, P5, and P6 are correctly delayed until P1/P2 baseline exists.
They need a shared baseline receipt shape so workers do not invent three incompatible baselines.
Affected beads: `flywheel-3nf8t`, `flywheel-3q54j`, `flywheel-1ctd2`.

Pattern 6: The dispatch count phrase can confuse future workers.
The DAG has 10 total beads, not 12 unique bead IDs.
Two of the ten are tombstones.
Future reports should say "10 unique beads including 2 tombstones" or "8 implementation beads plus 2 tombstones".
Affected artifact: `04-BEADS-DAG.md:8-12` is correct; the dispatch wording is the ambiguity.

## 4. Top 5 High-Impact Recommendations

Recommendation 1: Add one exact L112-style probe per bead body.
Each probe should be copy-pasteable.
Each probe should fail closed.
Each probe should use `jq`, `rg`, or a named test script.
This is the biggest dispatchability gain.

Recommendation 2: Replace DAG-only acceptance with runtime-contract acceptance.
The DAG can remain a citation.
Done should be proven by schema fixture, receipt output, no-mutation check, or test suite.
This affects contract-freeze and baseline beads.

Recommendation 3: Harden tombstone validation.
Use filtered `br list --json` queries that exclude `deprecation-tombstone` labels and closed/superseded migration notes.
Remove `.beads/issues.jsonl` from tombstone file estimates.
Say "use `br` to update metadata" when metadata changes are part of closure.

Recommendation 4: Define a shared baseline receipt for P4/P5/P6.
Minimum keys: schema version, baseline window id, selector quality, suppression quality, degraded count, fallback count, duplicate redispatch count, manual intervention count, observation class, source hash, and pass/fail.
P4 adds reservation-age observations.
P5 adds pane-liveness observations.
P6 adds human-nudge observations.

Recommendation 5: Put cross-plan replacement receipts inside tombstone bodies.
The cross-plan edges are valid now.
The bodies should still explicitly say that `flywheel-2s5pv`, `flywheel-3t1e7`, and `flywheel-27vu5` must be completed or accepted before tombstone closure.
This prevents a worker from treating the DAG edge as passive documentation.

## 5. Edits-As-Patch Table

| bead_id | dimension | proposed body change | rationale |
|---|---|---|---|
| `flywheel-181e5` | AG | Add `L112: selector_fixture.json jq -e '.selector_data_hash and .selector_freshness_ts and .selector_claim_command and .selector_show_command and .selector_runtime_path and .selector_unblocks'`. | Converts field freeze into a mechanical gate. |
| `flywheel-181e5` | TP | Name the selector fixture path under `.flywheel/fixtures/` or `tests/fixtures/`. | Prevents future worker from inventing fixture location. |
| `flywheel-3ctlx` | PC | Add `00-PLAN-r2.md:421-423` and `00-PLAN-r2.md:507-509` to citations. | Current citation is too narrow for owner placement across selector and retry facts. |
| `flywheel-3ctlx` | AG | Require the worker to choose one placement: selector, retry, or manager_state_fact, then record that choice in the receipt. | Avoids leaving placement ambiguous after the bead. |
| `flywheel-3ctlx` | AG | Add a probe rejecting callback-only owner derivation. | Directly closes `02-AUDIT-r2.md:339-341`. |
| `flywheel-2j1dw` | AG | Add a `jq` probe requiring `mission_delta_source`, `mission_delta_validation_state`, and `mission_delta_computed_by == "manager"`. | Makes PARTIAL-3 closure mechanical. |
| `flywheel-2j1dw` | TP | Add degraded A2 fixture name. | Makes missing-provenance behavior executable. |
| `flywheel-2bxry` | AG | Add a negative grep or shell test proving dispatch selection never uses `br ready`. | Directly enforces `00-PLAN-r2.md:329-330` and `00-PLAN-r2.md:391`. |
| `flywheel-2bxry` | AG | Add exact no-mutation or rollback probe. | Rollback is specified but not command-shaped. |
| `flywheel-12k9o` | FT | Clarify `.flywheel/dispatch-log.jsonl` as fixture/append-only test target only. | Avoids broad shared-log mutation. |
| `flywheel-12k9o` | AG | Add schema validation for `retry_state_receipt/v1` with first, second, third, changed, and uncertain fixtures. | Converts P2-A through P2-J into a reproducible matrix. |
| `flywheel-3lslr` | AG | Replace active-title grep with filtered query excluding `deprecation-tombstone` labels. | Prevents tombstone self-match. |
| `flywheel-3lslr` | FT | Remove `.beads/issues.jsonl` from Files and say metadata changes use `br` only. | Prevents direct Beads JSONL edits. |
| `flywheel-iaws7` | AG | Replace active-title grep with filtered query excluding `deprecation-tombstone` labels. | Prevents tombstone self-match. |
| `flywheel-iaws7` | FT | Remove `.beads/issues.jsonl` from Files and say metadata changes use `br` only. | Prevents direct Beads JSONL edits. |
| `flywheel-3nf8t` | AG | Add baseline receipt schema and `jq` probe for reservation-age observations. | Makes P4 entry condition executable. |
| `flywheel-3q54j` | AG | Add baseline receipt schema and `jq` probe for pane-liveness observations plus live capture provenance. | Makes P5 entry condition executable and protects L57/L67 truth-source constraints. |
| `flywheel-1ctd2` | AG | Add baseline receipt schema and `jq` probe for artifact-answerable versus true Joshua-only blockers. | Prevents nudge reduction from hiding real escalations. |

## 6. Cross-Plan-Edge Integrity Report

| edge | dependent | dependency | valid_target | issue |
|---:|---|---|---|---|
| 1 | `flywheel-3lslr` | `flywheel-2s5pv` | yes | Valid manager A0 replacement, cited at `04-BEADS-DAG.md:348-352` and manager table `04-BEADS-DAG.md:72`. |
| 2 | `flywheel-3lslr` | `flywheel-27vu5` | yes | Valid manager A4 replacement, cited at `04-BEADS-DAG.md:353-357` and manager table `04-BEADS-DAG.md:74`. |
| 3 | `flywheel-iaws7` | `flywheel-3t1e7` | yes | Valid manager A2 replacement, cited at `04-BEADS-DAG.md:358-362` and manager table `04-BEADS-DAG.md:73`. |
| 4 | `flywheel-iaws7` | `flywheel-27vu5` | yes | Valid manager A4 replacement, cited at `04-BEADS-DAG.md:363-367` and manager table `04-BEADS-DAG.md:74`. |

cross.plan.edge verdict: 4/4 valid.
All four targets are in the allowed manager-loop target set from the dispatch.
All four targets are present in the manager-loop DAG.
All four targets match the replacement rationale in the fleet DAG.
No edge points to a non-existent manager-loop bead.
No tombstone depends on the entire manager-loop chain unnecessarily.
No fleet bead attempts to own manager-loop architecture.

## 7. Deprecation Tombstone Audit

| tombstone | deprecated surface | replacements | rationale present | dependency complete | mechanical gap | completeness |
|---|---|---|---|---|---|---|
| `flywheel-3lslr` | Fleet P3 status brain | `flywheel-2s5pv`, `flywheel-27vu5` | yes | yes | self-match-safe grep and no direct `.beads/issues.jsonl` target needed | complete with r1 hardening |
| `flywheel-iaws7` | Fleet M measurement surface | `flywheel-3t1e7`, `flywheel-27vu5` | yes | yes | self-match-safe grep and no direct `.beads/issues.jsonl` target needed | complete with r1 hardening |

Tombstone 1 evidence:
The DAG identifies `flywheel-3lslr` at `04-BEADS-DAG.md:302-320`.
It maps replacement owner to manager A0 and A4 at `04-BEADS-DAG.md:306-308`.
It gives the rationale at `04-BEADS-DAG.md:309-315`.
It gives completion expectations at `04-BEADS-DAG.md:316-320`.

Tombstone 2 evidence:
The DAG identifies `flywheel-iaws7` at `04-BEADS-DAG.md:321-339`.
It maps replacement owner to manager A2 and A4 at `04-BEADS-DAG.md:325-327`.
It gives the rationale at `04-BEADS-DAG.md:328-334`.
It gives completion expectations at `04-BEADS-DAG.md:335-339`.

Deprecation verdict:
The tombstones are complete as migration markers.
They are not yet ideal as worker-dispatch bodies.
Their r1 polish should focus on mechanical validation shape, not design changes.

## 8. Convergence Assessment

Round: r0 baseline.
Convergence test from dispatch: 2 consecutive rounds with less than 5 percent changes.
Current state: baseline established, not yet converged.
Expected r1 change size: small but above 5 percent because 18 body edits are recommended.
Expected r2 state after r1: likely below 5 percent if r1 only adds probes and tombstone hardening.
Proceed to r1 body update round after the parallel manager-loop review lands.

What should not change in r1:
Do not change the 10 unique bead IDs.
Do not add new fleet-autonomy beads.
Do not remove the tombstones.
Do not change the 4 cross-plan edges.
Do not move P4/P5/P6 before P2.
Do not move manager-loop state/scoring/rendering back into fleet.
Do not revive `br ready` as a dispatch selector.
Do not treat callback prose as a retry controller.

What should change in r1:
Add exact L112 probes.
Harden tombstone greps.
Remove direct `.beads/issues.jsonl` file targets.
Add shared baseline receipt schema language.
Clarify append-only shared log behavior.
Tighten blocker-owner plan citations.

Readiness call:
The graph is structurally sound.
The cross-plan edges are valid.
The tombstones are conceptually complete.
The implementation beads are mostly dispatchable.
The bead set should receive a body-polish r1 before implementation dispatch.

## 9. Evidence Appendix

Evidence 001: `04-BEADS-DAG.md:8` says 10 total beads were created.
Evidence 002: `04-BEADS-DAG.md:11` says 2 deprecation tombstones exist.
Evidence 003: `04-BEADS-DAG.md:14-15` says dependency cycles are zero.
Evidence 004: `04-BEADS-DAG.md:25-33` cites the primary R2 plan anchors.
Evidence 005: `04-BEADS-DAG.md:34-39` cites the primary R2 audit anchors.
Evidence 006: `04-BEADS-DAG.md:50-59` names all 10 fleet bead nodes.
Evidence 007: `04-BEADS-DAG.md:60-62` names the three manager-loop replacement nodes used by fleet tombstones.
Evidence 008: `04-BEADS-DAG.md:84-96` lists the bead table.
Evidence 009: `04-BEADS-DAG.md:103-113` lists fleet-internal dependency commands.
Evidence 010: `04-BEADS-DAG.md:114-120` lists cross-plan tombstone dependency commands.
Evidence 011: `04-BEADS-DAG.md:121-135` lists live dependency rows.
Evidence 012: `04-BEADS-DAG.md:141-169` defines Wave 0 contract-freeze work.
Evidence 013: `04-BEADS-DAG.md:170-190` defines Wave 1 P1 selector work.
Evidence 014: `04-BEADS-DAG.md:191-208` defines Wave 2 P2 suppression work.
Evidence 015: `04-BEADS-DAG.md:209-229` defines Wave 3 tombstone work.
Evidence 016: `04-BEADS-DAG.md:230-249` defines Wave 4 repair baseline work.
Evidence 017: `04-BEADS-DAG.md:250-300` maps 3/3 audit partials to beads.
Evidence 018: `04-BEADS-DAG.md:301-343` records the tombstone register.
Evidence 019: `04-BEADS-DAG.md:344-383` records the cross-plan edge register.
Evidence 020: `04-BEADS-DAG.md:384-402` details `flywheel-181e5`.
Evidence 021: `04-BEADS-DAG.md:403-422` details `flywheel-3ctlx`.
Evidence 022: `04-BEADS-DAG.md:423-440` details `flywheel-2j1dw`.
Evidence 023: `04-BEADS-DAG.md:441-461` details `flywheel-2bxry`.
Evidence 024: `04-BEADS-DAG.md:462-483` details `flywheel-12k9o`.
Evidence 025: `04-BEADS-DAG.md:484-502` details `flywheel-3lslr`.
Evidence 026: `04-BEADS-DAG.md:503-521` details `flywheel-iaws7`.
Evidence 027: `04-BEADS-DAG.md:522-538` details `flywheel-3nf8t`.
Evidence 028: `04-BEADS-DAG.md:539-555` details `flywheel-3q54j`.
Evidence 029: `04-BEADS-DAG.md:556-572` details `flywheel-1ctd2`.
Evidence 030: `04-BEADS-DAG.md:583-608` repeats count and cycle proof.
Evidence 031: `00-PLAN-r2.md:324-330` forbids `br ready` as dispatch authority and names `bv --robot-next`.
Evidence 032: `00-PLAN-r2.md:357-367` defines P1 selector fixtures.
Evidence 033: `00-PLAN-r2.md:368-380` defines P1 acceptance gates.
Evidence 034: `00-PLAN-r2.md:404-454` defines `selector_receipt/v1`.
Evidence 035: `00-PLAN-r2.md:456-494` defines P2 same-candidate acceptance.
Evidence 036: `00-PLAN-r2.md:511-555` defines `retry_state_receipt/v1`.
Evidence 037: `00-PLAN-r2.md:557-603` defines deprecated carry-forward constraints.
Evidence 038: `00-PLAN-r2.md:637-669` defines P4/P5/P6 baseline entry conditions.
Evidence 039: `02-AUDIT-r2.md:289-315` requires selector source and freshness fields.
Evidence 040: `02-AUDIT-r2.md:318-343` requires blocker-owner field placement.
Evidence 041: `02-AUDIT-r2.md:345-372` requires mission-delta provenance aliases.
Evidence 042: `02-AUDIT-r2.md:374-380` says partials must become bead acceptance or dependencies.
Evidence 043: manager-loop DAG `04-BEADS-DAG.md:48-56` names manager replacement nodes.
Evidence 044: manager-loop DAG `04-BEADS-DAG.md:69-77` validates replacement bead IDs.
Evidence 045: read-only `br show flywheel-181e5 --json` confirmed dependent `flywheel-2bxry`.
Evidence 046: read-only `br show flywheel-3ctlx --json` confirmed dependents `flywheel-2bxry` and `flywheel-12k9o`.
Evidence 047: read-only `br show flywheel-2j1dw --json` confirmed dependent `flywheel-2bxry`.
Evidence 048: read-only `br show flywheel-2bxry --json` confirmed dependencies on all three Wave 0 beads.
Evidence 049: read-only `br show flywheel-12k9o --json` confirmed dependencies on `flywheel-2bxry` and `flywheel-3ctlx`.
Evidence 050: read-only `br show flywheel-3lslr --json` confirmed manager dependencies `flywheel-2s5pv` and `flywheel-27vu5`.
Evidence 051: read-only `br show flywheel-iaws7 --json` confirmed manager dependencies `flywheel-3t1e7` and `flywheel-27vu5`.
Evidence 052: read-only `br show flywheel-3nf8t --json` confirmed dependency on `flywheel-12k9o`.
Evidence 053: read-only `br show flywheel-3q54j --json` confirmed dependency on `flywheel-12k9o`.
Evidence 054: read-only `br show flywheel-1ctd2 --json` confirmed dependency on `flywheel-12k9o`.
Evidence 055: `br dep cycles` returned no dependency cycles.
Evidence 056: `rg --files` confirmed the named script and test paths are mostly real.
Evidence 057: Socraticode surfaced L80 bead-quality mining and L82 canonical CLI scoping as relevant local doctrine.
Evidence 058: Skills-best-practices lookup ranked `beads-workflow` as the top match for bead polish and dispatchability.
Evidence 059: `/beads-workflow` requires self-contained, testable beads with explicit dependencies and no cycles.
Evidence 060: `/beads-br` requires JSON/structured `br` use and no bare `bv`.
Evidence 061: `/beads-bv` requires robot mode only for graph-aware triage.
Evidence 062: `/canonical-cli-scoping` applies to CLI surfaces and requires doctor/health/repair and JSON discipline.
Evidence 063: `/jeff-swarm-ops` requires polish convergence before swarm dispatch.
Evidence 064: `/jeff-planning-enhanced` treats bead polishing as cheaper than implementation rework.
Evidence 065: This artifact preserves read-only constraints and proposes edits only as text.

## 10. Callback Metrics

self_grade=A
composite=9.45
beads_reviewed=10+2tombstones/12
avg_bead_score=9.05
highest_scoring_bead=flywheel-2j1dw_9.50
lowest_scoring_bead=flywheel-3lslr_8.50
systemic_gaps_count=6
cross_plan_edges_valid=4/4
deprecation_tombstones_complete=2/2
high_impact_recommendations=5
proposed_edits_count=18
read_only=true
bead_db_writes=0
l112_expected=OK_polish_r0_fleet_autonomy
