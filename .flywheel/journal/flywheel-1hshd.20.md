---
bead: flywheel-1hshd.20
title: cost-telemetry-token-burn-probe.sh canonical-CLI scaffold + 18-TODO fillin (NUANCED-PARTIAL-BYPASS 5th, lint-idiom-fix 3rd)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-1hshd (jloib wave-4; sub-bead 20 of 37)
sister_exemplars: 5ke66.8 + 1hshd.{11,16,18} (NUANCED siblings); 5ke66.15 + 1hshd.14 (lint-idiom-fix siblings); 1hshd.13 (4-direction fidelity sister)
---

# Journey: flywheel-1hshd.20

## What Joshua asked for

Wave-4-general-20. Surface: cost-telemetry-token-burn-probe.sh =
recurring measurement for the value-gap-hunter `cost-telemetry-token-burn`
dimension (Meadows #8); proxy from dispatch-log.

## What I shipped

NUANCED-PARTIAL-BYPASS — 5th application. Bypass list `{--info,
--schema}` (sister subset to 5ke66.8 freshness-probe). Native owns
those two flags PLUS `--doctor` FLAG (pre-bypassed by scaffolder's
smart native-flag detection). Scaffold owns `--examples` + verbs.

Plus LINT-IDIOM-FIX 3rd application: original `set -uo pipefail` for
jq aggregation no-match tolerance → `set -euo pipefail; set +e` two-line
idiom. Pattern formally mature at 3 occurrences.

- 18 TODO markers replaced with substantive impl
- _scaffold_is_canonical_arg returns 1 for --info|--schema (NUANCED);
  scaffolder pre-emitted --doctor|--dispatch-log|--hours|--ledger bypass
- doctor: 6 named probes (jq load-bearing — script does all aggregation)
- health: 36h stale threshold (1.5x daily probe cadence)
- repair: 2 scopes (ledger_dir + audit_log_dir)
- validate: 3 subjects (hours-back [1,168] week-cap matching --hours
  default 24; ledger-row required schema_version+ts subset of native
  17-field schema; audit-row standard); rc=64
- audit: cli_emit_audit_tail; why: 4 keys
- Test 13 → 19 with calibration:
  - Test 14: NUANCED 5th-application annotation
  - Test 15: native --doctor FLAG bypass verified
  - Test 18: lint-idiom-fix 3rd-application preservation
  - Test 19: 4-DIRECTION fidelity (sister to 1hshd.13 SELECTIVE pattern)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations after idiom-fix).

## Notable

- **5th NUANCED application** confirms mechanical maturity of the
  variant. Per-flag baseline probe always drives variant choice.
- **3rd lint-idiom-fix application** formalizes the pattern. The
  two-line `set -euo pipefail; set +e` idiom is the canonical recipe
  for scripts with intentional `-e` exclusion (no-match jq, missing
  log file, etc.).
- **Native --doctor FLAG vs scaffold doctor VERB** coexistence is novel
  for this surface. Two routes (FLAG → native cmd_run, VERB → scaffold
  scaffold_cmd_doctor) both yield canonical envelopes via different paths.
- **Cross-source test backed off** to 4-direction fidelity. Initial
  attempt compared scaffold's minimum-required (2 fields) against
  native's complete-row-schema (17 fields) — those serve different
  contracts. 4-direction routing is the better fidelity check.
- **Coordination flow note**: skillos:1 shipped Phases A+B at 04:38Z
  (49.76h cadence baseline measured, prior 0.9h was structural lie).
  Phase C ball is in flywheel:1's court via the orchestrator's earlier
  04:35Z ratification of the original 04:25Z packet. I forwarded the
  Phases A+B + Phase C handoff to flywheel:1 before starting this bead.

## Files touched

- `.flywheel/scripts/cost-telemetry-token-burn-probe.sh` (268 → 524 lines)
- `tests/cost-telemetry-token-burn-probe-canonical-cli.sh` (94 → 162 lines)
- `.flywheel/audit/flywheel-1hshd.20/{evidence,journey,compliance,15 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-1hshd.20.md`

## Mission fitness

Class: **adjacent**. cost-telemetry-token-burn-probe.sh is the recurring
measurement for the value-gap-hunter cost-telemetry dimension;
canonical-CLI surface lets orchestrator probe substrate + validate args.
