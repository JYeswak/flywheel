---
bead: flywheel-5ke66.8
title: fleet-canonical-rule-freshness-probe.sh canonical-CLI scaffold + 18-TODO fillin (NUANCED-PARTIAL-BYPASS)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-5ke66 (jloib wave-2; sub-bead 8 of 21)
sister_exemplars: 5ke66.6 (985, full PARTIAL-BYPASS); 5ke66.4 (985, BYPASS-ALL); 5ke66.2 (985, NO-BYPASS)
---

# Journey: flywheel-5ke66.8

## What Joshua asked for

Wave-2-general-8 (8th 5ke66 sub-bead). Surface:
fleet-canonical-rule-freshness-probe.sh = per-session META-RULE-CACHE.md
staleness probe vs canonical INDEX.md.

## What I shipped

This is a **NUANCED-PARTIAL-BYPASS** case — the FOURTH wzjo9.1.7 variant
documented (in the same 4-bead wave-2 sequence). Native owns ONLY
`--info` (text purpose) and `--schema` (raw JSON-Schema for per-session
row format), but does NOT support `--examples` (errors with rc=64 on
unknown arg). So the bypass list is `{--info, --schema}` — letting
`--examples` fall through to native would silently break the canonical
contract.

- 18 TODO markers replaced with substantive impl
- `_scaffold_is_canonical_arg` returns 1 for `--info|--schema` only;
  returns 0 for `--examples` (scaffold owns it)
- doctor: 6 named probes including stat_available with detail field
  annotating BSD `-f %m` + GNU `-c %Y` mtime form fallback
- health: 12h stale threshold (intra-day cadence)
- repair: 2 scopes (canonical_index_dir, audit_log_dir)
- validate: 3 subjects (session-name lowercase-prefix; status-value
  enum-typed `{fresh,stale,missing}` matching native --schema enum;
  audit-row standard)
- audit: cli_emit_audit_tail; why: 4 keys (ts/session/cache_path/run_id)
- Test 13 → 19 with calibration to NUANCED contract:
  - Test 4: scaffold envelope (`--examples` is scaffold's, NOT bypassed)
  - Test 14: NUANCED annotation grep-discoverable
  - Test 15: **dual-direction fidelity check** — `--info` native AND
    `--examples` scaffold both verified in one assertion
  - Test 16: status-value full-enum sweep
  - Test 19: backward-compat default-run preserved

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations). All four route directions (native/scaffold ×
flag/verb) functional.

## Notable

- Four wzjo9.1.7 variants now documented: NO-BYPASS / PARTIAL-BYPASS /
  NUANCED-PARTIAL-BYPASS / BYPASS-ALL. Worth filing META-RULE in
  feedback memory: "wzjo9.1.7 variant-choice depends on which native
  arg form a script supports — probe each before scaffold to determine
  the bypass list":
  - No native canonical surface → NO-BYPASS
  - Native ALL of --info/--schema/--examples → PARTIAL-BYPASS
  - Native SOME of --info/--schema/--examples → NUANCED-PARTIAL-BYPASS
  - Native verb subcommands (doctor/health/...) → BYPASS-ALL
- Test 15 dual-direction check is the canonical fidelity pattern for
  NUANCED variants (catches both over-bypass and under-bypass regressions
  in one assertion).

## Bug-catch (META-RULE candidate)

Test 19 initially used `"$SCRIPT" --json | head -1 | jq` which failed
under `set -uo pipefail` because `head -1` closes the pipe early →
producer SIGPIPE → rc=141 → test fails. Test reproduced fine
interactively (rc=0) but consistently failed inside the test runner.
Fixed with file-capture pattern: `"$SCRIPT" --json >tmpfile; head -1
tmpfile | jq`.

META-RULE candidate: `set -uo pipefail` + `command | head -N | jq` is
unsafe when the command is a long-running producer (will return
SIGPIPE rc=141 from the consumer side under pipefail). Use file capture
when the producer outputs more than `head -N` lines.

## Files touched

- `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh` (111 → 357 lines)
- `tests/fleet-canonical-rule-freshness-probe-canonical-cli.sh` (94 → 162 lines)
- `.flywheel/audit/flywheel-5ke66.8/{evidence,journey,compliance,17 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-5ke66.8.md`

## Mission fitness

Class: **adjacent**. fleet-canonical-rule-freshness-probe.sh is the
cross-session META-RULE-CACHE staleness detector; canonical-CLI surface
lets orchestrator probe substrate + validate session names + status
enum values.
