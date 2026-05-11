---
bead: flywheel-5ke66.19
title: state-md-miner.sh canonical-CLI scaffold + 18-TODO fillin (PARTIAL-BYPASS, 3rd application)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-5ke66 (jloib wave-2; sub-bead 19 of 21)
sister_exemplars: 5ke66.11 (985, same PARTIAL); 5ke66.6 (985, same PARTIAL)
---

# Journey: flywheel-5ke66.19

## What Joshua asked for

Wave-2-general-19 (19th 5ke66 sub-bead). Surface: state-md-miner.sh =
fleet STATE.md miner that identifies stale entries (>--stale-days,
default 14) and proposes /flywheel:learn auto-bead candidates
(--max-beads-per-repo, default 5).

## What I shipped

PARTIAL-BYPASS variant — third application. Native `--info / --schema
/ --examples` all PASSTHRU to python heredoc emitting state-md-miner/v1
canonical envelope + full JSON-Schema for findings + decisions arrays;
scaffold owns verb subcommands.

- 18 TODO markers replaced with substantive impl
- `_scaffold_is_canonical_arg` returns 1 for `--info|--schema|--examples`
- doctor: 7 named probes (python3 + roster + state_dir load-bearing trio)
- health: 36h stale threshold (1.5x daily mining cadence)
- repair: 2 scopes (state_dir + audit_log_dir)
- validate: 3 subjects (repo-path absolute-only matching --repo arg;
  stale-days [1,365] matching --stale-days arg with default 14;
  audit-row standard)
- audit: cli_emit_audit_tail; why: 4 keys (ts/repo/finding_id/run_id)
- Test 13 → 19 with calibration + fillin (dual-direction fidelity check
  + range-bound validators + load-bearing probe trio)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations). Recipe transferred mechanically from 5ke66.11.

## Notable

- Third PARTIAL-BYPASS confirms variant + recipe maturity. No
  surprises during application; pattern is now mechanical.
- repo-path validator (absolute-only) mirrors 5ke66.2 append-safe-write
  target-path pattern. Worth formalizing as canonical: any path-arg
  validator should reject relative paths because dispatch packets run
  from unpredictable CWD.
- Native --info keys (default_roster, default_state_dir) align with
  scaffold doctor probes (roster_readable, state_dir_writable) —
  scaffold complements native by telling the operator whether those
  paths are CURRENTLY readable/writable, not just what the defaults are.

## Files touched

- `.flywheel/scripts/state-md-miner.sh` (503 → 749 lines)
- `tests/state-md-miner-canonical-cli.sh` (94 → 158 lines)
- `.flywheel/audit/flywheel-5ke66.19/{evidence,journey,compliance,15 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-5ke66.19.md`

## Mission fitness

Class: **adjacent**. state-md-miner.sh drives /flywheel:learn auto-bead
creation from STATE.md staleness; canonical-CLI surface lets
orchestrator probe substrate + validate args before triggering mining.
