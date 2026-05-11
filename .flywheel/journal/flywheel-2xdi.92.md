---
bead: flywheel-2xdi.92
title: probe-without-receiver fix — public-artifact-pipeline-probe regression test
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
sister: flywheel-2xdi.90 (operator-fatigue-probe; same recipe)
---

# Journey: flywheel-2xdi.92

## What the bead asked for

Same class as 2xdi.90: `public-artifact-pipeline-probe.sh` emits probe
output but no receiver references it.

## What I shipped

Same recipe: `tests/public-artifact-pipeline-probe-canonical-cli.sh`,
10/10 PASS. Test name matches gap-hunt-probe's corpus #5 pattern
(`*-canonical-cli*.sh`).

Probe has slightly richer surface than fatigue-probe (--dry-run/--apply
mutation discipline), so test covers those too.

## Verification

- Test: 10/10 PASS (clean, no refinement needed)
- Fresh gap-hunt-probe: public-artifact-pipeline-probe.sh no longer in cold list
- probe-without-receiver total: 19 → 16 (this fix + sampling re-rank)

## Pattern note

2nd faithful application of the 2xdi.90 receiver wire-in recipe. The recipe
is now proven for probe-class scripts that need a corpus-#5 (test file)
receiver. If/when N=3 (next probe-without-receiver bead), this becomes a
candidate skill discovery: `pattern-emerged-probe-without-receiver-via-
canonical-cli-test-fix`.
