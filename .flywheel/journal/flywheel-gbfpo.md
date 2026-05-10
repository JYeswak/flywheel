---
bead: flywheel-gbfpo
title: plan-to-bead-auto-trigger.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: direct
parent: flywheel-ok1sk (jloib wave-1; sub-bead 4 of 17)
sister_exemplars: 0pkcf=985, ou656=985, lrdum=985 (avg 985)
---

# Journey: flywheel-gbfpo

## What Joshua asked for

Wave-1-beads-4 (4th ok1sk sub-bead). Bash file with bash interpreter;
straightforward bash scaffolder application. Sister recipe (lrdum)
applied with domain-specific tailoring.

## What I shipped

- 18 TODO markers filled with substantive impl
- doctor: 6 named probes (br_executable, jq_available, find_available,
  repo_root_resolvable, plans_dir_present, audit_log_dir_writable) with
  load-bearing emphasis on br + jq + plans_dir (the plan-to-bead pipeline trio)
- health: $SCAFFOLD_AUDIT_LOG binding with stale-threshold
- repair: 2 scopes (plans_dir, audit_log_dir) with apply contract
- validate: 3 subjects with **3-layer plan-path enforcement** (under
  .flywheel/PLANS/, .md extension, exists on disk) — each rejection has a
  distinct `reason` code (tests 16+17 verify both)
- bead-id regex accepts dotted sub-bead form (sister lrdum pattern)
- audit + why: standard sister pattern
- Test 13 → 19 (calibrated 2 + added 6 fillin including 2 layered plan-path
  rejection tests + dotted sub-bead test)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean.

## Notable

- The plan-path validate is more granular than other surfaces' path validate:
  3 distinct rejection reasons (`not_under_plans_dir`, `not_markdown_extension`,
  `not_found_on_disk`) so callers can act on the specific failure. Tests 16+17
  cover the first two; the third (`not_found_on_disk`) requires a real path
  test.
- doctor reports `find_available` as a probe — POSIX `find` is rare to be
  missing but this script literally uses `find -mindepth 2 -maxdepth 2 -type f
  -name '00-PLAN.md'` (per the script's run path) so probing for it explicitly
  catches the rare missing-find environment.

## Files touched

- `.flywheel/scripts/plan-to-bead-auto-trigger.sh` (145 → 632 lines)
- `tests/plan-to-bead-auto-trigger-canonical-cli.sh` (13 → 19 tests)
- `.flywheel/audit/flywheel-gbfpo/{evidence,journey,compliance,smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-gbfpo.md`

## Mission fitness

Class: **direct**. Wave-1-beads-4 sub-bead from ok1sk decomposition;
canonical-cli scaffold + fillin on a beads-lane plan-to-bead trigger.
