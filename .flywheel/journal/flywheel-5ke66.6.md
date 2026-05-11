---
bead: flywheel-5ke66.6
title: daily-report.sh canonical-CLI scaffold + 18-TODO fillin (WZJO9.1.7 PARTIAL-BYPASS)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-5ke66 (jloib wave-2; sub-bead 6 of 21)
sister_exemplars: 5ke66.4 (985, full BYPASS-ALL); 5ke66.2 (985, no-bypass)
---

# Journey: flywheel-5ke66.6

## What Joshua asked for

Wave-2-general-6 (6th 5ke66 sub-bead). Surface: daily-report.sh = bash
wrapper around daily-report.py with NTM analytics rollup append.

## What I shipped

This is a **WZJO9.1.7 PARTIAL-BYPASS** case — the third wzjo9.1.7
variant. Native `--info / --schema / --examples` flags PASSTHRU to the
python heredoc (richer JSON-Schema for the daily-report result envelope,
full version + script metadata), but the scaffold's verb subcommands
(doctor/health/repair/validate/audit/why) are NOT natively supported.

Strategy: scaffold owns verb form, native owns flag form.

- 18 TODO markers replaced with substantive impl
- `_scaffold_is_canonical_arg` modified: returns 0 for verbs (scaffold
  fires) but returns 1 for `--info|--schema|--examples` flags (native
  PASSTHRU fires)
- doctor: 7 named probes (python3 + ntm + daily_report_py all load-bearing)
- health: 36h stale threshold (1.5x daily cadence)
- repair: 2 scopes (scratch_dir for $TMPDIR, audit_log_dir)
- validate: 3 subjects (session-name lowercase-prefix matching default;
  report-path .md OR .json matching script's actual outputs; audit-row)
- audit: cli_emit_audit_tail; why: 4 keys (ts/session/report_path/run_id)
- Test 13 → 19 with calibration to PARTIAL-BYPASS contract:
  - Tests 2/3/4: native PASSTHRU shape (.version+.script;
    .$schema+.title="flywheel daily report result"; text examples)
  - Tests 5-13: scaffold owns (doctor/health/repair/validate/audit/why/help/
    quickstart all use scaffold envelopes)
  - Test 14: PARTIAL-BYPASS annotation grep-discoverable
  - Test 19: **dual-assertion fidelity check** — `--info` returns
    `.version` AND lacks `.command` (catches regressions where bypass
    is lifted and scaffold accidentally takes over the flag)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations). PARTIAL-BYPASS verified — both native and
scaffold surfaces fire on their respective inputs.

## Notable

- Three wzjo9.1.7 variants now documented:
  - **NO-BYPASS** (5ke66.2 append-safe-write): scaffold owns all canonical
  - **PARTIAL-BYPASS** (this surface): scaffold owns verbs, native owns flags
  - **BYPASS-ALL** (5ke66.4 bleed-ledger-watch + wzjo9.1.7 flywheel-loop):
    native owns everything; scaffold is unreachable defensive fallback
- Test 19 dual-assertion (native field present + scaffold field absent) is
  the canonical fidelity check for PARTIAL-BYPASS. Without it, a regression
  could lift the bypass silently and all other tests would still pass
  (because scaffold envelopes also have `.version`).
- Initial smoke runs caught the schema collision: `--schema doctor` (intended
  to query scaffold per-surface schema) instead routed to native PASSTHRU
  which rejected `doctor` as an unknown positional. Resolved by removing
  those smoke calls and routing per-surface schema info through `help <topic>`
  instead (which goes through scaffold). The native --schema (full
  JSON-Schema for result envelope) is the more important consumer surface.

## Files touched

- `.flywheel/scripts/daily-report.sh` (58 → 304 lines)
- `tests/daily-report-canonical-cli.sh` (94 → 156 lines)
- `.flywheel/audit/flywheel-5ke66.6/{evidence,journey,compliance,15 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-5ke66.6.md`

## Mission fitness

Class: **adjacent**. daily-report.sh is the daily flywheel report
generator with NTM rollup; canonical-CLI surface (mixed scaffold +
native) lets orchestrator probe report substrate and validate session
names + report paths.
