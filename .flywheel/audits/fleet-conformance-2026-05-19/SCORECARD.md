# Fleet Conformance Scorecard — 2026-05-19

- Schema: `fleet-conformance-audit/v1`
- Inventory: `/Users/josh/Developer/flywheel/.flywheel/inventory/2026-05-19-rebuild/inventory-rebuild.jsonl`
- Surfaces audited: 2128
- Validators: 10
- skill_quality_bar_coverage_ratio: 0.609
- PASS/FAIL/SKIP: 6961/4469/9850
- Applicable checks: 11430

## Per MP

| MP | PASS | FAIL | SKIP | Applicable | Coverage |
|---|---:|---:|---:|---:|---:|
| MP-01 | 18 | 1506 | 604 | 1524 | 0.0118 |
| MP-02 | 1 | 2 | 2125 | 3 | 0.3333 |
| MP-03 | 696 | 1095 | 337 | 1791 | 0.3886 |
| MP-04 | 1229 | 149 | 750 | 1378 | 0.8919 |
| MP-15 | 608 | 1007 | 513 | 1615 | 0.3765 |
| MP-22 | 11 | 0 | 2117 | 11 | 1 |
| MP-26 | 3 | 0 | 2125 | 3 | 1 |
| MP-33 | 1299 | 333 | 496 | 1632 | 0.796 |
| MP-44 | 1709 | 94 | 325 | 1803 | 0.9479 |
| MP-66 | 1387 | 283 | 458 | 1670 | 0.8305 |

## Failing Samples

- MP-01 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — CLI-like surface lacks sentinel fallback evidence
- MP-03 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — agent-facing CLI lacks capabilities/robot-docs ergonomics marker
- MP-04 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — receipt/callback surface lacks schema_version
- MP-15 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — missing canonical CLI subcommands: health repair validate audit why
- MP-33 flywheel:`.flywheel/audit/flywheel-05ost/test-loop-driver-doctor.before` — durable artifact/schema surface lacks explicit schema envelope marker
- MP-03 flywheel:`.flywheel/audit/flywheel-13u0.1/l112-probe.sh` — agent-facing CLI lacks capabilities/robot-docs ergonomics marker
- MP-15 flywheel:`.flywheel/audit/flywheel-13u0.1/l112-probe.sh` — missing canonical CLI subcommands: doctor health repair validate why
- MP-03 flywheel:`.flywheel/audit/flywheel-13u0.2/l112-probe.sh` — agent-facing CLI lacks capabilities/robot-docs ergonomics marker
- MP-15 flywheel:`.flywheel/audit/flywheel-13u0.2/l112-probe.sh` — missing canonical CLI subcommands: doctor health repair validate audit why
- MP-03 flywheel:`.flywheel/audit/flywheel-13u0.4/l112-probe.sh` — agent-facing CLI lacks capabilities/robot-docs ergonomics marker
- MP-04 flywheel:`.flywheel/audit/flywheel-13u0.4/l112-probe.sh` — receipt/callback surface lacks schema_version
- MP-15 flywheel:`.flywheel/audit/flywheel-13u0.4/l112-probe.sh` — missing canonical CLI subcommands: doctor repair why
- MP-33 flywheel:`.flywheel/audit/flywheel-13u0.4/l112-probe.sh` — durable artifact/schema surface lacks explicit schema envelope marker
- MP-44 flywheel:`.flywheel/audit/flywheel-13u0.4/l112-probe.sh` — name/path-sensitive surface lacks resolution contract
- MP-03 flywheel:`.flywheel/audit/flywheel-1ebor/l112-probe.sh` — agent-facing CLI lacks capabilities/robot-docs ergonomics marker
- MP-15 flywheel:`.flywheel/audit/flywheel-1ebor/l112-probe.sh` — missing canonical CLI subcommands: doctor health repair validate audit why
- MP-33 flywheel:`.flywheel/audit/flywheel-1ebor/l112-probe.sh` — durable artifact/schema surface lacks explicit schema envelope marker
- MP-66 flywheel:`.flywheel/audit/flywheel-1ebor/l112-probe.sh` — subjective/generated output surface lacks sidecar conformance marker
- MP-01 flywheel:`.flywheel/audit/flywheel-1hshd.11/canonical-root-drift-fleet-check.before` — CLI-like surface lacks sentinel fallback evidence
- MP-15 flywheel:`.flywheel/audit/flywheel-1hshd.11/canonical-root-drift-fleet-check.before` — missing canonical CLI subcommands: health repair validate audit why
