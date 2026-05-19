# Fleet Conformance Scorecard — 2026-05-19-v5-reachability-weighted

- Schema: `fleet-conformance-audit/v1`
- Inventory: `/Users/josh/Developer/flywheel/.flywheel/inventory/2026-05-19-rebuild/inventory-rebuild.jsonl`
- Surfaces audited: 2122
- Validators: 30
- skill_quality_bar_coverage_ratio: 0.3645
- PASS/FAIL/SKIP: 7021/12239/44400
- Applicable checks: 19260
- raw_coverage_ratio: 0.3645
- reachability_weighted_coverage_ratio: 0.3467
- dead-code PASS inflation delta: 0.0178
- Reachability split: reachable_pass=6677 dead_pass=344 reachable_fail=11346 dead_fail=893
- raw=0.3645 reachable_weighted=0.3467 delta=-0.0178 (4.88% inflation from dead-code PASS)
- v1 baseline 10-MP v1: 0.609
- v2 delta: -0.2445

## Per MP

| MP | PASS | FAIL | SKIP | Reachable PASS | Dead PASS | Applicable | Raw Coverage | Weighted Coverage |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| MP-01 | 18 | 1502 | 602 | 14 | 4 | 1520 | 0.0118 | 0.0092 |
| MP-02 | 1 | 2 | 2119 | 1 | 0 | 3 | 0.3333 | 0.3333 |
| MP-03 | 696 | 1090 | 336 | 643 | 53 | 1786 | 0.3897 | 0.36 |
| MP-04 | 1228 | 149 | 745 | 1183 | 45 | 1377 | 0.8918 | 0.8591 |
| MP-15 | 608 | 1002 | 512 | 603 | 5 | 1610 | 0.3776 | 0.3745 |
| MP-22 | 11 | 0 | 2111 | 11 | 0 | 11 | 1 | 1 |
| MP-26 | 3 | 0 | 2119 | 3 | 0 | 3 | 1 | 1 |
| MP-33 | 1298 | 330 | 494 | 1247 | 51 | 1628 | 0.7973 | 0.766 |
| MP-44 | 1707 | 92 | 323 | 1595 | 112 | 1799 | 0.9489 | 0.8866 |
| MP-66 | 1384 | 282 | 456 | 1316 | 68 | 1666 | 0.8307 | 0.7899 |
| MP-80 | 0 | 252 | 1870 | 0 | 0 | 252 | 0 | 0 |
| MP-81 | 0 | 292 | 1830 | 0 | 0 | 292 | 0 | 0 |
| MP-82 | 0 | 519 | 1603 | 0 | 0 | 519 | 0 | 0 |
| MP-83 | 28 | 637 | 1457 | 26 | 2 | 665 | 0.0421 | 0.0391 |
| MP-84 | 0 | 134 | 1988 | 0 | 0 | 134 | 0 | 0 |
| MP-85 | 25 | 580 | 1517 | 23 | 2 | 605 | 0.0413 | 0.038 |
| MP-86 | 0 | 81 | 2041 | 0 | 0 | 81 | 0 | 0 |
| MP-87 | 0 | 240 | 1882 | 0 | 0 | 240 | 0 | 0 |
| MP-88 | 14 | 607 | 1501 | 12 | 2 | 621 | 0.0225 | 0.0193 |
| MP-89 | 0 | 661 | 1461 | 0 | 0 | 661 | 0 | 0 |
| MP-90 | 0 | 959 | 1163 | 0 | 0 | 959 | 0 | 0 |
| MP-91 | 0 | 898 | 1224 | 0 | 0 | 898 | 0 | 0 |
| MP-92 | 0 | 187 | 1935 | 0 | 0 | 187 | 0 | 0 |
| MP-93 | 0 | 172 | 1950 | 0 | 0 | 172 | 0 | 0 |
| MP-94 | 0 | 193 | 1929 | 0 | 0 | 193 | 0 | 0 |
| MP-95 | 0 | 240 | 1882 | 0 | 0 | 240 | 0 | 0 |
| MP-96 | 0 | 232 | 1890 | 0 | 0 | 232 | 0 | 0 |
| MP-97 | 0 | 478 | 1644 | 0 | 0 | 478 | 0 | 0 |
| MP-98 | 0 | 291 | 1831 | 0 | 0 | 291 | 0 | 0 |
| MP-99 | 0 | 137 | 1985 | 0 | 0 | 137 | 0 | 0 |

## Top-5 Lowest Coverage

| MP | PASS | FAIL | SKIP | Reachable PASS | Dead PASS | Applicable | Raw Coverage | Weighted Coverage |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| MP-80 | 0 | 252 | 1870 | 0 | 0 | 252 | 0 | 0 |
| MP-81 | 0 | 292 | 1830 | 0 | 0 | 292 | 0 | 0 |
| MP-82 | 0 | 519 | 1603 | 0 | 0 | 519 | 0 | 0 |
| MP-84 | 0 | 134 | 1988 | 0 | 0 | 134 | 0 | 0 |
| MP-86 | 0 | 81 | 2041 | 0 | 0 | 81 | 0 | 0 |

## Top-5 Highest Coverage

| MP | PASS | FAIL | SKIP | Reachable PASS | Dead PASS | Applicable | Raw Coverage | Weighted Coverage |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| MP-26 | 3 | 0 | 2119 | 3 | 0 | 3 | 1 | 1 |
| MP-22 | 11 | 0 | 2111 | 11 | 0 | 11 | 1 | 1 |
| MP-44 | 1707 | 92 | 323 | 1595 | 112 | 1799 | 0.9489 | 0.8866 |
| MP-04 | 1228 | 149 | 745 | 1183 | 45 | 1377 | 0.8918 | 0.8591 |
| MP-66 | 1384 | 282 | 456 | 1316 | 68 | 1666 | 0.8307 | 0.7899 |

## Failing Samples

- MP-83 flywheel:`.flywheel/PLANS/ntm-local-upstream-reconcile-2026-05-02/launch-on-pane-0.sh` — session recovery surface lacks portable recovery ladder evidence
- MP-86 flywheel:`.flywheel/PLANS/ntm-local-upstream-reconcile-2026-05-02/launch-on-pane-0.sh` — upstream/bug-report surface lacks clean-room reproduction evidence
- MP-89 flywheel:`.flywheel/PLANS/ntm-local-upstream-reconcile-2026-05-02/launch-on-pane-0.sh` — multi-phase workflow lacks mode-scoped workspace evidence
- MP-91 flywheel:`.flywheel/PLANS/ntm-local-upstream-reconcile-2026-05-02/launch-on-pane-0.sh` — loop-like surface lacks progress-counter forced-motion evidence
- MP-01 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — CLI-like surface lacks sentinel fallback evidence
- MP-03 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — agent-facing CLI lacks capabilities/robot-docs ergonomics marker
- MP-04 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — receipt/callback surface lacks schema_version
- MP-15 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — missing canonical CLI subcommands: health repair validate audit why
- MP-33 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — durable artifact/schema surface lacks explicit schema envelope marker
- MP-82 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — hook-like surface lacks lifecycle guardrail chain evidence
- MP-83 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — session recovery surface lacks portable recovery ladder evidence
- MP-85 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — verdict surface lacks runtime truth/freshness evidence
- MP-90 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — skill-like surface lacks adjacent boundary router evidence
- MP-91 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — loop-like surface lacks progress-counter forced-motion evidence
- MP-03 flywheel:`.flywheel/audit/flywheel-13u0.1/l112-probe.sh` — agent-facing CLI lacks capabilities/robot-docs ergonomics marker
- MP-15 flywheel:`.flywheel/audit/flywheel-13u0.1/l112-probe.sh` — missing canonical CLI subcommands: doctor health repair validate why
- MP-03 flywheel:`.flywheel/audit/flywheel-13u0.2/l112-probe.sh` — agent-facing CLI lacks capabilities/robot-docs ergonomics marker
- MP-15 flywheel:`.flywheel/audit/flywheel-13u0.2/l112-probe.sh` — missing canonical CLI subcommands: doctor health repair validate audit why
- MP-97 flywheel:`.flywheel/audit/flywheel-13u0.2/l112-probe.sh` — retrieval surface lacks parity/provenance/drift evidence
- MP-03 flywheel:`.flywheel/audit/flywheel-13u0.4/l112-probe.sh` — agent-facing CLI lacks capabilities/robot-docs ergonomics marker
