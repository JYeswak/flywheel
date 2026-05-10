---
bead: flywheel-bu0es
title: test-doctor-empty-errors.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: direct
parent: flywheel-ok1sk (jloib wave-1; sub-bead 6 of 17)
sister_exemplars: 0pkcf=985, ou656=985, lrdum=985, gbfpo=985, kz7o0=985 (avg 985)
---

# Journey: flywheel-bu0es

## What Joshua asked for

Wave-1-doctrine-6 (6th ok1sk sub-bead). This script IS the synthetic
regression test for flywheel-9vb9i's loud-failure invariant fix —
canonical-cli'ing it brings doctrine to the test surface itself.

## What I shipped

- 18 TODO markers filled with substantive impl
- doctor: 6 named probes (bash, jq, mktemp, flywheel_loop_executable,
  python3, audit_log_dir) — load-bearing trio: flywheel_loop_executable
  (the binary under test) + bash + jq
- health: $SCAFFOLD_AUDIT_LOG binding with stale-threshold
- repair: 2 scopes (state_dir, audit_log_dir) with apply contract
- validate: 3 subjects with test-domain contracts:
  - **test-name**: matches `^test-[a-z0-9-]+$` (canonical fleet-wide test-script naming)
  - **fixture-path**: regular-file + readable check (fixture-driven tests are common)
  - audit-row: standard
- audit + why: standard sister pattern
- Test 13 → 19 (calibrated 2 + added 6 fillin including test-name +
  fixture-path rejection tests)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean.

## Notable

- This script is META-TEST: it tests flywheel-loop doctor's contract
  (status=fail must have non-empty errors[]). flywheel-9vb9i shipped
  the doctor-side fix; this script is the regression guard. Adding
  canonical-cli to the test itself ensures the test surface is also
  inspectable + doctorable.
- The `flywheel_loop_executable` doctor check is recursive-relevant:
  this script's whole purpose is to test flywheel-loop, so probing for
  it is the critical readiness check.

## Files touched

- `.flywheel/scripts/test-doctor-empty-errors.sh` (168 → 657 lines)
- `tests/test-doctor-empty-errors-canonical-cli.sh` (13 → 19 tests)
- `.flywheel/audit/flywheel-bu0es/{evidence,journey,compliance,smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-bu0es.md`

## Mission fitness

Class: **direct**. Wave-1-doctrine-6 sub-bead from ok1sk decomposition;
canonical-cli scaffold + fillin on a doctrine-lane synthetic regression test.
