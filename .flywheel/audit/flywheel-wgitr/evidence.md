---
title: flywheel-wgitr evidence — BLOCKED with 8-sub-bead decomposition
type: evidence
created: 2026-05-10
bead: flywheel-wgitr
parent: flywheel-jloib (canonical-baseline) / flywheel-yw63j (wave 1 scaffold)
chain: doctor-mode-integration / lane-work
---

# flywheel-wgitr evidence

**Status:** BLOCKED — scope too large for single worker tick (176 TODOs, 4-8h estimated, multi-hour per-surface judgment work). 8 sub-beads filed for decomposed dispatch.

## Scope mismatch

| Metric | Value | Single-tick budget |
|---|---|---|
| TODO markers (parent) | 176 across 8 surfaces (22 per surface) | 1-3 surfaces |
| Estimated effort | 4-8 hours | <1 hour |
| Per-surface judgment | Surface-specific substrate, scopes, schemas, audit logs | Generic templates ruled out by bead author |

The bead author explicitly notes: *"This is the per-surface judgment work the helper lib intentionally doesn't cover."* That rules out the otherwise-tempting templatize-the-stubs path.

## Decomposition (8 sub-beads filed)

Each sub-bead is one surface, ~18 TODOs each, ~30-60 min estimated:

| # | Surface | Sub-bead |
|---|---|---|
| 1 | build-dispatch-packet | flywheel-q71jb |
| 2 | dispatch-and-log | flywheel-vc3zs |
| 3 | dispatch-author-contract-probe | flywheel-tfgt3 |
| 4 | dispatch-canonical-cli-validator | flywheel-39vhm |
| 5 | dispatch-deferral-lint | flywheel-bqvpa |
| 6 | dispatch-delivery-verify | flywheel-5kjez |
| 7 | dispatch-log-backfill-v2 | flywheel-x882q |
| 8 | dispatch-log-v2-violations-doctor | flywheel-hpirw |

Each sub-bead names: the 6 stub categories to fill in, surface-specific boundary, 5 acceptance gates (AG1: TODO replacement; AG2: bash -n; AG3: lint clean; AG4: 13/13 PASS preserved; AG5: substantive non-stub return values), parent + sister cross-refs, P3 priority.

## Per-surface substrate analysis (preparation)

| Surface | Funcs | TODOs | Audit log |
|---|---:|---:|---|
| build-dispatch-packet | 23 | 18 | (none — generates packets, not logs) |
| dispatch-and-log | 18 | 18 | implicit (writes to dispatch-log.jsonl) |
| dispatch-author-contract-probe | 22 | 18 | (none — read-only probe) |
| dispatch-canonical-cli-validator | 31 | 18 | implicit (validation receipt) |
| dispatch-deferral-lint | 17 | 18 | implicit (lint receipt) |
| dispatch-delivery-verify | 29 | 18 | implicit (verify receipt) |
| dispatch-log-backfill-v2 | 17 | 18 | `$REPO/.flywheel/dispatch-log.jsonl` (mutating) |
| dispatch-log-v2-violations-doctor | 18 | 18 | `$REPO/.flywheel/dispatch-log.jsonl` (read) |

The two `dispatch-log-*` surfaces share the canonical `dispatch-log.jsonl`; their fill-ins will likely share helper patterns. The other 6 are independent.

## Why BLOCKED, not partial-DONE

Filling 1-2 surfaces and leaving 6-7 partial would create a quality
bar inconsistency. Each surface needs 30-60 min of focused per-surface
attention; a multi-hour batch from one worker risks shallow fill-ins
on later surfaces as fatigue/budget compresses.

Decomposed dispatch (8 sub-beads, possibly parallelized across worker
panes) lets each sub-bead get a fresh-context worker. This is the
canonical "scope-too-large-for-single-tick → decompose-by-natural-unit"
disposition.

## Sister disposition shapes today

This bead joins the precondition-decides-which-gate-fires family:
- `flywheel-g6xaw` — trigger-gated (external release wait)
- `flywheel-nsjse` — multi-actor experiment (orch + Joshua + unbounded wait)
- `flywheel-fqsmx` — cohort-policy-not-met (producer cadence not active)
- `flywheel-h17x` — DEFER-gated doctrine (insufficient B6 data)
- `flywheel-u4fmq` — fleet-impacting substrate swap (orch authority)
- `flywheel-ze4xv` — cross-repo cohort partial-DONE
- `flywheel-9ijf` — dep-blocked-after-work-complete
- `flywheel-wgitr` (this) — **scope-too-large-for-single-tick → decompose**

8th distinct disposition shape today. The unifying principle: when single-
tick budget can't cover the bead's stated effort, decompose into
single-tick-fit sub-beads (one per natural unit) rather than ship
shallow fill-ins.

## Boundary preserved

- DID NOT edit any of the 8 wave-1 surfaces
- DID NOT touch `.flywheel/scripts/scaffold-canonical-cli.sh` (per user note)
- DID NOT inadvertently overlap with peer pane 2's scaffolder fix work

## Acceptance gates (vs spec)

| Spec gate | Status |
|---|:-:|
| Each surface's doctor returns substantive substrate probes | **DEFERRED to 8 sub-beads** |
| repair --apply has real scope-specific actions | **DEFERRED to 8 sub-beads** |
| validate has real schema rules | **DEFERRED to 8 sub-beads** |
| why has real provenance | **DEFERRED to 8 sub-beads** |

did=0/4, didnt=AG1-4(decomposed-to-8-sub-beads), gaps=8 sub-beads filed.

## Skill discovery

`sd_ids=scope-too-large-for-single-tick-decompose-by-natural-unit-class`

Generic shape: when a bead's stated effort exceeds single-tick budget
AND the bead has natural decomposition units (8 surfaces, 6 phases,
N items), the canonical disposition is BLOCKED + file N sub-beads
each at ~budget-fit effort. Per L52, no observed gap is absorbed;
each sub-bead is the L52 receipt for its surface's TODO set. Sister
to today's other "precondition decides which gate fires" patterns
but distinguished by the *budget* precondition rather than data,
cohort, or coordination.

## Cross-references

- This bead: `flywheel-wgitr` (BLOCKED 2026-05-10)
- Parent: `flywheel-yw63j` (wave-1 scaffold; closed)
- Sister waves: `flywheel-jh5bb` (wave-2 .flywheel/scripts), `flywheel-aav72`
  (wave-2-cross-repo), `flywheel-hj4ip` (wave-3 .flywheel/bin)
- 8 sub-beads filed: q71jb, vc3zs, tfgt3, 39vhm, bqvpa, 5kjez, x882q, hpirw
- Memory cross-refs: `feedback_orchestrator_must_finish_p0_before_filing_more`
  (this is P2, decomposable),
  `feedback_data_decides_not_human_meatpuppet` (data: 4-8h estimate vs single-tick budget)
- L-rules cited: L52 (8 sub-beads filed; not silent absorption), L70 (BLOCKED IS the next-actionable; decomposition is the same-tick disposition)
