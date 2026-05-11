---
bead: flywheel-1hshd.16
title: codex-queued-not-submitted-bare-enter-primitive.sh canonical-CLI scaffold + 18-TODO fillin (NUANCED-PARTIAL-BYPASS, 2nd cross-source consistency)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-1hshd (jloib wave-4; sub-bead 16 of 37)
sister_exemplars: 5ke66.8 + 1hshd.11 (NUANCED siblings); 5ke66.11 (cross-source consistency 1st)
---

# Journey: flywheel-1hshd.16

## What Joshua asked for

Wave-4-general-16. Surface:
codex-queued-not-submitted-bare-enter-primitive.sh = bounded bare-Enter
recovery primitive for codex queued-not-submitted panes; coordinates
with capacity-halt lease/auth/budget/success sub-primitives; emits
9 stable exit codes.

## What I shipped

NUANCED-PARTIAL-BYPASS variant — 3rd application (5ke66.8, 1hshd.11,
this). Native owns `--info|--examples` (rich canonical envelopes);
NOT `--schema` or verbs.

Plus 2nd application of CROSS-SOURCE CONSISTENCY check — the 9 exit
codes from native --info `.exit_codes` keys MUST equal scaffold
validate `.valid_codes` (sorted-string equality). Pattern is now
formally mature at 2 occurrences (5ke66.11 conformance-axis +
1hshd.16 exit-code).

- 18 TODO markers replaced with substantive impl
- _scaffold_is_canonical_arg returns 1 for --info|--examples; returns 0
  for --schema (NOT bypassed) + verbs
- doctor: 9 named probes including capacity_halt trio
  (lease + auth + budget all load-bearing for recovery coordination)
- health: 7d stale threshold (on-demand recovery primitive)
- repair: 2 scopes (fallback_ledger_dir + audit_log_dir)
- validate: 4 subjects (session-name lowercase-prefix; pane-index
  [0,99]; exit-code enum {0,1,2,3,4,5,6,7,8} per script docstring;
  audit-row standard)
- audit: cli_emit_audit_tail; why: 4 keys
- Test 13 → 19 with calibration:
  - Tests 2/4: native shapes (info.v1 + examples.v1)
  - Test 3: scaffold --schema (NOT bypassed)
  - Tests 5-13: scaffold owns subcommands
  - Test 14: NUANCED-PARTIAL-BYPASS annotation grep-discoverable
  - Test 15: capacity_halt trio probe assertion
  - Test 16: exit-code full-enum sweep (9 values)
  - Test 19: 2nd cross-source consistency check (exit_codes drift)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations).

## Notable

- **2nd cross-source consistency** application formally matures the
  pattern. For surfaces where BOTH native + scaffold encode the same
  enum (axis labels in 5ke66.11, exit codes here), assert sorted
  equality between the two sources.
- **Three-way consistency**: validators reference docstring → tests
  cross-check against native --info → native --info matches docstring.
  Catches drift in any of the three.
- **Capacity-halt trio probe** captures the script's coordination
  dependencies. The script can't safely send a bare-Enter without
  lease (concurrency), auth (per-pane safety), and budget (rate-limit).
  Doctor surfaces all three executable status before any recovery run.

## Files touched

- `.flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh` (180 → 426 lines)
- `tests/codex-queued-not-submitted-bare-enter-primitive-canonical-cli.sh` (94 → 162 lines)
- `.flywheel/audit/flywheel-1hshd.16/{evidence,journey,compliance,17 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-1hshd.16.md`

## Mission fitness

Class: **adjacent**. codex-queued-not-submitted-bare-enter-primitive.sh
is the bounded recovery primitive for codex panes; canonical-CLI
surface lets orchestrator probe substrate + validate args before
invoking recovery.
