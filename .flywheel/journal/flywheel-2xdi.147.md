---
bead: flywheel-2xdi.147
title: wired-but-cold fix — cross-repo-fmh-probe test (N=4 post-promotion)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: 2xdi.90 + .92 + .146 (N=4 post-promotion application)
---

# Journey: flywheel-2xdi.147

## What the bead asked for

`.flywheel/scripts/cross-repo-fmh-probe.sh` wired-but-cold.

## Investigation (N=35 bead-hypothesis META-rule)

- Script exists, well-formed (cross-repo-fmh-probe.v1 schema)
- Owns flywheel-1rmp.12 (cross-repo failure-mode-harvester value-gap)
- Full canonical-cli surface: --info/--schema/--doctor/--health/--json
  + operational args (--lookback-days/--min-repos/--top)
- Step 4o anti-pattern preserved (READ-ONLY)
- 0 active corpus receivers → genuine cold

## What I shipped

`tests/cross-repo-fmh-probe-canonical-cli.sh` (105 lines, 12/12 PASS):
- 5 canonical-cli surface envelopes (info/schema/doctor/health/json)
- 3 operational arg acceptance (lookback-days/min-repos/top)
- Step 4o READ-ONLY anti-pattern (extends to br/ntm mutating verbs too)
- schema_version stability across all 5 surfaces
- owner-bead (flywheel-1rmp.12) citation preservation

## Verification

- 12/12 test PASS
- Fresh probe: `cross-repo-fmh-probe` cleared

## L112 probe

    bash tests/cross-repo-fmh-probe-canonical-cli.sh | tail -1

Expected: `grep:pass=12 fail=0`.

## Pattern note — 1st post-promotion instance

Sister to 2xdi.146 (which carried the N=3 promotion filing). This is
the 1st post-promotion application of the test-receiver wire-in recipe.

Confirms operational stability:
- Recipe template unchanged
- Assertion count grew (9/10/10 → 12) reflecting probe surface richness,
  not template change
- Test file naming + corpus #5 mapping work identically

Cluster distribution:
- doctrine cross-link forward-link: N=11
- probe corpus extensions: N=4
- **test-receiver wire-in: N=4** ← tied for 2nd-most-replicated

24th distinct fix shape entry in 2xdi/kwjja/r9pri arc.
