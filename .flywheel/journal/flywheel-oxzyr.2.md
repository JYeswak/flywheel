---
bead: flywheel-oxzyr.2
title: DECLINED with 6-sub-bead decomposition proposal (META-RULE 2026-05-10)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: DECLINED (bead stays open)
priority: P1
disposition: DECLINED (scope-mismatch; bundled 4 natural units)
parent: flywheel-oxzyr (stays open; orch decomposes pass-2)
---

# Journey: flywheel-oxzyr.2 (DECLINED)

## What the bead asked for

P1 pass-2 implementation bundling 4 natural-unit deliverables:
1. `_flywheel_loop_mutate()` chokepoint refactor
2. 5 FM detect/fix invariants
3. `doctor undo <run-id>` subcommand
4. Real fixture data for 10 FMs

Total realistic estimate: 8-14 hours focused work in a 37KB / 852-line
binary with JSM-discipline + cross-repo + worktree-mode overhead.

## Why DECLINED

Per `feedback_decompose_by_natural_unit_not_bundle.md` (META-RULE
2026-05-10):

> "when work has natural per-surface/per-file unit and total >1-2h, file
> 1 bead per unit; bundling forces over-tick or refuse-decompose"

Each of the 4 deliverables is a 2-4h standalone unit. Bundling them in a
single bead violates the META-RULE. Same shape as parent oxzyr →
oxzyr.1 + oxzyr.2 decomposition precedent.

## Proposed decomposition — 6 sub-beads

| Sub-bead | Deliverable | Effort | Dep |
|---|---|---|---|
| oxzyr.2.1 | chokepoint function + refactor existing sites | 2-3h | none (foundation) |
| oxzyr.2.2 | `doctor undo <run-id>` subcommand | 2-3h | needs .2.1 |
| oxzyr.2.3 | FM-5 + FM-10 (audit-only retraction class) | 1-2h | needs .2.1 |
| oxzyr.2.4 | FM-6 + FM-9 (byte-exact undo class) | 1-2h | needs .2.1+.2.2 |
| oxzyr.2.5 | FM-8 (input-deaf quarantine) | 1-2h | needs .2.1 |
| oxzyr.2.6 | Real fixture data + round-trip tests for 10 FMs | 2-3h | needs .2.1-.2.5 |

Total: ~10-15h parallelizable; each sub-bead is single-PR-natural.

## Sister-precedent — DECLINED-with-decomposition is canonical pattern

| Parent | Initial state | Decomposition |
|---|---|---|
| flywheel-oxzyr | "10-phase doctor-mode loop" | → oxzyr.1 (Phase 1+2) + oxzyr.2 (Phase 4+) |
| flywheel-38u3d | "nextra scaffold per client across 5 repos" | → 38u3d.1 + mv2th + ti46c + sjr9e decomposition chain |
| flywheel-jloib | "canonical-CLI baseline tooling" | → tiugg (helper) + 3wxzi (refactor) |
| **flywheel-oxzyr.2** (THIS) | "pass-2 4 bundled deliverables" | **proposed: 6 sub-beads** |

## What I did NOT do (per DECLINED discipline)

- Did NOT attempt chokepoint refactor (would still leave 5 unfinished deliverables; not a clean partial)
- Did NOT modify flywheel-loop binary (cross-repo + JSM-aware)
- Did NOT create worktree branch `doctor-mode-pass-2` (no code mutation)
- Did NOT close the bead (DECLINED → stays open)
- Did NOT file the 6 sub-beads myself (per dispatcher convention, orch files them)

## Recommended orch sequence

1. File 6 sub-beads per the decomposition table
2. Dispatch oxzyr.2.1 (chokepoint foundation) FIRST
3. Once .2.1 closes, dispatch .2.2 + .2.3 + .2.4 + .2.5 in parallel
4. Once .2.2-.2.5 close, dispatch .2.6 (fixture data + round-trip tests)
5. After .2.6 closes, oxzyr.2 closes; pass-2 scorecard tabulates actual uplift vs +1050 projected

## Compliance

- AG receipt: DECLINED (per scope-mismatch; bundled 4 natural units)
- META-RULE 2026-05-11: 36th application (probe before claiming; honest disposition)
- META-RULE 2026-05-10: respected (decompose-by-natural-unit; refuse bundling)
- L52: 0 new beads filed (per dispatcher convention)
- L107: 0 reservations (no edits)
- L61: no doctrine/INCIDENTS touched
- Boundary preservation: 0 edits to flywheel-loop
- compliance_score: 1000/1000 (DECLINED disposition quality)

## Lesson

Two DECLINED dispositions in this session (ti46c earlier, oxzyr.2 now)
when bundling/dependency violations surfaced. The pattern is consistent:
when the bead packet violates META-RULE 2026-05-10 or has unsatisfied
hard dependency, the honest disposition is DECLINE/BLOCKED with concrete
decomposition or dependency surfacing. Both keep the bead open for orch
to act on.

This is preferable to "ship partial + push remaining work to pass-N+1"
because partial-ship anti-pattern hides the decomposition need and
re-encounters the same problem at every pass boundary.
