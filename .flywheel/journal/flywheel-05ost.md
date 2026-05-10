---
bead: flywheel-05ost
title: test-loop-driver-doctor.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: direct
parent: flywheel-ok1sk (jloib wave-1; sub-bead 7 of 17)
sister_exemplars: 6 closes avg 985 (0pkcf, ou656, lrdum, gbfpo, kz7o0, bu0es)
---

# Journey: flywheel-05ost

## What Joshua asked for

Wave-1-doctrine-7 (7th ok1sk sub-bead). Sister to bu0es (test-doctor-empty-errors).
Both are synthetic L57 loop-driver doctor verdict tests. Apply same recipe.

## What I shipped

- 18 TODO markers filled with sister-bu0es recipe (zero regression catches)
- Doctor: 6 probes (bash, jq, mktemp, flywheel_loop_executable, python3, audit_log_dir)
- Health: $SCAFFOLD_AUDIT_LOG binding
- Repair: 2 scopes (state_dir, audit_log_dir); apply contract enforced
- Validate: 3 subjects (test-name, fixture-path, audit-row) with rejection tests
- Audit + Why: standard sister pattern
- Test 13 → 19 (calibrated 2 + added 6 fillin)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean.

## Notable

- Sister-pattern transfer from bu0es was clean — both scripts share the
  same "synthetic doctor verdict test" domain. Same probe set, same
  validate subjects, same scopes. Confirms the test-domain canonical-cli
  template is well-defined.
- 196 → 685 lines (489 added) — typical for a sister bash file.

## Files touched

- `.flywheel/scripts/test-loop-driver-doctor.sh` (196 → 685 lines)
- `tests/test-loop-driver-doctor-canonical-cli.sh` (13 → 19 tests)
- `.flywheel/audit/flywheel-05ost/{evidence,journey,compliance,smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-05ost.md`

## Mission fitness

Class: **direct**. Wave-1-doctrine-7 sub-bead from ok1sk decomposition.
