# Dry-Run/Apply Parity Contract Conformance

Generated: `2026-05-20T03:53:04Z`
Root: `/Users/josh/Developer/flywheel`
Status: `fail`

## Summary

| Metric | Count |
|---|---:|
| total | `598` |
| pass | `8` |
| fail | `553` |
| no_fixture | `37` |

## Named Initial Checks

| Status | Path | Detail |
|---|---|---|
| `PASS` | `.flywheel/scripts/branch-protection-apply.sh` | fixture contains parity assertion |
| `NOT-DUAL` | `.flywheel/scripts/auto-push.sh` | no dual-mode flag pair detected |
| `FAIL` | `.flywheel/scripts/supabase-rls-emergency-fix.sh` | fixture exists but no parity assertion was detected |
| `NOT-DUAL` | `.flywheel/scripts/mp-validator-framework.sh` | no dual-mode flag pair detected |
| `NO-FIXTURE` | `.flywheel/scripts/mp-scaffolders/MP-82-hook-lifecycle-guardrail-chain-scaffold.sh` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mp-scaffolders/MP-89-mode-scoped-phase-workspace-scaffold.sh` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mp-scaffolders/MP-90-adjacent-skill-boundary-router-scaffold.sh` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mp-scaffolders/MP-91-progress-counter-forced-motion-loop-scaffold.sh` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mp-scaffolders/MP-97-federated-retrieval-parity-provenance-scaffold.sh` | no matching smoke fixture found |
| `NOT-DUAL` | `.flywheel/scripts/codex-goal-mode-monitor-probe.sh` | no dual-mode flag pair detected |

## Scripts

| Status | Path | Modes | Fixture | Reason |
|---|---|---|---|---|
| `FAIL` | `.flywheel/scripts/adversarial-orch-self-audit-probe.sh` | `dry_run_apply` | `tests/adversarial-orch-self-audit-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/agent-mail-pre-allocate-worker-identities.sh` | `dry_run_apply` | `tests/agent-mail-pre-allocate-worker-identities-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/agent-mail-restart.sh` | `dry_run_apply` | `tests/agent-mail-restart.sh`, `tests/agent-mail-restart-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/agent-mail-send-redacted.sh` | `dry_run_apply` | `tests/agent-mail-send-redacted-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/agentmail-identity-canonical-validator.sh` | `dry_run_apply` | `tests/agentmail-identity-canonical-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/agents-md-fleet-propagator.sh` | `dry_run_apply` | `tests/agents-md-fleet-propagator.sh`, `tests/agents-md-fleet-propagator-canonical-cli.sh`, `tests/agents-md-fleet-propagator-large-ledger.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/agents-md-shard-extract.sh` | `dry_run_apply` | `tests/agents-md-shard-extract-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/append-safe-write.sh` | `dry_run_apply` | `tests/append-safe-write-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/apply-substrate-tuning.sh` | `dry_run_apply` | `tests/apply-substrate-tuning-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/apply-tmux-tuning.sh` | `dry_run_apply` | `tests/apply-tmux-tuning-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/auto-l112-gate.sh` | `dry_run_apply` | `tests/auto-l112-gate-canonical-cli.sh`, `tests/auto-l112-gate-orch-adoption-test.sh`, `tests/auto-l112-gate-test.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/auto-refill-decision-log.sh` | `dry_run_apply` | `tests/auto-refill-decision-log-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/bead-evidence-indexer.sh` | `dry_run_apply` | `tests/bead-evidence-indexer-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/beads-db-recover.sh` | `dry_run_apply` | `tests/beads-db-recover.sh`, `tests/beads-db-recover-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/bleed-ledger-watch.sh` | `dry_run_apply` | `tests/bleed-ledger-watch.sh`, `tests/bleed-ledger-watch-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/blocker-ac-tick-cadence.sh` | `dry_run_apply` | `tests/blocker-ac-tick-cadence-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/blocker-auto-close.sh` | `default_dry_run_apply` | `tests/blocker-auto-close.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/blocker-discipline-tick-chain.sh` | `default_dry_run_apply` | `tests/blocker-discipline-tick-chain.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/blocker-fail-escalator.sh` | `default_dry_run_apply` | `tests/blocker-fail-escalator.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/br-authority-probe.sh` | `dry_run_apply` | `tests/br-authority-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/br-close-with-gate.sh` | `dry_run_apply` | `tests/br-close-with-gate-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/br-db-corruption-monitor.sh` | `dry_run_apply` | `tests/br-db-corruption-monitor.sh`, `tests/br-db-corruption-monitor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/build-dispatch-packet.sh` | `dry_run_apply` | `tests/build-dispatch-packet-canonical-cli.sh`, `tests/build-dispatch-packet-callback-pane-topology.sh`, `tests/build-dispatch-packet-evidence-redacted.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/caam-rotate-and-respawn.sh` | `dry_run_apply` | `tests/caam-rotate-and-respawn-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/callback-envelope-schema-validator.sh` | `dry_run_apply` | `tests/callback-envelope-schema-validator.sh`, `tests/callback-envelope-schema-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/callback-fix-bead-opener.sh` | `dry_run_apply` | `tests/callback-fix-bead-opener-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/callback-receipt-validator.sh` | `dry_run_apply` | `tests/callback-receipt-validator-canonical-cli.sh`, `tests/callback-receipt-validator-wrapper-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/callback-spool-reap.sh` | `dry_run_apply` | `tests/callback-spool-reap.sh`, `tests/callback-spool-reap-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/canonical-doctrine-sync.sh` | `dry_run_apply` | `tests/canonical-doctrine-sync-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/canonical-root-drift-fleet-check.sh` | `dry_run_apply` | `tests/canonical-root-drift-fleet-check.sh`, `tests/canonical-root-drift-fleet-check-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh` | `dry_run_apply` | `tests/capacity-halt-auto-continue-primitive-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/capacity-halt-lease-primitive.sh` | `dry_run_apply` | `tests/capacity-halt-lease-primitive-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/capacity-halt-pane-authorization.sh` | `dry_run_apply` | `tests/capacity-halt-pane-authorization-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/check-trauma-class-substrate.sh` | `dry_run_apply` | `tests/check-trauma-class-substrate-canonical-cli.sh`, `tests/check-trauma-class-substrate-test.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/clobber-recovery.sh` | `dry_run_apply` | `tests/clobber-recovery-smoke.sh`, `tests/clobber-recovery-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/codex-budget-probe.sh` | `dry_run_apply` | `tests/codex-budget-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/codex-budget-watchdog.sh` | `dry_run_apply` | `tests/codex-budget-watchdog-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/codex-death-event-classifier.sh` | `dry_run_apply` | `tests/codex-death-event-classifier-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh` | `dry_run_apply` | `tests/codex-queued-not-submitted-bare-enter-primitive-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/codex-template-stuck-detector.sh` | `dry_run_apply` | `tests/codex-template-stuck-detector.sh`, `tests/codex-template-stuck-detector-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/continuous-productivity-detector-install.sh` | `dry_run_apply` | `tests/continuous-productivity-detector-install-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/continuous-productivity-detector.sh` | `dry_run_apply` | `tests/continuous-productivity-detector-canonical-cli.sh`, `tests/continuous-productivity-detector-install-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/cost-telemetry-token-burn-probe.sh` | `dry_run_apply` | `tests/cost-telemetry-token-burn-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/cross-pane-git-probe.sh` | `dry_run_apply` | `tests/cross-pane-git-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/cross-repo-trauma-aggregator.sh` | `dry_run_apply` | `tests/cross-repo-trauma-aggregator.sh`, `tests/cross-repo-trauma-aggregator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/cross-session-worker-borrow.sh` | `dry_run_apply` | `tests/cross-session-worker-borrow-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/cross-skill-dependency-probe.sh` | `dry_run_apply` | `tests/cross-skill-dependency-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/cross-time-synthesis-probe.sh` | `dry_run_apply` | `tests/cross-time-synthesis-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/customer-facing-observability-probe.sh` | `dry_run_apply` | `tests/customer-facing-observability-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/daily-jeff-ingest.sh` | `dry_run_apply` | `tests/daily-jeff-ingest-dry-run-bounds.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/daily-report-enabled-repos.sh` | `dry_run_apply` | `tests/daily-report-enabled-repos-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/daily-report.sh` | `dry_run_apply` | `tests/daily-report.sh`, `tests/daily-report-canonical-cli.sh`, `tests/daily-report-enabled-repos-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/disk-reclaim-batch-2026-05-07.sh` | `dry_run_apply` | `tests/disk-reclaim-batch-2026-05-07-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/dispatch-and-log.sh` | `dry_run_apply` | `tests/dispatch-and-log-canonical-cli.sh`, `tests/dispatch-and-log-expected-by-test.sh`, `tests/dispatch-and-log-ntm-gates.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/dispatch-author-contract-probe.sh` | `dry_run_apply` | `tests/dispatch-author-contract-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/dispatch-canonical-cli-validator.sh` | `dry_run_apply` | `tests/dispatch-canonical-cli-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/dispatch-deferral-lint.sh` | `dry_run_apply` | `tests/dispatch-deferral-lint-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/dispatch-delivery-verify.sh` | `dry_run_apply` | `tests/dispatch-delivery-verify-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/dispatch-log-backfill-v2.sh` | `dry_run_apply` | `tests/dispatch-log-backfill-v2-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/dispatch-log-schema-validator.sh` | `dry_run_apply` | `tests/dispatch-log-schema-validator-tick-wire-in.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/dispatch-log-v2-violations-doctor.sh` | `dry_run_apply` | `tests/dispatch-log-v2-violations-doctor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/dispatch-self-test-delivery-identity.sh` | `dry_run_apply` | `tests/dispatch-self-test-delivery-identity-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/dispatch-surface-conflict-probe.sh` | `dry_run_apply` | `tests/dispatch-surface-conflict-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/dispatch-trigger-gated-precheck.sh` | `dry_run_apply` | `tests/dispatch-trigger-gated-precheck-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/docs-validation-probe.sh` | `dry_run_apply` | `tests/docs-validation-probe.sh`, `tests/docs-validation-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/doctrine-broadcast-send.sh` | `dry_run_apply` | `tests/doctrine-broadcast-send-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/doctrine-ladder-promote.sh` | `dry_run_apply` | `tests/doctrine-ladder-promote-canonical-cli.sh`, `tests/doctrine-ladder-promote-incidents-dedup-smoke.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/doctrine-sync.sh` | `dry_run_apply` | `tests/doctrine-sync-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/escalate-capsule-plan-consumer.sh` | `dry_run_apply` | `tests/escalate-capsule-plan-consumer-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/file-length-probe.sh` | `dry_run_apply` | `tests/file-length-probe.sh`, `tests/file-length-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh` | `dry_run_apply` | `tests/fleet-canonical-rule-freshness-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/fleet-coherence-alert.sh` | `dry_run_apply` | `tests/fleet-coherence-alert.sh`, `tests/fleet-coherence-alert-canonical-cli.sh`, `tests/fleet-coherence-alert-degraded.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/fleet-coherence-launchd.sh` | `dry_run_apply` | `tests/fleet-coherence-launchd.sh`, `tests/fleet-coherence-launchd-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/fleet-coherence-lib.sh` | `dry_run_apply` | `tests/fleet-coherence-lib-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/fleet-comms-health-probe.sh` | `dry_run_apply` | `tests/fleet-comms-health-probe.sh`, `tests/fleet-comms-health-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/fleet-conformance-probe.sh` | `dry_run_apply` | `tests/fleet-conformance-probe.sh`, `tests/fleet-conformance-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/fleet-process-gap-detector.sh` | `dry_run_apply` | `tests/fleet-process-gap-detector.sh`, `tests/fleet-process-gap-detector-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/fleet-rotate-all-sessions.sh` | `dry_run_apply` | `tests/fleet-rotate-all-sessions-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/flywheel-adopt.sh` | `dry_run_apply` | `tests/flywheel-adopt-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/flywheel-codex-stuck-detector-install.sh` | `dry_run_apply` | `tests/flywheel-codex-stuck-detector-install-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/flywheel-loop-doctor-stale-descendant-reaper.sh` | `dry_run_apply` | `tests/flywheel-loop-doctor-stale-descendant-reaper.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/flywheel-recovery.sh` | `dry_run_apply` | `tests/flywheel-recovery-canonical-cli.sh`, `tests/flywheel-recovery-session-paths.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/frozen-pane-backtest.sh` | `dry_run_apply` | `tests/frozen-pane-backtest-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/frozen-pane-detector-fleet.sh` | `dry_run_apply` | `tests/frozen-pane-detector-fleet.sh`, `tests/frozen-pane-detector-fleet-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/frozen-pane-detector.sh` | `dry_run_apply` | `tests/frozen-pane-detector-canonical-cli.sh`, `tests/frozen-pane-detector-apply-gate-test.sh`, `tests/frozen-pane-detector-fleet-canonical-cli.sh`, `tests/frozen-pane-detector-fleet.sh`, `tests/frozen-pane-detector-self-test.sh`, `tests/frozen-pane-detector-slo-thresholds.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/fs-rag-sibling-rollout.sh` | `dry_run_apply` | `tests/fs-rag-sibling-rollout-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/fuckup-coverage-join.sh` | `dry_run_apply` | `tests/fuckup-coverage-join.sh`, `tests/fuckup-coverage-join-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/gap-hunt-probe.sh` | `dry_run_apply` | `tests/gap-hunt-probe-canonical-cli.sh`, `tests/gap-hunt-probe-0h0b-suppression-smoke.sh`, `tests/gap-hunt-probe-dcg-rest-api-memory.sh`, `tests/gap-hunt-probe-dedup-canonical-cli.sh`, `tests/gap-hunt-probe-doctrine-corpus.sh`, `tests/gap-hunt-probe-exec-sh-corpus.sh`, `tests/gap-hunt-probe-for-loop-source-corpus.sh`, `tests/gap-hunt-probe-for-loop-source.sh`, `tests/gap-hunt-probe-on-demand-validator-allowlist.sh`, `tests/gap-hunt-probe-phantom-bead-suppression.sh`, `tests/gap-hunt-probe-skill-md-corpus.sh`, `tests/gap-hunt-probe-skill-tree-md-corpus.sh`, `tests/gap-hunt-probe-subprocess-validator-callsite.sh`, `tests/gap-hunt-probe-tests-allowlist.sh`, `tests/gap-hunt-probe-tests-tree-exclusion-canonical-cli.sh`, `tests/gap-hunt-probe-var-assigned-source.sh`, `tests/gap-hunt-probe-verify-ntm-send-memory.sh`, `tests/gap-hunt-probe-worker-tick-stable-tail-memory.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/git-main-sync.sh` | `dry_run_apply` | `tests/git-main-sync-smoke.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/halt-disease-watchdog.sh` | `dry_run_apply` | `tests/halt-disease-watchdog-canonical-cli.sh`, `tests/halt-disease-watchdog-native-test.sh`, `tests/halt-disease-watchdog-stream-output-test.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/handoff-skill-to-skillos.sh` | `dry_run_apply` | `tests/handoff-skill-to-skillos.sh`, `tests/handoff-skill-to-skillos-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/headless-browser-reap.sh` | `dry_run_apply` | `tests/headless-browser-reap-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/hub-blocker-detect.sh` | `dry_run_apply` | `tests/hub-blocker-detect.sh`, `tests/hub-blocker-detect-canonical-cli.sh`, `tests/hub-blocker-detect-idempotency-key.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/idempotency-replay-guard.sh` | `dry_run_apply` | `tests/idempotency-replay-guard-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/idle-pane-auto-dispatch.sh` | `dry_run_apply` | `tests/idle-pane-auto-dispatch-canonical-cli.sh`, `tests/idle-pane-auto-dispatch-closed-guard-test.sh`, `tests/idle-pane-auto-dispatch-validated-write-test.sh`, `tests/idle-pane-auto-dispatch-work-started-validation-test.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/idle-state-probe.sh` | `dry_run_apply` | `tests/idle-state-probe.sh`, `tests/idle-state-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/inject-doc-toc.sh` | `dry_run_apply` | `tests/inject-doc-toc-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/install-pane1-bridge-tailer-launchd.sh` | `dry_run_apply` | `tests/install-pane1-bridge-tailer-launchd.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-bead-285-divergence-capture.sh` | `dry_run_apply` | `tests/jeff-bead-285-divergence-capture-idempotency-key.sh`, `tests/jeff-bead-285-divergence-capture-introspection.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-binary-version-watchtower.sh` | `dry_run_apply` | `tests/jeff-binary-version-watchtower.sh`, `tests/jeff-binary-version-watchtower-canonical-cli.sh`, `tests/jeff-binary-version-watchtower-homebrew-sbh.sh`, `tests/jeff-binary-version-watchtower-sbh-binary.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-clone-symlink-converter.sh` | `dry_run_apply` | `tests/jeff-clone-symlink-converter-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-corpus-compact.sh` | `dry_run_apply` | `tests/jeff-corpus-compact-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-corpus-delta-reindex.sh` | `dry_run_apply` | `tests/jeff-corpus-delta-reindex-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-daily-diff.sh` | `dry_run_apply` | `tests/jeff-daily-diff.sh`, `tests/jeff-daily-diff-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-intel-digest-actionable.sh` | `dry_run_apply` | `tests/jeff-intel-digest-actionable-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-intel-network.sh` | `dry_run_apply` | `tests/jeff-intel-network.sh`, `tests/jeff-intel-network-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-intel-scheduled-runner.sh` | `dry_run_apply` | `tests/jeff-intel-scheduled-runner-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-issue-response-poll.sh` | `dry_run_apply` | `tests/jeff-issue-response-poll-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-pattern-citation-probe.sh` | `dry_run_apply` | `tests/jeff-pattern-citation-probe.sh`, `tests/jeff-pattern-citation-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-philosophy-mine.sh` | `dry_run_apply` | `tests/jeff-philosophy-mine.sh`, `tests/jeff-philosophy-mine-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-shadow-socraticode.sh` | `dry_run_apply` | `tests/jeff-shadow-socraticode.sh`, `tests/jeff-shadow-socraticode-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-verdict-heuristic.sh` | `dry_run_apply` | `tests/jeff-verdict-heuristic-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeff-workaround-research-gate.sh` | `dry_run_apply` | `tests/jeff-workaround-research-gate-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/jeffrey-comment-watchtower.sh` | `dry_run_apply` | `tests/jeffrey-comment-watchtower-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/l70-ticks-punted-counter.sh` | `dry_run_apply` | `tests/l70-ticks-punted-counter.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/low-bead-threshold-detector.sh` | `dry_run_apply` | `tests/low-bead-threshold-detector-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/mission-anchor-dispatch-license.sh` | `dry_run_apply` | `tests/mission-anchor-dispatch-license-test.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/mission-lock-negative-invariants-validator.sh` | `dry_run_apply` | `tests/mission-lock-negative-invariants-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/mission-lock-readiness-doctor.sh` | `dry_run_apply` | `tests/mission-lock-readiness-doctor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/mission-lock-scaffold-validator.sh` | `dry_run_apply` | `tests/mission-lock-scaffold-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/mobile-eats-end-user-health-probe.sh` | `dry_run_apply` | `tests/mobile-eats-end-user-health-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh` | `dry_run_apply` | `tests/mobile-eats-loop-with-receipt-mirror-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/ntm-approve-human-gates.sh` | `dry_run_apply` | `tests/ntm-approve-human-gates-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/ntm-coordinator-shadow.sh` | `dry_run_apply` | `tests/ntm-coordinator-shadow-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/ntm-fleet-health.sh` | `dry_run_apply` | `tests/ntm-fleet-health-canonical-cli.sh`, `tests/ntm-fleet-health-apply-gate-test.sh`, `tests/ntm-fleet-health-role-split.sh`, `tests/ntm-fleet-health-topology-regression.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/ntm-pane-sidecar-respawn.sh` | `dry_run_apply` | `tests/ntm-pane-sidecar-respawn.sh`, `tests/ntm-pane-sidecar-respawn-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/ntm-pipeline-shadow.sh` | `dry_run_apply` | `tests/ntm-pipeline-shadow-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/ntm-preflight-l91-wrapper.sh` | `dry_run_apply` | `tests/ntm-preflight-l91-wrapper-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/ntm-safety-dcg-sibling.sh` | `dry_run_apply` | `tests/ntm-safety-dcg-sibling-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/ntm-scrub-secret-scan-wrapper.sh` | `dry_run_apply` | `tests/ntm-scrub-secret-scan-wrapper-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/ntm-surface-coverage-trend.sh` | `dry_run_apply` | `tests/ntm-surface-coverage-trend-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/ntm-surface-validation-driver.sh` | `dry_run_apply` | `tests/ntm-surface-validation-driver-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/ntm-wave2-native-probes.sh` | `dry_run_apply` | `tests/ntm-wave2-native-probes-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/orch-agent-mail-session-register.sh` | `dry_run_apply` | `tests/orch-agent-mail-session-register.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/orch-worker-identity-manifest.sh` | `dry_run_apply` | `tests/orch-worker-identity-manifest.sh`, `tests/orch-worker-identity-manifest-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/orchestrator-callback-artifact-fix-bead.sh` | `dry_run_apply` | `tests/orchestrator-callback-artifact-fix-bead-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/orchestrator-callback-artifact-validator.sh` | `dry_run_apply` | `tests/orchestrator-callback-artifact-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/peer-orch-blocker-watch.sh` | `dry_run_apply` | `tests/peer-orch-blocker-watch.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/peer-orch-freeze-monitor.sh` | `dry_run_apply` | `tests/peer-orch-freeze-monitor.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/peer-orch-respawn-permit.sh` | `dry_run_apply` | `tests/peer-orch-respawn-permit.sh`, `tests/peer-orch-respawn-permit-canonical-cli-test.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/picoz-archive-and-fresh-2026-05-07.sh` | `dry_run_apply` | `tests/picoz-archive-and-fresh-2026-05-07-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/plan-state-lens-merge.sh` | `dry_run_apply` | `tests/plan-state-lens-merge-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/plan-to-bead-auto-trigger.sh` | `dry_run_apply` | `tests/plan-to-bead-auto-trigger-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/polish-preflight-quality-gate.sh` | `dry_run_apply` | `tests/polish-preflight-quality-gate-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/pre-dispatch-state-db-lock-check.sh` | `dry_run_apply` | `tests/pre-dispatch-state-db-lock-check-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/private-tmp-prune.sh` | `dry_run_apply` | `tests/private-tmp-prune.sh`, `tests/private-tmp-prune-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/promotion-candidate-stale-fire-reaper.sh` | `dry_run_apply` | `tests/promotion-candidate-stale-fire-reaper-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/public-artifact-pipeline-probe.sh` | `dry_run_apply` | `tests/public-artifact-pipeline-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/quality-bar-close-gate.sh` | `dry_run_apply` | `tests/quality-bar-close-gate.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/recovery-baseline-snapshot.sh` | `dry_run_apply` | `tests/recovery-baseline-snapshot-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/recovery-baseline-status.sh` | `dry_run_apply` | `tests/recovery-baseline-status-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/recovery-doctor-probe.sh` | `dry_run_apply` | `tests/recovery-doctor-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/recovery-escape-then-reprompt.sh` | `dry_run_apply` | `tests/recovery-escape-then-reprompt-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/recovery-install-plist-alpsinsurance.sh` | `dry_run_apply` | `tests/recovery-install-plist-alpsinsurance-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/recovery-install-plist-clutterfreespaces.sh` | `dry_run_apply` | `tests/recovery-install-plist-clutterfreespaces-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/recovery-install-plist-mobile-eats.sh` | `dry_run_apply` | `tests/recovery-install-plist-mobile-eats-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/recovery-install-plist-skillos.sh` | `dry_run_apply` | `tests/recovery-install-plist-skillos-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/recovery-preinstall-audit.sh` | `dry_run_apply` | `tests/recovery-preinstall-audit-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/recovery-restore-harness.sh` | `dry_run_apply` | `tests/recovery-restore-harness-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/regenerate-dicklesworthstone-sources.sh` | `dry_run_apply` | `tests/regenerate-dicklesworthstone-sources.sh`, `tests/regenerate-dicklesworthstone-sources-idempotency-key.sh`, `tests/regenerate-dicklesworthstone-sources-known-silos-registry.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/rule-hint-lifecycle.sh` | `dry_run_apply` | `tests/rule-hint-lifecycle.sh`, `tests/rule-hint-lifecycle-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/scaffold-canonical-cli.sh` | `dry_run_apply` | `tests/scaffold-canonical-cli-apply-gate-regression.sh`, `tests/scaffold-canonical-cli-bugfix-bundle.sh`, `tests/scaffold-canonical-cli-e2e.sh`, `tests/scaffold-canonical-cli-flag-collision.sh`, `tests/scaffold-canonical-cli-shebang-guard.sh`, `tests/scaffold-canonical-cli-verb-collision-regression.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/security-precommit-installer.sh` | `dry_run_apply` | `tests/security-precommit-installer-idempotency-key.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/shared-surface-reservation-check.sh` | `dry_run_apply` | `tests/shared-surface-reservation-check.sh`, `tests/shared-surface-reservation-check-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/skill-bandit-measurement-probe.sh` | `dry_run_apply` | `tests/skill-bandit-measurement-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/skill-enhance-jsm-discipline.sh` | `dry_run_apply` | `tests/skill-enhance-jsm-discipline.sh`, `tests/skill-enhance-jsm-discipline-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/skillos-routed-tail.sh` | `dry_run_apply` | `tests/skillos-routed-tail-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/skillos-template-handshake.sh` | `dry_run_apply` | `tests/skillos-template-handshake-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/stale-error-auto-ping.sh` | `dry_run_apply` | `tests/stale-error-auto-ping.sh`, `tests/stale-error-auto-ping-idempotency-key.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/stale-in-progress-reaper.sh` | `dry_run_apply` | `tests/stale-in-progress-reaper.sh`, `tests/stale-in-progress-reaper-carve-out.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/state-md-miner.sh` | `dry_run_apply` | `tests/state-md-miner.sh`, `tests/state-md-miner-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/state-store-authority-probe.sh` | `dry_run_apply` | `tests/state-store-authority-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/storage-headroom-watcher.sh` | `dry_run_apply` | `tests/storage-headroom-watcher.sh`, `tests/storage-headroom-watcher-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/storage-pause-auto-resume.sh` | `dry_run_apply` | `tests/storage-pause-auto-resume.sh`, `tests/storage-pause-auto-resume-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/storage-pressure-doctor.sh` | `dry_run_apply` | `tests/storage-pressure-doctor.sh`, `tests/storage-pressure-doctor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/storage-probe.sh` | `dry_run_apply` | `tests/storage-probe.sh`, `tests/storage-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/storage-prune.sh` | `dry_run_apply` | `tests/storage-prune-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/substrate-loop-contract-validator.sh` | `dry_run_apply` | `tests/substrate-loop-contract-validator.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/supabase-rls-emergency-fix.sh` | `default_dry_run_apply` | `tests/supabase-rls-emergency-fix.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/sync-canonical-doctrine.sh` | `dry_run_apply` | `tests/sync-canonical-doctrine-doctor.sh`, `tests/sync-canonical-doctrine-idempotency-key.sh`, `tests/sync-canonical-doctrine-introspection.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/sync-four-lens-validator.sh` | `dry_run_apply` | `tests/sync-four-lens-validator.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/team-pulse-heartbeat.sh` | `dry_run_apply` | `tests/team-pulse-heartbeat.sh`, `tests/team-pulse-heartbeat-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/team-roster-watch.sh` | `dry_run_apply` | `tests/team-roster-watch-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/tentacle-drift-sweep.sh` | `dry_run_apply` | `tests/tentacle-drift-sweep.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/tentacle-inventory-bump.sh` | `dry_run_apply` | `tests/tentacle-inventory-bump-atomic-fixture.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/test-agent-mail-redact.sh` | `dry_run_apply` | `tests/test-agent-mail-redact-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/test-auto-respawn.sh` | `dry_run_apply` | `tests/test-auto-respawn.sh`, `tests/test-auto-respawn-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/test-doctor-empty-errors.sh` | `dry_run_apply` | `tests/test-doctor-empty-errors-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/test-fuckup-join.sh` | `dry_run_apply` | `tests/test-fuckup-join-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/test-loop-driver-doctor.sh` | `dry_run_apply` | `tests/test-loop-driver-doctor-canonical-cli.sh`, `tests/test-loop-driver-doctor-no-cass-check.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/test-safe-probe.sh` | `dry_run_apply` | `tests/test-safe-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/test-skillos-bridge.sh` | `dry_run_apply` | `tests/test-skillos-bridge-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/test-sync-canonical-doctrine.sh` | `dry_run_apply` | `tests/test-sync-canonical-doctrine-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/test-sync-stamped-repos-coverage.sh` | `dry_run_apply` | `tests/test-sync-stamped-repos-coverage-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/tick-hook-firing-verifier.sh` | `dry_run_apply` | `tests/tick-hook-firing-verifier.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/tick-skill-version-check.sh` | `dry_run_apply` | `tests/tick-skill-version-check-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/tmp-aggressive-prune.sh` | `dry_run_apply` | `tests/test-tmp-aggressive-prune.sh`, `tests/tmp-aggressive-prune-doctor.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/tmp-prune.sh` | `dry_run_apply` | `tests/tmp-prune-canonical-cli.sh`, `tests/test-tmp-prune.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/topology-tick-refresh.sh` | `dry_run_apply` | `tests/topology-tick-refresh.sh`, `tests/topology-tick-refresh-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/trauma-handoff.sh` | `dry_run_apply` | `tests/trauma-handoff-agent-mail-send.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/validate-callback-before-close.sh` | `dry_run_apply` | `tests/validate-callback-before-close.sh`, `tests/validate-callback-before-close-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/validate-skill-discovery-callback.sh` | `dry_run_apply` | `tests/validate-skill-discovery-callback-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/value-gap-probe.sh` | `dry_run_apply` | `tests/value-gap-probe.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/verify-watcher-launchd-active.sh` | `dry_run_apply` | `tests/verify-watcher-launchd-active-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/watcher-isomorphic-probe.sh` | `dry_run_apply` | `tests/watcher-isomorphic-probe.sh`, `tests/watcher-isomorphic-probe-fleet.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/worker-auto-respawn-watchdog-install.sh` | `dry_run_apply` | `tests/worker-auto-respawn-watchdog-install-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/worker-auto-respawn-watchdog.sh` | `dry_run_apply` | `tests/worker-auto-respawn-watchdog-canonical-cli.sh`, `tests/worker-auto-respawn-watchdog-install-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/worker-deep-liveness-probe-launchd-install.sh` | `dry_run_apply` | `tests/worker-deep-liveness-probe-launchd-install-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/worker-head-verify.sh` | `dry_run_apply` | `tests/worker-head-verify-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/worker-stall-alert-probe.sh` | `dry_run_apply` | `tests/worker-stall-alert-probe.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `.flywheel/scripts/worker-tick-jsm-outcomes.sh` | `dry_run_apply` | `tests/worker-tick-jsm-outcomes-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/abs-target-canonical-cli.sh` | `dry_run_apply` | `tests/abs-target-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/adversarial-orch-self-audit-probe-canonical-cli.sh` | `dry_run_apply` | `tests/adversarial-orch-self-audit-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-14423-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-14423-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-1725-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-1725-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-20800-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-20800-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-21313-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-21313-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-28756-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-28756-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-32174-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-32174-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-32693-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-32693-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-45987-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-45987-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-56679-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-56679-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-5780-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-5780-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-58117-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-58117-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-73998-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-73998-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-83848-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-83848-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ag2-fixture-90723-canonical-cli.sh` | `dry_run_apply` | `tests/ag2-fixture-90723-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/agent-mail-pre-allocate-worker-identities-canonical-cli.sh` | `dry_run_apply` | `tests/agent-mail-pre-allocate-worker-identities-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/agent-mail-restart-canonical-cli.sh` | `dry_run_apply` | `tests/agent-mail-restart-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/agent-mail-restart.sh` | `default_dry_run_apply` | `tests/agent-mail-restart.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/agent-mail-send-redacted-canonical-cli.sh` | `dry_run_apply` | `tests/agent-mail-send-redacted-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/agentmail-identity-canonical-validator-canonical-cli.sh` | `dry_run_apply` | `tests/agentmail-identity-canonical-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/agents-md-fleet-propagator-canonical-cli.sh` | `dry_run_apply` | `tests/agents-md-fleet-propagator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/agents-md-fleet-propagator.sh` | `default_dry_run_apply` | `tests/agents-md-fleet-propagator.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/agents-md-shard-extract-canonical-cli.sh` | `dry_run_apply` | `tests/agents-md-shard-extract-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/append-safe-write-canonical-cli.sh` | `dry_run_apply` | `tests/append-safe-write-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/apply-substrate-tuning-canonical-cli.sh` | `dry_run_apply` | `tests/apply-substrate-tuning-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/apply-tmux-tuning-canonical-cli.sh` | `dry_run_apply` | `tests/apply-tmux-tuning-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/auto-l112-gate-canonical-cli.sh` | `dry_run_apply` | `tests/auto-l112-gate-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/auto-refill-decision-log-canonical-cli.sh` | `dry_run_apply` | `tests/auto-refill-decision-log-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/auto-respawn-detector-canonical-cli.sh` | `dry_run_apply` | `tests/auto-respawn-detector-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-14423-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-14423-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-1725-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-1725-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-20800-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-20800-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-21313-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-21313-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-28756-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-28756-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-32174-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-32174-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-32693-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-32693-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-45987-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-45987-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-56679-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-56679-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-5780-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-5780-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-58117-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-58117-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-73998-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-73998-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-83848-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-83848-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-a-90723-canonical-cli.sh` | `dry_run_apply` | `tests/bak-a-90723-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-14423-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-14423-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-1725-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-1725-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-20800-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-20800-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-21313-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-21313-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-28756-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-28756-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-32174-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-32174-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-32693-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-32693-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-45987-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-45987-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-56679-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-56679-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-5780-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-5780-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-58117-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-58117-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-73998-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-73998-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-83848-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-83848-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bak-b-90723-canonical-cli.sh` | `dry_run_apply` | `tests/bak-b-90723-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bash_abs-canonical-cli.sh` | `dry_run_apply` | `tests/bash_abs-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bash_env-canonical-cli.sh` | `dry_run_apply` | `tests/bash_env-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bcv-task-harness-canonical-cli.sh` | `dry_run_apply` | `tests/bcv-task-harness-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bead-blocker-sync.sh` | `dry_run_apply` | `tests/bead-blocker-sync.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bead-evidence-indexer-canonical-cli.sh` | `dry_run_apply` | `tests/bead-evidence-indexer-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/beads-db-recover-canonical-cli.sh` | `dry_run_apply` | `tests/beads-db-recover-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/beads-db-recover.sh` | `dry_run_apply` | `tests/beads-db-recover.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/beads-mem-tmp-cleanup.sh` | `dry_run_apply` | `tests/beads-mem-tmp-cleanup.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/bleed-ledger-watch-canonical-cli.sh` | `dry_run_apply` | `tests/bleed-ledger-watch-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/blocker-ac-tick-cadence-canonical-cli.sh` | `dry_run_apply` | `tests/blocker-ac-tick-cadence-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/blocker-auto-close.sh` | `default_dry_run_apply` | `tests/blocker-auto-close.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/blocker-discipline-tick-chain.sh` | `default_dry_run_apply` | `tests/blocker-discipline-tick-chain.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/blocker-fail-escalator.sh` | `default_dry_run_apply` | `tests/blocker-fail-escalator.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/br-authority-probe-canonical-cli.sh` | `dry_run_apply` | `tests/br-authority-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/br-close-with-gate-canonical-cli.sh` | `dry_run_apply` | `tests/br-close-with-gate-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/br-db-corruption-monitor-canonical-cli.sh` | `dry_run_apply` | `tests/br-db-corruption-monitor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/build-dispatch-packet-canonical-cli.sh` | `dry_run_apply` | `tests/build-dispatch-packet-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/caam-rotate-and-respawn-canonical-cli.sh` | `dry_run_apply` | `tests/caam-rotate-and-respawn-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/callback-envelope-schema-validator-canonical-cli.sh` | `dry_run_apply` | `tests/callback-envelope-schema-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/callback-fix-bead-opener-canonical-cli.sh` | `dry_run_apply` | `tests/callback-fix-bead-opener-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/callback-receipt-validator-canonical-cli.sh` | `dry_run_apply` | `tests/callback-receipt-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/callback-receipt-validator-wrapper-canonical-cli.sh` | `dry_run_apply` | `tests/callback-receipt-validator-wrapper-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/callback-spool-reap-canonical-cli.sh` | `dry_run_apply` | `tests/callback-spool-reap-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/callback-spool-reap.sh` | `dry_run_apply` | `tests/callback-spool-reap.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/canonical-cli-lint-l9.sh` | `default_dry_run_apply` | `tests/canonical-cli-lint-l9.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/canonical-cli-lint-precommit.sh` | `dry_run_apply` | `tests/canonical-cli-lint-precommit.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/canonical-root-drift-fleet-check-canonical-cli.sh` | `dry_run_apply` | `tests/canonical-root-drift-fleet-check-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/capacity-halt-auto-continue-primitive-canonical-cli.sh` | `dry_run_apply` | `tests/capacity-halt-auto-continue-primitive-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/capacity-halt-lease-primitive-canonical-cli.sh` | `dry_run_apply` | `tests/capacity-halt-lease-primitive-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/capacity-halt-pane-authorization-canonical-cli.sh` | `dry_run_apply` | `tests/capacity-halt-pane-authorization-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/check-trauma-class-substrate-canonical-cli.sh` | `dry_run_apply` | `tests/check-trauma-class-substrate-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/cleanup-scratch.sh` | `dry_run_apply` | `tests/cleanup-scratch.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/clobber-recovery-canonical-cli.sh` | `dry_run_apply` | `tests/clobber-recovery-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/closed-bead-artifact-scan.sh` | `dry_run_apply` | `tests/closed-bead-artifact-scan.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/codex-budget-probe-canonical-cli.sh` | `dry_run_apply` | `tests/codex-budget-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/codex-budget-watchdog-canonical-cli.sh` | `dry_run_apply` | `tests/codex-budget-watchdog-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/codex-death-event-classifier-canonical-cli.sh` | `dry_run_apply` | `tests/codex-death-event-classifier-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/codex-queued-not-submitted-bare-enter-primitive-canonical-cli.sh` | `dry_run_apply` | `tests/codex-queued-not-submitted-bare-enter-primitive-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/codex-template-stuck-detector-canonical-cli.sh` | `dry_run_apply` | `tests/codex-template-stuck-detector-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/collision-fixture-canonical-cli.sh` | `dry_run_apply` | `tests/collision-fixture-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/concurrent-a-canonical-cli.sh` | `dry_run_apply` | `tests/concurrent-a-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/concurrent-b-canonical-cli.sh` | `dry_run_apply` | `tests/concurrent-b-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/continuous-productivity-detector-canonical-cli.sh` | `dry_run_apply` | `tests/continuous-productivity-detector-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/continuous-productivity-detector-install-canonical-cli.sh` | `dry_run_apply` | `tests/continuous-productivity-detector-install-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/cost-telemetry-token-burn-probe-canonical-cli.sh` | `dry_run_apply` | `tests/cost-telemetry-token-burn-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/cross-pane-git-probe-canonical-cli.sh` | `dry_run_apply` | `tests/cross-pane-git-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/cross-repo-trauma-aggregator-canonical-cli.sh` | `dry_run_apply` | `tests/cross-repo-trauma-aggregator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/cross-session-worker-borrow-canonical-cli.sh` | `dry_run_apply` | `tests/cross-session-worker-borrow-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/cross-skill-dependency-probe-canonical-cli.sh` | `dry_run_apply` | `tests/cross-skill-dependency-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/cross-time-synthesis-probe-canonical-cli.sh` | `dry_run_apply` | `tests/cross-time-synthesis-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/customer-facing-observability-probe-canonical-cli.sh` | `dry_run_apply` | `tests/customer-facing-observability-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/daily-report-canonical-cli.sh` | `dry_run_apply` | `tests/daily-report-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/daily-report-enabled-repos-canonical-cli.sh` | `dry_run_apply` | `tests/daily-report-enabled-repos-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/depersonalize-table-codemod.sh` | `dry_run_apply` | `tests/depersonalize-table-codemod.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/dicklesworthstone-signal-gate.sh` | `dry_run_apply` | `tests/dicklesworthstone-signal-gate.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/disk-reclaim-batch-2026-05-07-canonical-cli.sh` | `dry_run_apply` | `tests/disk-reclaim-batch-2026-05-07-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/dispatch-and-log-canonical-cli.sh` | `dry_run_apply` | `tests/dispatch-and-log-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/dispatch-author-contract-probe-canonical-cli.sh` | `dry_run_apply` | `tests/dispatch-author-contract-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/dispatch-canonical-cli-validator-canonical-cli.sh` | `dry_run_apply` | `tests/dispatch-canonical-cli-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/dispatch-deferral-lint-canonical-cli.sh` | `dry_run_apply` | `tests/dispatch-deferral-lint-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/dispatch-delivery-verify-canonical-cli.sh` | `dry_run_apply` | `tests/dispatch-delivery-verify-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/dispatch-log-backfill-v2-canonical-cli.sh` | `dry_run_apply` | `tests/dispatch-log-backfill-v2-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/dispatch-log-v2-violations-doctor-canonical-cli.sh` | `dry_run_apply` | `tests/dispatch-log-v2-violations-doctor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/dispatch-self-test-delivery-identity-canonical-cli.sh` | `dry_run_apply` | `tests/dispatch-self-test-delivery-identity-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/dispatch-surface-conflict-probe-canonical-cli.sh` | `dry_run_apply` | `tests/dispatch-surface-conflict-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/dispatch-trigger-gated-precheck-canonical-cli.sh` | `dry_run_apply` | `tests/dispatch-trigger-gated-precheck-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/docs-validation-probe-canonical-cli.sh` | `dry_run_apply` | `tests/docs-validation-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/doctrine-broadcast-send-canonical-cli.sh` | `dry_run_apply` | `tests/doctrine-broadcast-send-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/doctrine-ladder-promote-canonical-cli.sh` | `dry_run_apply` | `tests/doctrine-ladder-promote-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/doctrine-sync-canonical-cli.sh` | `dry_run_apply` | `tests/doctrine-sync-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/empty-canonical-cli.sh` | `dry_run_apply` | `tests/empty-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/escalate-capsule-plan-consumer-canonical-cli.sh` | `dry_run_apply` | `tests/escalate-capsule-plan-consumer-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/file-length-probe-canonical-cli.sh` | `dry_run_apply` | `tests/file-length-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/file-rag-discipline-lint.sh` | `default_dry_run_apply` | `tests/file-rag-discipline-lint.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-canonical-rule-freshness-probe-canonical-cli.sh` | `dry_run_apply` | `tests/fleet-canonical-rule-freshness-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-coherence-alert-canonical-cli.sh` | `dry_run_apply` | `tests/fleet-coherence-alert-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-coherence-launchd-canonical-cli.sh` | `dry_run_apply` | `tests/fleet-coherence-launchd-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-coherence-launchd.sh` | `dry_run_apply` | `tests/fleet-coherence-launchd.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-coherence-lib-canonical-cli.sh` | `dry_run_apply` | `tests/fleet-coherence-lib-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-comms-health-probe-canonical-cli.sh` | `dry_run_apply` | `tests/fleet-comms-health-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-comms-health-probe.sh` | `default_dry_run_apply` | `tests/fleet-comms-health-probe.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-conductor-mvp-gate.sh` | `dry_run_apply` | `tests/fleet-conductor-mvp-gate.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-conformance-probe-canonical-cli.sh` | `dry_run_apply` | `tests/fleet-conformance-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-conformance-probe.sh` | `dry_run_apply` | `tests/fleet-conformance-probe.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-process-gap-detector-canonical-cli.sh` | `dry_run_apply` | `tests/fleet-process-gap-detector-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-process-gap-detector.sh` | `dry_run_apply` | `tests/fleet-process-gap-detector.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-rotate-all-sessions-canonical-cli.sh` | `dry_run_apply` | `tests/fleet-rotate-all-sessions-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fleet-shutdown-recovery.sh` | `dry_run_apply` | `tests/fleet-shutdown-recovery.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-adopt-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-adopt-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-agents-pointer-sweep-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-agents-pointer-sweep-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-anchor-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-anchor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-autoloop-canonical-cli-scaffold.sh` | `dry_run_apply` | `tests/flywheel-autoloop-canonical-cli-scaffold.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-autoloop-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-autoloop-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-cass-correlate-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-cass-correlate-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-check-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-check-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-codex-orient-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-codex-orient-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-codex-snapshot-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-codex-snapshot-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-codex-stuck-detector-install-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-codex-stuck-detector-install-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-conductor-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-conductor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-dashboard-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-dashboard-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-digest-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-digest-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-doctrine-sync-canonical-cli-scaffold.sh` | `dry_run_apply` | `tests/flywheel-doctrine-sync-canonical-cli-scaffold.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-domain-spec-validate-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-domain-spec-validate-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-friday-digest-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-friday-digest-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-inject-latest-line-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-inject-latest-line-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-install-hooks-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-install-hooks-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-lock-repair-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-lock-repair-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-loop-doctor-stale-descendant-reaper.sh` | `dry_run_apply` | `tests/flywheel-loop-doctor-stale-descendant-reaper.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-loop-repair-beads-db-health.sh` | `dry_run_apply` | `tests/flywheel-loop-repair-beads-db-health.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-outcome-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-outcome-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-pattern-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-pattern-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-quality-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-quality-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-quality-gate-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-quality-gate-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-recovery-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-recovery-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-recovery-session-paths.sh` | `dry_run_apply` | `tests/flywheel-recovery-session-paths.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-render-latest-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-render-latest-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-source-monitor-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-source-monitor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-stale-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-stale-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-summarize-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-summarize-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-sync-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-sync-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-trauma-check-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-trauma-check-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-verdict-canonical-cli.sh` | `dry_run_apply` | `tests/flywheel-verdict-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-watchers-allowlist-test.sh` | `dry_run_apply` | `tests/flywheel-watchers-allowlist-test.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/flywheel-watchers-test.sh` | `dry_run_apply` | `tests/flywheel-watchers-test.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/foo-bash-canonical-cli.sh` | `dry_run_apply` | `tests/foo-bash-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/frozen-pane-backtest-canonical-cli.sh` | `dry_run_apply` | `tests/frozen-pane-backtest-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/frozen-pane-detector-canonical-cli.sh` | `dry_run_apply` | `tests/frozen-pane-detector-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/frozen-pane-detector-fleet.sh` | `dry_run_apply` | `tests/frozen-pane-detector-fleet.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/frozen-pane-detector-self-test.sh` | `dry_run_apply` | `tests/frozen-pane-detector-self-test.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fs-rag-sibling-rollout-canonical-cli.sh` | `dry_run_apply` | `tests/fs-rag-sibling-rollout-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/fuckup-coverage-join-canonical-cli.sh` | `dry_run_apply` | `tests/fuckup-coverage-join-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/gap-hunt-probe-canonical-cli.sh` | `dry_run_apply` | `tests/gap-hunt-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/git-main-sync-smoke.sh` | `dry_run_apply` | `tests/git-main-sync-smoke.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/halt-disease-watchdog-canonical-cli.sh` | `dry_run_apply` | `tests/halt-disease-watchdog-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/handoff-skill-to-skillos-canonical-cli.sh` | `dry_run_apply` | `tests/handoff-skill-to-skillos-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/headless-browser-probe.sh` | `dry_run_apply` | `tests/headless-browser-probe.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/headless-browser-reap-canonical-cli.sh` | `dry_run_apply` | `tests/headless-browser-reap-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/hub-blocker-detect-canonical-cli.sh` | `dry_run_apply` | `tests/hub-blocker-detect-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/hub-blocker-detect-idempotency-key.sh` | `default_dry_run_apply` | `tests/hub-blocker-detect-idempotency-key.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/idempotency-replay-guard-canonical-cli.sh` | `dry_run_apply` | `tests/idempotency-replay-guard-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/idle-pane-auto-dispatch-canonical-cli.sh` | `dry_run_apply` | `tests/idle-pane-auto-dispatch-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/idle-pane-auto-dispatch-validated-write-test.sh` | `dry_run_apply` | `tests/idle-pane-auto-dispatch-validated-write-test.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/idle-state-probe-canonical-cli.sh` | `dry_run_apply` | `tests/idle-state-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/inject-skill-auto-routes-canonical-cli.sh` | `dry_run_apply` | `tests/inject-skill-auto-routes-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/install-pane1-bridge-tailer-launchd.sh` | `dry_run_apply` | `tests/install-pane1-bridge-tailer-launchd.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-bead-285-divergence-capture-idempotency-key.sh` | `dry_run_apply` | `tests/jeff-bead-285-divergence-capture-idempotency-key.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-bead-285-divergence-capture-introspection.sh` | `default_dry_run_apply` | `tests/jeff-bead-285-divergence-capture-introspection.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-binary-version-watchtower-canonical-cli.sh` | `dry_run_apply` | `tests/jeff-binary-version-watchtower-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-binary-version-watchtower.sh` | `dry_run_apply` | `tests/jeff-binary-version-watchtower.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-clone-symlink-converter-canonical-cli.sh` | `default_dry_run_apply` | `tests/jeff-clone-symlink-converter-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-corpus-accretive.sh` | `dry_run_apply` | `tests/jeff-corpus-accretive.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-corpus-compact-canonical-cli.sh` | `dry_run_apply` | `tests/jeff-corpus-compact-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-corpus-delta-reindex-canonical-cli.sh` | `dry_run_apply` | `tests/jeff-corpus-delta-reindex-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-daily-diff-canonical-cli.sh` | `dry_run_apply` | `tests/jeff-daily-diff-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-intel-digest-actionable-canonical-cli.sh` | `dry_run_apply` | `tests/jeff-intel-digest-actionable-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-intel-network.sh` | `dry_run_apply` | `tests/jeff-intel-network.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-intel-schedule.sh` | `dry_run_apply` | `tests/jeff-intel-schedule.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-issue-response-poll-canonical-cli.sh` | `dry_run_apply` | `tests/jeff-issue-response-poll-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-issue.sh` | `dry_run_apply` | `tests/jeff-issue.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-philosophy-mine-canonical-cli.sh` | `dry_run_apply` | `tests/jeff-philosophy-mine-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-shadow-socraticode-canonical-cli.sh` | `dry_run_apply` | `tests/jeff-shadow-socraticode-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/jeff-verdict-heuristic-canonical-cli.sh` | `dry_run_apply` | `tests/jeff-verdict-heuristic-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/low-bead-threshold-detector-canonical-cli.sh` | `dry_run_apply` | `tests/low-bead-threshold-detector-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/mission-lock-negative-invariants-validator-canonical-cli.sh` | `dry_run_apply` | `tests/mission-lock-negative-invariants-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/mission-lock-readiness-doctor-canonical-cli.sh` | `dry_run_apply` | `tests/mission-lock-readiness-doctor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/mission-lock-scaffold-validator-canonical-cli.sh` | `dry_run_apply` | `tests/mission-lock-scaffold-validator-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/mobile-eats-end-user-health-probe-canonical-cli.sh` | `dry_run_apply` | `tests/mobile-eats-end-user-health-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/mobile-eats-loop-with-receipt-mirror-canonical-cli.sh` | `dry_run_apply` | `tests/mobile-eats-loop-with-receipt-mirror-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/npm-install-guard-canonical-cli.sh` | `dry_run_apply` | `tests/npm-install-guard-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-approve-human-gates-canonical-cli.sh` | `dry_run_apply` | `tests/ntm-approve-human-gates-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-coordinator-shadow-canonical-cli.sh` | `dry_run_apply` | `tests/ntm-coordinator-shadow-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-fleet-health-canonical-cli.sh` | `dry_run_apply` | `tests/ntm-fleet-health-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-pane-sidecar-respawn-canonical-cli.sh` | `dry_run_apply` | `tests/ntm-pane-sidecar-respawn-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-pane-sidecar-respawn.sh` | `dry_run_apply` | `tests/ntm-pane-sidecar-respawn.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-pipeline-shadow-canonical-cli.sh` | `dry_run_apply` | `tests/ntm-pipeline-shadow-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-preflight-l91-wrapper-canonical-cli.sh` | `dry_run_apply` | `tests/ntm-preflight-l91-wrapper-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-safety-dcg-sibling-canonical-cli.sh` | `dry_run_apply` | `tests/ntm-safety-dcg-sibling-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-scrub-secret-scan-wrapper-canonical-cli.sh` | `dry_run_apply` | `tests/ntm-scrub-secret-scan-wrapper-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-surface-coverage-trend-canonical-cli.sh` | `dry_run_apply` | `tests/ntm-surface-coverage-trend-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-surface-validation-driver-canonical-cli.sh` | `dry_run_apply` | `tests/ntm-surface-validation-driver-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/ntm-wave2-native-probes-canonical-cli.sh` | `dry_run_apply` | `tests/ntm-wave2-native-probes-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/orch-worker-identity-manifest-canonical-cli.sh` | `dry_run_apply` | `tests/orch-worker-identity-manifest-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/orch-worker-identity-manifest.sh` | `dry_run_apply` | `tests/orch-worker-identity-manifest.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/peer-orch-productivity-watch.sh` | `default_dry_run_apply` | `tests/peer-orch-productivity-watch.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/peer-orch-respawn-permit.sh` | `dry_run_apply` | `tests/peer-orch-respawn-permit.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/picoz-archive-and-fresh-2026-05-07-canonical-cli.sh` | `dry_run_apply` | `tests/picoz-archive-and-fresh-2026-05-07-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/plan-to-bead-auto-trigger-canonical-cli.sh` | `dry_run_apply` | `tests/plan-to-bead-auto-trigger-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/polish-preflight-quality-gate-canonical-cli.sh` | `dry_run_apply` | `tests/polish-preflight-quality-gate-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/pre-dispatch-state-db-lock-check-canonical-cli.sh` | `dry_run_apply` | `tests/pre-dispatch-state-db-lock-check-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/private-tmp-prune-canonical-cli.sh` | `dry_run_apply` | `tests/private-tmp-prune-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/private-tmp-prune.sh` | `dry_run_apply` | `tests/private-tmp-prune.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/promotion-candidate-stale-fire-reaper-canonical-cli.sh` | `dry_run_apply` | `tests/promotion-candidate-stale-fire-reaper-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/public-artifact-pipeline-probe-canonical-cli.sh` | `dry_run_apply` | `tests/public-artifact-pipeline-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/quality-bar-close-gate.sh` | `dry_run_apply` | `tests/quality-bar-close-gate.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/recovery-baseline-snapshot-canonical-cli.sh` | `dry_run_apply` | `tests/recovery-baseline-snapshot-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/recovery-baseline-status-canonical-cli.sh` | `dry_run_apply` | `tests/recovery-baseline-status-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/recovery-doctor-probe-canonical-cli.sh` | `dry_run_apply` | `tests/recovery-doctor-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/recovery-escape-then-reprompt-canonical-cli.sh` | `dry_run_apply` | `tests/recovery-escape-then-reprompt-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/recovery-install-plist-alpsinsurance-canonical-cli.sh` | `dry_run_apply` | `tests/recovery-install-plist-alpsinsurance-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/recovery-install-plist-clutterfreespaces-canonical-cli.sh` | `dry_run_apply` | `tests/recovery-install-plist-clutterfreespaces-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/recovery-install-plist-mobile-eats-canonical-cli.sh` | `dry_run_apply` | `tests/recovery-install-plist-mobile-eats-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/recovery-install-plist-skillos-canonical-cli.sh` | `dry_run_apply` | `tests/recovery-install-plist-skillos-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/recovery-preinstall-audit-canonical-cli.sh` | `dry_run_apply` | `tests/recovery-preinstall-audit-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/recovery-restore-harness-canonical-cli.sh` | `dry_run_apply` | `tests/recovery-restore-harness-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/regenerate-dicklesworthstone-sources-idempotency-key.sh` | `dry_run_apply` | `tests/regenerate-dicklesworthstone-sources-idempotency-key.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/regenerate-dicklesworthstone-sources.sh` | `dry_run_apply` | `tests/regenerate-dicklesworthstone-sources.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/rel-fixture-45987-canonical-cli.sh` | `dry_run_apply` | `tests/rel-fixture-45987-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/rule-hint-lifecycle.sh` | `default_dry_run_apply` | `tests/rule-hint-lifecycle.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/scaffold-canonical-cli-apply-gate-regression.sh` | `default_dry_run_apply` | `tests/scaffold-canonical-cli-apply-gate-regression.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/scaffold-canonical-cli-e2e.sh` | `dry_run_apply` | `tests/scaffold-canonical-cli-e2e.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/security-precommit-hook.sh` | `dry_run_apply` | `tests/security-precommit-hook.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/security-precommit-installer-idempotency-key.sh` | `dry_run_apply` | `tests/security-precommit-installer-idempotency-key.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/security-settings-propagation.sh` | `dry_run_apply` | `tests/security-settings-propagation.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/sh_posix-canonical-cli.sh` | `dry_run_apply` | `tests/sh_posix-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/shared-surface-reservation-check-canonical-cli.sh` | `dry_run_apply` | `tests/shared-surface-reservation-check-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/skill-bandit-measurement-probe-canonical-cli.sh` | `dry_run_apply` | `tests/skill-bandit-measurement-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/skill-enhance-jsm-discipline-canonical-cli.sh` | `dry_run_apply` | `tests/skill-enhance-jsm-discipline-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/skillos-routed-tail-canonical-cli.sh` | `dry_run_apply` | `tests/skillos-routed-tail-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/skillos-template-handshake-canonical-cli.sh` | `dry_run_apply` | `tests/skillos-template-handshake-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/stale-error-auto-ping-idempotency-key.sh` | `default_dry_run_apply` | `tests/stale-error-auto-ping-idempotency-key.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/stale-error-auto-ping.sh` | `default_dry_run_apply` | `tests/stale-error-auto-ping.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/stale-in-progress-reaper.sh` | `default_dry_run_apply` | `tests/stale-in-progress-reaper.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/state-md-miner-canonical-cli.sh` | `dry_run_apply` | `tests/state-md-miner-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/state-md-miner.sh` | `dry_run_apply` | `tests/state-md-miner.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/state-store-authority-probe-canonical-cli.sh` | `dry_run_apply` | `tests/state-store-authority-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/storage-headroom-watcher-canonical-cli.sh` | `dry_run_apply` | `tests/storage-headroom-watcher-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/storage-pause-auto-resume-canonical-cli.sh` | `dry_run_apply` | `tests/storage-pause-auto-resume-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/storage-pause-auto-resume.sh` | `dry_run_apply` | `tests/storage-pause-auto-resume.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/storage-pressure-doctor-canonical-cli.sh` | `dry_run_apply` | `tests/storage-pressure-doctor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/storage-probe-canonical-cli.sh` | `dry_run_apply` | `tests/storage-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/storage-prune-canonical-cli.sh` | `dry_run_apply` | `tests/storage-prune-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/substrate-discipline-primitives.sh` | `dry_run_apply` | `tests/substrate-discipline-primitives.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/substrate-loop-contract-validator.sh` | `dry_run_apply` | `tests/substrate-loop-contract-validator.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/supabase-rls-emergency-fix.sh` | `default_dry_run_apply` | `tests/supabase-rls-emergency-fix.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/sync-four-lens-validator.sh` | `dry_run_apply` | `tests/sync-four-lens-validator.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/team-pulse-heartbeat-canonical-cli.sh` | `dry_run_apply` | `tests/team-pulse-heartbeat-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/team-roster-watch-canonical-cli.sh` | `dry_run_apply` | `tests/team-roster-watch-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/tentacle-drift-sweep.sh` | `dry_run_apply` | `tests/tentacle-drift-sweep.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/tentacle-inventory-bump-atomic-fixture.sh` | `default_dry_run_apply` | `tests/tentacle-inventory-bump-atomic-fixture.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-agent-mail-redact-canonical-cli.sh` | `dry_run_apply` | `tests/test-agent-mail-redact-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-auto-respawn-canonical-cli.sh` | `dry_run_apply` | `tests/test-auto-respawn-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-doctor-empty-errors-canonical-cli.sh` | `dry_run_apply` | `tests/test-doctor-empty-errors-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-fmnv2-sync-canonical-root-block-roundtrip.sh` | `default_dry_run_apply` | `tests/test-fmnv2-sync-canonical-root-block-roundtrip.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-fuckup-join-canonical-cli.sh` | `dry_run_apply` | `tests/test-fuckup-join-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-inject-memory-hits-canonical-cli.sh` | `dry_run_apply` | `tests/test-inject-memory-hits-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-loop-driver-doctor-canonical-cli.sh` | `dry_run_apply` | `tests/test-loop-driver-doctor-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-safe-probe-canonical-cli.sh` | `dry_run_apply` | `tests/test-safe-probe-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-skillos-bridge-canonical-cli.sh` | `dry_run_apply` | `tests/test-skillos-bridge-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-sync-canonical-doctrine-canonical-cli.sh` | `dry_run_apply` | `tests/test-sync-canonical-doctrine-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-sync-stamped-repos-coverage-canonical-cli.sh` | `dry_run_apply` | `tests/test-sync-stamped-repos-coverage-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-tmp-aggressive-prune.sh` | `dry_run_apply` | `tests/test-tmp-aggressive-prune.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test-tmp-prune.sh` | `dry_run_apply` | `tests/test-tmp-prune.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_apply_substrate_tuning.sh` | `dry_run_apply` | `tests/test_apply_substrate_tuning.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_apply_tmux_tuning.sh` | `default_dry_run_apply` | `tests/test_apply_tmux_tuning.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_bead_evidence_indexer.sh` | `default_dry_run_apply` | `tests/test_bead_evidence_indexer.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_dispatch_enforcement_backfill.sh` | `dry_run_apply` | `tests/test_dispatch_enforcement_backfill.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_flywheel_adopt_command_contract.sh` | `dry_run_apply` | `tests/test_flywheel_adopt_command_contract.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_flywheel_loop_activation_contract.sh` | `dry_run_apply` | `tests/test_flywheel_loop_activation_contract.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_flywheel_loop_driver_writeback.sh` | `dry_run_apply` | `tests/test_flywheel_loop_driver_writeback.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_flywheel_loop_revive.sh` | `dry_run_apply` | `tests/test_flywheel_loop_revive.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_idle_pane_watcher_convergence.sh` | `dry_run_apply` | `tests/test_idle_pane_watcher_convergence.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_mission_lock_frontmatter_idempotent.sh` | `dry_run_apply` | `tests/test_mission_lock_frontmatter_idempotent.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_regen_sources_from_gh.sh` | `dry_run_apply` | `tests/test_regen_sources_from_gh.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_skillos_discovery_coordinator.sh` | `dry_run_apply` | `tests/test_skillos_discovery_coordinator.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_skillos_notify.sh` | `dry_run_apply` | `tests/test_skillos_notify.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/test_worker_tick_jsm_outcomes.sh` | `dry_run_apply` | `tests/test_worker_tick_jsm_outcomes.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/tick-skill-version-check-canonical-cli.sh` | `dry_run_apply` | `tests/tick-skill-version-check-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/tmp-aggressive-prune-doctor.sh` | `default_dry_run_apply` | `tests/tmp-aggressive-prune-doctor.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/tmp-prune-canonical-cli.sh` | `dry_run_apply` | `tests/tmp-prune-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/topology-tick-refresh-canonical-cli.sh` | `dry_run_apply` | `tests/topology-tick-refresh-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/trauma-handoff-agent-mail-send.sh` | `dry_run_apply` | `tests/trauma-handoff-agent-mail-send.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/validate-callback-before-close-canonical-cli.sh` | `default_dry_run_apply` | `tests/validate-callback-before-close-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/validate-callback-before-close.sh` | `default_dry_run_apply` | `tests/validate-callback-before-close.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/validate-skill-discovery-callback-canonical-cli.sh` | `dry_run_apply` | `tests/validate-skill-discovery-callback-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/validation-fix-bead.sh` | `dry_run_apply` | `tests/validation-fix-bead.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/value-gap-probe.sh` | `dry_run_apply` | `tests/value-gap-probe.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/verify-watcher-launchd-active-canonical-cli.sh` | `dry_run_apply` | `tests/verify-watcher-launchd-active-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/wire-or-explain-close-gate.sh` | `dry_run_apply` | `tests/wire-or-explain-close-gate.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/worker-auto-respawn-watchdog-canonical-cli.sh` | `dry_run_apply` | `tests/worker-auto-respawn-watchdog-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/worker-auto-respawn-watchdog-install-canonical-cli.sh` | `dry_run_apply` | `tests/worker-auto-respawn-watchdog-install-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/worker-head-verify-canonical-cli.sh` | `dry_run_apply` | `tests/worker-head-verify-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/worker-stall-alert-probe.sh` | `default_dry_run_apply` | `tests/worker-stall-alert-probe.sh` | fixture exists but no parity assertion was detected |
| `FAIL` | `tests/worker-tick-jsm-outcomes-canonical-cli.sh` | `dry_run_apply` | `tests/worker-tick-jsm-outcomes-canonical-cli.sh` | fixture exists but no parity assertion was detected |
| `NO-FIXTURE` | `.flywheel/scripts/agentmail-fd-pressure-probe.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/blocker-discipline-tick-chain-launchd-install.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/branch-protection-fleet-rollout.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/canonical-cli-lint-precommit-installer.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/coordinator-daemon-health.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/dispatch-log-fitness-invariant.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/doctrine-polish-bar-lint.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/flywheel-onboard.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/gap-hunt-probe-self-calibration.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/git-main-sync-fleet-rollout.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/install-coordinator-daemon.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/install-fleet-codex-health-launchd.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/install-git-main-sync-launchd.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/install-stuck-detector-watchdog.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/integrate-stall-escalator.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mission-fitness-callback-validator.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mission-fitness-doctor.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mp-scaffolder-runner.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mp-scaffolders/MP-82-hook-lifecycle-guardrail-chain-scaffold.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mp-scaffolders/MP-89-mode-scoped-phase-workspace-scaffold.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mp-scaffolders/MP-90-adjacent-skill-boundary-router-scaffold.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mp-scaffolders/MP-91-progress-counter-forced-motion-loop-scaffold.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/mp-scaffolders/MP-97-federated-retrieval-parity-provenance-scaffold.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/ntm-audit-receipts.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/ntm-checkpoint-rollback-guard.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/ntm-metrics-doctor-probe.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/ntm-policy-contracts.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/ntm-quota-proactive-probe.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/ntm-serve-eventstream-bridge.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/orch-tick-stale-auto-bead-close.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/parity-contract-add-fixture.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/pre-write-path-guard.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/scaffold-canonical-cli-py.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/scaffold-doc-frontmatter.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/session-residue-prune.sh` | `default_dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/supabase-local-validate-and-push.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `NO-FIXTURE` | `.flywheel/scripts/validation-e2e-smoke.sh` | `dry_run_apply` | `none` | no matching smoke fixture found |
| `PASS` | `.flywheel/scripts/bcv-task-harness.sh` | `dry_run_apply` | `tests/bcv-task-harness.sh`, `tests/bcv-task-harness-canonical-cli.sh`, `tests/bcv-task-harness-idempotency-key.sh` | fixture contains parity assertion |
| `PASS` | `.flywheel/scripts/branch-protection-apply.sh` | `dry_run_apply` | `tests/branch-protection-apply-smoke.sh` | fixture contains parity assertion |
| `PASS` | `.flywheel/scripts/cleanup-scratch.sh` | `dry_run_apply` | `tests/cleanup-scratch.sh`, `tests/cleanup-scratch-canonical-cli.sh` | fixture contains parity assertion |
| `PASS` | `.flywheel/scripts/parity-contract-validator.sh` | `dry_run_apply`, `check_commit`, `plan_execute` | `tests/parity-contract-validator-smoke.sh` | fixture contains parity assertion |
| `PASS` | `tests/bcv-task-harness-idempotency-key.sh` | `default_dry_run_apply` | `tests/bcv-task-harness-idempotency-key.sh` | fixture contains parity assertion |
| `PASS` | `tests/branch-protection-apply-smoke.sh` | `dry_run_apply` | `tests/branch-protection-apply-smoke.sh` | fixture contains parity assertion |
| `PASS` | `tests/cleanup-scratch-canonical-cli.sh` | `dry_run_apply` | `tests/cleanup-scratch-canonical-cli.sh` | fixture contains parity assertion |
| `PASS` | `tests/parity-contract-validator-smoke.sh` | `dry_run_apply`, `plan_execute` | `tests/parity-contract-validator-smoke.sh` | fixture contains parity assertion |

## JSON Envelope

```json
{
  "generated_at": "2026-05-20T03:53:04Z",
  "named_checks": [
    {
      "detail": "fixture contains parity assertion",
      "path": ".flywheel/scripts/branch-protection-apply.sh",
      "status": "PASS"
    },
    {
      "detail": "no dual-mode flag pair detected",
      "path": ".flywheel/scripts/auto-push.sh",
      "status": "NOT-DUAL"
    },
    {
      "detail": "fixture exists but no parity assertion was detected",
      "path": ".flywheel/scripts/supabase-rls-emergency-fix.sh",
      "status": "FAIL"
    },
    {
      "detail": "no dual-mode flag pair detected",
      "path": ".flywheel/scripts/mp-validator-framework.sh",
      "status": "NOT-DUAL"
    },
    {
      "detail": "no matching smoke fixture found",
      "path": ".flywheel/scripts/mp-scaffolders/MP-82-hook-lifecycle-guardrail-chain-scaffold.sh",
      "status": "NO-FIXTURE"
    },
    {
      "detail": "no matching smoke fixture found",
      "path": ".flywheel/scripts/mp-scaffolders/MP-89-mode-scoped-phase-workspace-scaffold.sh",
      "status": "NO-FIXTURE"
    },
    {
      "detail": "no matching smoke fixture found",
      "path": ".flywheel/scripts/mp-scaffolders/MP-90-adjacent-skill-boundary-router-scaffold.sh",
      "status": "NO-FIXTURE"
    },
    {
      "detail": "no matching smoke fixture found",
      "path": ".flywheel/scripts/mp-scaffolders/MP-91-progress-counter-forced-motion-loop-scaffold.sh",
      "status": "NO-FIXTURE"
    },
    {
      "detail": "no matching smoke fixture found",
      "path": ".flywheel/scripts/mp-scaffolders/MP-97-federated-retrieval-parity-provenance-scaffold.sh",
      "status": "NO-FIXTURE"
    },
    {
      "detail": "no dual-mode flag pair detected",
      "path": ".flywheel/scripts/codex-goal-mode-monitor-probe.sh",
      "status": "NOT-DUAL"
    }
  ],
  "report_path": ".flywheel/audits/parity-contract-conformance-20260520T035304Z.md",
  "root": "/Users/josh/Developer/flywheel",
  "rows": [
    {
      "fixtures": [
        "tests/adversarial-orch-self-audit-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/adversarial-orch-self-audit-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agent-mail-pre-allocate-worker-identities-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/agent-mail-pre-allocate-worker-identities.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agent-mail-restart.sh",
        "tests/agent-mail-restart-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/agent-mail-restart.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agent-mail-send-redacted-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/agent-mail-send-redacted.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agentmail-identity-canonical-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/agentmail-identity-canonical-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agents-md-fleet-propagator.sh",
        "tests/agents-md-fleet-propagator-canonical-cli.sh",
        "tests/agents-md-fleet-propagator-large-ledger.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/agents-md-fleet-propagator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agents-md-shard-extract-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/agents-md-shard-extract.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/append-safe-write-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/append-safe-write.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/apply-substrate-tuning-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/apply-substrate-tuning.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/apply-tmux-tuning-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/apply-tmux-tuning.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/auto-l112-gate-canonical-cli.sh",
        "tests/auto-l112-gate-orch-adoption-test.sh",
        "tests/auto-l112-gate-test.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/auto-l112-gate.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/auto-refill-decision-log-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/auto-refill-decision-log.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bead-evidence-indexer-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/bead-evidence-indexer.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/beads-db-recover.sh",
        "tests/beads-db-recover-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/beads-db-recover.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bleed-ledger-watch.sh",
        "tests/bleed-ledger-watch-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/bleed-ledger-watch.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/blocker-ac-tick-cadence-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/blocker-ac-tick-cadence.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/blocker-auto-close.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/blocker-auto-close.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/blocker-discipline-tick-chain.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/blocker-discipline-tick-chain.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/blocker-fail-escalator.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/blocker-fail-escalator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/br-authority-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/br-authority-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/br-close-with-gate-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/br-close-with-gate.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/br-db-corruption-monitor.sh",
        "tests/br-db-corruption-monitor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/br-db-corruption-monitor.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/build-dispatch-packet-canonical-cli.sh",
        "tests/build-dispatch-packet-callback-pane-topology.sh",
        "tests/build-dispatch-packet-evidence-redacted.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/build-dispatch-packet.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/caam-rotate-and-respawn-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/caam-rotate-and-respawn.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/callback-envelope-schema-validator.sh",
        "tests/callback-envelope-schema-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/callback-envelope-schema-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/callback-fix-bead-opener-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/callback-fix-bead-opener.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/callback-receipt-validator-canonical-cli.sh",
        "tests/callback-receipt-validator-wrapper-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/callback-receipt-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/callback-spool-reap.sh",
        "tests/callback-spool-reap-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/callback-spool-reap.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/canonical-doctrine-sync-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/canonical-doctrine-sync.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/canonical-root-drift-fleet-check.sh",
        "tests/canonical-root-drift-fleet-check-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/canonical-root-drift-fleet-check.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/capacity-halt-auto-continue-primitive-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/capacity-halt-auto-continue-primitive.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/capacity-halt-lease-primitive-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/capacity-halt-lease-primitive.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/capacity-halt-pane-authorization-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/capacity-halt-pane-authorization.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/check-trauma-class-substrate-canonical-cli.sh",
        "tests/check-trauma-class-substrate-test.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/check-trauma-class-substrate.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/clobber-recovery-smoke.sh",
        "tests/clobber-recovery-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/clobber-recovery.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/codex-budget-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/codex-budget-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/codex-budget-watchdog-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/codex-budget-watchdog.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/codex-death-event-classifier-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/codex-death-event-classifier.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/codex-queued-not-submitted-bare-enter-primitive-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/codex-template-stuck-detector.sh",
        "tests/codex-template-stuck-detector-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/codex-template-stuck-detector.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/continuous-productivity-detector-install-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/continuous-productivity-detector-install.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/continuous-productivity-detector-canonical-cli.sh",
        "tests/continuous-productivity-detector-install-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/continuous-productivity-detector.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cost-telemetry-token-burn-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/cost-telemetry-token-burn-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cross-pane-git-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/cross-pane-git-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cross-repo-trauma-aggregator.sh",
        "tests/cross-repo-trauma-aggregator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/cross-repo-trauma-aggregator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cross-session-worker-borrow-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/cross-session-worker-borrow.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cross-skill-dependency-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/cross-skill-dependency-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cross-time-synthesis-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/cross-time-synthesis-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/customer-facing-observability-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/customer-facing-observability-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/daily-jeff-ingest-dry-run-bounds.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/daily-jeff-ingest.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/daily-report-enabled-repos-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/daily-report-enabled-repos.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/daily-report.sh",
        "tests/daily-report-canonical-cli.sh",
        "tests/daily-report-enabled-repos-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/daily-report.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/disk-reclaim-batch-2026-05-07-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/disk-reclaim-batch-2026-05-07.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-and-log-canonical-cli.sh",
        "tests/dispatch-and-log-expected-by-test.sh",
        "tests/dispatch-and-log-ntm-gates.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-and-log.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-author-contract-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-author-contract-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-canonical-cli-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-canonical-cli-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-deferral-lint-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-deferral-lint.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-delivery-verify-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-delivery-verify.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-log-backfill-v2-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-log-backfill-v2.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-log-schema-validator-tick-wire-in.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-log-schema-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-log-v2-violations-doctor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-log-v2-violations-doctor.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-self-test-delivery-identity-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-self-test-delivery-identity.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-surface-conflict-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-surface-conflict-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-trigger-gated-precheck-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-trigger-gated-precheck.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/docs-validation-probe.sh",
        "tests/docs-validation-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/docs-validation-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/doctrine-broadcast-send-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/doctrine-broadcast-send.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/doctrine-ladder-promote-canonical-cli.sh",
        "tests/doctrine-ladder-promote-incidents-dedup-smoke.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/doctrine-ladder-promote.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/doctrine-sync-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/doctrine-sync.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/escalate-capsule-plan-consumer-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/escalate-capsule-plan-consumer.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/file-length-probe.sh",
        "tests/file-length-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/file-length-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-canonical-rule-freshness-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/fleet-canonical-rule-freshness-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-coherence-alert.sh",
        "tests/fleet-coherence-alert-canonical-cli.sh",
        "tests/fleet-coherence-alert-degraded.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/fleet-coherence-alert.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-coherence-launchd.sh",
        "tests/fleet-coherence-launchd-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/fleet-coherence-launchd.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-coherence-lib-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/fleet-coherence-lib.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-comms-health-probe.sh",
        "tests/fleet-comms-health-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/fleet-comms-health-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-conformance-probe.sh",
        "tests/fleet-conformance-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/fleet-conformance-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-process-gap-detector.sh",
        "tests/fleet-process-gap-detector-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/fleet-process-gap-detector.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-rotate-all-sessions-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/fleet-rotate-all-sessions.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-adopt-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/flywheel-adopt.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-codex-stuck-detector-install-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/flywheel-codex-stuck-detector-install.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-loop-doctor-stale-descendant-reaper.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/flywheel-loop-doctor-stale-descendant-reaper.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-recovery-canonical-cli.sh",
        "tests/flywheel-recovery-session-paths.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/flywheel-recovery.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/frozen-pane-backtest-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/frozen-pane-backtest.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/frozen-pane-detector-fleet.sh",
        "tests/frozen-pane-detector-fleet-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/frozen-pane-detector-fleet.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/frozen-pane-detector-canonical-cli.sh",
        "tests/frozen-pane-detector-apply-gate-test.sh",
        "tests/frozen-pane-detector-fleet-canonical-cli.sh",
        "tests/frozen-pane-detector-fleet.sh",
        "tests/frozen-pane-detector-self-test.sh",
        "tests/frozen-pane-detector-slo-thresholds.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/frozen-pane-detector.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fs-rag-sibling-rollout-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/fs-rag-sibling-rollout.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fuckup-coverage-join.sh",
        "tests/fuckup-coverage-join-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/fuckup-coverage-join.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/gap-hunt-probe-canonical-cli.sh",
        "tests/gap-hunt-probe-0h0b-suppression-smoke.sh",
        "tests/gap-hunt-probe-dcg-rest-api-memory.sh",
        "tests/gap-hunt-probe-dedup-canonical-cli.sh",
        "tests/gap-hunt-probe-doctrine-corpus.sh",
        "tests/gap-hunt-probe-exec-sh-corpus.sh",
        "tests/gap-hunt-probe-for-loop-source-corpus.sh",
        "tests/gap-hunt-probe-for-loop-source.sh",
        "tests/gap-hunt-probe-on-demand-validator-allowlist.sh",
        "tests/gap-hunt-probe-phantom-bead-suppression.sh",
        "tests/gap-hunt-probe-skill-md-corpus.sh",
        "tests/gap-hunt-probe-skill-tree-md-corpus.sh",
        "tests/gap-hunt-probe-subprocess-validator-callsite.sh",
        "tests/gap-hunt-probe-tests-allowlist.sh",
        "tests/gap-hunt-probe-tests-tree-exclusion-canonical-cli.sh",
        "tests/gap-hunt-probe-var-assigned-source.sh",
        "tests/gap-hunt-probe-verify-ntm-send-memory.sh",
        "tests/gap-hunt-probe-worker-tick-stable-tail-memory.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/gap-hunt-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/git-main-sync-smoke.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/git-main-sync.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/halt-disease-watchdog-canonical-cli.sh",
        "tests/halt-disease-watchdog-native-test.sh",
        "tests/halt-disease-watchdog-stream-output-test.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/halt-disease-watchdog.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/handoff-skill-to-skillos.sh",
        "tests/handoff-skill-to-skillos-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/handoff-skill-to-skillos.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/headless-browser-reap-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/headless-browser-reap.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/hub-blocker-detect.sh",
        "tests/hub-blocker-detect-canonical-cli.sh",
        "tests/hub-blocker-detect-idempotency-key.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/hub-blocker-detect.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/idempotency-replay-guard-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/idempotency-replay-guard.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/idle-pane-auto-dispatch-canonical-cli.sh",
        "tests/idle-pane-auto-dispatch-closed-guard-test.sh",
        "tests/idle-pane-auto-dispatch-validated-write-test.sh",
        "tests/idle-pane-auto-dispatch-work-started-validation-test.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/idle-pane-auto-dispatch.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/idle-state-probe.sh",
        "tests/idle-state-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/idle-state-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/inject-doc-toc-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/inject-doc-toc.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/install-pane1-bridge-tailer-launchd.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/install-pane1-bridge-tailer-launchd.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-bead-285-divergence-capture-idempotency-key.sh",
        "tests/jeff-bead-285-divergence-capture-introspection.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-bead-285-divergence-capture.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-binary-version-watchtower.sh",
        "tests/jeff-binary-version-watchtower-canonical-cli.sh",
        "tests/jeff-binary-version-watchtower-homebrew-sbh.sh",
        "tests/jeff-binary-version-watchtower-sbh-binary.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-binary-version-watchtower.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-clone-symlink-converter-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-clone-symlink-converter.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-corpus-compact-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-corpus-compact.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-corpus-delta-reindex-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-corpus-delta-reindex.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-daily-diff.sh",
        "tests/jeff-daily-diff-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-daily-diff.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-intel-digest-actionable-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-intel-digest-actionable.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-intel-network.sh",
        "tests/jeff-intel-network-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-intel-network.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-intel-scheduled-runner-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-intel-scheduled-runner.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-issue-response-poll-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-issue-response-poll.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-pattern-citation-probe.sh",
        "tests/jeff-pattern-citation-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-pattern-citation-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-philosophy-mine.sh",
        "tests/jeff-philosophy-mine-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-philosophy-mine.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-shadow-socraticode.sh",
        "tests/jeff-shadow-socraticode-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-shadow-socraticode.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-verdict-heuristic-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-verdict-heuristic.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-workaround-research-gate-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeff-workaround-research-gate.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeffrey-comment-watchtower-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/jeffrey-comment-watchtower.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/l70-ticks-punted-counter.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/l70-ticks-punted-counter.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/low-bead-threshold-detector-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/low-bead-threshold-detector.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/mission-anchor-dispatch-license-test.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mission-anchor-dispatch-license.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/mission-lock-negative-invariants-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mission-lock-negative-invariants-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/mission-lock-readiness-doctor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mission-lock-readiness-doctor.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/mission-lock-scaffold-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mission-lock-scaffold-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/mobile-eats-end-user-health-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mobile-eats-end-user-health-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/mobile-eats-loop-with-receipt-mirror-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-approve-human-gates-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-approve-human-gates.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-coordinator-shadow-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-coordinator-shadow.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-fleet-health-canonical-cli.sh",
        "tests/ntm-fleet-health-apply-gate-test.sh",
        "tests/ntm-fleet-health-role-split.sh",
        "tests/ntm-fleet-health-topology-regression.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-fleet-health.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-pane-sidecar-respawn.sh",
        "tests/ntm-pane-sidecar-respawn-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-pane-sidecar-respawn.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-pipeline-shadow-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-pipeline-shadow.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-preflight-l91-wrapper-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-preflight-l91-wrapper.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-safety-dcg-sibling-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-safety-dcg-sibling.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-scrub-secret-scan-wrapper-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-scrub-secret-scan-wrapper.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-surface-coverage-trend-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-surface-coverage-trend.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-surface-validation-driver-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-surface-validation-driver.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-wave2-native-probes-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-wave2-native-probes.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/orch-agent-mail-session-register.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/orch-agent-mail-session-register.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/orch-worker-identity-manifest.sh",
        "tests/orch-worker-identity-manifest-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/orch-worker-identity-manifest.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/orchestrator-callback-artifact-fix-bead-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/orchestrator-callback-artifact-fix-bead.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/orchestrator-callback-artifact-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/orchestrator-callback-artifact-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/peer-orch-blocker-watch.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/peer-orch-blocker-watch.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/peer-orch-freeze-monitor.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/peer-orch-freeze-monitor.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/peer-orch-respawn-permit.sh",
        "tests/peer-orch-respawn-permit-canonical-cli-test.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/peer-orch-respawn-permit.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/picoz-archive-and-fresh-2026-05-07-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/picoz-archive-and-fresh-2026-05-07.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/plan-state-lens-merge-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/plan-state-lens-merge.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/plan-to-bead-auto-trigger-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/plan-to-bead-auto-trigger.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/polish-preflight-quality-gate-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/polish-preflight-quality-gate.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/pre-dispatch-state-db-lock-check-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/pre-dispatch-state-db-lock-check.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/private-tmp-prune.sh",
        "tests/private-tmp-prune-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/private-tmp-prune.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/promotion-candidate-stale-fire-reaper-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/promotion-candidate-stale-fire-reaper.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/public-artifact-pipeline-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/public-artifact-pipeline-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/quality-bar-close-gate.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/quality-bar-close-gate.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-baseline-snapshot-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/recovery-baseline-snapshot.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-baseline-status-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/recovery-baseline-status.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-doctor-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/recovery-doctor-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-escape-then-reprompt-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/recovery-escape-then-reprompt.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-install-plist-alpsinsurance-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/recovery-install-plist-alpsinsurance.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-install-plist-clutterfreespaces-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/recovery-install-plist-clutterfreespaces.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-install-plist-mobile-eats-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/recovery-install-plist-mobile-eats.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-install-plist-skillos-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/recovery-install-plist-skillos.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-preinstall-audit-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/recovery-preinstall-audit.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-restore-harness-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/recovery-restore-harness.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/regenerate-dicklesworthstone-sources.sh",
        "tests/regenerate-dicklesworthstone-sources-idempotency-key.sh",
        "tests/regenerate-dicklesworthstone-sources-known-silos-registry.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/regenerate-dicklesworthstone-sources.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/rule-hint-lifecycle.sh",
        "tests/rule-hint-lifecycle-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/rule-hint-lifecycle.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/scaffold-canonical-cli-apply-gate-regression.sh",
        "tests/scaffold-canonical-cli-bugfix-bundle.sh",
        "tests/scaffold-canonical-cli-e2e.sh",
        "tests/scaffold-canonical-cli-flag-collision.sh",
        "tests/scaffold-canonical-cli-shebang-guard.sh",
        "tests/scaffold-canonical-cli-verb-collision-regression.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/scaffold-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/security-precommit-installer-idempotency-key.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/security-precommit-installer.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/shared-surface-reservation-check.sh",
        "tests/shared-surface-reservation-check-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/shared-surface-reservation-check.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/skill-bandit-measurement-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/skill-bandit-measurement-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/skill-enhance-jsm-discipline.sh",
        "tests/skill-enhance-jsm-discipline-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/skill-enhance-jsm-discipline.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/skillos-routed-tail-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/skillos-routed-tail.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/skillos-template-handshake-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/skillos-template-handshake.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/stale-error-auto-ping.sh",
        "tests/stale-error-auto-ping-idempotency-key.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/stale-error-auto-ping.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/stale-in-progress-reaper.sh",
        "tests/stale-in-progress-reaper-carve-out.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/stale-in-progress-reaper.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/state-md-miner.sh",
        "tests/state-md-miner-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/state-md-miner.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/state-store-authority-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/state-store-authority-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/storage-headroom-watcher.sh",
        "tests/storage-headroom-watcher-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/storage-headroom-watcher.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/storage-pause-auto-resume.sh",
        "tests/storage-pause-auto-resume-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/storage-pause-auto-resume.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/storage-pressure-doctor.sh",
        "tests/storage-pressure-doctor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/storage-pressure-doctor.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/storage-probe.sh",
        "tests/storage-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/storage-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/storage-prune-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/storage-prune.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/substrate-loop-contract-validator.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/substrate-loop-contract-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/supabase-rls-emergency-fix.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/supabase-rls-emergency-fix.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/sync-canonical-doctrine-doctor.sh",
        "tests/sync-canonical-doctrine-idempotency-key.sh",
        "tests/sync-canonical-doctrine-introspection.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/sync-canonical-doctrine.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/sync-four-lens-validator.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/sync-four-lens-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/team-pulse-heartbeat.sh",
        "tests/team-pulse-heartbeat-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/team-pulse-heartbeat.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/team-roster-watch-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/team-roster-watch.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/tentacle-drift-sweep.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/tentacle-drift-sweep.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/tentacle-inventory-bump-atomic-fixture.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/tentacle-inventory-bump.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-agent-mail-redact-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/test-agent-mail-redact.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-auto-respawn.sh",
        "tests/test-auto-respawn-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/test-auto-respawn.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-doctor-empty-errors-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/test-doctor-empty-errors.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-fuckup-join-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/test-fuckup-join.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-loop-driver-doctor-canonical-cli.sh",
        "tests/test-loop-driver-doctor-no-cass-check.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/test-loop-driver-doctor.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-safe-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/test-safe-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-skillos-bridge-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/test-skillos-bridge.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-sync-canonical-doctrine-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/test-sync-canonical-doctrine.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-sync-stamped-repos-coverage-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/test-sync-stamped-repos-coverage.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/tick-hook-firing-verifier.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/tick-hook-firing-verifier.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/tick-skill-version-check-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/tick-skill-version-check.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-tmp-aggressive-prune.sh",
        "tests/tmp-aggressive-prune-doctor.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/tmp-aggressive-prune.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/tmp-prune-canonical-cli.sh",
        "tests/test-tmp-prune.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/tmp-prune.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/topology-tick-refresh.sh",
        "tests/topology-tick-refresh-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/topology-tick-refresh.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/trauma-handoff-agent-mail-send.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/trauma-handoff.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/validate-callback-before-close.sh",
        "tests/validate-callback-before-close-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/validate-callback-before-close.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/validate-skill-discovery-callback-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/validate-skill-discovery-callback.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/value-gap-probe.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/value-gap-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/verify-watcher-launchd-active-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/verify-watcher-launchd-active.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/watcher-isomorphic-probe.sh",
        "tests/watcher-isomorphic-probe-fleet.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/watcher-isomorphic-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/worker-auto-respawn-watchdog-install-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/worker-auto-respawn-watchdog-install.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/worker-auto-respawn-watchdog-canonical-cli.sh",
        "tests/worker-auto-respawn-watchdog-install-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/worker-auto-respawn-watchdog.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/worker-deep-liveness-probe-launchd-install-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/worker-deep-liveness-probe-launchd-install.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/worker-head-verify-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/worker-head-verify.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/worker-stall-alert-probe.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/worker-stall-alert-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/worker-tick-jsm-outcomes-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/worker-tick-jsm-outcomes.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "script",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/abs-target-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/abs-target-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/adversarial-orch-self-audit-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/adversarial-orch-self-audit-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-14423-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-14423-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-1725-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-1725-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-20800-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-20800-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-21313-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-21313-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-28756-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-28756-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-32174-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-32174-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-32693-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-32693-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-45987-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-45987-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-56679-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-56679-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-5780-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-5780-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-58117-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-58117-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-73998-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-73998-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-83848-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-83848-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ag2-fixture-90723-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ag2-fixture-90723-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agent-mail-pre-allocate-worker-identities-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/agent-mail-pre-allocate-worker-identities-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agent-mail-restart-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/agent-mail-restart-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agent-mail-restart.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/agent-mail-restart.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agent-mail-send-redacted-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/agent-mail-send-redacted-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agentmail-identity-canonical-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/agentmail-identity-canonical-validator-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agents-md-fleet-propagator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/agents-md-fleet-propagator-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agents-md-fleet-propagator.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/agents-md-fleet-propagator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/agents-md-shard-extract-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/agents-md-shard-extract-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/append-safe-write-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/append-safe-write-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/apply-substrate-tuning-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/apply-substrate-tuning-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/apply-tmux-tuning-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/apply-tmux-tuning-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/auto-l112-gate-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/auto-l112-gate-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/auto-refill-decision-log-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/auto-refill-decision-log-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/auto-respawn-detector-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/auto-respawn-detector-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-14423-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-14423-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-1725-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-1725-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-20800-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-20800-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-21313-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-21313-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-28756-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-28756-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-32174-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-32174-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-32693-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-32693-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-45987-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-45987-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-56679-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-56679-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-5780-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-5780-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-58117-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-58117-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-73998-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-73998-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-83848-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-83848-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-a-90723-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-a-90723-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-14423-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-14423-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-1725-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-1725-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-20800-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-20800-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-21313-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-21313-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-28756-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-28756-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-32174-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-32174-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-32693-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-32693-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-45987-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-45987-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-56679-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-56679-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-5780-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-5780-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-58117-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-58117-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-73998-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-73998-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-83848-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-83848-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bak-b-90723-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bak-b-90723-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bash_abs-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bash_abs-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bash_env-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bash_env-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bcv-task-harness-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bcv-task-harness-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bead-blocker-sync.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bead-blocker-sync.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bead-evidence-indexer-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bead-evidence-indexer-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/beads-db-recover-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/beads-db-recover-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/beads-db-recover.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/beads-db-recover.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/beads-mem-tmp-cleanup.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/beads-mem-tmp-cleanup.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/bleed-ledger-watch-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/bleed-ledger-watch-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/blocker-ac-tick-cadence-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/blocker-ac-tick-cadence-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/blocker-auto-close.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/blocker-auto-close.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/blocker-discipline-tick-chain.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/blocker-discipline-tick-chain.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/blocker-fail-escalator.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/blocker-fail-escalator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/br-authority-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/br-authority-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/br-close-with-gate-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/br-close-with-gate-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/br-db-corruption-monitor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/br-db-corruption-monitor-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/build-dispatch-packet-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/build-dispatch-packet-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/caam-rotate-and-respawn-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/caam-rotate-and-respawn-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/callback-envelope-schema-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/callback-envelope-schema-validator-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/callback-fix-bead-opener-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/callback-fix-bead-opener-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/callback-receipt-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/callback-receipt-validator-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/callback-receipt-validator-wrapper-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/callback-receipt-validator-wrapper-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/callback-spool-reap-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/callback-spool-reap-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/callback-spool-reap.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/callback-spool-reap.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/canonical-cli-lint-l9.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/canonical-cli-lint-l9.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/canonical-cli-lint-precommit.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/canonical-cli-lint-precommit.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/canonical-root-drift-fleet-check-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/canonical-root-drift-fleet-check-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/capacity-halt-auto-continue-primitive-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/capacity-halt-auto-continue-primitive-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/capacity-halt-lease-primitive-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/capacity-halt-lease-primitive-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/capacity-halt-pane-authorization-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/capacity-halt-pane-authorization-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/check-trauma-class-substrate-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/check-trauma-class-substrate-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cleanup-scratch.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/cleanup-scratch.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/clobber-recovery-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/clobber-recovery-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/closed-bead-artifact-scan.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/closed-bead-artifact-scan.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/codex-budget-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/codex-budget-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/codex-budget-watchdog-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/codex-budget-watchdog-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/codex-death-event-classifier-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/codex-death-event-classifier-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/codex-queued-not-submitted-bare-enter-primitive-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/codex-queued-not-submitted-bare-enter-primitive-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/codex-template-stuck-detector-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/codex-template-stuck-detector-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/collision-fixture-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/collision-fixture-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/concurrent-a-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/concurrent-a-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/concurrent-b-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/concurrent-b-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/continuous-productivity-detector-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/continuous-productivity-detector-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/continuous-productivity-detector-install-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/continuous-productivity-detector-install-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cost-telemetry-token-burn-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/cost-telemetry-token-burn-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cross-pane-git-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/cross-pane-git-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cross-repo-trauma-aggregator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/cross-repo-trauma-aggregator-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cross-session-worker-borrow-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/cross-session-worker-borrow-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cross-skill-dependency-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/cross-skill-dependency-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/cross-time-synthesis-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/cross-time-synthesis-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/customer-facing-observability-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/customer-facing-observability-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/daily-report-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/daily-report-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/daily-report-enabled-repos-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/daily-report-enabled-repos-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/depersonalize-table-codemod.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/depersonalize-table-codemod.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dicklesworthstone-signal-gate.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/dicklesworthstone-signal-gate.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/disk-reclaim-batch-2026-05-07-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/disk-reclaim-batch-2026-05-07-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-and-log-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/dispatch-and-log-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-author-contract-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/dispatch-author-contract-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-canonical-cli-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/dispatch-canonical-cli-validator-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-deferral-lint-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/dispatch-deferral-lint-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-delivery-verify-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/dispatch-delivery-verify-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-log-backfill-v2-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/dispatch-log-backfill-v2-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-log-v2-violations-doctor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/dispatch-log-v2-violations-doctor-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-self-test-delivery-identity-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/dispatch-self-test-delivery-identity-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-surface-conflict-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/dispatch-surface-conflict-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/dispatch-trigger-gated-precheck-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/dispatch-trigger-gated-precheck-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/docs-validation-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/docs-validation-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/doctrine-broadcast-send-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/doctrine-broadcast-send-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/doctrine-ladder-promote-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/doctrine-ladder-promote-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/doctrine-sync-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/doctrine-sync-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/empty-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/empty-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/escalate-capsule-plan-consumer-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/escalate-capsule-plan-consumer-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/file-length-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/file-length-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/file-rag-discipline-lint.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/file-rag-discipline-lint.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-canonical-rule-freshness-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-canonical-rule-freshness-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-coherence-alert-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-coherence-alert-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-coherence-launchd-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-coherence-launchd-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-coherence-launchd.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-coherence-launchd.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-coherence-lib-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-coherence-lib-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-comms-health-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-comms-health-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-comms-health-probe.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-comms-health-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-conductor-mvp-gate.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-conductor-mvp-gate.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-conformance-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-conformance-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-conformance-probe.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-conformance-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-process-gap-detector-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-process-gap-detector-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-process-gap-detector.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-process-gap-detector.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-rotate-all-sessions-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-rotate-all-sessions-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fleet-shutdown-recovery.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fleet-shutdown-recovery.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-adopt-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-adopt-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-agents-pointer-sweep-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-agents-pointer-sweep-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-anchor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-anchor-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-autoloop-canonical-cli-scaffold.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-autoloop-canonical-cli-scaffold.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-autoloop-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-autoloop-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-cass-correlate-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-cass-correlate-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-check-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-check-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-codex-orient-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-codex-orient-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-codex-snapshot-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-codex-snapshot-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-codex-stuck-detector-install-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-codex-stuck-detector-install-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-conductor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-conductor-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-dashboard-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-dashboard-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-digest-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-digest-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-doctrine-sync-canonical-cli-scaffold.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-doctrine-sync-canonical-cli-scaffold.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-domain-spec-validate-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-domain-spec-validate-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-friday-digest-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-friday-digest-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-inject-latest-line-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-inject-latest-line-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-install-hooks-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-install-hooks-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-lock-repair-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-lock-repair-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-loop-doctor-stale-descendant-reaper.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-loop-doctor-stale-descendant-reaper.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-loop-repair-beads-db-health.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-loop-repair-beads-db-health.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-outcome-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-outcome-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-pattern-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-pattern-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-quality-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-quality-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-quality-gate-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-quality-gate-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-recovery-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-recovery-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-recovery-session-paths.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-recovery-session-paths.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-render-latest-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-render-latest-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-source-monitor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-source-monitor-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-stale-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-stale-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-summarize-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-summarize-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-sync-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-sync-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-trauma-check-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-trauma-check-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-verdict-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-verdict-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-watchers-allowlist-test.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-watchers-allowlist-test.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/flywheel-watchers-test.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/flywheel-watchers-test.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/foo-bash-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/foo-bash-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/frozen-pane-backtest-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/frozen-pane-backtest-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/frozen-pane-detector-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/frozen-pane-detector-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/frozen-pane-detector-fleet.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/frozen-pane-detector-fleet.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/frozen-pane-detector-self-test.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/frozen-pane-detector-self-test.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fs-rag-sibling-rollout-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fs-rag-sibling-rollout-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/fuckup-coverage-join-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/fuckup-coverage-join-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/gap-hunt-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/gap-hunt-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/git-main-sync-smoke.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/git-main-sync-smoke.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/halt-disease-watchdog-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/halt-disease-watchdog-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/handoff-skill-to-skillos-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/handoff-skill-to-skillos-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/headless-browser-probe.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/headless-browser-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/headless-browser-reap-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/headless-browser-reap-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/hub-blocker-detect-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/hub-blocker-detect-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/hub-blocker-detect-idempotency-key.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/hub-blocker-detect-idempotency-key.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/idempotency-replay-guard-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/idempotency-replay-guard-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/idle-pane-auto-dispatch-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/idle-pane-auto-dispatch-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/idle-pane-auto-dispatch-validated-write-test.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/idle-pane-auto-dispatch-validated-write-test.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/idle-state-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/idle-state-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/inject-skill-auto-routes-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/inject-skill-auto-routes-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/install-pane1-bridge-tailer-launchd.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/install-pane1-bridge-tailer-launchd.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-bead-285-divergence-capture-idempotency-key.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-bead-285-divergence-capture-idempotency-key.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-bead-285-divergence-capture-introspection.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-bead-285-divergence-capture-introspection.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-binary-version-watchtower-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-binary-version-watchtower-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-binary-version-watchtower.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-binary-version-watchtower.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-clone-symlink-converter-canonical-cli.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-clone-symlink-converter-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-corpus-accretive.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-corpus-accretive.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-corpus-compact-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-corpus-compact-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-corpus-delta-reindex-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-corpus-delta-reindex-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-daily-diff-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-daily-diff-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-intel-digest-actionable-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-intel-digest-actionable-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-intel-network.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-intel-network.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-intel-schedule.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-intel-schedule.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-issue-response-poll-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-issue-response-poll-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-issue.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-issue.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-philosophy-mine-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-philosophy-mine-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-shadow-socraticode-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-shadow-socraticode-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/jeff-verdict-heuristic-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/jeff-verdict-heuristic-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/low-bead-threshold-detector-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/low-bead-threshold-detector-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/mission-lock-negative-invariants-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/mission-lock-negative-invariants-validator-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/mission-lock-readiness-doctor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/mission-lock-readiness-doctor-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/mission-lock-scaffold-validator-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/mission-lock-scaffold-validator-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/mobile-eats-end-user-health-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/mobile-eats-end-user-health-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/mobile-eats-loop-with-receipt-mirror-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/mobile-eats-loop-with-receipt-mirror-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/npm-install-guard-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/npm-install-guard-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-approve-human-gates-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-approve-human-gates-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-coordinator-shadow-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-coordinator-shadow-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-fleet-health-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-fleet-health-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-pane-sidecar-respawn-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-pane-sidecar-respawn-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-pane-sidecar-respawn.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-pane-sidecar-respawn.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-pipeline-shadow-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-pipeline-shadow-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-preflight-l91-wrapper-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-preflight-l91-wrapper-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-safety-dcg-sibling-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-safety-dcg-sibling-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-scrub-secret-scan-wrapper-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-scrub-secret-scan-wrapper-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-surface-coverage-trend-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-surface-coverage-trend-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-surface-validation-driver-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-surface-validation-driver-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/ntm-wave2-native-probes-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/ntm-wave2-native-probes-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/orch-worker-identity-manifest-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/orch-worker-identity-manifest-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/orch-worker-identity-manifest.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/orch-worker-identity-manifest.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/peer-orch-productivity-watch.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/peer-orch-productivity-watch.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/peer-orch-respawn-permit.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/peer-orch-respawn-permit.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/picoz-archive-and-fresh-2026-05-07-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/picoz-archive-and-fresh-2026-05-07-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/plan-to-bead-auto-trigger-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/plan-to-bead-auto-trigger-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/polish-preflight-quality-gate-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/polish-preflight-quality-gate-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/pre-dispatch-state-db-lock-check-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/pre-dispatch-state-db-lock-check-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/private-tmp-prune-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/private-tmp-prune-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/private-tmp-prune.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/private-tmp-prune.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/promotion-candidate-stale-fire-reaper-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/promotion-candidate-stale-fire-reaper-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/public-artifact-pipeline-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/public-artifact-pipeline-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/quality-bar-close-gate.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/quality-bar-close-gate.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-baseline-snapshot-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/recovery-baseline-snapshot-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-baseline-status-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/recovery-baseline-status-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-doctor-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/recovery-doctor-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-escape-then-reprompt-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/recovery-escape-then-reprompt-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-install-plist-alpsinsurance-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/recovery-install-plist-alpsinsurance-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-install-plist-clutterfreespaces-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/recovery-install-plist-clutterfreespaces-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-install-plist-mobile-eats-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/recovery-install-plist-mobile-eats-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-install-plist-skillos-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/recovery-install-plist-skillos-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-preinstall-audit-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/recovery-preinstall-audit-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/recovery-restore-harness-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/recovery-restore-harness-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/regenerate-dicklesworthstone-sources-idempotency-key.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/regenerate-dicklesworthstone-sources-idempotency-key.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/regenerate-dicklesworthstone-sources.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/regenerate-dicklesworthstone-sources.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/rel-fixture-45987-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/rel-fixture-45987-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/rule-hint-lifecycle.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/rule-hint-lifecycle.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/scaffold-canonical-cli-apply-gate-regression.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/scaffold-canonical-cli-apply-gate-regression.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/scaffold-canonical-cli-e2e.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/scaffold-canonical-cli-e2e.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/security-precommit-hook.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/security-precommit-hook.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/security-precommit-installer-idempotency-key.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/security-precommit-installer-idempotency-key.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/security-settings-propagation.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/security-settings-propagation.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/sh_posix-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/sh_posix-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/shared-surface-reservation-check-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/shared-surface-reservation-check-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/skill-bandit-measurement-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/skill-bandit-measurement-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/skill-enhance-jsm-discipline-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/skill-enhance-jsm-discipline-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/skillos-routed-tail-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/skillos-routed-tail-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/skillos-template-handshake-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/skillos-template-handshake-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/stale-error-auto-ping-idempotency-key.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/stale-error-auto-ping-idempotency-key.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/stale-error-auto-ping.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/stale-error-auto-ping.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/stale-in-progress-reaper.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/stale-in-progress-reaper.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/state-md-miner-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/state-md-miner-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/state-md-miner.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/state-md-miner.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/state-store-authority-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/state-store-authority-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/storage-headroom-watcher-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/storage-headroom-watcher-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/storage-pause-auto-resume-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/storage-pause-auto-resume-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/storage-pause-auto-resume.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/storage-pause-auto-resume.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/storage-pressure-doctor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/storage-pressure-doctor-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/storage-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/storage-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/storage-prune-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/storage-prune-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/substrate-discipline-primitives.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/substrate-discipline-primitives.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/substrate-loop-contract-validator.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/substrate-loop-contract-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/supabase-rls-emergency-fix.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/supabase-rls-emergency-fix.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/sync-four-lens-validator.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/sync-four-lens-validator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/team-pulse-heartbeat-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/team-pulse-heartbeat-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/team-roster-watch-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/team-roster-watch-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/tentacle-drift-sweep.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/tentacle-drift-sweep.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/tentacle-inventory-bump-atomic-fixture.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/tentacle-inventory-bump-atomic-fixture.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-agent-mail-redact-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-agent-mail-redact-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-auto-respawn-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-auto-respawn-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-doctor-empty-errors-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-doctor-empty-errors-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-fmnv2-sync-canonical-root-block-roundtrip.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-fmnv2-sync-canonical-root-block-roundtrip.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-fuckup-join-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-fuckup-join-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-inject-memory-hits-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-inject-memory-hits-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-loop-driver-doctor-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-loop-driver-doctor-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-safe-probe-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-safe-probe-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-skillos-bridge-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-skillos-bridge-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-sync-canonical-doctrine-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-sync-canonical-doctrine-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-sync-stamped-repos-coverage-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-sync-stamped-repos-coverage-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-tmp-aggressive-prune.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-tmp-aggressive-prune.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test-tmp-prune.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test-tmp-prune.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_apply_substrate_tuning.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_apply_substrate_tuning.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_apply_tmux_tuning.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_apply_tmux_tuning.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_bead_evidence_indexer.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_bead_evidence_indexer.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_dispatch_enforcement_backfill.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_dispatch_enforcement_backfill.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_flywheel_adopt_command_contract.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_flywheel_adopt_command_contract.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_flywheel_loop_activation_contract.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_flywheel_loop_activation_contract.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_flywheel_loop_driver_writeback.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_flywheel_loop_driver_writeback.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_flywheel_loop_revive.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_flywheel_loop_revive.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_idle_pane_watcher_convergence.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_idle_pane_watcher_convergence.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_mission_lock_frontmatter_idempotent.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_mission_lock_frontmatter_idempotent.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_regen_sources_from_gh.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_regen_sources_from_gh.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_skillos_discovery_coordinator.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_skillos_discovery_coordinator.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_skillos_notify.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_skillos_notify.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/test_worker_tick_jsm_outcomes.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/test_worker_tick_jsm_outcomes.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/tick-skill-version-check-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/tick-skill-version-check-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/tmp-aggressive-prune-doctor.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/tmp-aggressive-prune-doctor.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/tmp-prune-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/tmp-prune-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/topology-tick-refresh-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/topology-tick-refresh-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/trauma-handoff-agent-mail-send.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/trauma-handoff-agent-mail-send.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/validate-callback-before-close-canonical-cli.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/validate-callback-before-close-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/validate-callback-before-close.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/validate-callback-before-close.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/validate-skill-discovery-callback-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/validate-skill-discovery-callback-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/validation-fix-bead.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/validation-fix-bead.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/value-gap-probe.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/value-gap-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/verify-watcher-launchd-active-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/verify-watcher-launchd-active-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/wire-or-explain-close-gate.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/wire-or-explain-close-gate.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/worker-auto-respawn-watchdog-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/worker-auto-respawn-watchdog-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/worker-auto-respawn-watchdog-install-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/worker-auto-respawn-watchdog-install-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/worker-head-verify-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/worker-head-verify-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/worker-stall-alert-probe.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/worker-stall-alert-probe.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [
        "tests/worker-tick-jsm-outcomes-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": "tests/worker-tick-jsm-outcomes-canonical-cli.sh",
      "reason": "fixture exists but no parity assertion was detected",
      "source_type": "test",
      "status": "FAIL"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/agentmail-fd-pressure-probe.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/blocker-discipline-tick-chain-launchd-install.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/branch-protection-fleet-rollout.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/canonical-cli-lint-precommit-installer.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/coordinator-daemon-health.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/dispatch-log-fitness-invariant.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/doctrine-polish-bar-lint.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/flywheel-onboard.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/gap-hunt-probe-self-calibration.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/git-main-sync-fleet-rollout.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/install-coordinator-daemon.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/install-fleet-codex-health-launchd.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/install-git-main-sync-launchd.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/install-stuck-detector-watchdog.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/integrate-stall-escalator.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mission-fitness-callback-validator.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mission-fitness-doctor.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mp-scaffolder-runner.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mp-scaffolders/MP-82-hook-lifecycle-guardrail-chain-scaffold.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mp-scaffolders/MP-89-mode-scoped-phase-workspace-scaffold.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mp-scaffolders/MP-90-adjacent-skill-boundary-router-scaffold.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mp-scaffolders/MP-91-progress-counter-forced-motion-loop-scaffold.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/mp-scaffolders/MP-97-federated-retrieval-parity-provenance-scaffold.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-audit-receipts.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-checkpoint-rollback-guard.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-metrics-doctor-probe.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-policy-contracts.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-quota-proactive-probe.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/ntm-serve-eventstream-bridge.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/orch-tick-stale-auto-bead-close.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/parity-contract-add-fixture.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/pre-write-path-guard.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/scaffold-canonical-cli-py.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/scaffold-doc-frontmatter.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/session-residue-prune.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/supabase-local-validate-and-push.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [],
      "path": ".flywheel/scripts/validation-e2e-smoke.sh",
      "reason": "no matching smoke fixture found",
      "source_type": "script",
      "status": "NO-FIXTURE"
    },
    {
      "fixtures": [
        "tests/bcv-task-harness.sh",
        "tests/bcv-task-harness-canonical-cli.sh",
        "tests/bcv-task-harness-idempotency-key.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [
        "tests/bcv-task-harness-idempotency-key.sh"
      ],
      "path": ".flywheel/scripts/bcv-task-harness.sh",
      "reason": "fixture contains parity assertion",
      "source_type": "script",
      "status": "PASS"
    },
    {
      "fixtures": [
        "tests/branch-protection-apply-smoke.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [
        "tests/branch-protection-apply-smoke.sh"
      ],
      "path": ".flywheel/scripts/branch-protection-apply.sh",
      "reason": "fixture contains parity assertion",
      "source_type": "script",
      "status": "PASS"
    },
    {
      "fixtures": [
        "tests/cleanup-scratch.sh",
        "tests/cleanup-scratch-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [
        "tests/cleanup-scratch-canonical-cli.sh"
      ],
      "path": ".flywheel/scripts/cleanup-scratch.sh",
      "reason": "fixture contains parity assertion",
      "source_type": "script",
      "status": "PASS"
    },
    {
      "fixtures": [
        "tests/parity-contract-validator-smoke.sh"
      ],
      "mode_groups": [
        "dry_run_apply",
        "check_commit",
        "plan_execute"
      ],
      "parity_fixtures": [
        "tests/parity-contract-validator-smoke.sh"
      ],
      "path": ".flywheel/scripts/parity-contract-validator.sh",
      "reason": "fixture contains parity assertion",
      "source_type": "script",
      "status": "PASS"
    },
    {
      "fixtures": [
        "tests/bcv-task-harness-idempotency-key.sh"
      ],
      "mode_groups": [
        "default_dry_run_apply"
      ],
      "parity_fixtures": [
        "tests/bcv-task-harness-idempotency-key.sh"
      ],
      "path": "tests/bcv-task-harness-idempotency-key.sh",
      "reason": "fixture contains parity assertion",
      "source_type": "test",
      "status": "PASS"
    },
    {
      "fixtures": [
        "tests/branch-protection-apply-smoke.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [
        "tests/branch-protection-apply-smoke.sh"
      ],
      "path": "tests/branch-protection-apply-smoke.sh",
      "reason": "fixture contains parity assertion",
      "source_type": "test",
      "status": "PASS"
    },
    {
      "fixtures": [
        "tests/cleanup-scratch-canonical-cli.sh"
      ],
      "mode_groups": [
        "dry_run_apply"
      ],
      "parity_fixtures": [
        "tests/cleanup-scratch-canonical-cli.sh"
      ],
      "path": "tests/cleanup-scratch-canonical-cli.sh",
      "reason": "fixture contains parity assertion",
      "source_type": "test",
      "status": "PASS"
    },
    {
      "fixtures": [
        "tests/parity-contract-validator-smoke.sh"
      ],
      "mode_groups": [
        "dry_run_apply",
        "plan_execute"
      ],
      "parity_fixtures": [
        "tests/parity-contract-validator-smoke.sh"
      ],
      "path": "tests/parity-contract-validator-smoke.sh",
      "reason": "fixture contains parity assertion",
      "source_type": "test",
      "status": "PASS"
    }
  ],
  "schema_version": "parity-contract-conformance.v1",
  "scripts_dir": ".flywheel/scripts",
  "status": "fail",
  "summary": {
    "fail": 553,
    "no_fixture": 37,
    "pass": 8,
    "total": 598
  },
  "tests_dir": "tests"
}
```
