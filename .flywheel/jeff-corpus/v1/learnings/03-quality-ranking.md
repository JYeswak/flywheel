# Jeff Corpus Quality-Signal Ranking - Phase 3
bead: flywheel-w3pr.1
generated_at: 2026-05-04T10:17:10Z
scope: all manifest repos scored from `.flywheel/jeff-corpus/v1/manifest.json` plus repo-local read-only signals

## Receipt
- Manifest path: `.flywheel/jeff-corpus/v1/manifest.json`
- Manifest baseline: `jeff-corpus-v3`
- Manifest generated_at: `2026-05-04T01:29:14Z`
- Manifest repo_count: 177
- Repos scored: 177
- Phase 1 input: `.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md`
- Phase 2 input: `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md`

## Scoring Contract
Each repo receives six 0-5 quality-signal scores. The weighted total is normalized to 0-100: test coverage proxy 24%, runnable test surface 18%, doc completeness 16%, schema discipline 16%, doctor presence 14%, idempotency markers 12%.

- `test coverage proxy`: test/spec file density, source/test ratio, and explicit fixture/conformance/test command markers.
- `doc completeness`: README, AGENTS/CLAUDE doctrine, docs directory, examples/tutorials, and changelog presence.
- `schema discipline`: schema/OpenAPI/proto/migration/contract/conformance files and schema-version terms.
- `doctor presence`: doctor/health/check/diagnostic/repair/recovery paths and content terms.
- `idempotency markers`: idempotent, dry-run, atomic, fail-closed, receipt, ledger, lock, retry, and replay markers.
- `runnable test surface`: obvious worker-runnable entrypoints such as `cargo test`, pytest/tox config, package test scripts, Makefile test target, shell tests, or CI workflows.

Caveat: this is a quality-signal ranking, not a semantic endorsement of correctness. It intentionally rewards machine-checkable surfaces because Phase 3 is looking for accretive validation patterns Joshua can reuse.

## Partial-Result State
- repos_scored: 177
- missing_local_path: 0
- missing_readme: 7
- no_test_files: 73
- no_runnable_test_surface: 74
- no_schema_markers: 73
- no_doctor_markers: 64
- incomplete_socraticode_coverage: 0
- low_index_coverage_proxy: 16

Repos with `incomplete_socraticode_coverage` are not excluded from judgment; they still appear in rankings with a caveat. Repos with `low_index_coverage_proxy` have fewer than 10 qdrant points and may be small or under-indexed; use local evidence before treating their bottom ranking as meaningful.

## Top 20
| rank | repo | score | tests | docs | schema | doctor | idempotency | runnable | qdrant | caveats | evidence |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| 1 | `frankentui` | 96.4 | 5 | 5 | 5 | 5 | 5 | 4 | 22333 | none | tests: crates/doctor_frankentui/TEST_MATRIX.md, crates/doctor_frankentui/tests/asupersync_validation.rs, crates/doctor_frankentui/tests/e2e_contract_gate.rs, crates/doctor_frankentui/tests/ir_invariant_tests.rs; schema: crates/doctor_frankentui/contracts/opentui_confidence_model_v1.json, crates/doctor_frankentui/contracts/opentui_evidence_manifest_v1.json, crates/doctor_frankentui/contracts/opentui_licensing_provenance_v1.json, crates/doctor_frankentui/contracts/opentui_semantic_equivalence_v1.json; doctor: .github/workflows/doctor_frankentui_extended.yml, crates/doctor_frankentui/Cargo.toml, crates/doctor_frankentui/TEST_MATRIX.md, crates/doctor_frankentui/VERIFICATION_REPORT.md; runnable: .github/workflows, Cargo.toml + tests, Makefile test target, tests/*.sh |
| 2 | `frankensqlite` | 93.2 | 5 | 4 | 5 | 5 | 5 | 4 | 24510 | none | tests: crates/fsqlite-btree/src/index_seek_bug_test.rs, crates/fsqlite-btree/src/interior_delete_test.rs, crates/fsqlite-btree/src/table_seek_bug_test.rs, crates/fsqlite-core/src/bench_test.rs; schema: conformance/.gitkeep, conformance/backlog_quality_gate_baseline.json, conformance/slt/smoke/basic.slt, crates/fsqlite-core/tests/conformance_oracle_ext.rs; doctor: crates/fsqlite-core/src/commit_repair.rs, crates/fsqlite-core/src/repair_engine.rs, crates/fsqlite-core/src/repair_symbols.rs, crates/fsqlite-e2e/src/fsqlite_recovery_demo.rs; runnable: .github/workflows, Cargo.toml + tests, package.json scripts.test, tests/*.sh |
| 3 | `asupersync` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 25317 | none | tests: asupersync-browser-core/tests/abi_exports.rs, asupersync-browser-core/tests/artifact_layout.rs, asupersync-macros/tests/compile_fail/conformance_missing_spec.rs, asupersync-macros/tests/compile_fail/conformance_missing_spec.stderr; schema: .beads/.migration-hint-ts, .claude/skills/asupersync-mega-skill/references/BROWNFIELD-MIGRATION.md, .claude/skills/asupersync-mega-skill/references/NETWORKING-PROTOCOL-STACK.md, .github/workflows/conformance.yml; doctor: .beads/repair-backups/20260215T213337Z/config.yaml, .beads/repair-backups/20260215T213337Z/daemon-error, .beads/repair-backups/20260215T213337Z/issues.jsonl, .beads/repair-backups/20260215T213337Z/metadata.json; runnable: .github/workflows, Cargo.toml + tests, Makefile test target |
| 4 | `asupersync_ansi_c` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 6956 | none | tests: docs/TEST_COMPLETENESS_MATRIX.md, docs/TEST_LOG_SCHEMA.md, schemas/test_log.schema.json, tests/TEST.md; schema: .schema-baseline-hash, docs/API_DOCUMENTATION_CONTRACT.md, docs/E2E_SCENARIO_PACKS_AND_REPORT_CONTRACT.md, docs/INVARIANT_SCHEMA.md; doctor: .beads/.br_recovery/20260314T004143Z/config.yaml, .beads/.br_recovery/20260314T004143Z/issues.jsonl, include/asx/app/doctor.h, include/asx/runtime/browser_diagnostic.h; runnable: .github/workflows, Makefile test target, tests/*.sh |
| 5 | `coding_agent_session_search` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 12258 | none | tests: scripts/e2e/e2e_logging_acceptance_test.sh, scripts/e2e_logging_acceptance_test.sh, scripts/tests/generate_evidence_bundle.sh, scripts/tests/run_all.sh; schema: .beads/migration_baseline/BASELINE_SUMMARY.md, .beads/migration_baseline/SUMMARY.md, .beads/migration_baseline/baseline_bench.log, .beads/migration_baseline/baseline_binary_size.txt; doctor: .github/workflows/acfs-checksums-dispatch.yml, docs/RECOVERY.md, docs/SECURITY_AUDIT_CHECKLIST.md, docs/planning/RECOVERY_RUNBOOK.md; runnable: .github/workflows, Cargo.toml + tests, tests/*.sh |
| 6 | `franken_networkx` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 16390 | none | tests: crates/fnx-algorithms/src/bin/test_msd.rs, crates/fnx-algorithms/src/bin_test.rs, crates/fnx-algorithms/src/test_dijkstra.rs, crates/fnx-conformance/tests/asupersync_adapter_state_machine_gate.rs; schema: artifacts/asupersync/schema/v1/asupersync_adapter_state_machine_schema_v1.json, artifacts/asupersync/schema/v1/asupersync_capability_matrix_schema_v1.json, artifacts/asupersync/schema/v1/asupersync_fault_injection_schema_v1.json, artifacts/asupersync/schema/v1/asupersync_performance_characterization_schema_v1.json; doctor: .beads/imports/reality_check_2026-04-08.md, REALITY_CHECK.md, REALITY_CHECK_BRIDGE_PLAN_2026-04-08.md, artifacts/asupersync/v1/asupersync_final_evidence_pack_v1.recovered.json; runnable: .github/workflows, Cargo.toml + tests, python test config |
| 7 | `franken_node` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 32657 | none | tests: artifacts/assurance/pcel_self_test.json, artifacts/asupersync/bd-1now.5.3/workspaces/trace-bd-1now-5-3-semantic-boundary-e2e/allowed_canonical_alignment_cancellation/scripts/lib/test_logger.py, artifacts/asupersync/bd-1now.5.3/workspaces/trace-bd-1now-5-3-semantic-boundary-e2e/allowed_local_model_region_tree/scripts/lib/test_logger.py, artifacts/asupersync/bd-1now.5.3/workspaces/trace-bd-1now-5-3-semantic-boundary-e2e/forbidden_duplicate_family_runtime_cancellation/scripts/lib/test_logger.py; schema: .github/workflows/change-summary-contract-gate.yml, .github/workflows/connector-conformance.yml, .github/workflows/migration-velocity-gate.yml, .github/workflows/no-contract-no-merge-gate.yml; doctor: artifacts/10.14/posterior_diagnostics_report.json, artifacts/10.14/repair_proof_samples.json, artifacts/10.15/darklantern_bd721z_checker_report.exit, artifacts/10.15/darklantern_bd721z_checker_report.json; runnable: .github/workflows, Cargo.toml + tests, tests/*.sh |
| 8 | `frankenlibc` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 30658 | none | tests: crates/frankenlibc-abi/tests/c11threads_abi_test.rs, crates/frankenlibc-abi/tests/conformance_diff_acct.rs, crates/frankenlibc-abi/tests/conformance_diff_adjtimex.rs, crates/frankenlibc-abi/tests/conformance_diff_aio.rs; schema: crates/frankenlibc-abi/tests/conformance_diff_acct.rs, crates/frankenlibc-abi/tests/conformance_diff_adjtimex.rs, crates/frankenlibc-abi/tests/conformance_diff_aio.rs, crates/frankenlibc-abi/tests/conformance_diff_aligned_alloc.rs; doctor: crates/frankenlibc-core/src/stdlib/fmtcheck.rs, crates/frankenlibc-harness/tests/hardened_repair_deny_matrix_test.rs, crates/frankenlibc-membrane/src/check_oracle.rs, crates/frankenlibc-membrane/src/runtime_math/pomdp_repair.rs; runnable: .github/workflows, Cargo.toml + tests, tests/*.sh |
| 9 | `frankensearch` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 7618 | none | tests: crates/frankensearch-core/tests/golden/adapter_conformance_report_v1.golden.json, crates/frankensearch-core/tests/golden/adapter_conformance_violations_embedding_invalid_v1.golden.json, crates/frankensearch-core/tests/golden/adapter_conformance_violations_filter_fidelity_v1.golden.json, crates/frankensearch-core/tests/golden/adapter_conformance_violations_index_invalid_v1.golden.json; schema: crates/frankensearch-core/src/contract_sanity.rs, crates/frankensearch-core/tests/golden/adapter_conformance_report_v1.golden.json, crates/frankensearch-core/tests/golden/adapter_conformance_violations_embedding_invalid_v1.golden.json, crates/frankensearch-core/tests/golden/adapter_conformance_violations_filter_fidelity_v1.golden.json; doctor: crates/frankensearch-core/src/repair.rs, crates/frankensearch-durability/src/repair_trailer.rs, crates/frankensearch-fsfs/tests/golden/e2e_event_oracle_check_roundtrip_v1.golden.json, crates/frankensearch-fsfs/tests/golden/fsfs_determinism_check_result_roundtrip_v1.golden.json; runnable: .github/workflows, Cargo.toml + tests, tests/*.sh |
| 10 | `frankenterm` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 62556 | none | tests: crates/frankenterm-alloc/tests/arena_stress.rs, crates/frankenterm-core-connectors/tests/proptest_connector_boundary.rs, crates/frankenterm-core-mcp/tests/proptest_mcp_client_boundary.rs, crates/frankenterm-core-policy-types/tests/proptest_policy_audit_chain.rs; schema: crates/frankenterm-core-audit-types/src/migration_rehearsal.rs, crates/frankenterm-core-tantivy/src/recorder_lexical_schema.rs, crates/frankenterm-core/src/api_schema.rs, crates/frankenterm-core/src/mcp_middleware.rs; doctor: .github/workflows/lindley-bounds-check.yml, .github/workflows/reality-check-drumbeat.yml, .github/workflows/storage-backend-callsites-check.yml, .github/workflows/storage-backend-comparison-check.yml; runnable: .github/workflows, Cargo.toml + tests, tests/*.sh |
| 11 | `mcp_agent_mail_rust` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 17548 | none | tests: crates/mcp-agent-mail-cli/src/bin/test_db.rs, crates/mcp-agent-mail-cli/tests/artifacts/cli/share_preview/20260206_142939_161762325/server.log, crates/mcp-agent-mail-cli/tests/artifacts/cli/share_preview/20260206_152222_212369100/server.log, crates/mcp-agent-mail-cli/tests/artifacts/cli/share_preview/20260206_160117_142732384/server.log; schema: .github/workflows/conformance-fixture-regen.yml, crates/mcp-agent-mail-cli/tests/semantic_conformance.rs, crates/mcp-agent-mail-conformance/Cargo.toml, crates/mcp-agent-mail-conformance/README.md; doctor: .beads/.br_recovery/beads.db-wal.orphan_20260313T224229Z, .beads/.br_recovery/beads.db.20260313_224031_514673114.bak, RECOVERY_RUNBOOK.md, benches/golden/am_doctor_help.txt; runnable: .github/workflows, Cargo.toml + tests, tests/*.sh |
| 12 | `ntm` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 31709 | none | tests: cmd/test_fix/main.go, e2e/activity_metrics_test.go, e2e/auto_respawner_test.go, e2e/checkpoint_test.go; schema: .beads/.migration-hint-ts, docs/WORKFLOW_SCHEMA.md, docs/attention-feed-contract.md, docs/freshness-contract.md; doctor: .beads/.br_recovery/codex_beads_repair_20260321T023237Z/config.yaml, .beads/.br_recovery/codex_beads_repair_20260321T023237Z/issues.jsonl, .beads/.br_recovery/codex_beads_repair_20260321T023237Z/metadata.json, docs/robot-system-health-adapter.md; runnable: .github/workflows, Makefile test target, tests/*.sh |
| 13 | `pi_agent_rust` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 21210 | none | tests: docs/TEST_COVERAGE_MATRIX.md, docs/schema/test_evidence_logging_contract.json, docs/schema/test_evidence_logging_instance.json, docs/test_double_inventory.json; schema: .github/workflows/conformance.yml, docs/conformance-operator-playbook.md, docs/contracts/dropin-certification-contract.json, docs/contracts/dropin-upstream-baseline.json; doctor: .beads/recovery_20260315T063533Z/beads.db.dirty_issues.stderr, .beads/recovery_20260315T063533Z/beads.db.dirty_issues.txt, .beads/recovery_20260315T063533Z/beads.db.integrity.stderr, .beads/recovery_20260315T063533Z/beads.db.integrity.txt; runnable: .github/workflows, Cargo.toml + tests, tests/*.sh |
| 14 | `beads_rust` | 90.0 | 5 | 5 | 5 | 4 | 5 | 3 | 4077 | none | tests: docs/TEST_HARNESS.md, scripts/agent_smoke_test.sh, tests/bench_cold_warm.rs, tests/bench_cold_warm_start.rs; schema: .github/workflows/conformance.yml, CLI_SCHEMA.json, agent_baseline/help/br_schema_help.txt, agent_baseline/schemas/schema_all.json; doctor: docs/SYNC_MAINTENANCE_CHECKLIST.md, scripts/check_regression.py, src/cli/commands/doctor.rs, tests/fixtures/json_baseline/doctor.json; runnable: .github/workflows, Cargo.toml + tests, tests/*.sh |
| 15 | `remote_compilation_helper` | 89.6 | 5 | 5 | 4 | 5 | 5 | 3 | 5697 | none | tests: .baselines/test_performance_baseline.json, rch-common/src/e2e/test_workers.rs, rch-common/src/patterns_security_test.rs, rch-common/src/ssh_timeout_test.rs; schema: docs/RICH_OUTPUT_MIGRATION.md, docs/api/schemas/api-error.schema.json, docs/api/schemas/api-response.schema.json, docs/api/schemas/error-codes.json; doctor: agent_baseline/doctor.json, docs/runbooks/worker-recovery.md, rch/src/commands/config_doctor.rs, rch/src/doctor.rs; runnable: .github/workflows, Cargo.toml + tests, tests/*.sh |
| 16 | `flywheel_connectors` | 89.2 | 5 | 5 | 5 | 5 | 5 | 2 | 52283 | none | tests: connectors/1password/tests/integration.rs, connectors/airtable/tests/integration.rs, connectors/algolia/tests/integration.rs, connectors/amplitude/tests/connector_suite_happy_path.rs; schema: FCP_CDDL_V2.cddl, connectors/anthropic/tests/conformance_contract.rs, connectors/discord/tests/conformance_contract.rs, connectors/github/tests/conformance_contract.rs; doctor: crates/fcp-bootstrap/src/cold_recovery.rs, crates/fcp-bootstrap/src/recovery_phrase.rs, crates/fcp-conformance/src/bin/reqcheck.rs, crates/fcp-conformance/src/reqcheck/mod.rs; runnable: .github/workflows, Cargo.toml + tests |
| 17 | `flywheel_gateway` | 89.2 | 5 | 5 | 5 | 5 | 5 | 2 | 8594 | none | tests: apps/gateway/src/__tests__/agent-analytics.test.ts, apps/gateway/src/__tests__/agent-detection.service.test.ts, apps/gateway/src/__tests__/agent-driver-config.test.ts, apps/gateway/src/__tests__/agent-events.test.ts; schema: apps/gateway/src/__tests__/auth.middleware.test.ts, apps/gateway/src/__tests__/fixtures/invalid-schema-manifest.yaml, apps/gateway/src/__tests__/idempotency.middleware.test.ts, apps/gateway/src/__tests__/maintenance.middleware.test.ts; doctor: apps/gateway/src/__tests__/agent-health-score.service.test.ts, apps/gateway/src/__tests__/checkpoint.test.ts, apps/gateway/src/__tests__/context-health.service.test.ts, apps/gateway/src/__tests__/health.routes.test.ts; runnable: .github/workflows, package.json scripts.test |
| 18 | `franken_numpy` | 89.2 | 5 | 5 | 5 | 5 | 5 | 2 | 23475 | none | tests: artifacts/contracts/test_logging_contract_v1.json, artifacts/phase2c/FNP-P2C-007/test_contract_gate_report_rng_packet007.json, crates/fnp-conformance/src/test_contracts.rs, crates/fnp-conformance/tests/numpy_reference_ops.rs; schema: artifacts/contracts/CRASH_SIGNATURE_REGISTRY_V1.json, artifacts/contracts/PHASE2C_ARTIFACT_TOPOLOGY_V1.md, artifacts/contracts/PORTING_ESSENCE_EXTRACTION_LEDGER_V1.json, artifacts/contracts/PORTING_ESSENCE_EXTRACTION_LEDGER_V1.md; doctor: .beads/recovery_20260331T030214Z/.gitignore, .beads/recovery_20260331T030214Z/config.yaml, .beads/recovery_20260331T030214Z/issues.jsonl, .beads/recovery_20260331T030214Z/metadata.json; runnable: .github/workflows, Cargo.toml + tests |
| 19 | `frankenfs` | 89.2 | 5 | 5 | 5 | 5 | 5 | 2 | 7533 | none | tests: crates/ffs-block/tests/cache_workload_comparison.rs, crates/ffs-block/tests/perf_regression_e2e.rs, crates/ffs-block/tests/writeback_e2e.rs, crates/ffs-btrfs/tests/DISCREPANCIES.md; schema: conformance/COVERAGE.md, conformance/DISCREPANCIES.md, conformance/PROVENANCE.md, conformance/fixtures/btrfs_devitem.json; doctor: baselines/hyperfine/20260213/ffs_harness_check_fixtures.json, baselines/hyperfine/20260213/ffs_harness_check_fixtures.txt, baselines/hyperfine/20260218/ffs_cli_mount_recovery_probe.json, baselines/hyperfine/20260218/ffs_cli_mount_recovery_probe.stderr; runnable: .github/workflows, Cargo.toml + tests |
| 20 | `frankenmermaid` | 89.2 | 5 | 5 | 5 | 5 | 5 | 2 | 38181 | none | tests: crates/fm-cli/tests/benchmark_regression_harness.rs, crates/fm-cli/tests/canary_rollout_drills.rs, crates/fm-cli/tests/config_roundtrip_test.rs, crates/fm-cli/tests/corpus_ingestion.rs; schema: crates/fm-cli/tests/fixtures/frankentui_conformance/COVERAGE.md, crates/fm-cli/tests/fixtures/frankentui_conformance/DISCREPANCIES.md, crates/fm-cli/tests/fixtures/frankentui_conformance/PROVENANCE.md, crates/fm-cli/tests/fixtures/frankentui_conformance/architecture_basic.mmd; doctor: crates/fm-cli/tests/fnx_capability_checks.rs, crates/fm-cli/tests/golden/fuzzy_keyword_recovery.mmd, crates/fm-cli/tests/golden/fuzzy_keyword_recovery.svg, crates/fm-cli/tests/golden/layout_checksums.json; runnable: .github/workflows, Cargo.toml + tests |

## Bottom 20
| rank | repo | score | tests | docs | schema | doctor | idempotency | runnable | qdrant | caveats | evidence |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| 1 | `advice_for_learning_to_code_and_making_an_app` | 0.0 | 0 | 0 | 0 | 0 | 0 | 0 | 1856 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: - |
| 2 | `cellular_automata_snowflake_simulator` | 0.0 | 0 | 0 | 0 | 0 | 0 | 0 | 44 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: - |
| 3 | `military_history_articles` | 0.0 | 0 | 0 | 0 | 0 | 0 | 0 | 5 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy | docs: - |
| 4 | `my_shared_conversations` | 0.0 | 0 | 0 | 0 | 0 | 0 | 0 | 649 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: - |
| 5 | `yto_blog_posts` | 0.0 | 0 | 0 | 0 | 0 | 0 | 0 | 14 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: - |
| 6 | `rano` | 2.4 | 0 | 0 | 0 | 0 | 1 | 0 | 33 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: - |
| 7 | `anti_alzheimers_flasher` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 5 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy | docs: README.md |
| 8 | `automated_passive_causal_determination` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 35 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: README.md |
| 9 | `automatic_cpp_code_analysis_with_gpt` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 22 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: README.md |
| 10 | `automatic_log_collector_and_analyzer` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 82 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: README.md |
| 11 | `ball_fighters` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 10 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: README.md |
| 12 | `causal_direction_estimation_from_data` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 19 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: README.md |
| 13 | `ChatTTS` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 32 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: README.md, README_CN.md |
| 14 | `cohomological_ai` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 28 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: README.md |
| 15 | `github-diff-viewer` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 21 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: README.md |
| 16 | `hessian_free_email_chain` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 4 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy | docs: README.md |
| 17 | `hoeffdings_d_explainer` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 9 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy | docs: README.md, README_Chinese.md, README_Japanese.md |
| 18 | `interactive_reversible_cellular_automata` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 13 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: README.md |
| 19 | `introduction_to_temporal_logic` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 11 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: README.md |
| 20 | `llm-docs` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 92 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers | docs: README.md |

## Caveat Buckets
| caveat | count | sample repos |
|---|---:|---|
| `low_index_coverage_proxy` | 16 | `anti_alzheimers_flasher`, `bakery_algorithm`, `cool_desktop_wallpapers`, `curl_bash_one_liners_for_flywheel_tools`, `eidetic-engine-docs`, `grassmann_article`, `hessian_free_email_chain`, `hoeffdings_d_explainer`, `military_history_articles`, `multivariate_normality_testing`, `paxos_vs_raft`, `sassaman_and_dingledine_on_remailers_at_blackhat_2003`, +4 more |
| `missing_readme` | 7 | `advice_for_learning_to_code_and_making_an_app`, `cellular_automata_snowflake_simulator`, `fmd_blog_posts`, `military_history_articles`, `my_shared_conversations`, `rano`, `yto_blog_posts` |
| `no_doctor_markers` | 64 | `ChatTTS`, `Dicklesworthstone`, `advice_for_learning_to_code_and_making_an_app`, `anti_alzheimers_flasher`, `ascii_art_mini_transformer`, `automated_passive_causal_determination`, `automatic_cpp_code_analysis_with_gpt`, `automatic_log_collector_and_analyzer`, `bakery_algorithm`, `ball_fighters`, `bulk_transcribe_youtube_videos_from_playlist`, `cardinal_network_analysis`, +52 more |
| `no_runnable_test_surface` | 74 | `ChatTTS`, `advice_for_learning_to_code_and_making_an_app`, `agent-mailbox-viewer-example`, `agent_flywheel_clawdbot_skills_and_integrations`, `anti_alzheimers_flasher`, `asupersync_website`, `automated_passive_causal_determination`, `automatic_cpp_code_analysis_with_gpt`, `automatic_log_collector_and_analyzer`, `bakery_algorithm`, `ball_fighters`, `beads_for_cass`, +62 more |
| `no_schema_markers` | 73 | `ChatTTS`, `aadc`, `advice_for_learning_to_code_and_making_an_app`, `agent-mailbox-viewer-example`, `agent_settings_backup_script`, `anti_alzheimers_flasher`, `automated_passive_causal_determination`, `automatic_cpp_code_analysis_with_gpt`, `automatic_log_collector_and_analyzer`, `bakery_algorithm`, `ball_fighters`, `beads-for-frankentui`, +61 more |
| `no_test_files` | 73 | `ChatTTS`, `Dicklesworthstone`, `acip`, `advice_for_learning_to_code_and_making_an_app`, `agent-mailbox-viewer-example`, `agent_flywheel_clawdbot_skills_and_integrations`, `anti_alzheimers_flasher`, `asupersync_website`, `automated_passive_causal_determination`, `automatic_cpp_code_analysis_with_gpt`, `automatic_log_collector_and_analyzer`, `bakery_algorithm`, +61 more |

## Full 177-Repo Score Table
| rank | repo | score | tests | docs | schema | doctor | idempotency | runnable | tests/src | qdrant/chunks | caveats |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 1 | `frankentui` | 96.4 | 5 | 5 | 5 | 5 | 5 | 4 | 1445/578 | 22333/22333 | none |
| 2 | `frankensqlite` | 93.2 | 5 | 4 | 5 | 5 | 5 | 4 | 969/453 | 24510/24510 | none |
| 3 | `asupersync` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 604/654 | 25317/25317 | none |
| 4 | `asupersync_ansi_c` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 273/268 | 6956/6956 | none |
| 5 | `coding_agent_session_search` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 734/193 | 12258/12258 | none |
| 6 | `franken_networkx` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 683/534 | 16390/16390 | none |
| 7 | `franken_node` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 1219/855 | 32657/32657 | none |
| 8 | `frankenlibc` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 867/507 | 30658/30658 | none |
| 9 | `frankensearch` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 162/216 | 7618/7618 | none |
| 10 | `frankenterm` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 4808/1963 | 62556/62556 | none |
| 11 | `mcp_agent_mail_rust` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 870/278 | 17548/17548 | none |
| 12 | `ntm` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 889/740 | 31709/31709 | none |
| 13 | `pi_agent_rust` | 92.8 | 5 | 5 | 5 | 5 | 5 | 3 | 19423/158 | 21210/21210 | none |
| 14 | `beads_rust` | 90.0 | 5 | 5 | 5 | 4 | 5 | 3 | 202/87 | 4077/4077 | none |
| 15 | `remote_compilation_helper` | 89.6 | 5 | 5 | 4 | 5 | 5 | 3 | 167/249 | 5697/5697 | none |
| 16 | `flywheel_connectors` | 89.2 | 5 | 5 | 5 | 5 | 5 | 2 | 1096/1547 | 52283/52283 | none |
| 17 | `flywheel_gateway` | 89.2 | 5 | 5 | 5 | 5 | 5 | 2 | 222/438 | 8594/8594 | none |
| 18 | `franken_numpy` | 89.2 | 5 | 5 | 5 | 5 | 5 | 2 | 656/748 | 23475/23475 | none |
| 19 | `frankenfs` | 89.2 | 5 | 5 | 5 | 5 | 5 | 2 | 134/215 | 7533/7533 | none |
| 20 | `frankenmermaid` | 89.2 | 5 | 5 | 5 | 5 | 5 | 2 | 136/77 | 38181/38181 | none |
| 21 | `franken_whisper` | 86.8 | 5 | 4 | 5 | 4 | 5 | 3 | 160/36 | 2675/2675 | none |
| 22 | `frankenredis` | 86.4 | 5 | 5 | 5 | 4 | 5 | 2 | 170/89 | 5284/5284 | none |
| 23 | `frankenscipy` | 86.4 | 5 | 5 | 5 | 4 | 5 | 2 | 121/159 | 8273/8273 | none |
| 24 | `meta_skill` | 86.4 | 5 | 5 | 5 | 4 | 5 | 2 | 159/246 | 5225/5225 | none |
| 25 | `franken_engine` | 86.0 | 5 | 4 | 5 | 5 | 5 | 2 | 2523/702 | 122121/122121 | none |
| 26 | `frankenpandas` | 86.0 | 5 | 4 | 5 | 5 | 5 | 2 | 110/74 | 7520/7520 | none |
| 27 | `brenner_bot` | 85.6 | 5 | 5 | 5 | 5 | 5 | 1 | 235/371 | 9630/9630 | none |
| 28 | `frankenjax` | 85.6 | 5 | 5 | 5 | 5 | 5 | 1 | 136/102 | 6730/6730 | none |
| 29 | `beads_viewer` | 83.6 | 5 | 5 | 3 | 4 | 5 | 3 | 284/2913 | 7709/7709 | none |
| 30 | `destructive_command_guard` | 83.6 | 5 | 4 | 4 | 4 | 5 | 3 | 147/164 | 3813/3813 | none |
| 31 | `process_triage` | 83.2 | 5 | 4 | 5 | 4 | 5 | 2 | 100/227 | 4503/4503 | none |
| 32 | `doodlestein_self_releaser` | 82.4 | 5 | 5 | 4 | 5 | 5 | 1 | 130/0 | 2052/2052 | none |
| 33 | `eidetic_engine_cli` | 82.4 | 5 | 4 | 5 | 5 | 5 | 1 | 278/131 | 7113/7113 | none |
| 34 | `jeffrey_emanuel_personal_site` | 80.8 | 5 | 5 | 4 | 4 | 4 | 2 | 48/217 | 2108/2108 | none |
| 35 | `jeffreysprompts.com` | 80.8 | 5 | 4 | 3 | 5 | 4 | 3 | 414/511 | 6108/6108 | none |
| 36 | `markdown_web_browser` | 80.0 | 5 | 5 | 3 | 4 | 5 | 2 | 63/54 | 1442/1442 | none |
| 37 | `mcp_agent_mail` | 80.0 | 5 | 5 | 3 | 4 | 5 | 2 | 143/28 | 2725/2725 | none |
| 38 | `agentic_coding_flywheel_setup` | 79.6 | 5 | 4 | 3 | 5 | 5 | 2 | 117/283 | 7321/7321 | none |
| 39 | `sqlmodel_rust` | 78.8 | 5 | 5 | 5 | 3 | 3 | 2 | 32/114 | 2352/2352 | none |
| 40 | `charmed_rust` | 78.4 | 5 | 5 | 5 | 2 | 4 | 2 | 159/138 | 4760/4760 | none |
| 41 | `frankentorch` | 78.0 | 4 | 3 | 5 | 5 | 5 | 2 | 8/31 | 3696/3696 | none |
| 42 | `rich_rust` | 78.0 | 5 | 5 | 4 | 3 | 4 | 2 | 119/78 | 2658/2658 | none |
| 43 | `fastmcp_rust` | 77.2 | 5 | 4 | 4 | 3 | 5 | 2 | 40/94 | 2590/2590 | none |
| 44 | `cass_memory_system` | 76.8 | 5 | 5 | 2 | 4 | 5 | 2 | 171/59 | 2417/2417 | none |
| 45 | `coding_agent_account_manager` | 76.4 | 5 | 4 | 2 | 5 | 5 | 2 | 189/232 | 6154/6154 | none |
| 46 | `tsap_mcp_server` | 75.6 | 5 | 4 | 4 | 5 | 2 | 2 | 79/247 | 5494/5494 | none |
| 47 | `vibe_cockpit` | 75.2 | 5 | 3 | 5 | 4 | 3 | 2 | 125/114 | 1882/1882 | none |
| 48 | `mcp_agent_mail_website` | 74.0 | 5 | 3 | 4 | 3 | 5 | 2 | 13/82 | 1000/1000 | none |
| 49 | `fastapi_rust` | 73.2 | 5 | 5 | 4 | 3 | 2 | 2 | 35/85 | 2825/2825 | none |
| 50 | `coding_agent_usage_tracker` | 72.4 | 5 | 3 | 3 | 4 | 3 | 3 | 64/72 | 1401/1401 | none |
| 51 | `ultimate_mcp_server` | 71.6 | 5 | 4 | 3 | 3 | 4 | 2 | 20/160 | 3000/3000 | none |
| 52 | `storage_ballast_helper` | 71.2 | 5 | 5 | 2 | 2 | 5 | 2 | 32/71 | 2829/2829 | none |
| 53 | `repo_updater` | 70.0 | 5 | 4 | 2 | 4 | 5 | 1 | 107/0 | 2344/2344 | none |
| 54 | `opentui_rust` | 69.6 | 5 | 5 | 3 | 2 | 3 | 2 | 94/82 | 1858/1858 | none |
| 55 | `wezterm` | 69.6 | 4 | 4 | 2 | 3 | 5 | 3 | 14/774 | 13974/13974 | none |
| 56 | `xf` | 69.6 | 5 | 4 | 2 | 3 | 3 | 3 | 36/57 | 3334/3334 | none |
| 57 | `automated_plan_reviser_pro` | 68.8 | 5 | 4 | 1 | 3 | 4 | 3 | 37/0 | 128/128 | none |
| 58 | `model_guided_research` | 68.4 | 5 | 5 | 1 | 3 | 4 | 2 | 11/67 | 932/932 | none |
| 59 | `cross_agent_session_resumer` | 68.0 | 5 | 4 | 2 | 2 | 5 | 2 | 87/23 | 1161/1161 | none |
| 60 | `savant-elite` | 68.0 | 5 | 3 | 1 | 3 | 5 | 3 | 28/1 | 278/278 | none |
| 61 | `automated_flywheel_setup_checker` | 66.8 | 5 | 2 | 1 | 5 | 5 | 2 | 49/30 | 667/667 | none |
| 62 | `phage_explorer` | 66.8 | 5 | 4 | 3 | 3 | 2 | 2 | 61/464 | 5549/5549 | none |
| 63 | `beads_viewer_rust` | 65.6 | 5 | 3 | 3 | 2 | 4 | 2 | 38/56 | 2604/2604 | none |
| 64 | `slb` | 64.8 | 5 | 3 | 2 | 2 | 5 | 2 | 95/112 | 3143/3143 | none |
| 65 | `ultimate_bug_scanner` | 64.4 | 3 | 4 | 2 | 5 | 4 | 2 | 6/343 | 1981/1981 | none |
| 66 | `toon_rust` | 63.6 | 5 | 3 | 3 | 3 | 2 | 2 | 55/32 | 517/517 | none |
| 67 | `rust_scriptbots` | 62.8 | 4 | 4 | 1 | 3 | 5 | 2 | 9/49 | 1303/1303 | none |
| 68 | `rust_stream_deck` | 62.4 | 5 | 3 | 2 | 2 | 4 | 2 | 148/30 | 610/610 | none |
| 69 | `post_compact_reminder` | 61.2 | 5 | 3 | 0 | 3 | 5 | 2 | 10/0 | 94/94 | no_schema_markers |
| 70 | `rust_proxy` | 58.0 | 4 | 4 | 1 | 3 | 3 | 2 | 7/19 | 550/550 | none |
| 71 | `aadc` | 57.2 | 5 | 3 | 0 | 2 | 3 | 3 | 40/2 | 271/271 | no_schema_markers |
| 72 | `agent_settings_backup_script` | 55.6 | 5 | 3 | 0 | 1 | 5 | 2 | 50/0 | 475/475 | no_schema_markers |
| 73 | `gonode` | 55.2 | 5 | 3 | 5 | 2 | 0 | 0 | 50/423 | 3145/3145 | no_runnable_test_surface |
| 74 | `frankentui_website` | 54.8 | 5 | 3 | 1 | 3 | 4 | 0 | 20/121 | 5981/5981 | no_runnable_test_surface |
| 75 | `bio_inspired_nanochat` | 54.4 | 3 | 4 | 1 | 3 | 2 | 3 | 6/61 | 605/605 | none |
| 76 | `ascii_art_mini_transformer` | 51.2 | 5 | 3 | 1 | 0 | 3 | 2 | 55/45 | 727/727 | no_doctor_markers |
| 77 | `frankensqlite_website` | 51.2 | 5 | 3 | 2 | 1 | 2 | 1 | 12/103 | 612/612 | none |
| 78 | `giil` | 50.8 | 5 | 3 | 1 | 2 | 2 | 1 | 49/0 | 191/191 | none |
| 79 | `homebrew-tap` | 50.0 | 3 | 4 | 0 | 3 | 3 | 2 | 7/14 | 177/177 | no_schema_markers |
| 80 | `surface-dial-rust` | 50.0 | 4 | 3 | 0 | 2 | 2 | 3 | 7/27 | 389/389 | no_schema_markers |
| 81 | `textract-py3` | 49.2 | 5 | 3 | 1 | 1 | 1 | 2 | 118/37 | 239/239 | none |
| 82 | `fast_cmaes` | 47.2 | 4 | 3 | 0 | 1 | 2 | 3 | 9/12 | 136/136 | no_schema_markers |
| 83 | `system_resource_protection_script` | 46.0 | 3 | 2 | 0 | 3 | 4 | 2 | 1/6 | 145/145 | no_schema_markers |
| 84 | `lemelsonbot` | 44.8 | 4 | 4 | 2 | 1 | 0 | 1 | 3/7 | 811/811 | none |
| 85 | `ultrasearch` | 43.6 | 1 | 4 | 3 | 2 | 3 | 1 | 0/105 | 687/687 | no_test_files |
| 86 | `wasm_cmaes` | 43.2 | 4 | 3 | 0 | 0 | 3 | 2 | 3/10 | 115/115 | no_schema_markers, no_doctor_markers |
| 87 | `ultimate_mcp_client` | 42.8 | 3 | 4 | 1 | 1 | 1 | 2 | 2/5 | 873/873 | none |
| 88 | `scoop-bucket` | 42.0 | 2 | 3 | 0 | 3 | 3 | 2 | 1/0 | 74/74 | no_schema_markers |
| 89 | `chat_shared_conversation_to_file` | 39.6 | 2 | 3 | 1 | 1 | 3 | 2 | 2/3 | 108/108 | none |
| 90 | `swiss_army_llama` | 37.6 | 4 | 1 | 1 | 0 | 2 | 2 | 9/13 | 178/178 | no_doctor_markers |
| 91 | `asupersync_website` | 34.0 | 1 | 3 | 3 | 1 | 3 | 0 | 0/81 | 559/559 | no_test_files, no_runnable_test_surface |
| 92 | `cmaes_explainer` | 34.0 | 1 | 4 | 1 | 3 | 2 | 0 | 0/39 | 195/195 | no_test_files, no_runnable_test_surface |
| 93 | `misc_coding_agent_tips_and_scripts` | 32.0 | 1 | 2 | 1 | 2 | 5 | 0 | 0/1 | 268/268 | no_test_files, no_runnable_test_surface |
| 94 | `prepareprojectforllmprompt` | 31.6 | 4 | 2 | 0 | 0 | 1 | 1 | 12/2 | 24/24 | no_schema_markers, no_doctor_markers |
| 95 | `llm_docs` | 30.8 | 4 | 1 | 0 | 0 | 2 | 1 | 8/30 | 248/248 | no_schema_markers, no_doctor_markers |
| 96 | `claude_code_agent_farm` | 29.6 | 1 | 2 | 1 | 2 | 4 | 0 | 0/1 | 1421/1421 | no_test_files, no_runnable_test_surface |
| 97 | `hacker-news-clone` | 29.6 | 3 | 1 | 3 | 0 | 1 | 0 | 5/68 | 130/130 | no_runnable_test_surface, no_doctor_markers |
| 98 | `acip` | 29.2 | 0 | 2 | 1 | 4 | 2 | 1 | 0/0 | 79/79 | no_test_files |
| 99 | `beads-for-frankentui` | 27.6 | 2 | 2 | 0 | 2 | 1 | 1 | 1/17 | 835/835 | no_schema_markers |
| 100 | `source_to_prompt_tui` | 26.4 | 1 | 3 | 1 | 1 | 1 | 1 | 0/3 | 286/286 | no_test_files |
| 101 | `fast_vector_similarity` | 26.0 | 2 | 1 | 0 | 0 | 1 | 3 | 1/2 | 38/38 | no_schema_markers, no_doctor_markers |
| 102 | `agent_flywheel_clawdbot_skills_and_integrations` | 24.8 | 1 | 2 | 1 | 2 | 2 | 0 | 0/0 | 151/151 | no_test_files, no_runnable_test_surface |
| 103 | `ffn` | 24.0 | 3 | 3 | 0 | 0 | 0 | 0 | 5/10 | 179/179 | no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 104 | `franken_agent_detection` | 23.6 | 1 | 2 | 2 | 0 | 1 | 1 | 0/30 | 578/578 | no_test_files, no_doctor_markers |
| 105 | `github_stars_curve` | 23.6 | 3 | 1 | 0 | 0 | 1 | 1 | 4/7 | 18/18 | no_schema_markers, no_doctor_markers |
| 106 | `beads_for_asupersync` | 22.4 | 2 | 1 | 1 | 1 | 0 | 1 | 1/17 | 1302/1302 | none |
| 107 | `beads_viewer_for_agentic_coding_flywheel_setup` | 21.6 | 2 | 2 | 0 | 2 | 0 | 0 | 1/17 | 346/346 | no_runnable_test_surface, no_schema_markers |
| 108 | `loaded-pow` | 21.2 | 3 | 1 | 0 | 0 | 0 | 1 | 2/9 | 84/84 | no_schema_markers, no_doctor_markers |
| 109 | `beads_for_franken_engine` | 20.0 | 1 | 1 | 1 | 1 | 1 | 1 | 1/17 | 587/587 | none |
| 110 | `llm-tournament` | 18.8 | 1 | 2 | 0 | 1 | 2 | 0 | 2/27 | 564/564 | no_runnable_test_surface, no_schema_markers |
| 111 | `useful_coding_guides_for_llms` | 17.6 | 0 | 3 | 1 | 0 | 2 | 0 | 0/0 | 66/66 | no_test_files, no_runnable_test_surface, no_doctor_markers |
| 112 | `ees` | 17.2 | 0 | 2 | 1 | 1 | 2 | 0 | 0/7 | 85/85 | no_test_files, no_runnable_test_surface |
| 113 | `beads_for_cass` | 16.8 | 1 | 2 | 0 | 2 | 0 | 0 | 1/17 | 345/345 | no_runnable_test_surface, no_schema_markers |
| 114 | `toon-go` | 16.0 | 2 | 2 | 0 | 0 | 0 | 0 | 1/1 | 46/46 | no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 115 | `mindmap-generator` | 14.8 | 0 | 2 | 1 | 1 | 1 | 0 | 0/1 | 80/80 | no_test_files, no_runnable_test_surface |
| 116 | `beads_viewer-pages` | 14.4 | 0 | 2 | 0 | 2 | 1 | 0 | 0/17 | 446/446 | no_test_files, no_runnable_test_surface, no_schema_markers |
| 117 | `useful_tmux_commands` | 14.4 | 0 | 2 | 1 | 0 | 2 | 0 | 0/0 | 66/66 | no_test_files, no_runnable_test_surface, no_doctor_markers |
| 118 | `llm_introspective_compression_and_metacognition` | 14.0 | 0 | 2 | 0 | 1 | 2 | 0 | 0/0 | 14/14 | no_test_files, no_runnable_test_surface, no_schema_markers |
| 119 | `gemini-api-updater-doc` | 13.6 | 1 | 1 | 1 | 0 | 1 | 0 | 0/0 | 17/17 | no_test_files, no_runnable_test_surface, no_doctor_markers |
| 120 | `cass-memory-system-agent-mailbox-viewer` | 12.4 | 0 | 2 | 1 | 1 | 0 | 0 | 0/8 | 126/126 | no_test_files, no_runnable_test_surface |
| 121 | `Dicklesworthstone` | 12.4 | 0 | 1 | 1 | 0 | 1 | 1 | 0/0 | 12/12 | no_test_files, no_doctor_markers |
| 122 | `llm_multi_round_coding_tournament` | 12.4 | 0 | 2 | 1 | 1 | 0 | 0 | 0/1 | 13116/13116 | no_test_files, no_runnable_test_surface |
| 123 | `markdown-browser-agent-mailbox-viewer` | 12.4 | 0 | 2 | 1 | 1 | 0 | 0 | 0/8 | 127/127 | no_test_files, no_runnable_test_surface |
| 124 | `suno2cd` | 12.4 | 0 | 2 | 0 | 0 | 1 | 1 | 0/5 | 48/48 | no_test_files, no_schema_markers, no_doctor_markers |
| 125 | `raptorq_article` | 12.0 | 0 | 2 | 0 | 2 | 0 | 0 | 0/4 | 106/106 | no_test_files, no_runnable_test_surface, no_schema_markers |
| 126 | `beads_for_cass_memory_system` | 10.8 | 1 | 1 | 0 | 1 | 0 | 0 | 1/17 | 473/473 | no_runnable_test_surface, no_schema_markers |
| 127 | `bakery_algorithm` | 10.4 | 0 | 1 | 0 | 0 | 3 | 0 | 0/1 | 9/9 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 128 | `guide_to_openai_response_api_and_agents_sdk` | 9.6 | 0 | 2 | 1 | 0 | 0 | 0 | 0/0 | 46/46 | no_test_files, no_runnable_test_surface, no_doctor_markers |
| 129 | `agent-mailbox-viewer-example` | 9.2 | 0 | 2 | 0 | 1 | 0 | 0 | 0/8 | 127/127 | no_test_files, no_runnable_test_surface, no_schema_markers |
| 130 | `jazz_chord_progression_editor_html` | 9.2 | 0 | 2 | 0 | 1 | 0 | 0 | 0/0 | 110/110 | no_test_files, no_runnable_test_surface, no_schema_markers |
| 131 | `eidetic-engine-website-project` | 8.8 | 0 | 1 | 1 | 0 | 1 | 0 | 0/29 | 201/201 | no_test_files, no_runnable_test_surface, no_doctor_markers |
| 132 | `llm_aided_ocr` | 8.8 | 0 | 2 | 0 | 0 | 1 | 0 | 0/2 | 47/47 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 133 | `fmd_blog_posts` | 8.4 | 0 | 0 | 0 | 3 | 0 | 0 | 0/0 | 132/132 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers |
| 134 | `the_lighthill_debate_on_ai` | 8.4 | 0 | 1 | 0 | 1 | 1 | 0 | 0/0 | 5/5 | no_test_files, no_runnable_test_surface, no_schema_markers, low_index_coverage_proxy |
| 135 | `llm_aided_legal_discovery_bot` | 8.0 | 0 | 1 | 0 | 0 | 2 | 0 | 0/2 | 80/80 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 136 | `sassaman_and_dingledine_on_remailers_at_blackhat_2003` | 8.0 | 0 | 1 | 0 | 0 | 2 | 0 | 0/0 | 5/5 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 137 | `multivariate_normality_testing` | 6.8 | 0 | 1 | 0 | 0 | 0 | 1 | 0/0 | 6/6 | no_test_files, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 138 | `sqlalchemy_data_model_visualizer` | 6.8 | 0 | 1 | 0 | 0 | 0 | 1 | 0/2 | 7/7 | no_test_files, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 139 | `bulk_transcribe_youtube_videos_from_playlist` | 6.4 | 0 | 1 | 1 | 0 | 0 | 0 | 0/1 | 15/15 | no_test_files, no_runnable_test_surface, no_doctor_markers |
| 140 | `cardinal_network_analysis` | 6.4 | 0 | 2 | 0 | 0 | 0 | 0 | 0/0 | 11/11 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 141 | `cloud_benchmarker` | 6.4 | 0 | 2 | 0 | 0 | 0 | 0 | 0/8 | 31/31 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 142 | `cool_desktop_wallpapers` | 6.4 | 0 | 2 | 0 | 0 | 0 | 0 | 0/0 | 2/2 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 143 | `curl_bash_one_liners_for_flywheel_tools` | 6.4 | 0 | 2 | 0 | 0 | 0 | 0 | 0/0 | 6/6 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 144 | `kissinger_undergraduate_thesis` | 6.4 | 0 | 2 | 0 | 0 | 0 | 0 | 0/0 | 118/118 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 145 | `letter_learning_game` | 6.4 | 0 | 2 | 0 | 0 | 0 | 0 | 0/0 | 158/158 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 146 | `eidetic-engine-docs` | 5.6 | 0 | 1 | 0 | 0 | 1 | 0 | 0/0 | 6/6 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 147 | `grassmann_article` | 5.6 | 0 | 1 | 0 | 0 | 1 | 0 | 0/0 | 2/2 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 148 | `most-influential-github-repo-stars` | 5.6 | 0 | 1 | 0 | 0 | 1 | 0 | 0/5 | 31/31 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 149 | `textsynth_server_cluster` | 5.6 | 0 | 1 | 0 | 0 | 1 | 0 | 0/1 | 25/25 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 150 | `anti_alzheimers_flasher` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/0 | 5/5 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 151 | `automated_passive_causal_determination` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/3 | 35/35 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 152 | `automatic_cpp_code_analysis_with_gpt` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/1 | 22/22 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 153 | `automatic_log_collector_and_analyzer` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/1 | 82/82 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 154 | `ball_fighters` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/0 | 10/10 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 155 | `causal_direction_estimation_from_data` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/1 | 19/19 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 156 | `ChatTTS` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/14 | 32/32 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 157 | `cohomological_ai` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/1 | 28/28 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 158 | `github-diff-viewer` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/9 | 21/21 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 159 | `hessian_free_email_chain` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/0 | 4/4 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 160 | `hoeffdings_d_explainer` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/0 | 9/9 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 161 | `interactive_reversible_cellular_automata` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/0 | 13/13 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 162 | `introduction_to_temporal_logic` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/0 | 11/11 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 163 | `llm-docs` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/0 | 92/92 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 164 | `nextjs-github-markdown-blog` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/25 | 59/59 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 165 | `paxos_vs_raft` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/0 | 3/3 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 166 | `ppp_loan_fraud_analysis` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/3 | 92/92 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 167 | `py_chord_chart_generator` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/1 | 17/17 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 168 | `some_thoughts_on_ai_alignment` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/0 | 4/4 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 169 | `visual_astar_python` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/1 | 86/86 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 170 | `your-source-to-prompt.html` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/0 | 21/21 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 171 | `youtube_transcript_cleaner` | 3.2 | 0 | 1 | 0 | 0 | 0 | 0 | 0/0 | 4/4 | no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 172 | `rano` | 2.4 | 0 | 0 | 0 | 0 | 1 | 0 | 0/6 | 33/33 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 173 | `advice_for_learning_to_code_and_making_an_app` | 0.0 | 0 | 0 | 0 | 0 | 0 | 0 | 0/0 | 1856/1856 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 174 | `cellular_automata_snowflake_simulator` | 0.0 | 0 | 0 | 0 | 0 | 0 | 0 | 0/0 | 44/44 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 175 | `military_history_articles` | 0.0 | 0 | 0 | 0 | 0 | 0 | 0 | 0/0 | 5/5 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers, low_index_coverage_proxy |
| 176 | `my_shared_conversations` | 0.0 | 0 | 0 | 0 | 0 | 0 | 0 | 0/0 | 649/649 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |
| 177 | `yto_blog_posts` | 0.0 | 0 | 0 | 0 | 0 | 0 | 0 | 0/0 | 14/14 | missing_readme, no_test_files, no_runnable_test_surface, no_schema_markers, no_doctor_markers |

## Adopt / Avoid Notes
- Adopt from top-ranked repos: keep validation surfaces close to runnable commands, fixtures, structured schemas, and doctor/repair endpoints.
- Extend from middle-ranked repos: strong docs without runnable tests should become dispatch examples only after a probe command exists.
- Do not adopt from bottom-ranked repos by default: many are essays, demos, or tiny experiments where missing validation surfaces are expected; treat them as conceptual references unless a separate signal justifies reuse.
