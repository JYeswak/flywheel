# Fleet Conformance Scorecard — 2026-05-19

- Schema: `fleet-conformance-audit/v1`
- Inventory: `/Users/josh/Developer/flywheel/.flywheel/inventory/2026-05-19-rebuild/inventory-rebuild.jsonl`
- Surfaces audited: 2128
- Validators: 30
- skill_quality_bar_coverage_ratio: 0.3641
- PASS/FAIL/SKIP: 7031/12280/44529
- Applicable checks: 19311
- v1 baseline 10-MP v1: 0.609
- v2 delta: -0.2449

## Per MP

| MP | PASS | FAIL | SKIP | Applicable | Coverage |
|---|---:|---:|---:|---:|---:|
| MP-01 | 18 | 1506 | 604 | 1524 | 0.0118 |
| MP-02 | 1 | 2 | 2125 | 3 | 0.3333 |
| MP-03 | 696 | 1095 | 337 | 1791 | 0.3886 |
| MP-04 | 1230 | 149 | 749 | 1379 | 0.892 |
| MP-15 | 608 | 1007 | 513 | 1615 | 0.3765 |
| MP-22 | 11 | 0 | 2117 | 11 | 1 |
| MP-26 | 3 | 0 | 2125 | 3 | 1 |
| MP-33 | 1300 | 332 | 496 | 1632 | 0.7966 |
| MP-44 | 1709 | 94 | 325 | 1803 | 0.9479 |
| MP-66 | 1387 | 283 | 458 | 1670 | 0.8305 |
| MP-80 | 0 | 252 | 1876 | 252 | 0 |
| MP-81 | 0 | 293 | 1835 | 293 | 0 |
| MP-82 | 0 | 520 | 1608 | 520 | 0 |
| MP-83 | 29 | 638 | 1461 | 667 | 0.0435 |
| MP-84 | 0 | 136 | 1992 | 136 | 0 |
| MP-85 | 25 | 581 | 1522 | 606 | 0.0413 |
| MP-86 | 0 | 81 | 2047 | 81 | 0 |
| MP-87 | 0 | 239 | 1889 | 239 | 0 |
| MP-88 | 14 | 609 | 1505 | 623 | 0.0225 |
| MP-89 | 0 | 662 | 1466 | 662 | 0 |
| MP-90 | 0 | 969 | 1159 | 969 | 0 |
| MP-91 | 0 | 898 | 1230 | 898 | 0 |
| MP-92 | 0 | 187 | 1941 | 187 | 0 |
| MP-93 | 0 | 172 | 1956 | 172 | 0 |
| MP-94 | 0 | 193 | 1935 | 193 | 0 |
| MP-95 | 0 | 240 | 1888 | 240 | 0 |
| MP-96 | 0 | 234 | 1894 | 234 | 0 |
| MP-97 | 0 | 480 | 1648 | 480 | 0 |
| MP-98 | 0 | 291 | 1837 | 291 | 0 |
| MP-99 | 0 | 137 | 1991 | 137 | 0 |

## Top-5 Lowest Coverage

| MP | PASS | FAIL | SKIP | Applicable | Coverage |
|---|---:|---:|---:|---:|---:|
| MP-80 | 0 | 252 | 1876 | 252 | 0 |
| MP-81 | 0 | 293 | 1835 | 293 | 0 |
| MP-82 | 0 | 520 | 1608 | 520 | 0 |
| MP-84 | 0 | 136 | 1992 | 136 | 0 |
| MP-86 | 0 | 81 | 2047 | 81 | 0 |

## Top-5 Highest Coverage

| MP | PASS | FAIL | SKIP | Applicable | Coverage |
|---|---:|---:|---:|---:|---:|
| MP-26 | 3 | 0 | 2125 | 3 | 1 |
| MP-22 | 11 | 0 | 2117 | 11 | 1 |
| MP-44 | 1709 | 94 | 325 | 1803 | 0.9479 |
| MP-04 | 1230 | 149 | 749 | 1379 | 0.892 |
| MP-66 | 1387 | 283 | 458 | 1670 | 0.8305 |

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
