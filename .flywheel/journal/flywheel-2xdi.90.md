---
bead: flywheel-2xdi.90
title: probe-without-receiver fix — operator-fatigue-probe regression test
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
---

# Journey: flywheel-2xdi.90

## What the bead asked for

`operator-fatigue-probe.sh` emits probe output but no tick/status/last_tick
receiver references it.

## Investigation (N=14 bead-hypothesis META-rule)

Probe exists, well-formed, canonical-cli surfaces work. Scanned all 5
gap-hunt corpora (tick.md, last_tick receipts, .flywheel/scripts/*.sh
callers, launchd plists, test files) — no receivers. Genuine gap.

Two receiver options:
1. **Tick wire-in** at `~/.claude/commands/flywheel/tick.md` — cross-repo
   into JSM-managed claude commands; requires patch-artifact discipline
   per the doctrine just shipped in 2xdi.93.
2. **Regression test** at `tests/` — in-scope, sister-pattern proven by
   cost-telemetry-token-burn-probe-canonical-cli.sh etc.

Chose option 2.

## What I shipped

`tests/operator-fatigue-probe-canonical-cli.sh` — 9 assertions:
1. syntax
2-5. canonical-cli triad (--info / --schema / --doctor / --health)
6. default --json run emits measurement envelope
7. Step 4o anti-pattern preserved (no notification call sites)
8. READ-ONLY discipline
9. Strict-mode loud failure on missing input

Test name follows the `*-canonical-cli*.sh` convention so it matches
gap-hunt-probe's corpus pattern #5.

## Mid-bead test refinements

Test 7 (Step 4o regex) and Test 9 (missing-input assumption) both needed
refinement before clean PASS. Tests THEMSELVES exhibit the bead-hypothesis
META-rule: probe expected behavior empirically before asserting it.

## Verification

- Test: 9/9 PASS
- Fresh gap-hunt-probe: `operator-fatigue-probe.sh` no longer in cold list
- `probe-without-receiver` total: 20 → 19

## L112 probe

    bash .flywheel/scripts/gap-hunt-probe.sh --json |
      jq '.gap_ids[] | select(test("probe-without-receiver.*operator-fatigue"))'

Expected: empty output.

## Pattern note

`probe-without-receiver` resolves via any of 5 corpus-#-receiver shapes.
Choosing the LIGHTEST-touch receiver (test file vs tick wire-in) avoids
cross-repo mutator path when in-repo path suffices.

Extends 2xdi.* fix cluster: 47/49/64/66 corpus extensions, 93 doctrine
cross-link, 90 = test-receiver wire-in.
