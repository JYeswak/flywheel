# Inventory Rebuild Diff

Generated: 2026-05-19T07:31:27Z

## Summary

- Baseline rows: 3791
- Rebuild rows: 3813
- Repos covered: 11
- new_surfaces_count: 22
- removed_surfaces_count: 0
- orphaned_surface_count: 0
- legacy_orphan_candidates_count: 565
- Status: PASS
- Next action: PASS: close Substrate Quality Program umbrella; no orphaned surfaces detected.

## Rebuild Per-Repo Breakdown

| Repo | Surfaces |
|---|---:|
| agent-bench | 16 |
| alpsinsurance | 172 |
| clutterfreespaces | 338 |
| flywheel | 1720 |
| frankensqlite | 204 |
| mobile-eats | 72 |
| ntm | 42 |
| picoz | 229 |
| skillos | 377 |
| vrtx | 124 |
| zesttube | 519 |

## Rebuild Per-Class Breakdown

| Class | Surfaces |
|---|---:|
| CLI | 387 |
| doctor | 430 |
| hook | 85 |
| ledger-writer | 729 |
| other | 499 |
| test | 1219 |
| validator | 464 |

## Added Surfaces

| Repo | Path | Class | Invoke count 30d | Age days |
|---|---|---|---:|---:|
| flywheel | `.flywheel/inventory/2026-05-19-rebuild/inventory-rebuild-diff.sh` | ledger-writer | 0 | 0 |
| flywheel | `.flywheel/scripts/agent-ergonomics-fleet-audit.sh` | validator | 3 | 0 |
| flywheel | `.flywheel/scripts/cross-repo-inheritance-audit.sh` | validator | 1 | 0 |
| flywheel | `.flywheel/scripts/frozen-pane-detector.sh__agent_ergonomics_audit/regression-tests.sh` | other | 2 | 0 |
| flywheel | `.flywheel/scripts/inventory-tier-refine.sh` | ledger-writer | 1 | 0 |
| flywheel | `.flywheel/scripts/ntm-spawn-templates-versioned.py__agent_ergonomics_audit/regression-tests.sh` | other | 2 | 0 |
| flywheel | `.flywheel/scripts/ntm-wave2-native-probes.sh__agent_ergonomics_audit/regression-tests.sh` | other | 2 | 0 |
| flywheel | `.flywheel/scripts/peer-orch-blocker-watch.sh__agent_ergonomics_audit/regression-tests.sh` | other | 2 | 0 |
| flywheel | `.flywheel/scripts/peer-orch-respawn-permit.sh__agent_ergonomics_audit/regression-tests.sh` | other | 2 | 0 |
| flywheel | `.flywheel/scripts/recovery-escape-then-reprompt.sh__agent_ergonomics_audit/regression-tests.sh` | other | 2 | 0 |
| flywheel | `.flywheel/scripts/stale-error-auto-ping.sh__agent_ergonomics_audit/regression-tests.sh` | other | 2 | 0 |
| flywheel | `.flywheel/scripts/storage-probe.sh__agent_ergonomics_audit/regression-tests.sh` | other | 2 | 0 |
| flywheel | `.flywheel/scripts/worker-auto-respawn-watchdog.sh__agent_ergonomics_audit/regression-tests.sh` | other | 2 | 0 |
| flywheel | `bin/flywheel__agent_ergonomics_audit/regression-tests.sh` | other | 2 | 0 |
| flywheel | `tests/agent-ergonomics-fleet-audit.sh` | test | 5 | 0 |
| flywheel | `tests/cross-repo-inheritance-audit.sh` | test | 2 | 0 |
| flywheel | `tests/inventory-rebuild-diff.sh` | test | 0 | 0 |
| flywheel | `tests/inventory-tier-refine.sh` | test | 2 | 0 |
| mobile-eats | `.flywheel/goals/2026-05-19-phase0-acute-breakages-pane2.validate.sh` | validator | 0 | 0 |
| zesttube | `scripts/promote_v6_scene_candidates.sh` | other | 0 | 0 |
| zesttube | `scripts/studio_macos_release_lane.sh` | CLI | 0 | 0 |
| zesttube | `scripts/studio_publish_readiness.sh` | other | 0 | 0 |

## Removed Surfaces

| Repo | Path | Class | Invoke count 30d | Age days |
|---|---|---|---:|---:|
| none | none | none | 0 | 0 |

## Orphaned Surfaces

Scope: added surfaces in the rebuild diff.

Heuristic: age_days >= 7, invoke_count_30d = 0, and no inbound references in tracked code/docs/tests/dispatch-log scan.

| Repo | Path | Class | Invoke count 30d | Age days |
|---|---|---|---:|---:|
| none | none | none | 0 | 0 |

## Legacy Orphan Candidates

These candidates come from the full rebuild row set, not just surfaces added during the Substrate Quality Program window. They are reported separately because Phase 5 closes the program-window orphan check; cleanup routing belongs to a follow-up hygiene phase.

- legacy_orphan_candidates_count: 565

- agent-bench: `run-bench.sh`
- agent-bench: `scripts/grade-run.sh`
- agent-bench: `scripts/run-phase2.sh`
- alpsinsurance: `.flywheel/scripts/bead-quality-mining.sh.bak.20260508T054142Z`
- alpsinsurance: `.flywheel/scripts/bead-quality-mining.sh.bak.20260508T235955Z`
- alpsinsurance: `.flywheel/scripts/cleanup-scratch.sh.bak.20260511T085150Z`
- alpsinsurance: `.flywheel/scripts/dispatch-and-verify.sh.bak.20260508T162251Z`
- alpsinsurance: `.flywheel/scripts/dispatch-and-verify.sh.bak.20260509T045045Z`
- alpsinsurance: `.flywheel/scripts/sync-canonical-doctrine.sh.bak.20260508T161302Z`
- alpsinsurance: `.flywheel/scripts/sync-canonical-doctrine.sh.bak.20260509T045046Z`
- alpsinsurance: `.flywheel/scripts/sync-canonical-doctrine.sh.bak.20260509T060555Z`
- alpsinsurance: `.flywheel/scripts/sync-canonical-doctrine.sh.bak.20260509T185424Z`
- alpsinsurance: `.flywheel/scripts/sync-canonical-doctrine.sh.bak.20260510T010319Z`
- alpsinsurance: `.flywheel/scripts/sync-canonical-doctrine.sh.bak.20260510T012015Z`
- alpsinsurance: `.flywheel/scripts/sync-canonical-doctrine.sh.bak.20260511T024355Z`
- alpsinsurance: `.flywheel/scripts/sync-canonical-doctrine.sh.bak.20260511T085150Z`
- alpsinsurance: `.flywheel/scripts/tmp-aggressive-prune.sh.bak.20260509T045045Z`
- alpsinsurance: `.flywheel/scripts/tmp-aggressive-prune.sh.bak.20260510T010319Z`
- alpsinsurance: `.flywheel/scripts/topology-tick-refresh.sh.bak.20260511T024355Z`
- alpsinsurance: `backend/scripts/smoke-test-coolify.sh`
- alpsinsurance: `backend/scripts/validate_feedback_e2e.sh`
- alpsinsurance: `scripts/check-no-placeholder-org-uuid.sh`
- alpsinsurance: `scripts/cutover/import_workato_payloads.py`
- alpsinsurance: `scripts/cutover/run_rehearsal.py`
- alpsinsurance: `scripts/dev-browser.sh`
- alpsinsurance: `scripts/hubspot_sdk_coverage.py`
- alpsinsurance: `scripts/start-frontend.sh`
- alpsinsurance: `scripts/stop-local.sh`
- alpsinsurance: `scripts/test-fixtures/test_entrypoint_fail_closed.sh`
- alpsinsurance: `scripts/validate-prod-config.sh`
- alpsinsurance: `scripts/validate-staging-parity.py`
- alpsinsurance: `scripts/verify-staging.sh`
- alpsinsurance: `scripts/wave3/lint_no_credential_literals.sh`
- alpsinsurance: `scripts/wave3/lint_rotation_cadence.sh`
- alpsinsurance: `scripts/wave3/lint_rotation_evidence.sh`
- alpsinsurance: `scripts/wave3/validate_hubspot_pat_runbook.sh`
- clutterfreespaces: `scripts/pre-deploy-check.sh`
- flywheel: `.flywheel/scripts/doctrine-mechanism-coverage.py`
- flywheel: `.flywheel/scripts/quality-bar-close-gate.sh.bak.flywheel-bg06b-20260511T000420Z`
- flywheel: `.flywheel/scripts/wire_or_explain_chain_verifier.py`
- flywheel: `.flywheel/tests/test-br-db-close-path.sh`
- flywheel: `.flywheel/tests/test-sister-orch-2-blocker-escalation.sh`
- flywheel: `.flywheel/tests/test-three-judges-publishability-validator.sh`
- flywheel: `.flywheel/tests/test-two-truth-sources-validator.sh`
- flywheel: `.flywheel/tests/test_agentmail_identity_canonical_gate.sh`
- flywheel: `.flywheel/tests/test_calling_in_sick_policy_gate.sh`
- flywheel: `.flywheel/tests/test_capacity_halt_burst_budget.sh`
- flywheel: `.flywheel/tests/test_capacity_halt_live_detect.sh`
- flywheel: `.flywheel/tests/test_capacity_halt_success_measurement.sh`
- flywheel: `.flywheel/tests/test_close_validator_contract_probe.sh`
- flywheel: `.flywheel/tests/test_doctrine_drift_trend_probe.sh`
- flywheel: `.flywheel/tests/test_enter_press_not_respawn_class_gate.sh`
- flywheel: `.flywheel/tests/test_flywheel_owns_orch_pane_recovery_gate.sh`
- flywheel: `.flywheel/tests/test_flywheel_respawn_boot_wait_window.sh`
- flywheel: `.flywheel/tests/test_identity_stability_tuple_gate.sh`
- flywheel: `.flywheel/tests/test_jeff_clone_symlink_converter.sh`
- flywheel: `.flywheel/tests/test_orch_no_punt_output_gate.sh`
- flywheel: `.flywheel/tests/test_orch_p0_finish_first_gate.sh`
- flywheel: `.flywheel/tests/test_recency_weighted_two_truth_classifier.sh`
- flywheel: `tests/deep-audit.sh`
- flywheel: `tests/doctor-3-surface-scoping.sh`
- flywheel: `tests/fleet-coherence-alert-degraded.sh`
- flywheel: `tests/flywheel-watchers-test.sh.bak.b56fix01-20260505T013353Z`
- flywheel: `tests/loop-driver-drain-receipts.sh`
- flywheel: `tests/ntm-surface-changes.sh`
- flywheel: `tests/ntm-surface-conflicts.sh`
- flywheel: `tests/ntm-surface-grep.sh`
- flywheel: `tests/test_autoloop_decision_tree_10step.sh`
- flywheel: `tests/test_autoloop_executor_default_no_spawn.sh`
- flywheel: `tests/test_autoloop_executor_high_score_one_action.sh`
- flywheel: `tests/test_autoloop_executor_non_whitelist_fails.sh`
- flywheel: `tests/test_autoloop_no_op_streak_force_replan.sh`
- flywheel: `tests/test_autoloop_no_op_streak_halt.sh`
- flywheel: `tests/test_autoloop_no_op_streak_warn.sh`
- flywheel: `tests/test_brenner_hypothesis_slate.sh`
- flywheel: `tests/test_callback_contract_explicit_no_socraticode_passes.sh`
- flywheel: `tests/test_callback_contract_indexed_chunks_unknown_blocks.sh`
- flywheel: `tests/test_callback_contract_missing_did_didnt_blocks.sh`
- flywheel: `tests/test_compliance_pack_backward_compat.sh`
- flywheel: `tests/test_convergence_telemetry_round_artifact.sh`
- flywheel: `tests/test_convergence_telemetry_simple_plan_advisory.sh`
- flywheel: `tests/test_convergence_telemetry_unstable_blocks.sh`
- flywheel: `tests/test_dispatch_contract_violations_doctor_signal.sh`
- flywheel: `tests/test_ev_anchor_resolution.sh`
- flywheel: `tests/test_ev_anchor_unresolved_blocks.sh`
- flywheel: `tests/test_evidence_excerpt_mismatch.sh`
- flywheel: `tests/test_evidence_pack_v2_resolution.sh`
- flywheel: `tests/test_flywheel_cron_refuses_non_executable.sh`
- flywheel: `tests/test_flywheel_cron_remove_pause_resume_dry_run.sh`
- flywheel: `tests/test_hypothesis_slate_happy_path.sh`
- flywheel: `tests/test_hypothesis_slate_kill_condition_required.sh`
- flywheel: `tests/test_hypothesis_slate_required.sh`
- flywheel: `tests/test_hypothesis_slate_third_alternative_required.sh`
- flywheel: `tests/test_l128_doctrine_present.sh`
- flywheel: `tests/test_monolith_size_regression.sh`
- flywheel: `tests/test_ntm_lock_failure_contract.sh`
- flywheel: `tests/test_recovery_install_plist_clutterfreespaces.sh`
- flywheel: `tests/test_refute_contradiction_detection.sh`
- flywheel: `tests/test_tick_non_codex_uses_ntm_health.sh`
- flywheel: `tests/test_tick_pws_canonical_for_codex.sh`
- ... 465 additional legacy candidates omitted from markdown summary
