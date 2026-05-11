---
bead: flywheel-5ke66.2
title: append-safe-write.sh canonical-CLI scaffold + 18-TODO fillin
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-5ke66 (jloib wave-2; sub-bead 2 of 21 — first wave-2 surface)
sister_exemplars: vuc9c (985), d80zq (985), ugjvq (985), 64hud (985), x0k3j (985), vs78t (985), lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Journey: flywheel-5ke66.2

## What Joshua asked for

Wave-2-general-2 (2nd 5ke66 sub-bead; FIRST wave-2 surface from the
general lane — wave-1 was domain-specific lanes like jeff-corpus,
testing, loop-driver). Surface: append-safe-write.sh = canonical
EOF-lease + tail-divergence-retry append primitive.

## What I shipped

- 18 TODO markers replaced with substantive impl
- doctor: 6 named probes with detail annotations on load-bearing ones
  (python3 cites lock/lease/append heredoc, mktemp cites stdin-payload
  capture)
- health: 7d stale threshold (on-demand primitive)
- repair: 2 scopes (scratch_dir for $TMPDIR, audit_log_dir)
- validate: 3 subjects (target-path absolute-only matching the script's
  resolve() behavior; lease-ms integer range [1,60000] matching --lease-ms
  arg defaults; audit-row standard)
- audit: cli_emit_audit_tail; why: 4 keys including
  **idempotency_key** which is the canonical key for this primitive
- Test 13 → 19 (calibrated 2 + 6 fillin including LOAD-BEARING
  backward-compat test 19 that pipes a payload, verifies status=ok JSON,
  AND verifies the payload actually landed in --target file)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations). Backward-compat run mode preserved (verified
end-to-end with a real append).

## Notable

- This is the FIRST wave-2 (general-lane) surface. Recipe transferred
  cleanly from wave-1 sisters (11 prior applications).
- target-path validator enforces absolute-only because the python heredoc
  does `.resolve(strict=False)` on relative paths, silently normalizing
  against CWD. Pre-validating absolute is a safety contract for dispatch-
  packet-driven callers where CWD is unpredictable.
- lease-ms validator uses bash arithmetic `(( arg >= 1 && arg <= 60000 ))`
  to enforce the `[1, 60000]` integer range; rejects both out-of-range
  AND non-integer under the same `out_of_range_or_not_integer` reason
- doctor probe detail field annotates the load-bearing dependencies
  inline (mktemp = stdin-payload, python3 = lock/lease/append) so an
  operator reading the doctor envelope understands WHY each probe matters

## Files touched

- `.flywheel/scripts/append-safe-write.sh` (200 → 446 lines)
- `tests/append-safe-write-canonical-cli.sh` (94 → 156 lines)
- `.flywheel/audit/flywheel-5ke66.2/{evidence,journey,compliance,17 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-5ke66.2.md`

## Mission fitness

Class: **adjacent**. append-safe-write.sh is the canonical EOF-lease +
tail-divergence-retry append primitive; canonical-CLI surface lets the
orchestrator validate target paths + lease values before invocation.
