---
bead: flywheel-wzjo9.2.1
title: clobber-recovery.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: direct
parent_wave: flywheel-wzjo9.2 (wave-2.0b — recovery infrastructure)
---

# Journey: flywheel-wzjo9.2.1

## What Joshua asked for

Wave 2.0b-a (first sub-bead of wave-2.0b recovery batch). Sister wave-2.0a
now 7/9 closed avg 982. Smallest-first; 30-60min budget.

## What I shipped

1. Reserved + backed up; dry-run + apply scaffold (no verb collisions)
2. Filled 18 TODO markers with substantive surface-specific impl:
   - 7 per-surface schemas in `scaffold_emit_schema`
   - 9 single-printf topic helpers (gl7om SIGPIPE-safe)
   - 6 named substrate probes in `scaffold_cmd_doctor` (including the
     load-bearing `head_content_nonempty` check that surfaces the same
     safety condition the script's exit-3 already guards)
   - $SCAFFOLD_AUDIT_LOG-binding `scaffold_cmd_health` (warn at >24h stale)
   - 2 surface-specific scopes in `scaffold_cmd_repair` (log_dir,
     truncated_doctrine) with apply contract enforced
   - 3 subjects in `scaffold_cmd_validate` (doctrine-path, canonical-set,
     recovery-row) with rc=1 schema rejection
   - cli_emit_audit_tail wiring in `scaffold_cmd_audit`
   - Provenance lookup in `scaffold_cmd_why` (3 states)
3. Audit-log wiring at repair terminal envelope (cli_audit_append)
4. Extended baseline 13-test suite to 19 (calibrated 2 tests + added 6
   fillin assertions including 2 load-bearing concrete-data tests)

## AG verification

| Gate | Result |
|---|---|
| AG1: 18 TODO replaced | ✓ |
| AG2: bash -n exits 0 | ✓ |
| AG3: lint exits 0 | ✓ |
| AG4: tests pass | ✓ 19/19 |
| AG5a-f: per-surface impl | ✓ |

Strict apply-spec validation predicate: **AG1-5 PASS**.

## Notable

- The doctor's `head_content_nonempty` probe is the load-bearing check —
  it surfaces (proactively) the same condition the script's exit-3 guard
  catches reactively. Bridges the safety contract into the canonical-cli
  introspection surface.
- `validate doctrine-path` enforces canonical-set membership BEFORE checking
  HEAD content (cheaper rejection for non-canonical paths).
- `repair truncated_doctrine` deliberately does NOT duplicate cmd_run logic;
  it's a documented invocation pointer (operator should run the script with
  no scope arg to invoke the canonical recovery flow).
- Test calibration (2 baseline tests) per `feedback_calibrate_test_to_actual_contract`
  META-RULE — `--scope none` swapped to `--scope log_dir`; bare `validate`
  refuses with rc=64 (canonical contract).

## Files touched

- `.flywheel/scripts/clobber-recovery.sh` (scaffold + 18-TODO fillin; 164→619 lines)
- `tests/clobber-recovery-canonical-cli.sh` (13 → 19 tests)
- `.flywheel/audit/flywheel-wzjo9.2.1/{evidence,journey,compliance,smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-wzjo9.2.1.md`

## Mission fitness

Class: **direct**. P2 wave-2.0b-a sub-bead per the wzjo9 recovery lane plan;
adds canonical-cli surface to a recovery primitive that was missing it.
