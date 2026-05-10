---
title: "WAVE-0 Close Plan - Duplicates and Obsoletes"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# WAVE-0 Close Plan - Duplicates and Obsoletes

date: 2026-05-05
mode: plan-space-only
task: close packets for reconciled duplicate and obsolete beads
bead_db_writes: 0

## Receipt

- Candidates reviewed: 6
- Close packets authored: 6
- Reclassified out after sanity check: 0
- Duplicates verified: 4/4
- Obsoletes verified: 2/2
- Commands below are apply packets only. They were not executed by this worker.
- Every command uses `br close ... --reason ... --json` per Beads CLI discipline.
- No dependency edges were changed in this plan-space pass.

## Inputs

- Reconciliation source: `.flywheel/PLANS/OPEN-BEADS-RECONCILIATION-2026-05-05.md`.
- Unified plan source: `.flywheel/PLANS/UNIFIED-DAG-2026-05-05.md`.
- Read-only bead inspection: `br --no-auto-import --allow-stale --lock-timeout 5000 show <id> --json`.
- Dispatch requirement: author exact close commands, cite reconciliation file lines, and verify superseding or invalidating plan context.

## Apply Safety

- This file is not an execution script.
- Apply owner should copy one command at a time after confirming they still want these six closures.
- Do not add `--force` during first pass.
- If `br close` refuses because a bead still has open dependents, stop and reconcile that dependent cascade in plan-space first.
- The safest order closes old leaves before old roots: obsolete leaf report, classifier, scanner, writer, schema root, then the old tick consumer.
- `flywheel-2te` is currently blocked and has open dependents, so it is intentionally last among the old Phase 0/1 coherence graph.
- `flywheel-2y4` has old downstream control-plane implications; close refusal should be treated as a useful guard, not a reason to force.

## Classification Summary

| Bead | Class | Verdict | Basis |
|---|---|---|---|
| flywheel-2te | DUPLICATE | Close | superseded by flywheel-181e5, flywheel-3ctlx, flywheel-2j1dw |
| flywheel-pd9 | DUPLICATE | Close | superseded by flywheel-2bxry, flywheel-12k9o |
| flywheel-1km | DUPLICATE | Close | superseded by flywheel-181e5, flywheel-3ctlx, flywheel-2j1dw |
| flywheel-dzj | DUPLICATE | Close | superseded by flywheel-gwbvf, flywheel-4ggh2, flywheel-2bxry |
| flywheel-1hn | OBSOLETE | Close | invalidated by manager A0/A2/A4 plus watchdog receipt path |
| flywheel-2y4 | OBSOLETE | Close | invalidated by manager-loop A0/A2/A4 and typed dispatch contracts |

## Reconciliation Line Register

- `flywheel-2te`: summary line 49, detail lines 229-235, duplicate register line 945.
- `flywheel-pd9`: summary line 77, detail lines 453-459, duplicate register line 946.
- `flywheel-1km`: summary line 89, detail lines 549-555, duplicate register line 947.
- `flywheel-dzj`: summary line 92, detail lines 573-579, duplicate register line 948.
- `flywheel-1hn`: summary line 60, detail lines 317-323, obsolete register line 1062.
- `flywheel-2y4`: summary line 110, detail lines 717-723, obsolete register line 1063.

## Unified-DAG Cross-Checks

- `UNIFIED-DAG-2026-05-05.md:79-107` defines the current unified register used to compare old beads against today's surviving plan.
- `UNIFIED-DAG-2026-05-05.md:88-92` lists Fleet roots and the P1/P2 selector/retry rows that replace the old fleet-coherence substrate.
- `UNIFIED-DAG-2026-05-05.md:98-107` lists Mission source/reality, Manager projection, and replay rows that replace scanner and consumer-style plans.
- `UNIFIED-DAG-2026-05-05.md:231-234` marks Manager A0/A4 as the critical path for read-only state and projection.
- `UNIFIED-DAG-2026-05-05.md:246-260` places Wave 1 work on local evidence-producing primitives, not old shadow-only fleet-coherence reports.
- `UNIFIED-DAG-2026-05-05.md:603-626` keeps bead writes serialized and out of worker panes; this close plan follows that rule.

## Plan Citations Used

- `fleet-autonomy-v1-2026-05-05/05-POLISH-r2.md:60-67` states that R2 freezes selector receipt, blocker ownership, mission-delta contracts, and deprecated primitive behavior.
- `fleet-autonomy-v1-2026-05-05/05-POLISH-r2.md:87-216` defines the detailed current Fleet rows for `flywheel-181e5`, `flywheel-3ctlx`, `flywheel-2j1dw`, `flywheel-2bxry`, and `flywheel-12k9o`.
- `fleet-autonomy-v1-2026-05-05/05-POLISH-r2.md:229-248` maps the old Fleet P3 status brain to Manager A0 and A4.
- `fleet-autonomy-v1-2026-05-05/05-POLISH-r2.md:258-272` maps old measurement overlay work to Manager A2 and A4.
- `fleet-autonomy-v1-2026-05-05/05-POLISH-r2.md:359-380` confirms the tombstone overlays for old P3/M style work.
- `manager-loop-architecture-2026-05-05/00-PLAN-r2.md:170-172` defines A0 as the read-only manager state primitive.
- `manager-loop-architecture-2026-05-05/00-PLAN-r2.md:242-244` says A0 accepts selector/retry receipts and blocker ownership fields after the Fleet gates exist.
- `manager-loop-architecture-2026-05-05/00-PLAN-r2.md:253-264` requires CLI discipline and canonical scoping for the manager root.
- `manager-loop-architecture-2026-05-05/00-PLAN-r2.md:937-953` sets manager ship order as A0, A2, A4.
- `manager-loop-architecture-2026-05-05/00-PLAN-r2.md:991` states G0 first, P1/P2 first globally, and A0 first in manager-loop implementation.
- `manager-loop-architecture-2026-05-05/00-PLAN-r2.md:1004-1007` maps old P3 status-brain work to A0/A4.
- `manager-loop-architecture-2026-05-05/00-PLAN-r2.md:1063` clarifies that manager-loop obsoletes control-plane shape, not every Fleet primitive.
- `watchdog-enablement-2026-05-05/00-PLAN.md:503-523` places watchdog under manager/fleet/mission as the liveness substrate.
- `watchdog-enablement-2026-05-05/00-PLAN.md:560-568` defines watchdog self-health fields and manager-consumed summaries.

## Close Packet 1 - flywheel-1hn

class: OBSOLETE
verdict: close
recommended order: 1

### Existing Body Verification

- Current status from read-only `br show`: open, priority 1.
- Existing title: run and summarize a 24-48h Phase 1 shadow signal-quality review.
- Existing acceptance asks for false-positive rate, p95 scan latency, scan budget, event volume, dedupe quality, and integration recommendation.
- Existing scope explicitly says the report performs no L61 sends, no bead filing, no topology writes, and no retention mutation.
- Existing dependencies point back to old fleet-coherence shadow/classifier rows.

### Reconciliation Evidence

- Reconciliation source classifies this bead as OBSOLETE at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:60`.
- Detail section is `OPEN-BEADS-RECONCILIATION-2026-05-05.md:317-323`.
- Obsolete register repeats the classification at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:1062`.
- Register rationale: standalone shadow signal-quality report is invalidated by Manager A0/A2/A4 and watchdog receipts as the composed state path.

### Superseding / Invalidating Context

- Manager A0 gives the read-only state model that the old report tried to approximate indirectly.
- Manager A2 owns queue scoring, which is where signal quality should influence ordering.
- Manager A4 owns projection/rendering, which is where report-style state becomes visible without being a separate shadow deliverable.
- Watchdog receipts provide liveness and substrate continuity below the manager layer.
- The old 24-48h standalone review would now compete with the Manager plus Watchdog acceptance path instead of feeding it.

### Exact Close Command

```bash
br close flywheel-1hn --reason "Obsolete after the 2026-05-05 manager-loop and watchdog plans: standalone Phase 1 shadow signal-quality reporting is replaced by Manager A0 read-only state, Manager A2 scoring, Manager A4 projection, and watchdog self-health receipts. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:317-323 and :1062." --json
```

### Apply Notes

- Close before the old classifier and schema-root duplicates so the old leaf report does not keep the obsolete chain alive.
- Do not file a replacement bead; replacement work already exists in Manager A0/A2/A4 and watchdog plan rows.
- If closure fails because old dependencies are still open, continue through the duplicate chain and retry after old parents close.

## Close Packet 2 - flywheel-pd9

class: DUPLICATE
verdict: close
recommended order: 2

### Existing Body Verification

- Current status from read-only `br show`: open, priority 1.
- Existing title: implement first fleet-coherence classifier pack in shadow mode.
- Existing body asks for shadow events such as `would_l61`, `would_bead`, and `would_no_bead_reason`.
- Existing classifier pack reads pane-work-signal, line-count/hash-delta, stale callback age, dispatch metadata, and bead/tick receipts.
- Existing guard says it should emit no real L61 sends and create no beads.

### Reconciliation Evidence

- Reconciliation source classifies this bead as DUPLICATE at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:77`.
- Detail section is `OPEN-BEADS-RECONCILIATION-2026-05-05.md:453-459`.
- Duplicate register repeats the classification at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:946`.
- Register rationale: old classifier pack overlaps selector and retry receipt contracts.

### Superseding Context

- `flywheel-2bxry` implements the selector adapter and selector receipt path.
- `flywheel-12k9o` implements the retry-state receipt path keyed by candidate and attempt-state hash.
- The current plan favors explicit receipt contracts over a broad shadow classifier that infers `would_*` actions.
- Manager A0/A2 consume typed receipts after the Fleet gates land, so the classifier role is no longer the authority boundary.

### Exact Close Command

```bash
br close flywheel-pd9 --reason "Duplicate of the 2026-05-05 Fleet selector and retry receipt path: flywheel-2bxry owns selector_receipt/v1 and flywheel-12k9o owns retry_state_receipt/v1, replacing the old shadow classifier pack and its would_l61/would_bead outputs. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:453-459 and :946." --json
```

### Apply Notes

- Close after `flywheel-1hn` because the old report depended on classifier output.
- Do not preserve the old `would_*` event vocabulary unless an apply owner explicitly maps it into A0/A2 diagnostic output later.
- Do not force-close if an unreviewed old dependent appears; add that dependent to a follow-up close packet instead.

## Close Packet 3 - flywheel-dzj

class: DUPLICATE
verdict: close
recommended order: 3

### Existing Body Verification

- Current status from read-only `br show`: open, priority 1.
- Existing title: build fleet-coherence scanner skeleton that reads fleet substrates without classifying drift yet.
- Existing scanner reads NTM state, topology, roster, pane-work-signal, dispatch log, and bead receipt surfaces.
- Existing output is neutral scan or heartbeat JSONL with no classification.
- Existing acceptance requires stale/missing source handling and read-only behavior.

### Reconciliation Evidence

- Reconciliation source classifies this bead as DUPLICATE at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:92`.
- Detail section is `OPEN-BEADS-RECONCILIATION-2026-05-05.md:573-579`.
- Duplicate register repeats the classification at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:948`.
- Register rationale: old scanner skeleton overlaps source reader, repo reality normalizer, and selector adapter.

### Superseding Context

- `flywheel-gwbvf` reads mission-relevant artifacts through an allowlist and emits source records as evidence only.
- `flywheel-4ggh2` normalizes repo reality facts such as dirty paths, canonical path, porcelain hash, and unpushed state without mutating worktrees or `.beads`.
- `flywheel-2bxry` owns selector reality and typed selector receipts.
- The old generic scanner would duplicate three sharper source-of-truth boundaries.

### Exact Close Command

```bash
br close flywheel-dzj --reason "Duplicate of the 2026-05-05 source/reality/selector split: flywheel-gwbvf owns mission source records, flywheel-4ggh2 owns repo reality normalization, and flywheel-2bxry owns selector receipts, replacing the old generic fleet-coherence scanner skeleton. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:573-579 and :948." --json
```

### Apply Notes

- Close before `flywheel-1km` because the old writer planned to persist output from this scanner.
- No source reader behavior is lost; it is split across Mission P0, Mission P1, and Fleet P1.
- If an apply owner wants a compatibility harness, it should be a separate read-only adapter over the new typed receipts, not this old scanner bead.

## Close Packet 4 - flywheel-1km

class: DUPLICATE
verdict: close
recommended order: 4

### Existing Body Verification

- Current status from read-only `br show`: open, priority 1.
- Existing title: implement fleet-coherence JSONL writer, atomic latest snapshot, close rows, and retention policy.
- Existing body asks for append-only scan rows, classifier events, close rows, latest symlink or atomic copy, and retention pruning.
- Existing acceptance includes schema migration notes and malformed-row tests.
- Existing bead blocks old scanner and classifier work.

### Reconciliation Evidence

- Reconciliation source classifies this bead as DUPLICATE at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:89`.
- Detail section is `OPEN-BEADS-RECONCILIATION-2026-05-05.md:549-555`.
- Duplicate register repeats the classification at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:947`.
- Register rationale: old schema writer is covered by explicit Fleet field-freeze roots.

### Superseding Context

- `flywheel-181e5` freezes selector source and freshness fields.
- `flywheel-3ctlx` freezes blocker-owner placement and required fields.
- `flywheel-2j1dw` freezes mission-delta provenance fields.
- Implementation behavior that looked like a generic writer is now owned by typed selector and retry receipt implementations, not a single fleet-coherence JSONL substrate.
- Keeping both writers would create competing receipt grammars.

### Exact Close Command

```bash
br close flywheel-1km --reason "Duplicate of the 2026-05-05 typed Fleet receipt contracts: flywheel-181e5 freezes selector source/freshness, flywheel-3ctlx freezes blocker-owner placement, and flywheel-2j1dw freezes mission-delta provenance, replacing the old generic fleet-coherence JSONL writer/latest/retention bead. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:549-555 and :947." --json
```

### Apply Notes

- Close after `flywheel-dzj` and `flywheel-pd9` so old producer/consumer leaves are gone first.
- Do not carry forward the atomic latest snapshot as an independent root unless a new typed receipt requires it.
- The close reason intentionally cites the field-freeze roots; implementation rows remain the place where append-only receipt writing belongs.

## Close Packet 5 - flywheel-2te

class: DUPLICATE
verdict: close
recommended order: 5

### Existing Body Verification

- Current status from read-only `br show`: blocked, priority 1.
- Existing title: freeze fleet-coherence event and suppression schemas, dedupe grammar, and fixtures before implementation.
- Existing body says Phase 0 must freeze event envelope, suppression schema, dedupe key grammar, and fixture JSONL.
- Existing acceptance asks for examples for work/idle mismatch, stale callback, stale dispatch, repeated suppressed signals, and 3-agent multi-pane cases.
- Existing body says all Phase 1 work is blocked until schema and fixtures are accepted.

### Reconciliation Evidence

- Reconciliation source classifies this bead as DUPLICATE at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:49`.
- Detail section is `OPEN-BEADS-RECONCILIATION-2026-05-05.md:229-235`.
- Duplicate register repeats the classification at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:945`.
- Register rationale: old fleet-coherence schema fixture overlaps today's frozen Fleet receipt fields.

### Superseding Context

- `flywheel-181e5` freezes selector receipt source and freshness fields.
- `flywheel-3ctlx` freezes blocker-owner placement and forbids callback-only ownership claims.
- `flywheel-2j1dw` freezes mission-delta provenance requirements.
- `flywheel-2bxry` and `flywheel-12k9o` implement selector and retry receipts on top of those contracts.
- The old schema-fixture bead is a duplicate root because it tries to preserve a broader fleet-coherence event grammar that the 2026-05-05 plan intentionally decomposes into typed receipts.

### Exact Close Command

```bash
br close flywheel-2te --reason "Duplicate of the 2026-05-05 Fleet receipt-contract roots: flywheel-181e5 freezes selector source/freshness, flywheel-3ctlx freezes blocker-owner placement, and flywheel-2j1dw freezes mission-delta provenance, replacing the old fleet-coherence schema/fixture/dedupe grammar root. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:229-235 and :945." --json
```

### Apply Notes

- Close after old leaf and writer/classifier/scanner duplicates because this bead is the old root.
- If `br close` refuses because of remaining open dependents, stop. Do not force-close until those dependents are classified.
- This packet is still a close recommendation; the dependency caution only affects apply order and force policy.

## Close Packet 6 - flywheel-2y4

class: OBSOLETE
verdict: close
recommended order: 6

### Existing Body Verification

- Current status from read-only `br show`: open, priority 1.
- Existing title: add tick Step 4i as read-only fleet-coherence event consumer with receipt dedupe.
- Existing body reads fleet-coherence JSONL/latest/suppressions and writes tick receipt fields plus read-only decisions.
- Existing acceptance forbids `br create`, final `no_bead_reason`, and repair dispatch.
- Existing output shape depends on the old fleet-coherence substrate being retained.

### Reconciliation Evidence

- Reconciliation source classifies this bead as OBSOLETE at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:110`.
- Detail section is `OPEN-BEADS-RECONCILIATION-2026-05-05.md:717-723`.
- Obsolete register repeats the classification at `OPEN-BEADS-RECONCILIATION-2026-05-05.md:1063`.
- Register rationale: old tick Step 4i read-only consumer is replaced by manager-loop A0/A2/A4 and typed dispatch contracts.

### Superseding / Invalidating Context

- Manager A0 consumes current selector/retry/blocker/mission-anchor inputs as state facts.
- Manager A2 scores queue candidates over A0 state.
- Manager A4 renders manager state without mutating dispatch or beads.
- Typed dispatch contracts and receipt rows replace a tick-local consumer of old fleet-coherence JSONL.
- The old Step 4i consumer would recreate a second control-plane path beside the manager-loop architecture.

### Exact Close Command

```bash
br close flywheel-2y4 --reason "Obsolete after the 2026-05-05 manager-loop architecture: old tick Step 4i consumption of fleet-coherence JSONL/latest/suppressions is replaced by Manager A0 state facts, Manager A2 queue scoring, Manager A4 rendering, and typed dispatch/receipt contracts. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:717-723 and :1063." --json
```

### Apply Notes

- Close only after the old fleet-coherence producer chain is closed or confirmed irrelevant.
- If an old action-consumer dependent is still open, classify that dependent before forcing this closure.
- This obsolete classification is about the old consumer architecture; it does not invalidate current Fleet P1/P2 receipt producers.

## Sequential Apply Packet

Run only if the apply owner accepts the sanity notes above.

```bash
br close flywheel-1hn --reason "Obsolete after the 2026-05-05 manager-loop and watchdog plans: standalone Phase 1 shadow signal-quality reporting is replaced by Manager A0 read-only state, Manager A2 scoring, Manager A4 projection, and watchdog self-health receipts. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:317-323 and :1062." --json
br close flywheel-pd9 --reason "Duplicate of the 2026-05-05 Fleet selector and retry receipt path: flywheel-2bxry owns selector_receipt/v1 and flywheel-12k9o owns retry_state_receipt/v1, replacing the old shadow classifier pack and its would_l61/would_bead outputs. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:453-459 and :946." --json
br close flywheel-dzj --reason "Duplicate of the 2026-05-05 source/reality/selector split: flywheel-gwbvf owns mission source records, flywheel-4ggh2 owns repo reality normalization, and flywheel-2bxry owns selector receipts, replacing the old generic fleet-coherence scanner skeleton. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:573-579 and :948." --json
br close flywheel-1km --reason "Duplicate of the 2026-05-05 typed Fleet receipt contracts: flywheel-181e5 freezes selector source/freshness, flywheel-3ctlx freezes blocker-owner placement, and flywheel-2j1dw freezes mission-delta provenance, replacing the old generic fleet-coherence JSONL writer/latest/retention bead. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:549-555 and :947." --json
br close flywheel-2te --reason "Duplicate of the 2026-05-05 Fleet receipt-contract roots: flywheel-181e5 freezes selector source/freshness, flywheel-3ctlx freezes blocker-owner placement, and flywheel-2j1dw freezes mission-delta provenance, replacing the old fleet-coherence schema/fixture/dedupe grammar root. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:229-235 and :945." --json
br close flywheel-2y4 --reason "Obsolete after the 2026-05-05 manager-loop architecture: old tick Step 4i consumption of fleet-coherence JSONL/latest/suppressions is replaced by Manager A0 state facts, Manager A2 queue scoring, Manager A4 rendering, and typed dispatch/receipt contracts. Evidence: OPEN-BEADS-RECONCILIATION-2026-05-05.md:717-723 and :1063." --json
```

## Dependency Sanity Check

- `flywheel-1hn` is a leaf-style obsolete report in the old Phase 1 review chain.
- `flywheel-pd9`, `flywheel-dzj`, and `flywheel-1km` form the old classifier/scanner/writer chain.
- `flywheel-2te` is the old schema root and should be closed after old chain leaves.
- `flywheel-2y4` is an old tick consumer and should not be forced if an unclassified old dependent remains open.
- The plan intentionally does not mutate dependencies, because the dispatch was plan-space only.
- Any refusal from `br close` should become a follow-up dependent-close review, not an immediate forced close.

## No-Reclass Sanity

- No duplicate candidate had a unique surviving acceptance criterion after comparison with today's Fleet/Mission/Manager/Watchdog plans.
- No obsolete candidate still represented a necessary implementation primitive in the current DAG.
- `flywheel-1hn` was not reclassified to duplicate because the replacement is an architecture path, not a one-to-one bead.
- `flywheel-2y4` was not reclassified to duplicate because the old tick-consumer architecture is invalidated rather than merely covered by a replacement implementation.
- `flywheel-2te`, `flywheel-1km`, `flywheel-dzj`, and `flywheel-pd9` remain duplicates because their retained value is now expressed by specific receipt/source/reality beads.

## Rollback Packet

- If an apply owner closes one of these in error, reopen the affected bead and cite this close plan in the reopen reason.
- Suggested rollback command shape: `br reopen <id> --reason "Reopened after close-plan apply review found retained unique scope; see WAVE-0-CLOSE-PLAN-2026-05-05." --json`.
- Because this plan does not remove dependencies, rollback does not require edge restoration.
- If a force close was used outside this plan, inspect dependents before reopening so the graph is coherent again.

## Callback Fields

- `beads_in_close_plan=6`
- `beads_reclassified_out=0`
- `duplicates_verified=4/4`
- `obsoletes_verified=2/2`
- `close_packets_authored=6`
- `bead_db_writes=0`
- `no_bead_reason=plan-space-only-close-packets`

## Final Verdict

Close all six reconciled candidates, subject to the apply safety rule that `br close` refusals must stop for dependent-cascade review instead of being bypassed with `--force`.
