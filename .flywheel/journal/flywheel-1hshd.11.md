---
bead: flywheel-1hshd.11
title: canonical-root-drift-fleet-check.sh canonical-CLI scaffold + 18-TODO fillin (NUANCED-PARTIAL-BYPASS, REPORT-ONLY repair scope)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-1hshd (jloib wave-4; sub-bead 11 of 37 — FIRST wave-4 surface shipped this session)
sister_exemplars: 5ke66.8 (985, same NUANCED variant from wave-2)
---

# Journey: flywheel-1hshd.11

## What Joshua asked for

Wave-4-general-11 — first wave-4 surface (different parent flywheel-1hshd
under "P0 partial × general lane split A — 37 surfaces"; lighter than
wave-2's "missing baseline" because some surfaces already have partial
canonical scaffold pre-scaffold).

Surface: canonical-root-drift-fleet-check.sh = per-fleet AGENTS.md
drift detector that calls sync-canonical-doctrine.sh per repo.

## What I shipped

NUANCED-PARTIAL-BYPASS variant (sister to 5ke66.8). Native owns
`--info / --examples`; native does NOT have `--schema` or verbs;
scaffold owns those.

Plus a NEW canonical pattern: **REPORT-ONLY repair scope** for the
`sync_helper_path` scope (cannot safely install/mutate because helper
lives elsewhere with its own install workflow).

- 18 TODO markers replaced with substantive impl
- _scaffold_is_canonical_arg returns 1 for --info|--examples; returns 0
  for --schema (NOT bypassed) + verbs
- doctor: 6 named probes (sync_helper_executable load-bearing for
  drift detection)
- health: 12h stale threshold (intra-day drift cadence)
- repair: 2 scopes (audit_log_dir standard + sync_helper_path REPORT-ONLY)
- validate: 3 subjects (root-path absolute-only matching 5ke66.{2,19}
  pattern; timeout-seconds [1,300] matching --timeout default 10;
  audit-row standard)
- audit: cli_emit_audit_tail; why: 4 keys (ts/root_path/repo/run_id)
- Test 13 → 19 with calibration:
  - Tests 2/3/4: native --info, scaffold --schema, native --examples
  - Test 15: dual-direction fidelity (--info native + --schema scaffold)
  - Tests 16-18: validate accept/reject pairs
  - Test 19: NEW REPORT-ONLY contract assertion
    (`.status==report` + `.existed` + `.executable`)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations).

## Notable

- First wave-4 surface confirms recipe transfer to partial-baseline
  scripts works mechanically. The only delta from wave-2 missing-baseline
  is that pre-scaffold native introspection needs per-flag baseline probe
  to determine the correct bypass list.
- REPORT-ONLY repair scope is the first canonical pattern beyond standard
  mkdir-based scopes. Useful for any scope where the target is owned by
  an external authority — install workflow, plist domain, etc. Better
  than faking a successful mkdir or refusing the scope outright.
- root-path absolute-only validator is the THIRD occurrence (after
  5ke66.2 target-path + 5ke66.19 repo-path). Three-occurrence pattern
  is now mature enough for formal META-RULE: "any path-arg validator
  should be absolute-only because dispatch packets run from
  unpredictable CWD".

## Files touched

- `.flywheel/scripts/canonical-root-drift-fleet-check.sh` (215 → 461 lines)
- `tests/canonical-root-drift-fleet-check-canonical-cli.sh` (94 → 162 lines)
- `.flywheel/audit/flywheel-1hshd.11/{evidence,journey,compliance,15 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-1hshd.11.md`

## Mission fitness

Class: **adjacent**. canonical-root-drift-fleet-check.sh is the
per-fleet AGENTS.md drift detector; canonical-CLI surface lets
orchestrator probe substrate + validate args + see REPORT-ONLY install
status of the sync helper before triggering drift checks.
