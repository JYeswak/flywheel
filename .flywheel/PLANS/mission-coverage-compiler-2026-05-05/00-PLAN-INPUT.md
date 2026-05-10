---
title: "00-PLAN-INPUT - Mission Coverage Compiler"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# 00-PLAN-INPUT - Mission Coverage Compiler

Date: 2026-05-05
Status: plan-space input for 3-lane review
Primary seed: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md`
Constraint: no source edits, no beads, no Joshua question
Output: `.flywheel/PLANS/mission-coverage-compiler-2026-05-05/00-PLAN-INPUT.md`

---

## 1. Why this plan exists

Mobile-eats exposed a fleet-wide planning substrate failure, not a local Nango bug.
The seed memo says the finding belongs in flywheel as a separate mission-coverage-
compiler plan input, not folded into fleet-autonomy-v1's watcher/orch substrate
scope (`mobile-eats-1-2026-05-05T1545Z.md:5`).

The immediate symptom is concrete: watchers were disabled, the loop marker was
false, and Joshua manually stopped automation after 59 chore commits and 0
mission progress (`mobile-eats-1-2026-05-05T1545Z.md:9-11`).

The deeper diagnosis is that "done except Nango" was never proven. The active
bead DB collapsed to two open beads; that was a planning-substrate failure, not
a completion signal (`mobile-eats-1-2026-05-05T1545Z.md:15`).

This plan exists to make the bead substrate subordinate to mission coverage. A
bead may track work. A closed bead may claim work. Neither proves the mission.
The compiler's job is to ground every claim in mission rows, artifacts, tests,
docs, metrics, validators, and current repo state.

The three terms that must survive review are `mission_compression`,
`false_bead_confidence`, and `missing_coverage_ledger`; they form the causal
chain named by the seed memo (`mobile-eats-1-2026-05-05T1545Z.md:21-27`).

## 2. Hard evidence

The seed names seven failure classes:

| Class | Seed evidence | Compiler obligation |
|---|---|---|
| `mission_compression` | M1-M4 collapsed to Nango (`mobile-eats-1-2026-05-05T1545Z.md:21`) | Enumerate mission surfaces before selecting work. |
| `false_bead_confidence` | `br ready=2` lacked mission proof (`mobile-eats-1-2026-05-05T1545Z.md:22`) | Treat ready/closed counts as claims. |
| `parasitic_loop` | Same blocker repeated without information (`mobile-eats-1-2026-05-05T1545Z.md:23`) | Penalize stale blocker churn. |
| `dirty_tree_drift` | 201 dirty entries and 38 unpushed commits (`mobile-eats-1-2026-05-05T1545Z.md:24`) | Start from repo reality. |
| `docs_not_load_bearing` | Docs not enforced as gates (`mobile-eats-1-2026-05-05T1545Z.md:25`) | Add doc proof beside artifact/test proof. |
| `validator_split_brain` | SAFE_TO_CLOSE vs BLOCK_CLOSE (`mobile-eats-1-2026-05-05T1545Z.md:26`) | Force validators onto one evidence row. |
| `missing_coverage_ledger` | No mission surface matrix (`mobile-eats-1-2026-05-05T1545Z.md:27`) | Build the ledger. |

The meta-class is explicit: the bead substrate trusts itself without grounding
in mission coverage (`mobile-eats-1-2026-05-05T1545Z.md:29-31`).

The proposed intervention is already a nine-step workflow: freeze, dirty-tree
triage, matrix, closed-bead audit, log mining, Jeff planning, Meadows analysis,
bead regeneration, dispatch contract, and loop reenable gate
(`mobile-eats-1-2026-05-05T1545Z.md:33-47`).

The seed also gives the matrix shape. Surfaces span product, backend, APIs,
CLIs, frontend, docs, tests, deployment, ops, and analytics; columns include
`what_are_we_building`, `done_means`, `mission_metric`, `artifact`,
`test_proof`, `doc_proof`, `grade`, `gap`, and `bead_id`
(`mobile-eats-1-2026-05-05T1545Z.md:39-41`).

This is fleet-wide because flywheel ready beads are not mission-graded, skillos
callbacks are invisible to grading, alpsinsurance stalled 6h50m on P3b without
mission-tied DoD, and mobile-eats hit all seven classes
(`mobile-eats-1-2026-05-05T1545Z.md:61-65`).

## 3. Paradigm shift

Current paradigm:

Beads are the plan of record. Closed beads imply completed work. Ready beads
imply useful next work. Dispatch callbacks imply progress. Validators can
disagree until a human or orchestrator reconciles them.

The seed falsifies that. `br ready=2` looked clean while the mission had
collapsed (`mobile-eats-1-2026-05-05T1545Z.md:15,22`).

Replacement paradigm:

The mission coverage matrix is the plan-of-record audit surface. Beads are work
tickets. Closed beads are claims. Dispatch callbacks are observations. Docs,
tests, artifacts, metrics, and validators are evidence.

This is a Donella leverage point #2/#3 shift before it is a #5 rule. The system
goal changes from "drain ready beads" to "close mission surfaces with proof."

Dispatch consequence: no worker should receive generic ready-bead work when the
compiler can identify uncovered mission rows first.

Validator consequence: SAFE_TO_CLOSE and BLOCK_CLOSE must either map to
different rows or produce a visible conflict on the same row
(`mobile-eats-1-2026-05-05T1545Z.md:26`).

Loop consequence: reenable only after clean/quarantined repo state, matrix
existence, watcher probes, and one manual tick that selects useful mission work
over stale blocker churn (`mobile-eats-1-2026-05-05T1545Z.md:47`).

## 4. Atomic primitives

The nine-step intervention compresses into six primitives.

### C0 - Freeze and repo reality snapshot

Derived from freeze plus dirty-tree triage (`mobile-eats-1-2026-05-05T1545Z.md:37-38`).
Stock: untrusted repo state.
Flows: dirty files, unpushed commits, generated artifacts, watcher events.
Leverage point: #9 delays plus #6 information flow.
Output: `repo_state_class`, `dirty_count`, `unpushed_count`, `watchers_frozen`,
`quarantine_required`.
Rule: the compiler may emit a draft matrix in dirty state, but green verdicts
are capped until dirty entries are classified.
Verification: a repo with unclassified dirty state cannot produce green coverage.

### C1 - Mission coverage matrix compiler

Derived from the matrix step (`mobile-eats-1-2026-05-05T1545Z.md:39-41`).
Stock: mission surfaces with evidence state.
Flows: mission anchors, README claims, routes, APIs, CLIs, tests, docs, deploy
state, analytics.
Leverage point: #6 information flow plus #3 system goal.
Minimum row: `surface`, `what_are_we_building`, `done_means`,
`mission_metric`, `artifact`, `test_proof`, `doc_proof`, `grade`, `gap`,
`bead_id`, `source_anchor`, `owner`, `last_verified_at`.
Rule: every row has evidence or an explicit gap; empty evidence plus empty gap
is invalid.
Verification: no mission surface disappears behind a ready-bead count.

### C2 - Closed-bead claim auditor

Derived from "closed beads as untrusted claims"
(`mobile-eats-1-2026-05-05T1545Z.md:42`).
Stock: closed-bead claims.
Flows: bead closures, callbacks, validation receipts, artifact paths, test
proof, doc proof.
Leverage point: #5 rules plus #8 negative feedback.
Rule: closed product/substrate beads must map to mission rows or become
ungrounded closure claims.
Typed gaps: `path_missing`, `test_missing`, `doc_missing`,
`mission_row_missing`, `validator_conflict`, `artifact_unverified`.
Verification: closed beads without mission proof cannot increase mission
coverage.

### C3 - Failure ledger miner

Derived from mining dispatch-log, fuckup-log, doctor, and validator failures
(`mobile-eats-1-2026-05-05T1545Z.md:43`).
Stock: process failures not yet routed into remediation.
Flows: dispatch rows, fuckup rows, doctor warnings, validator failures,
callback rejections, loop refusals.
Leverage point: #4 self-organization plus #6 information flow.
Rule: repeated failures that affect mission coverage must appear as row
blockers or compiler-owned process gaps.
Verification: all seven seed failure classes map to primitives or explicit
out-of-scope reasons.

### C4 - Planning and bead regeneration input

Derived from Jeff planning, Meadows analysis, and granular bead regeneration
(`mobile-eats-1-2026-05-05T1545Z.md:44-45`).
Stock: mission gaps ready for later work planning.
Flows: C0-C3 gap rows into plan-ready groups.
Leverage point: #3 goals plus #4 self-organization.
Rule: this plan does not create beads, but later bead candidates must be
self-contained, dependency-aware, mission-row-linked, and evidence-backed.
Verification: no candidate depends only on "inspect and report" unless it emits
a durable ledger, validator, or compiler row.

### C5 - Dispatch contract and loop reenable gate

Derived from the new dispatch contract and loop gate
(`mobile-eats-1-2026-05-05T1545Z.md:46-47`).
Stock: automation eligibility.
Flows: matrix freshness, dirty-state classification, watcher probes, validator
agreement, dispatch compliance.
Leverage point: #5 rules, #8 negative feedback, #9 delays.
Dispatch fields: pre/post git status, owned files only, docs/test/artifact
gates, `DID`, `DIDNT`, `GAPS`, no unrelated dirty tree, mission row references,
expected and observed coverage delta.
Reenable gates: clean/quarantined repo, matrix exists, watcher probes green,
validator agreement, manual tick selects mission-useful work.
Verification: no loop reenables while `missing_coverage_ledger` is active.

## 5. Donella lens

Primary stock: mission surfaces with verified evidence.
Secondary stocks: ungrounded closed-bead claims, dirty repo state, blocker churn,
validator disagreement, and non-load-bearing docs.

Inflow to mission coverage: artifact proof, test proof, doc proof, mission
metric proof, and validated closed-bead proof.

Outflow from mission coverage: stale evidence, code drift, doc drift, validator
contradiction, and owner-custody blockers that invalidate "done."

Leverage point distribution:

| Point | Use |
|---|---|
| #10 structure | Matrix links mission surfaces to evidence. |
| #9 delays | Freeze/triage and reenable gates shorten hidden delays. |
| #8 negative feedback | Closed-bead audit pushes back on false closure. |
| #6 information flow | Matrix exposes what bead counts hide. |
| #5 rules | Dispatch and loop gates make evidence mandatory. |
| #4 self-organization | Failure miner routes recurring classes to gaps. |
| #3 goals | Work selection optimizes mission coverage. |
| #2 paradigms | Beads stop being proof; they become claims. |

Anti-patterns to avoid: leverage theater, reminder substitution, human-as-
feedback-loop, source laundering, and grand reframe without instrumentation.
The compiler must flow into dispatch packets, validators, tests, docs gates, or
loop reenable gates; otherwise it is only a prettier report.

## 6. Jeff lens

Jeff would likely compress this to a typed compiler with boring invariants:
explicit inputs, JSON output, stable reason codes, dry-run defaults, replayable
fixtures, and mechanical verdicts.

Likely objection: "Do not build a doctrine document. Build the compiler."
This plan survives that objection only if review treats prose as a precursor to
one read-only primitive, not as a permanent operating surface.

Canonical CLI shape:

- `mission-coverage compile --repo <path> --json`
- `mission-coverage compile --repo <path> --markdown`
- `mission-coverage validate --repo <path> --matrix <file>`
- `mission-coverage doctor --repo <path> --json`
- `mission-coverage explain --surface <id>`
- `mission-coverage replay --from-dispatch-log <file>`
- `mission-coverage schema`
- `mission-coverage examples`

Mutation discipline: compile, validate, explain, replay, and doctor are
read-only by default. Any future bead generation is separate and dry-run first.

Correctness invariant: if bead state says low work remains while the compiler
finds rows with no artifact/test/doc proof, the compiler wins.

Scope warning: do not merge this into fleet-autonomy-v1; the seed memo already
routes it separately (`mobile-eats-1-2026-05-05T1545Z.md:5`).

## 7. Relationship to fleet-autonomy-v1 and manager-loop

Fleet-autonomy-v1 asks how the fleet selects and executes work without founder
intervention. Mission-coverage-compiler asks how the fleet knows selected or
closed work maps to mission coverage.

Manager-loop asks how the orchestrator consumes aggregate state rather than pane
noise. Mission-coverage-compiler should feed manager-loop, not replace it.

Cross-plan contract:

- fleet-autonomy calls the compiler before dispatch selection
- manager-loop reads compiler summary into the top-10 queue
- closed-bead audit uses compiler rows to validate closure impact
- dispatch validators require mission row references
- loop reenable gates require a fresh compiler verdict

Non-overlap: compiler does not manage panes, choose workers, send callbacks,
mutate beads in this phase, or reenable loops by itself.

## 8. Cross-orch integration

Mobile-eats contributes the taxonomy, matrix shape, and nine-step workflow
(`mobile-eats-1-2026-05-05T1545Z.md:17-47`).

Flywheel contributes Socraticode-first dispatch, file reservations,
issue-to-bead receipts, closed-bead auditing, callback validation, tick-driver
process truth, and stable failure reason codes.

Skillos contributes the validator-split-brain overlap; the seed explicitly
connects mobile-eats validator split brain with skillos callback-grade gaps
(`mobile-eats-1-2026-05-05T1545Z.md:56`).

Alpsinsurance contributes stall evidence: 6h50m on a P3b without mission-tied
DoD (`mobile-eats-1-2026-05-05T1545Z.md:64`).

Manager-loop consumes the coverage summary as a queue input. Fleet-autonomy
consumes it as a dispatch-selection guard. Repo-local loops consume it as a
reenable gate.

## 9. Success criteria

Plan-level success:

- all six primitives accepted or explicitly revised
- each primitive maps to seed steps
- each primitive names stock, flow, leverage point, and verification
- file remains plan-space only
- no bead is created

Compiler-level success:

- every mission surface has a row
- every row has evidence or explicit gap
- CLI rows include canonical CLI coverage fields
- closed beads are untrusted until mapped to rows
- validator disagreements become typed conflicts
- dirty tree state caps the verdict until classified
- docs count only when doc proof gate is checked

Loop-level success:

- no loop reenables while `missing_coverage_ledger` is true
- one manual tick selects mission-useful work before automation resumes
- blocker churn reduces dispatch confidence
- ready-bead counts cannot override coverage gaps

Fleet-level success:

- flywheel ready beads can be mission-ranked
- skillos callback visibility can be graded against mission rows
- alpsinsurance P3b-style stalls expose missing mission-tied DoD
- mobile-eats cannot claim "done except Nango" without matrix evidence

## 10. In scope

- Plan-space definition of the compiler.
- Six primitive decomposition C0-C5.
- Mobile-eats seed evidence with file:line citations.
- Donella stock/flow/leverage analysis.
- Jeff-style canonical primitive and CLI shape.
- Relationship to fleet-autonomy-v1 and manager-loop.
- Cross-orch inputs for review lanes.
- Success criteria, open questions, ship order, and verdict thresholds.

## 11. Out of scope

- Source code edits.
- Bead creation or mutation.
- Mobile-eats repo execution.
- Reenabling watchers.
- Resolving Nango.
- Rewriting fleet-autonomy-v1 or manager-loop.
- Creating a new skill before review acceptance.
- Replacing `br`, `bv`, `ntm`, agent-mail, or Socraticode.

## 12. Constraints honored

- Uses the requested output path.
- Cites the seed by file and line throughout.
- Stays plan-space only.
- Makes no source edit.
- Creates no bead.
- Asks no Joshua question.
- Derives matrix from mission-anchor-init shape plus doc/test/artifact gates as
  requested by seed routing (`mobile-eats-1-2026-05-05T1545Z.md:57`).
- Keeps fleet-autonomy and manager-loop boundaries intact.

## 13. Open questions for 3 review lanes

1. Is dirty-state classification a hard global blocker or row-local cap?
2. Should schema freeze happen in review or first implementation bead?
3. Is acceptable proof artifact+test, artifact+doc, or artifact+test+doc?
4. Should coverage score be row count, weighted surface score, or risk score?
5. How are old closed beads handled when they predate mission-row references?
6. Is validator split brain a row-level cap, global verdict cap, or both?
7. What freshness window makes matrix output valid for loop reenable?
8. Does manager-loop consume full JSON, markdown, or a summary projection?
9. Which later skill owns recurring practice: compiler, mission-anchor-init, or flywheel-loop doctrine?

## 14. Ship order

1. Review in Donella, Jeff, and integration lanes; reconcile into revision.
2. Freeze row schema; build read-only compiler for mobile-eats replay.
3. Integrate closed-bead claim audit and failure ledger miner.
4. Add canonical CLI surfaces plus doctor/validate/explain.
5. Add manager-loop summary projection and fleet-autonomy dispatch guard.
6. Add loop reenable gate, run four-repo audit, then convert approved gaps.

## 15. Verdict thresholds

Proceed to revision if composite review score is at least 9.0, no lane finds a
missing primitive, all lanes keep this separate from fleet-autonomy-v1, all
lanes agree it feeds manager-loop, and open questions are answerable without
Joshua.

Hold and revise if any lane says the matrix is leverage theater, gates are only
reminders, closed-bead audit remains optional, coverage score cannot be
computed, or validator split brain is not represented.

Reject if the plan depends on humans reading prose to catch mission compression,
treats bead state as proof, cannot represent `false_bead_confidence`, creates a
standalone artifact with no consumer, or folds back into watcher/autonomy work.

## Appendix A - Canonical citations

- Routing, watcher stop, diagnosis, failure classes, meta-class, workflow, matrix shape, routing table, fleet evidence, and next dispatch: `.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/cross-orch-input/mobile-eats-1-2026-05-05T1545Z.md:5-74`
- Skills read: planning-workflow, donella-meadows-systems-thinking, jeff-planning-enhanced, mission-anchor-init, canonical-cli-scoping, reality-check-for-project, and flywheel skills-best-practices results.
- Socraticode survey: four codebase searches against `/Users/josh/Developer/flywheel`, limit 10 each.
