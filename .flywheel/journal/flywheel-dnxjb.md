---
bead: flywheel-dnxjb
title: gap-hunt-probe probe-finder excludes test-tree paths (root cause fix)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
sister: flywheel-9a3k1 (auto-bead-filer dedup safety net; shipped earlier this tick)
parent: flywheel-2xdi
discovered_during: flywheel-2xdi.101
---

# Journey: flywheel-dnxjb

## What the bead asked for

gap-hunt-probe's `*-probe.sh` rglob picks up test files in `tests/` that
aren't actually probes. Fix the probe-finder to scope to canonical probe
locations only.

## Investigation (N=17 bead-hypothesis META-rule)

Bead offered 3 options:
- A: scope glob to .flywheel/scripts/ + ~/.claude/skills/ (path filter)
- B: introspect candidates for probe-shape signatures
- C: rename convention (already used in 2xdi.101 one-off)

Chose A. Surgical, predictable, paired with 9a3k1 dedup as
defense-in-depth.

## What I shipped

`.flywheel/scripts/gap-hunt-probe.sh` — new `_is_in_test_tree()` helper +
post-collection filter in `probe_without_receiver()`. Excludes paths
under `tests/` (top-level) and `.flywheel/tests/` (nested). Preserves
all other paths (real probes in scripts/ and skill-substrate trees).

Test: `tests/gap-hunt-probe-tests-tree-exclusion-canonical-cli.sh` 8/8 PASS

## Verification

- 8/8 new test PASS
- All 5 sister gap-hunt-probe tests still green
- Live probe count: probe-without-receiver 14 → 11 (3 historical FPs
  cleared by the filter)

## L112 probe

    bash tests/gap-hunt-probe-tests-tree-exclusion-canonical-cli.sh | tail -1

Expected: `grep:pass=8 fail=0`.

## Pattern note

8th distinct fix shape in 2xdi.* cluster:
- 47/49/64/66 = probe corpus extensions (broaden)
- 93 = doctrine cross-link
- 90/92 = test-receiver wire-in
- 100 = INCIDENTS citation
- 101/102 = canonical-cli rename
- **dnxjb = probe-finder path filter (narrow)**

Defense-in-depth with sister 9a3k1: this bead prevents misidentification
at the source; 9a3k1 dedups at the auto-filer layer. Either alone
addresses the immediate cluster; together they prevent recurrence under
new corpus-collision shapes.

Three beads (2xdi.101 + 9a3k1 + dnxjb) shipped same session as the
duplicate-bead-pair pattern Joshua surfaced. Hint-to-shipped-fix
arc: ~3 worker-ticks.
