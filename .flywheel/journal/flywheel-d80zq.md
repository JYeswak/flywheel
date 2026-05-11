---
bead: flywheel-d80zq
title: jeff-verdict-heuristic.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: adjacent
parent: flywheel-ok1sk (jloib wave-1; sub-bead 12 of 17)
sister_exemplars: ugjvq (985), 64hud (985), x0k3j (985), vs78t (985), lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Journey: flywheel-d80zq

## What Joshua asked for

Wave-1-jeff-corpus-12 (12th ok1sk sub-bead). Bash-wraps-python3 surface,
but unique among jeff-corpus siblings: this is a STATELESS classifier
(no git/repo/network deps), so substrate footprint is minimal.

## What I shipped

- 18 TODO markers replaced with substantive impl
- doctor: 6 named probes (smaller than sisters because stateless);
  envelope explicitly notes minimal substrate footprint to differentiate
  from x0k3j/ugjvq sisters which have git+repo dependencies
- health: 7d stale threshold (on-demand classifier; weekly grace, much
  more permissive than sisters' 12-36h thresholds for scheduled jobs)
- repair: 2 scopes (state_dir for verdict cache, audit_log_dir)
- validate: 3 subjects with the **load-bearing one being verdict
  enum** restricted to 4 canonical values (YES_ADOPT, YES_ADAPT,
  NO_NOT_OUR_DOMAIN, NEED_RESEARCH); case-sensitive
- audit: cli_emit_audit_tail; why: 4 keys (ts/repo/verdict/run_id)
- Test 13 → 19 (calibrated 2 + 6 fillin including FULL-ENUM sweep)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations).

## Notable

- verdict validate uses bash `case` over enum values rather than regex —
  cleaner expression of "must be one of these N strings" contract; emits
  `valid_verdicts` list in reject envelope so consumers learn the schema
- Test 15 sweeps all 4 enum values in a loop — catches any future
  mistake where someone removes a verdict from the case statement but
  forgets to remove from valid_subjects
- Test 17 explicitly tests case-sensitivity (rejects `yes_adopt`) to
  document the case-sensitive enum contract
- Bug-catch: initial test 14 jq query `[.checks[].name] | contains(...)
  and (.note // "" ...)` failed because after `|` the input becomes the
  array, not the object. Fixed with explicit parens + restart-from-input
  pattern. Sister scripts didn't hit this because they don't combine
  array-derived check + object-level field in one filter.

## Files touched

- `.flywheel/scripts/jeff-verdict-heuristic.sh` (146 → 392 lines)
- `tests/jeff-verdict-heuristic-canonical-cli.sh` (94 → 158 lines)
- `.flywheel/audit/flywheel-d80zq/{evidence,journey,compliance,15 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-d80zq.md`

## Mission fitness

Class: **adjacent**. jeff-verdict-heuristic.sh is the classifier that
decides whether to adopt/adapt/skip Jeff upstream patterns. Canonical-CLI
surface enables orchestrator-side verdict validation + classifier
substrate probing.
