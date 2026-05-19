# Tier Refinement

Generated: 2026-05-19T06:39:24Z
Inventory source: `.flywheel/inventory/2026-05-19/inventory.jsonl`

## Summary

- Refined surface rows: 3791
- Invariant status: PASS
- Next action: PASS: hand the Top 20 T1 queue to Phase 3; do not start Phase 3 from this phase.

## Refined Tier Distribution

| Tier | Surfaces |
|---|---:|
| T1 fleet-critical | 2125 |
| T2 common | 498 |
| T3 internal | 1054 |
| T4 deprecated | 114 |

## Per-Repo Tier Breakdown

| Repo | T1 | T2 | T3 | T4 |
|---|---:|---:|---:|---:|
| agent-bench | 5 | 3 | 1 | 7 |
| alpsinsurance | 16 | 62 | 78 | 16 |
| clutterfreespaces | 76 | 43 | 218 | 1 |
| flywheel | 1593 | 16 | 90 | 3 |
| frankensqlite | 0 | 21 | 183 | 0 |
| mobile-eats | 16 | 13 | 33 | 9 |
| ntm | 0 | 23 | 2 | 17 |
| picoz | 13 | 146 | 45 | 25 |
| skillos | 259 | 58 | 52 | 8 |
| vrtx | 45 | 46 | 25 | 8 |
| zesttube | 102 | 67 | 327 | 20 |

## T1 to T2 Demotions

| Repo | Path | Class | Invoke count 30d | Reason |
|---|---|---|---:|---|
| agent-bench | `.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |
| alpsinsurance | `.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |
| alpsinsurance | `.flywheel/scripts/br-substrate-fingerprint.sh` | ledger-writer | 0 | has_fixture_coverage=true |
| clutterfreespaces | `.flywheel/callbacks/cfs-k6ey.5/probe.sh` | doctor | 1 | invoke_count_30d=1..9 |
| clutterfreespaces | `.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |
| flywheel | `.flywheel/audit/flywheel-wzjo9.2.4/recovery-install-plist-alpsinsurance.before` | CLI | 0 | class=CLI |
| flywheel | `templates/flywheel-install/tests/test_polish_gate_discovery.sh` | test | 7 | invoke_count_30d=1..9; has_fixture_coverage=true |
| flywheel | `templates/flywheel-install/tests/test_polish_gate_reconcile.sh` | test | 7 | invoke_count_30d=1..9; has_fixture_coverage=true |
| flywheel | `templates/flywheel-install/tests/test_polish_gate_schema_inventory_parity.sh` | test | 7 | invoke_count_30d=1..9; has_fixture_coverage=true |
| frankensqlite | `scripts/bd_1rw_2_morsel_dispatch_e2e.sh` | CLI | 0 | class=CLI |
| mobile-eats | `.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |
| picoz | `.claude/skills/beads-bv/scripts/bv_triage_analyzer.py` | CLI | 0 | class=CLI |
| picoz | `.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |
| picoz | `scripts/bead_db_repair.sh` | ledger-writer | 0 | has_fixture_coverage=true |
| picoz | `scripts/check_reliability_design_bead_parity.py` | validator | 0 | has_fixture_coverage=true |
| picoz | `scripts/dispatch_with_verify.sh` | ledger-writer | 0 | has_fixture_coverage=true |
| picoz | `scripts/fix_beads_wedge_phase0.py` | ledger-writer | 0 | has_fixture_coverage=true |
| picoz | `scripts/hooks/bead-grade-pre.sh` | hook | 0 | has_fixture_coverage=true |
| picoz | `scripts/hooks/post-commit-bead-close.sh` | hook | 0 | has_fixture_coverage=true |
| picoz | `scripts/hooks/pre-dispatch-stop-check.sh` | hook | 0 | has_fixture_coverage=true |
| picoz | `scripts/hooks/verify_bead_premise_shim.py` | hook | 0 | has_fixture_coverage=true |
| picoz | `scripts/ntm_send_gated.sh` | validator | 0 | has_fixture_coverage=true |
| skillos | `.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |
| vrtx | `.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |
| zesttube | `.claude/worktrees/agent-a1e3a371495bbd709/.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |
| zesttube | `.claude/worktrees/agent-a2faa32727620358b/.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |
| zesttube | `.claude/worktrees/agent-a4c3096bfa875b98b/.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |
| zesttube | `.claude/worktrees/agent-af8f1f2b5229a95eb/.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |
| zesttube | `.flywheel/scripts/bead-quality-mining.sh` | CLI | 0 | class=CLI |

## T2 to T1 Promotions

| Repo | Path | Class | Invoke count 30d | Reason |
|---|---|---|---:|---|
| alpsinsurance | `install/smoke.sh` | validator | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| alpsinsurance | `scripts/secrets/pre-deploy-gate.sh` | validator | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-31kb/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-77tp/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-7bas/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-bai0/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-commercial-go-gates-ydb2.4/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-commercial-go-gates-ydb2.5/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-growth-39y6.2/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-growth-39y6.7/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-ia-journey-8vg7.1/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-ia-journey-8vg7.4/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-legal-substrate-huxq.1/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-legal-substrate-huxq.15/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-legal-substrate-huxq.16/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-legal-substrate-huxq.2/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-legal-substrate-huxq.3/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-legal-substrate-huxq.7/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-legal-substrate-huxq.8/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-legal-substrate-huxq.9/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-product-library-llts.1/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-product-library-llts.3/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-product-library-llts.4/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-product-library-llts.6/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-product-research-alpj.4/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-risk-coverage-07at.10/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-risk-coverage-07at.13/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-risk-coverage-07at.16/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-risk-coverage-07at.3/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-risk-coverage-07at.6/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-tax-accounting-5g3o.8/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-epic-visual-spec-wwo8.5/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-finding-account-deletion-loev/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-cfs-app-meta-surfaced-sweep-as6x/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-knn6/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-ktu2/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-n0hr/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-019-zxmd/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-023-gqfc/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-030-ubrq/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-033-x2ck/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-071-7tfs/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-075-1jw1/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-080-ochp/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-091-snho/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-096-4r2l/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-100-scou/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-107-0wtf/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-110-z7vn/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-114-uas3/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-130-ihlw/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-137-rl3w/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-140-z89n/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-144-d8vn/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-147-w3vh/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-155-4ijs/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-158-wrzf/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-162-h1cl/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-168-1isq/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-171-ayg5/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-tenant-scope-api-175-pb9h/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| clutterfreespaces | `.flywheel/audits/cfs-wl-tenant-resend-zkm1/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-13u0.1/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-13u0.2/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-13u0.4/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-1ebor/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-1jg/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-215/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-2xdi.11/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-2xdi.13/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-2xdi.14/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-2xdi.15/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-2xdi.2/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-2xdi.3/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-2xdi.5/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-2xdi.7/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-2xdi.8/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-2xdi.9/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-2xmq.3/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-3bb/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-3o76p/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-6f6/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-7wri/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-8lm8/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-9l31/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-aduvv/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-ae8aq/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-b1y/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-dwmb/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-gb54d.2/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-hoj82/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-i18f/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-id41/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-jg1j/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-jloib.1.pilot/scaffolded-build-dispatch-packet-test.sh.snapshot` | other | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/audit/flywheel-jloib.1.pilot/scaffolded-dispatch-and-log-test.sh.snapshot` | other | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/audit/flywheel-l95he/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-lzw7.4/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-me08/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-r58g/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-se7p/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-syfq/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-x18/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/audit/flywheel-z6lk3/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/fixtures/validate-fleet-coherence-fixtures.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/receipts/flywheel-03uki/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-13u0.3/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-13u0.5/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-2xdi.1/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-2xdi.10/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-2xdi.4/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-2xdi.6/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-bozy/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-cmov/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-dwavb/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-fg2v5/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-gcaf/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-hv071/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-ljrjw/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-lqsy/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-mdry/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-r52ig/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-v1q2/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/receipts/flywheel-wd48/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/scripts/audit-skill-handoff-coverage.sh` | validator | 1 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/canonical-cli-drift-detector.sh` | other | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/canonical-doctrine-sync.sh` | other | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/capacity-halt-success-measurement.sh` | CLI | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/close-validator-contract-probe.sh` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/codex-skill-scan-budget.py` | CLI | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/command-help-parity-audit.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/dicklesworthstone-signal-gate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/doctrine-3-surface-divergence-probe.sh` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/doctrine-drift-trend-probe.sh` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/emit-polish-round-telemetry.py` | CLI | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/evidence-pack-resolve.sh` | CLI | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/failure-class-emit.sh` | CLI | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/fleet-coherence-write.sh` | CLI | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/fleet-l-rule-lag-probe.sh` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/fleet-tenant-registry-preflight.py` | CLI | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/fleet-watcher-coverage-probe.sh` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-anthropic-adoption-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-anti-pitch-voice-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-brand-naming-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-brand-voice-skill-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-candidate-fit-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-coach-role-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-founder-post-voice-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-launch-economics-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-legal-structure-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-lifecycle-disposition-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-mobile-eats-shipping-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-nonprofit-extension-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-objective-coverage-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-operating-health-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-owner-economics-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-owner-search-phasing-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-owner-voice-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-peel-interviews-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-peer-coach-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-pour-readiness-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-press-readiness-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-progress-velocity-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-public-story-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-public-surface-audit-supersession-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-recent-progress-claim-honesty-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-recycle-loop-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-runway-receipt-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-shared-stack-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-skillos-forever-os-lock-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/holding-company-sustainable-pace-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/identity-stability-tuple-validator.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/idle-pane-mechanical-gate.sh` | validator | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/scripts/inbox-check-tick-step.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/incidents-evidence-link-validator.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/inject-forward-link-recipe.sh` | other | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/inject-operator-library-recipe.sh` | other | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/jeff-fixes-pull-probe.sh` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/jeff-issue-rubric.py` | CLI | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/jeff-issues-status-probe.sh` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/l168-registry-patch-plan.py` | CLI | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/leverage-evidence-gate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/loop-goal-contract-gate.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/memory-rule-gate-parity-detector.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/scripts/mission-lock-age-probe.sh` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/mission-lock-output-schema-validator.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/mobile-eats-path-a-validator.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/orch-handshakes-never-gate-on-joshua-gate.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/orch-p0-completion-gate.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/orphaned-mcp-tool-call-probe.py` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/portfolio-company-registry-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/probe-registry-audit.sh` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/repo-discipline-check.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/scripts/repo-hygiene-check.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `.flywheel/scripts/safe-probe.sh` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/stash-discipline-check.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/substrate-share-receipt-validate.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/sync-four-lens-validator.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/three-q-surface-audit.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/tmp-aggressive-prune.sh` | CLI | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/topology-gap-probe.sh` | doctor | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/track-classifier.sh` | ledger-writer | 1 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/two-truth-sources-validator.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/scripts/validate-jsm-sandbox-auth-marker.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/skillos-requests/doctor-repair-triad/scripts/self_test.sh` | other | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test-codex-death-event-classifier.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test-dcg-prose-trigger-strip.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test-frozen-pane-detector-fleet-introspection.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test-gap-hunt-probe-canonical-cli-test-corpus.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test-three-judges-publishability-validator.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test-tmp-aggressive-prune-introspection.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test-validate-callback-info-flag.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test_codex_template_stuck_detector.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test_ntm_policy_contracts.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test_ntm_preflight_l91_wrapper.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test_ntm_safety_dcg_sibling.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `.flywheel/tests/test_ntm_scrub_secret_scan_wrapper.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `scripts/check_links.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `scripts/contact_route_probe.py` | doctor | 0 | canonical_cli_present=true |
| flywheel | `scripts/isolated-agent-lane-smoke.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `scripts/journey-smoke.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `scripts/local-actions-preflight.sh` | CLI | 0 | canonical_cli_present=true |
| flywheel | `scripts/probe_repo_story_portability.py` | doctor | 0 | canonical_cli_present=true |
| flywheel | `scripts/repo-hygiene-check.sh` | validator | 1 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `scripts/validate-depersonalization-table.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `scripts/validate_cutover_receipts.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `scripts/validate_external_review.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `scripts/validate_installed_binary_source.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `scripts/validate_story_system_package.py` | validator | 0 | canonical_cli_present=true |
| flywheel | `scripts/website_accessibility.py` | CLI | 0 | canonical_cli_present=true |
| flywheel | `scripts/zs-frontend-quality-gate.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `templates/flywheel-install/.flywheel/scripts/idle-pane-mechanical-gate.sh` | validator | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `templates/flywheel-install/scripts/repo-discipline-check.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `templates/flywheel-install/scripts/repo-hygiene-check.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| flywheel | `templates/flywheel-install/scripts/stash-discipline-check.sh` | validator | 0 | canonical_cli_present=true |
| flywheel | `tests/abs-target-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/adversarial-orch-self-audit-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-14423-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-1725-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-20800-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-21313-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-28756-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-32174-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-32693-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-45987-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-56679-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-5780-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-58117-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-73998-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-83848-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ag2-fixture-90723-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/agent-lane-probe.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/agent-mail-fd-doctor.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/agent-mail-pre-allocate-worker-identities-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/agent-mail-restart-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/agent-mail-restart.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/agent-mail-send-redacted-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/agentmail-identity-canonical-validator-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/agents-md-fleet-propagator-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/agents-md-fleet-propagator.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/agents-md-shard-extract-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/append-safe-write-canonical-cli.sh` | test | 2 | canonical_cli_present=true |
| flywheel | `tests/apply-substrate-tuning-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/apply-tmux-tuning-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/audit-skill-handoff-coverage.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/auto-l112-gate-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/auto-l112-gate-test.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/auto-refill-decision-log-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/auto-respawn-detector-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-14423-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-1725-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-20800-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-21313-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-28756-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-32174-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-32693-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-45987-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-56679-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-5780-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-58117-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-73998-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-83848-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-a-90723-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-14423-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-1725-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-20800-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-21313-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-28756-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-32174-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-32693-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-45987-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-56679-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-5780-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-58117-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-73998-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-83848-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bak-b-90723-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bash_abs-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bash_env-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bcv-task-harness-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bcv-task-harness.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bead-evidence-indexer-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/beads-db-recover-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/beads-db-recover.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bleed-ledger-watch-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/bleed-ledger-watch.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/blocker-ac-tick-cadence-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/br-authority-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/br-close-with-gate-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/br-db-corruption-monitor-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/build-dispatch-packet-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/caam-auto-rotate-on-usage-limit-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/caam-auto-rotate-on-usage-limit.py-canonical-cli-py.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/caam-rotate-and-respawn-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/callback-envelope-schema-validator-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/callback-fix-bead-opener-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/callback-receipt-validator-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/callback-receipt-validator-wrapper-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/callback-spool-reap-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/callback-spool-reap.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/canonical-cli-helpers-smoke.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/canonical-cli-lint-l10.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/canonical-cli-lint-l9.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/canonical-cli-lint-precommit.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/canonical-cli-lint.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/canonical-cli-scoping-flywheel-loop.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/canonical-root-drift-fleet-check-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/canonical-root-drift-fleet-check.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/capacity-halt-auto-continue-primitive-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/capacity-halt-lease-primitive-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/capacity-halt-pane-authorization-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/check-trauma-class-substrate-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/check-trauma-class-substrate-test.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/cleanup-scratch-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/cleanup-scratch.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/clobber-recovery-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/codex-budget-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/codex-budget-watchdog-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/codex-death-event-classifier-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/codex-pane-path-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/codex-queued-not-submitted-bare-enter-primitive-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/codex-template-stuck-detector-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/collision-fixture-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/concurrent-a-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/concurrent-b-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/continuous-productivity-detector-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/continuous-productivity-detector-install-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/cost-telemetry-token-burn-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/cross-pane-git-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/cross-repo-fmh-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/cross-repo-trauma-aggregator-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/cross-repo-trauma-aggregator.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/cross-session-worker-borrow-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/cross-skill-dependency-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/cross-time-synthesis-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/customer-facing-observability-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/daily-report-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/daily-report-enabled-repos-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/daily-report.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/disk-reclaim-batch-2026-05-07-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/dispatch-and-log-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/dispatch-author-contract-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/dispatch-canonical-cli-validator-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/dispatch-deferral-lint-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/dispatch-delivery-verify-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/dispatch-log-backfill-v2-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/dispatch-log-v2-violations-doctor-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/dispatch-mode-metrics.sh` | test | 1 | canonical_cli_present=true |
| flywheel | `tests/dispatch-self-test-delivery-identity-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/dispatch-surface-conflict-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/dispatch-trigger-gated-precheck-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/docs-validation-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/docs-validation-probe.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/doctor-security-posture.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/doctrine-broadcast-send-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/doctrine-ladder-promote-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/doctrine-sync-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/empty-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/escalate-capsule-plan-consumer-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/false-close-audit.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/file-length-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fixtures/canonical-cli-lint-l9/clean.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fixtures/canonical-cli-lint-l9/dirty.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-canonical-rule-freshness-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-coherence-alert-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-coherence-alert.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-coherence-classifiers.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-coherence-launchd-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-coherence-lib-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-comms-health-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-comms-health-probe.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-conformance-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-conformance-probe.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-mail-auth-probe.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-process-gap-detector-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-process-gap-detector.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-refill-signal.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-rotate-all-sessions-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-rotate-on-caam-swap-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fleet-rotate-on-caam-swap.py-canonical-cli-py.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-adopt-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-agents-pointer-sweep-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-anchor-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-autoloop-canonical-cli-scaffold.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-autoloop-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-cass-correlate-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-check-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-codex-orient-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-codex-snapshot-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-codex-stuck-detector-install-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-conductor-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-dashboard-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-digest-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-docs-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-doctrine-sync-canonical-cli-scaffold.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-doctrine-sync-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-domain-spec-validate-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-friday-digest-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-inject-latest-line-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-install-hooks-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-lock-repair-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-loop-tick-canonical-cli-test.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-outcome-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-pattern-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-quality-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-quality-gate-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-readme-canonical-cli-py.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-recovery-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-render-latest-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-skillos-relay-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-source-monitor-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-stale-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-summarize-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-sync-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-toolset-parity.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-trauma-check-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-verdict-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/flywheel-watchers-test.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/foo-bash-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/frozen-pane-backtest-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/frozen-pane-detector-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/frozen-pane-detector-fleet-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fs-rag-sibling-rollout-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fuckup-coverage-join-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/fuckup-coverage-join.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/gap-hunt-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/gap-hunt-probe-dedup-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/gap-hunt-probe-tests-tree-exclusion-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/goal-build-canonical-cli.sh` | test | 1 | canonical_cli_present=true |
| flywheel | `tests/halt-disease-watchdog-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/halt-disease/regress-2026-05-04.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/handoff-skill-to-skillos-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/headless-browser-reap-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/hub-blocker-detect-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/hub-blocker-detect.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/idempotency-replay-guard-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/idle-pane-auto-dispatch-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/idle-state-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/inject-doc-toc-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/inject-skill-auto-routes-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/inject-skill-auto-routes.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-bead-285-divergence-capture-introspection.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-binary-version-watchtower-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-clone-symlink-converter-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-corpus-compact-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-corpus-delta-reindex-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-daily-diff-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-intel-digest-actionable-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-intel-network-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-intel-scheduled-runner-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-issue-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-issue-response-poll-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-pattern-citation-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-pattern-citation-probe.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-philosophy-mine-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-shadow-socraticode-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-shadow-socraticode.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-verdict-heuristic-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeff-workaround-research-gate-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/jeffrey-comment-watchtower-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/josh-requests-reverse-lookup-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/loop-goal-contract-gate.sh` | test | 1 | canonical_cli_present=true |
| flywheel | `tests/low-bead-threshold-detector-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/mission-lock-negative-invariants-validator-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/mission-lock-readiness-doctor-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/mission-lock-scaffold-validator-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/mobile-eats-end-user-health-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/mobile-eats-loop-with-receipt-mirror-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/npm-install-guard-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ntm-approve-human-gates-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ntm-coordinator-shadow-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ntm-fleet-health-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ntm-pane-sidecar-respawn-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ntm-pipeline-shadow-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ntm-preflight-l91-wrapper-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ntm-safety-dcg-sibling-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ntm-scrub-secret-scan-wrapper-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ntm-surface-coverage-trend-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ntm-surface-validation-driver-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/ntm-wave2-native-probes-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/orch-worker-identity-manifest-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/orchestrator-callback-artifact-fix-bead-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/orchestrator-callback-artifact-validator-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/orphaned-mcp-tool-call-doctor.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/part-02-portable_doctor_parity_fixture.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/peer-orch-respawn-permit-canonical-cli-test.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/picoz-archive-and-fresh-2026-05-07-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/plan-state-lens-merge-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/plan-to-bead-auto-trigger-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/polish-preflight-quality-gate-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/pre-dispatch-state-db-lock-check-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/private-tmp-prune-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/promotion-candidate-stale-fire-reaper-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/public-artifact-pipeline-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/public-flywheel-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/recovery-baseline-snapshot-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/recovery-baseline-status-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/recovery-doctor-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/recovery-escape-then-reprompt-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/recovery-install-plist-alpsinsurance-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/recovery-install-plist-clutterfreespaces-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/recovery-install-plist-mobile-eats-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/recovery-install-plist-skillos-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/recovery-preinstall-audit-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/recovery-restore-harness-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/regenerate-dicklesworthstone-sources.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/rel-fixture-45987-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/rule-hint-lifecycle-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/rule-hint-lifecycle.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/scaffold-canonical-cli-apply-gate-regression.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/scaffold-canonical-cli-bugfix-bundle.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/scaffold-canonical-cli-e2e.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/scaffold-canonical-cli-flag-collision.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/scaffold-canonical-cli-shebang-guard.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/scaffold-canonical-cli-verb-collision-regression.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/session-start-hook-smoke.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/sh_posix-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/shared-surface-reservation-check-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/skill-autoresearch-tooling-preference-class.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/skill-bandit-measurement-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/skill-enhance-jsm-discipline-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/skill-enhance-jsm-discipline.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/skillos-handoff-dispatch-template.sh` | test | 1 | canonical_cli_present=true |
| flywheel | `tests/skillos-routed-tail-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/skillos-template-handshake-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/skills-best-practices-health.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/state-md-miner-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/state-md-miner.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/state-store-authority-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/storage-headroom-watcher-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/storage-pause-auto-resume-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/storage-pause-auto-resume.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/storage-pressure-doctor-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/storage-pressure-doctor.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/storage-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/storage-prune-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/substrate-discipline-primitives.sh` | test | 1 | canonical_cli_present=true |
| flywheel | `tests/sync-canonical-doctrine-introspection.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/team-pulse-heartbeat-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/team-pulse-heartbeat.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/team-roster-watch-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/tentacle-inventory-bump-atomic-fixture.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/tentacle-launchd-matrix.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/tentacle-source-presence-audit.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test-agent-mail-redact-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test-auto-respawn-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test-auto-respawn.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test-doctor-empty-errors-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test-fuckup-join-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test-inject-memory-hits-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test-loop-driver-doctor-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test-safe-probe-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test-skillos-bridge-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test-sync-canonical-doctrine-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test-sync-stamped-repos-coverage-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test_callback_mission_fitness_required.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test_cli_registry_emit.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test_dispatch_log_schema_v2.sh` | test | 1 | canonical_cli_present=true |
| flywheel | `tests/test_mission_fitness_doctor.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/test_mission_lock_status_dashboard.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/tick-skill-version-check-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/tmp-prune-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/topology-tick-refresh-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/track-classifier.sh` | test | 1 | canonical_cli_present=true |
| flywheel | `tests/trap-rollback-inventory.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/trauma-claim-emitter-canonical-cli.sh` | test | 1 | canonical_cli_present=true |
| flywheel | `tests/validate-callback-before-close-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/validate-callback-before-close.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/validate-dispatch-log-gate3.sh` | test | 1 | canonical_cli_present=true |
| flywheel | `tests/validate-skill-discovery-callback-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/verify-watcher-launchd-active-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/worker-auto-respawn-watchdog-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/worker-auto-respawn-watchdog-install-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/worker-deep-liveness-probe-classification.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/worker-head-verify-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| flywheel | `tests/worker-tick-jsm-outcomes-canonical-cli.sh` | test | 0 | canonical_cli_present=true |
| mobile-eats | `.flywheel/scripts/repo-discipline-check.sh` | validator | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| mobile-eats | `next-app/scripts/secrets/pre-deploy-gate.sh` | validator | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| mobile-eats | `scripts/trust_gate_check.sh` | validator | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| picoz | `.flywheel/audit/flywheel-lzw7.1/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| picoz | `.flywheel/audit/flywheel-lzw7.2/l112-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `.flywheel/scripts/file-length-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `.flywheel/scripts/idle-pane-mechanical-gate.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `.flywheel/scripts/idle-state-probe.sh` | doctor | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `.flywheel/scripts/memory-rule-gate-parity-detector.sh` | validator | 0 | doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `.flywheel/scripts/repo-discipline-check.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `.flywheel/scripts/repo-hygiene-check.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `packs/seven-surface-check-pack/scripts/seven_surface_check.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/agent_mail_token_echo_guard.py` | CLI | 0 | canonical_cli_present=true |
| skillos | `scripts/context_proof_gate.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/parity_contract_check.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_audit_rubric_calibration.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_author_with_temporary_shadow.sh` | CLI | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_blocker_probe.py` | doctor | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_br_close_audit_gate.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_compression_proof.py` | CLI | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_cross_repo_fingerprint.py` | CLI | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_forbid_phrase_lint.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_integration_audit.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_jsm_distill_coverage_audit.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_jsm_health_probe.py` | doctor | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_jsm_queue_drain.sh` | other | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_managed_receipt_same_commit_lint.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_pack_feedback.py` | CLI | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_ranker_core.py` | CLI | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_supabase_local_env_wrapper.sh` | CLI | 0 | canonical_cli_present=true |
| skillos | `scripts/skillos_weekly_seven_surface_check.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/test_precommit_canonical_cli_gate.sh` | test | 0 | canonical_cli_present=true |
| skillos | `scripts/validate_all.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/validate_capability_event.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/validate_capability_packet.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/validate_capability_transition.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/validate_context_upgrade_packet.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/validate_fleet_gate_rollout.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/validate_provenance.py` | validator | 0 | canonical_cli_present=true |
| skillos | `scripts/validate_shared_definitions.py` | validator | 0 | canonical_cli_present=true |
| skillos | `state/packs/api-contract-pack/scripts/fleet-validate.py` | validator | 0 | canonical_cli_present=true |
| skillos | `state/packs/api-contract-pack/scripts/smoke.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `state/packs/api-contract-pack/validate.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `state/packs/career-ops-ecosystem-pack/scripts/smoke.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `state/packs/career-ops-ecosystem-pack/validate.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `state/packs/lifecycle-proof-pack/members/commercial-ready-packet/scripts/smoke.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `state/packs/lifecycle-proof-pack/members/lifecycle-goal-status/scripts/smoke.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `state/packs/lifecycle-proof-pack/members/northstar-acceptance/scripts/smoke.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `state/packs/lifecycle-proof-pack/validate.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `state/packs/local-actions-preflight-pack/scripts/smoke.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `state/packs/local-actions-preflight-pack/validate.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `state/packs/openui-generative-ui-pack/scripts/smoke.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `state/packs/openui-generative-ui-pack/validate.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `state/packs/repo-hygiene-preflight-pack/scripts/repo-hygiene-adoption.py` | CLI | 0 | canonical_cli_present=true |
| skillos | `state/packs/repo-hygiene-preflight-pack/scripts/smoke.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `state/packs/repo-hygiene-preflight-pack/validate.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `state/packs/superlinked-sie-inference-pack/scripts/smoke.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `state/packs/superlinked-sie-inference-pack/validate.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `state/packs/user-journey-wireframe-pack/scripts/smoke.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `state/packs/user-journey-wireframe-pack/validate.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `state/packs/zeststream-story-system-pack/scripts/smoke.sh` | validator | 0 | canonical_cli_present=true; doctor_or_validator_cross_repo_consumer>=1 |
| skillos | `state/packs/zeststream-story-system-pack/validate.sh` | validator | 0 | canonical_cli_present=true |
| skillos | `tests/e2e/e2e_capability_response.sh` | test | 0 | canonical_cli_present=true |
| skillos | `tests/e2e/e2e_composition_graph.sh` | test | 0 | canonical_cli_present=true |
| skillos | `tests/e2e/e2e_cross_repo_session_inject.sh` | test | 0 | canonical_cli_present=true |
| skillos | `tests/e2e/e2e_three_lens_gate.sh` | test | 0 | canonical_cli_present=true |
| skillos | `tests/unit/test_skillos_pack_apply_telemetry.sh` | test | 0 | canonical_cli_present=true |
| skillos | `tests/unit/test_skillos_pack_feedback.sh` | test | 0 | canonical_cli_present=true |
| vrtx | `scripts/n8n-vrtx-parity-packet.py` | other | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a1e3a371495bbd709/scripts/check_channel_guardrail.sh` | validator | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a1e3a371495bbd709/scripts/check_guardrails.sh` | validator | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a1e3a371495bbd709/scripts/marty-gc-empty-drop-dirs.py` | CLI | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a1e3a371495bbd709/scripts/voicebox_speak_status.py` | CLI | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a1e3a371495bbd709/src/wfloop/wfloop` | CLI | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a2faa32727620358b/scripts/check_channel_guardrail.sh` | validator | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a2faa32727620358b/scripts/check_guardrails.sh` | validator | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a2faa32727620358b/scripts/voicebox_speak_status.py` | CLI | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a2faa32727620358b/src/wfloop/wfloop` | CLI | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a4c3096bfa875b98b/scripts/check_channel_guardrail.sh` | validator | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a4c3096bfa875b98b/scripts/check_guardrails.sh` | validator | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a4c3096bfa875b98b/scripts/voicebox_speak_status.py` | CLI | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-a4c3096bfa875b98b/src/wfloop/wfloop` | CLI | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-af8f1f2b5229a95eb/scripts/check_channel_guardrail.sh` | validator | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-af8f1f2b5229a95eb/scripts/check_guardrails.sh` | validator | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-af8f1f2b5229a95eb/scripts/marty-gc-empty-drop-dirs.py` | CLI | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-af8f1f2b5229a95eb/scripts/voicebox_speak_status.py` | CLI | 0 | canonical_cli_present=true |
| zesttube | `.claude/worktrees/agent-af8f1f2b5229a95eb/src/wfloop/wfloop` | CLI | 0 | canonical_cli_present=true |
| zesttube | `scripts/check_channel_guardrail.sh` | validator | 0 | canonical_cli_present=true |
| zesttube | `scripts/check_guardrails.sh` | validator | 0 | canonical_cli_present=true |
| zesttube | `scripts/marty-gc-empty-drop-dirs.py` | CLI | 0 | canonical_cli_present=true |
| zesttube | `scripts/voicebox_speak_status.py` | CLI | 0 | canonical_cli_present=true |
| zesttube | `src/wfloop/wfloop` | CLI | 0 | canonical_cli_present=true |

## Top 20 T1 Surfaces Queued For Phase 3 Ergonomics Audit

| Rank | Repo | Path | Class | Invoke count 30d | Reason |
|---:|---|---|---|---:|---|
| 1 | skillos | `.flywheel/run-30m-loop.sh` | ledger-writer | 174 | invoke_count_30d>=10; canonical_cli_present=true |
| 2 | flywheel | `tests/test_ntm_coordinator_wire.sh` | test | 128 | invoke_count_30d>=10; canonical_cli_present=true |
| 3 | flywheel | `tests/kill-recover-drill-apply-gate-test.sh` | test | 120 | invoke_count_30d>=10; canonical_cli_present=true |
| 4 | flywheel | `bin/flywheel` | CLI | 118 | invoke_count_30d>=10; canonical_cli_present=true |
| 5 | flywheel | `tests/test_install_contract_step10.sh` | test | 96 | invoke_count_30d>=10; canonical_cli_present=true |
| 6 | flywheel | `.flywheel/scripts/frozen-pane-detector.sh` | ledger-writer | 93 | invoke_count_30d>=10; canonical_cli_present=true |
| 7 | flywheel | `tests/bead-quality-mining.sh` | test | 93 | invoke_count_30d>=10; canonical_cli_present=true |
| 8 | flywheel | `tests/jeff-daily-diff.sh` | test | 92 | invoke_count_30d>=10; canonical_cli_present=true |
| 9 | flywheel | `.flywheel/scripts/stale-error-auto-ping.sh` | ledger-writer | 82 | invoke_count_30d>=10; canonical_cli_present=true |
| 10 | flywheel | `.flywheel/scripts/storage-probe.sh` | doctor | 68 | invoke_count_30d>=10; canonical_cli_present=true |
| 11 | flywheel | `.flywheel/scripts/recovery-escape-then-reprompt.sh` | ledger-writer | 64 | invoke_count_30d>=10; canonical_cli_present=true |
| 12 | flywheel | `.flywheel/tests/test_ntm_coordinator_shadow.sh` | test | 64 | invoke_count_30d>=10; canonical_cli_present=true |
| 13 | flywheel | `tests/handoff-skill-to-skillos.sh` | test | 62 | invoke_count_30d>=10; canonical_cli_present=true |
| 14 | flywheel | `.flywheel/scripts/ntm-wave2-native-probes.sh` | doctor | 56 | invoke_count_30d>=10; canonical_cli_present=true |
| 15 | flywheel | `.flywheel/scripts/peer-orch-blocker-watch.sh` | CLI | 56 | invoke_count_30d>=10; canonical_cli_present=true |
| 16 | flywheel | `tests/peer-orch-respawn-permit.sh` | test | 56 | invoke_count_30d>=10; canonical_cli_present=true |
| 17 | flywheel | `.flywheel/scripts/ntm-spawn-templates-versioned.py` | CLI | 48 | invoke_count_30d>=10; canonical_cli_present=true |
| 18 | flywheel | `.flywheel/scripts/peer-orch-respawn-permit.sh` | ledger-writer | 48 | invoke_count_30d>=10; canonical_cli_present=true |
| 19 | flywheel | `tests/agent-mail-identity-registry.sh` | test | 48 | invoke_count_30d>=10; canonical_cli_present=true |
| 20 | flywheel | `tests/fleet-coherence-launchd.sh` | test | 48 | invoke_count_30d>=10; canonical_cli_present=true |

