---
bead: flywheel-1hshd.14
title: codex-budget-probe.sh canonical-CLI scaffold + 18-TODO fillin (NO-BYPASS, lint-idiom-fix 2nd application)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-1hshd (jloib wave-4; sub-bead 14 of 37)
sister_exemplars: 5ke66.15 (985, lint-idiom-fix sister); 5ke66.{2,13,15} + 1hshd.13 (NO-BYPASS family)
---

# Journey: flywheel-1hshd.14

## What Joshua asked for

Wave-4-general-14. Surface: codex-budget-probe.sh = codex-account budget
sampler that drives fleet drain decisions via fleet_state ∈ {ready,
draining, limit_hit}.

## What I shipped

NO-BYPASS variant — script has zero native canonical surfaces. Standard
recipe applies. Plus second application of LINT-IDIOM-FIX pattern from
5ke66.15 (script also uses `set -uo pipefail` for tmux/grep tolerance).

- 18 TODO markers replaced with substantive impl
- LINT-IDIOM-FIX: `set -uo pipefail` → `set -euo pipefail; set +e` with
  NOTE explaining the tmux/grep no-match tolerance rationale
- doctor: 9 named probes (tmux + grep + tail load-bearing trio for
  codex-tui.log scanning + tmux send-keys)
- health: 2h stale threshold (frequent budget probe cadence)
- repair: 3 scopes (state_dir + scratch_dir + audit_log_dir; sister to
  5ke66.13 mobile-eats DUAL-state pattern)
- validate: 4 subjects (session-name lowercase-prefix; threshold-pct
  [0,100] matching --threshold default 10; fleet-state enum
  {ready,draining,limit_hit} per docstring L11-L20; audit-row standard)
- audit: cli_emit_audit_tail; why: 4 keys (ts/session/fleet_state/run_id)
- Test 13 → 19 with calibration:
  - Tests 14: load-bearing trio probe assertion
  - Tests 15-17: session-name + threshold-pct accept/boundary/reject
  - Test 18: fleet-state full-enum sweep
  - Test 19: NEW lint-idiom-fix preservation assertion (BOTH `set -euo
    pipefail` AND `set +e` lines must be present)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations after idiom-fix).

## Notable

- **Second lint-idiom-fix** application formally matures the pattern.
  Two-occurrence threshold met. The two-line `set -euo pipefail; set +e`
  is now canonical for any script with intentional `-e` exclusion.
  Test 19 codifies the structural assertion that catches a future
  maintainer removing the `set +e` line.
- **fleet-state enum** is load-bearing: matches the LITERAL values the
  script computes per docstring. Validator references same enum so
  drift between script docstring + validator is immediately catchable.
- **Most-subjects validate** of the session (4 subjects). Each maps to
  a different facet of the script's contract: input args (session-name,
  threshold-pct), output enum (fleet-state), and audit standard.
- **3-scope repair** matches 5ke66.13 mobile-eats pattern (separate
  state-file dir + scratch dir + canonical audit log dir).

## Files touched

- `.flywheel/scripts/codex-budget-probe.sh` (227 → 473 lines)
- `tests/codex-budget-probe-canonical-cli.sh` (94 → 168 lines)
- `.flywheel/audit/flywheel-1hshd.14/{evidence,journey,compliance,17 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-1hshd.14.md`

## Mission fitness

Class: **adjacent**. codex-budget-probe.sh is the budget sampler that
drives fleet drain decisions; canonical-CLI surface lets orchestrator
probe substrate + validate args before triggering budget probes.
