# System Surface Inventory

Generated: 2026-05-19T06:25:37Z

## Summary

- Total executable surfaces: 3791
- Flywheel executable surfaces: 1702
- Consumer repos covered: 10/10
- Invariant status: PASS
- Next action: PASS: queue Phase 2 tier distribution refinement, then Phase 3 top-T1 ergonomics audit.

## Per-Repo Breakdown

| Repo | Surfaces |
|---|---:|
| agent-bench | 16 |
| alpsinsurance | 172 |
| clutterfreespaces | 338 |
| flywheel | 1702 |
| frankensqlite | 204 |
| mobile-eats | 71 |
| ntm | 42 |
| picoz | 229 |
| skillos | 377 |
| vrtx | 124 |
| zesttube | 516 |

## Per-Class Breakdown

| Class | Surfaces |
|---|---:|
| CLI | 387 |
| doctor | 430 |
| hook | 85 |
| ledger-writer | 726 |
| other | 487 |
| test | 1215 |
| validator | 461 |

## Per-Tier Breakdown

| Tier | Surfaces |
|---|---:|
| T1 fleet-critical | 918 |
| T2 common | 1191 |
| T3 internal | 1504 |
| T4 deprecated | 178 |

## Top 20 T1 Surfaces Queued For Phase 3 Audit

| Rank | Repo | Path | Class | Invoke count 30d | Lines |
|---:|---|---|---|---:|---:|
| 1 | flywheel | `bin/flywheel` | CLI | 41902 | 492 |
| 2 | skillos | `bin/skillos` | other | 774 | 920 |
| 3 | skillos | `.flywheel/run-30m-loop.sh` | ledger-writer | 348 | 734 |
| 4 | flywheel | `tests/test_ntm_coordinator_wire.sh` | test | 256 | 131 |
| 5 | flywheel | `tests/kill-recover-drill-apply-gate-test.sh` | test | 240 | 187 |
| 6 | flywheel | `tests/jeff-daily-diff.sh` | test | 220 | 180 |
| 7 | flywheel | `.flywheel/scripts/frozen-pane-detector.sh` | ledger-writer | 199 | 1693 |
| 8 | flywheel | `tests/bead-quality-mining.sh` | test | 199 | 126 |
| 9 | flywheel | `.flywheel/scripts/stale-error-auto-ping.sh` | ledger-writer | 193 | 158 |
| 10 | flywheel | `tests/test_install_contract_step10.sh` | test | 192 | 69 |
| 11 | flywheel | `.flywheel/scripts/jeff-daily-diff.sh` | ledger-writer | 163 | 1006 |
| 12 | flywheel | `tests/peer-orch-respawn-permit.sh` | test | 160 | 120 |
| 13 | flywheel | `.flywheel/scripts/peer-orch-respawn-permit.sh` | ledger-writer | 152 | 303 |
| 14 | flywheel | `tests/stale-error-auto-ping.sh` | test | 140 | 89 |
| 15 | flywheel | `tests/handoff-skill-to-skillos.sh` | test | 139 | 105 |
| 16 | flywheel | `.flywheel/scripts/storage-probe.sh` | doctor | 136 | 783 |
| 17 | flywheel | `.flywheel/scripts/recovery-escape-then-reprompt.sh` | ledger-writer | 128 | 284 |
| 18 | flywheel | `.flywheel/tests/test_ntm_coordinator_shadow.sh` | test | 128 | 113 |
| 19 | flywheel | `.flywheel/scripts/bead-quality-mining.sh` | CLI | 119 | 488 |
| 20 | flywheel | `.flywheel/scripts/ntm-wave2-native-probes.sh` | doctor | 112 | 415 |

