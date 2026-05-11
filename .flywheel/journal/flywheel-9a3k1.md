---
bead: flywheel-9a3k1
title: auto-bead-filer dedup against open beads with matching title
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-2xdi
discovered_during: flywheel-2xdi.101 (Joshua-flagged)
sister: flywheel-dnxjb (probe-finder tests/ FP root cause)
---

# Journey: flywheel-9a3k1

## What the bead asked for

Auto-bead-filer didn't dedup on title. Two gap_ids with same basename
(e.g., `state-store-authority-probe.sh` in `.flywheel/scripts/` AND `tests/`)
produced two beads with identical titles in the queue (2xdi.101 + .102).

## What I shipped

Three coordinated changes in `.flywheel/scripts/gap-hunt-probe.sh`:

1. **New `open_bead_titles()` function** — calls `br list --status open
   --status in_progress --limit 5000 --json` once per main() invocation,
   returns `{title: bead_id}` dict. First-seen wins (oldest open bead owns
   the title).

2. **`create_bead(open_titles=...)` parameter + dedup check** — if title
   already in cache, warn + return None instead of filing duplicate.

3. **`main()` integration** — builds cache before auto-bead loop; mutates
   cache as new beads are filed (intra-run dedup) so two same-title gaps
   in a single tick also dedup.

## Test design

`tests/gap-hunt-probe-dedup-canonical-cli.sh` 8/8 PASS. Stubs `br` via
PATH override; integration test asserts dedup short-circuits matching
title AND allows non-matching title through (no false-positive dedup).

## Verification

- 8/8 new test PASS
- All 4 sister gap-hunt-probe tests still green (4/4, 4/4, 4/4, 6/6)
- Live probe dry-run: probe-without-receiver count stable at 14 (no
  regression)

## L112 probe

    bash tests/gap-hunt-probe-dedup-canonical-cli.sh | tail -1

Expected: `grep:pass=8 fail=0`.

## Pattern note

Joshua-hint productivity: dispatch note about a "dup title" in 2xdi.101
surfaced TWO root causes — auto-filer dedup (this bead) + probe-finder
FP (`flywheel-dnxjb`). Closing both in the same session prevents the
duplicate-bead-pair pattern from recurring.

The auto-bead-filer is now the safety-net for any future basename
collisions across the 5 corpora gap-hunt-probe scans. Even if the
probe-finder is later tightened (dnxjb), this dedup remains as
defense-in-depth against new corpus-collision shapes.
