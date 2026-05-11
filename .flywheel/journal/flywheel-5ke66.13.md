---
bead: flywheel-5ke66.13
title: mobile-eats-loop-with-receipt-mirror.sh canonical-CLI scaffold + 18-TODO fillin (NO-BYPASS, 3-scope repair)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-5ke66 (jloib wave-2; sub-bead 13 of 21)
sister_exemplars: 5ke66.2 (985, same NO-BYPASS variant, 2-scope repair)
---

# Journey: flywheel-5ke66.13

## What Joshua asked for

Wave-2-general-13 (13th 5ke66 sub-bead). Surface:
mobile-eats-loop-with-receipt-mirror.sh = bash wrapper running the
mobile-eats product tick + mirroring its receipt into the flywheel-loop
state directory.

## What I shipped

NO-BYPASS variant — script has zero native canonical surfaces (per-flag
baseline probe pre-scaffold confirmed `--info / --schema / --examples /
doctor` all just trigger the default cmd_run loop with WARN noise).
Scaffold owns all canonical surfaces; cmd_run preserved on bare invocation.

- 18 TODO markers replaced with substantive impl
- doctor: 9 named probes (most-instrumented surface this session;
  product_tick + bridge + jsonl_append_lib are load-bearing trio)
- health: 2h stale threshold (frequent loop cadence)
- repair: 3 scopes (out_dir + log_dir + audit_log_dir) — first surface
  to use this pattern; codified as canonical "dual-state-+-event-log"
  for multi-dir state surfaces
- validate: 3 subjects (receipt-event enum {receipt_mirrored,
  receipt_mirror_failed} matching script emit; exit-code [0,255] POSIX
  range; audit-row standard)
- audit: cli_emit_audit_tail; why: 4 keys (ts/event/path/run_id)
- Test 13 → 19 with NEW 3-scope structural assertion (test 19) that
  asserts the EXACT scope-list sorted-string equality

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations). Recipe transferred cleanly from 5ke66.2 with
extension to 3-scope repair pattern.

## Notable

- **3-scope repair pattern** introduced this surface: surfaces managing
  separate production-state + event-log + audit-log directories need
  three distinct repair scopes (not two). Test 19 codifies this as a
  structural assertion (sorted scope-list equality) that catches both
  scope-add AND scope-remove regressions.
- Most-instrumented doctor of the session (9 probes). The product_tick +
  bridge + jsonl_append_lib trio captures the script's external-program
  dependencies; jsonl_append_lib_sourceable is intentionally warn-tier
  matching the script's own `append_jsonl_best_effort` semantic.
- receipt-event enum `{receipt_mirrored, receipt_mirror_failed}` is
  load-bearing because these are the LITERAL strings the script emits
  in its `event:` field — drift between the validator enum and the emit
  strings would silently break downstream consumers.

## Files touched

- `.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh` (56 → 302 lines)
- `tests/mobile-eats-loop-with-receipt-mirror-canonical-cli.sh` (94 → 158 lines)
- `.flywheel/audit/flywheel-5ke66.13/{evidence,journey,compliance,17 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-5ke66.13.md`

## Mission fitness

Class: **adjacent**. mobile-eats-loop-with-receipt-mirror.sh is the
mobile-eats integration loop wrapper; canonical-CLI surface lets
orchestrator probe substrate + validate event names + exit codes.
