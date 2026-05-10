---
bead: flywheel-jloib
title: flywheel-cli-canonical-baseline (decomposition tick)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped (decomposition-only)
priority: P1
mission_fitness: adjacent
sister_pattern: wzjo9 (4-wave decomposition)
---

# Journey: flywheel-jloib decomposition

## What Joshua asked for

Decompose flywheel-jloib (P1 doctor-mode-integration-2) into N sub-beads
with apply-specs. Use canonical-cli inventory as scope source. Sister
exemplars: 1fk5f (8 sub-beads filed), wzjo9 (4 sub-waves filed).
**DECOMPOSITION-ONLY**: file beads, don't implement.

## Scope analysis

405 binaries in inventory. Filter `ownership=own AND priority=P0 AND
canonical_cli_scoping_status IN (missing, partial)` yielded 143 surfaces.
P1 own surfaces all already in `passing` state — no work needed there.

## Decision: 5 wave beads, hierarchical decomposition

Reconciled the natural-unit META-RULE (one bead per binary) with the
sister-exemplar pattern (4-8 sub-beads) using **wzjo9's hierarchical model**:
file 5 wave beads now, defer per-binary sub-bead filing until each wave is
dispatched (matching `wzjo9.1 → wzjo9.1.{1..9}` expansion at exec time).

Wave structure (status × lane):
- Wave 1 (ok1sk): P0 missing × non-general lanes (21 surfaces, 7 lanes)
- Wave 2 (ni92d): P0 missing × general lane (21 surfaces)
- Wave 3 (5ke66): P0 partial × non-general lanes (27 surfaces, 8 lanes)
- Wave 4 (k8gcv): P0 partial × general lane split A (37 surfaces)
- Wave 5 (1hshd): P0 partial × general lane split B (37 surfaces)

Total = 143. ✓

## Why 5 and not 4

The general lane has 95 surfaces — too big for one wave (refuse-decompose
problem). Splitting general into two alphabetic halves (37+37) plus 3
status-bucketed waves for the lighter remainder gave 5 evenly-sized waves.
4 waves would have forced 95 general into one bead; 8 waves would have
filed one bead per lane (heavy-tailed and noisier).

## Files written

- `.flywheel/audit/flywheel-jloib/decomposition-receipt.md` (this dispatch's primary deliverable)
- `.flywheel/audit/flywheel-jloib/wave-{1..5}-apply-spec.md` (5 apply-specs)
- `.flywheel/journal/flywheel-jloib.md` (this file)

## Beads filed

5 wave beads, all priority=P0 type=task, all parent-child linked to flywheel-jloib:
- flywheel-ok1sk (wave 1)
- flywheel-ni92d (wave 2)
- flywheel-5ke66 (wave 3)
- flywheel-k8gcv (wave 4)
- flywheel-1hshd (wave 5)

## Beads NOT touched

- 11 jeff-stack-orchestrated binaries: out of scope per parent boundary
  (upstream issues, not patches)
- 9 P0 own-passing binaries: already meet baseline
- 118 P1 own-passing binaries: already meet baseline

## Mission fitness

Class: **adjacent**. The decomposition itself doesn't ship canonical-cli
baselines (the parent goal); it sets up the dispatch surface so subsequent
worker ticks can ship them in parallel without re-doing bucketing analysis.

## Notable

- jeff-corpus showed up across both missing (4) and partial (12) waves —
  these are flywheel-authored shell scripts for the jeff-corpus pipeline,
  NOT jeff-stack binaries (which are owned by Jeffrey). Filter relied on
  `ownership=own` field from inventory, not name prefix.
- `br create` swallowed the first wave-1 ID silently (race with daemon?);
  retry produced ok1sk. Tracked via the wave-id mapping file rather than
  by parsing each `br create` invocation's output.
