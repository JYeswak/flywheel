---
bead: flywheel-vuc9c
title: test-fuckup-join.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P0
mission_fitness: adjacent
parent: flywheel-ok1sk (jloib wave-1; sub-bead 14 of 17 — first testing-lane)
sister_exemplars: d80zq (985), ugjvq (985), 64hud (985), x0k3j (985), vs78t (985), lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Journey: flywheel-vuc9c

## What Joshua asked for

Wave-1-testing-14 (14th ok1sk sub-bead; first surface from the testing
lane). Synthetic-fixture test that verifies fuckup-log + processed-ledger
JOIN logic excludes 3 aggregate-processed rows.

## What I shipped

- 18 TODO markers replaced with substantive impl
- doctor: 6 named probes including **jq_slurpfile_supported** which is
  load-bearing — the joined_count() filter literally requires the
  --slurpfile flag and without it the test logic is non-functional
- health: 7d stale threshold (test surface, weekly grace)
- repair: 2 scopes (scratch_dir for $TMPDIR fixture target, audit_log_dir)
- validate: 3 subjects (jsonl-path .jsonl-only matching fixture file
  naming, trauma-class lowercase-prefix matching the script's class-N
  fixture pattern, audit-row standard)
- audit: cli_emit_audit_tail; why: 3 keys (ts/test_name/run_id)
- Test 13 → 19 (calibrated 2 + 6 fillin including a load-bearing
  **backward-compat test 19** that verifies the original synthetic JOIN
  test still passes via cmd_run after scaffold)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations). Backward-compat run mode preserved.

## Notable

- This is the FIRST test-lane surface in the wave-1 series (sisters were
  jeff-corpus / loop-driver / etc). The recipe transferred cleanly with
  no scaffolder regressions.
- Test 19 is the load-bearing fidelity check: confirms that the
  canonical-cli scaffold does NOT break the original synthetic-fixture
  JOIN test the script exists to run. Without this test, all 19 could
  pass while silently breaking the script's primary purpose.
- jq_slurpfile_supported is a finer-grained probe than just
  "jq_available" — older jq builds or BusyBox jq may lack --slurpfile.
  Probing it explicitly catches the cryptic-failure case before it
  surfaces as confusing test errors.

## Files touched

- `.flywheel/scripts/test-fuckup-join.sh` (76 → 322 lines)
- `tests/test-fuckup-join-canonical-cli.sh` (94 → 154 lines)
- `.flywheel/audit/flywheel-vuc9c/{evidence,journey,compliance,15 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-vuc9c.md`

## Mission fitness

Class: **adjacent**. test-fuckup-join.sh is the fuckup-log substrate
JOIN verifier; canonical-CLI surface enables orchestrator-side substrate
probing + fixture-label validation.
