# C2 Frozen Projection Invariant Scanner Deep Research

Scope: read-only design for `frozen-projection-of-mutable-state` scanner. Sources read: `/Users/josh/Developer/flywheel/.flywheel/plans/orch-uptime-2026-05-06/01-RESEARCH-C.md` sections "Frozen Projection Extension" and "Doctor Invariant Proposal"; `/Users/josh/Developer/flywheel/.flywheel/plans/orch-uptime-2026-05-06/03-AUDIT-r1-paradigm.md` F4 amendment.

Socraticode: 10 searches, canonical repo `/Users/josh/Developer/flywheel`, indexed chunks observed 978. Relevant hits: L57/L117 driver proof, `templates/flywheel-install/schema.json` driver keys, `tests/flywheel-tick-driver.sh`, dispatch contract in `README.md`, F4 warn-before-fail precedent in plan/audit incidents.

## 1. Five Concrete Scan-Input Groups

Scanner should collect with deterministic sort and absolute paths. These are the current concrete inputs.

### G1 LaunchAgent plists: `/Users/josh/Library/LaunchAgents/*.plist` (134)
- G1.01: /Users/josh/Library/LaunchAgents/com.cubcloud.cass-weekly-reflect.plist; /Users/josh/Library/LaunchAgents/com.rano.daemon.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.mission-gap-bead-proposer.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.cost-per-customer.plist; /Users/josh/Library/LaunchAgents/com.google.keystone.xpcservice.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.skill-gap-detector.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.codex-stuck-detector-watchdog.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.ntm-watcher-heartbeat.plist
- G1.02: /Users/josh/Library/LaunchAgents/com.claudemem.worker.plist; /Users/josh/Library/LaunchAgents/com.pico-z.decision-ledger-sentinel.plist; /Users/josh/Library/LaunchAgents/com.zeststream.anthropic-proxy.plist; /Users/josh/Library/LaunchAgents/homebrew.mxcl.grafana.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.skillos-beads-prefix-watcher.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.context-integrity-scan-skills.plist; /Users/josh/Library/LaunchAgents/com.zeststream.docker-autostart.plist; /Users/josh/Library/LaunchAgents/com.google.keystone.agent.plist
- G1.03: /Users/josh/Library/LaunchAgents/com.kgraph.nightly-pipeline.plist; /Users/josh/Library/LaunchAgents/com.pico-z.l1-sentinel.plist; /Users/josh/Library/LaunchAgents/homebrew.mxcl.prometheus.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.frozen-pane-detector-fleet.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.mcp-agent-mail-local.plist; /Users/josh/Library/LaunchAgents/com.zeststream.bead-stats-sweep.plist; /Users/josh/Library/LaunchAgents/com.zeststream.substrate-doctor.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.search-quality-feedback.plist
- G1.04: /Users/josh/Library/LaunchAgents/ai.zeststream.alps-idle-pane-watch.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.learning-healthcheck.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-idle-pane-watch.plist; /Users/josh/Library/LaunchAgents/com.zeststream.nightly-regression.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.storage-health.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.vrtx-idle-pane-watch.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.skillos-codex-stuck-detector.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.mobile-eats-flywheel-loop.plist
- G1.05: /Users/josh/Library/LaunchAgents/ai.zeststream.skillos-blocker-tick-watcher.plist; /Users/josh/Library/LaunchAgents/com.clawdbot.gateway.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.infisical-sync.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.daily-ledger-sync.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.mission-freshness-audit.plist; /Users/josh/Library/LaunchAgents/com.zeststream.cross-project-sweep.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.research-arxiv-poll.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.skill-quality-heatmap.plist
- G1.06: /Users/josh/Library/LaunchAgents/ai.zeststream.canonical-meta-rules-sync-watchdog.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.skill-hash-ledger-build.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.skillos-idle-pane-watch.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.mobile-eats-codex-stuck-detector.plist; /Users/josh/Library/LaunchAgents/com.jeffreys-skills.jsm-auto-update.plist; /Users/josh/Library/LaunchAgents/com.zeststream.skill-metrics-collect.plist; /Users/josh/Library/LaunchAgents/com.cass.autoindex.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.security-posture.plist
- G1.07: /Users/josh/Library/LaunchAgents/com.cubcloud.skills-sync.plist; /Users/josh/Library/LaunchAgents/homebrew.mxcl.sleepwatcher.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-jeff-x-poll.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.alps-flywheel-loop.plist; /Users/josh/Library/LaunchAgents/com.flywheel.tick.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.python-inventory.plist; /Users/josh/Library/LaunchAgents/com.flywheel.shutdown-recovery.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.ecosystem-port-security-drift.plist
- G1.08: /Users/josh/Library/LaunchAgents/com.cass.reflect.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.plan-archive-stale.plist; /Users/josh/Library/LaunchAgents/ai.openclaw.gateway.plist; /Users/josh/Library/LaunchAgents/com.zeststream.deal-webhook-listener.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.auto-skill-grader.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-jeff-philosophy-monthly.plist; /Users/josh/Library/LaunchAgents/com.caam.auth-agent.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.skillos-flywheel-loop.plist
- G1.09: /Users/josh/Library/LaunchAgents/com.pico-z.stats-sampler.plist; /Users/josh/Library/LaunchAgents/com.pico-z.wal-checkpoint-cron.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.skill-outcome-harvester.plist; /Users/josh/Library/LaunchAgents/homebrew.mxcl.redis.plist; /Users/josh/Library/LaunchAgents/com.zeststream.flywheel-idle-pane-watch.plist; /Users/josh/Library/LaunchAgents/com.pico-z.weekly-cache-prune.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.auto-trigger-autoresearch.plist; /Users/josh/Library/LaunchAgents/com.pico-z.kalshi-capture-full.plist
- G1.10: /Users/josh/Library/LaunchAgents/com.ntm.bead-status.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.qdrant-keepalive.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.skill-proposal-generator.plist; /Users/josh/Library/LaunchAgents/com.zeststream.cc-cleanup.plist; /Users/josh/Library/LaunchAgents/com.zeststream.lone-wolves-sweep.plist; /Users/josh/Library/LaunchAgents/com.zeststream.jsm-sync.plist; /Users/josh/Library/LaunchAgents/com.ccmirror.ccr.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.skill-pass-to-beads.plist
- G1.11: /Users/josh/Library/LaunchAgents/homebrew.mxcl.postgresql@17.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.service-slo-check.plist; /Users/josh/Library/LaunchAgents/com.zeststream.claude-orphan-reaper.plist; /Users/josh/Library/LaunchAgents/com.zeststream.ks-server.plist; /Users/josh/Library/LaunchAgents/com.zeststream.heartbeat-liveness.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-daily-jeff-ingest.plist; /Users/josh/Library/LaunchAgents/com.zeststream.infisical-sync.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.research-reddit-poll.plist
- G1.12: /Users/josh/Library/LaunchAgents/homebrew.mxcl.ollama.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.alps-codex-stuck-detector.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.continuous-productivity-detector.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.baseline-capture.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.claude-creds-mirror.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.worker-auto-respawn-watchdog.plist; /Users/josh/Library/LaunchAgents/com.cass-v2.eval-regression.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.compliance-audit.plist
- G1.13: /Users/josh/Library/LaunchAgents/com.cubcloud.cross-project-promoter.plist; /Users/josh/Library/LaunchAgents/com.zeststream.secret-permissions-auditor.plist; /Users/josh/Library/LaunchAgents/com.zeststream.ccmirror-update.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.context-integrity-scan.plist; /Users/josh/Library/LaunchAgents/com.zeststream.docker-maintenance.plist; /Users/josh/Library/LaunchAgents/com.zeststream.cass-sync.plist; /Users/josh/Library/LaunchAgents/com.zeststream.skill-pass-sweep.plist; /Users/josh/Library/LaunchAgents/com.pico-z.p0-probes.plist
- G1.14: /Users/josh/Library/LaunchAgents/ai.zeststream.codex-watchtower-daily.plist; /Users/josh/Library/LaunchAgents/com.zeststream.daemon-cron.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.skill-index-qdrant.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.arxiv-research-pipeline.plist; /Users/josh/Library/LaunchAgents/com.opencode.wisdom-update.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.orbstack-trial-reminder.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.stale-knowledge-refresh.plist; /Users/josh/Library/LaunchAgents/com.pico-z.ingest-server.plist
- G1.15: /Users/josh/Library/LaunchAgents/ai.zeststream.ntm-fleet-health.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.mission-staleness-detector.plist; /Users/josh/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.jeff-daily-stack-ingest.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.pipeline-conformance.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.python-health.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.token-efficiency.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.skill-refresh.plist
- G1.16: /Users/josh/Library/LaunchAgents/com.pico-z.batch-import.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.self-healing-monitor.plist; /Users/josh/Library/LaunchAgents/com.caam.daemon.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.hook-health-check.plist; /Users/josh/Library/LaunchAgents/com.cubcloud.sglang-latency-metrics.plist; /Users/josh/Library/LaunchAgents/com.zeststream.deal-tracker.plist; /Users/josh/Library/LaunchAgents/com.zeststream.mga-status.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.mobile-eats-idle-pane-watch.plist
- G1.17: /Users/josh/Library/LaunchAgents/com.caam.auth-coordinator.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.research-weekly-reconcile.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.vrtx-codex-stuck-detector.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.system-health.plist; /Users/josh/Library/LaunchAgents/ai.zeststream.flywheel-codex-stuck-detector.plist; /Users/josh/Library/LaunchAgents/homebrew.mxcl.postgresql@16.plist

### G2 Loop tick scripts: `/Users/josh/.local/bin/*flywheel-loop-tick` (2)
- G2.01: /Users/josh/.local/bin/mobile-eats-flywheel-loop-tick; /Users/josh/.local/bin/alps-flywheel-loop-tick

### G3 Repo tick/watch/stuck scripts: `/Users/josh/Developer/flywheel/.flywheel/scripts/*{tick,watch,stuck}*` (25)
- G3.01: /Users/josh/Developer/flywheel/.flywheel/scripts/worker-auto-respawn-watchdog.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/ticks-punted-probe.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/watcher-isomorphic-probe.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/halt-disease-watchdog.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/halt-disease-watchdog.md; /Users/josh/Developer/flywheel/.flywheel/scripts/jeff-corpus-diff-watcher.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/tick-receipt-validator.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/tick-hook-firing-verifier.sh
- G3.02: /Users/josh/Developer/flywheel/.flywheel/scripts/codex-template-stuck-detector-watchdog.plist; /Users/josh/Developer/flywheel/.flywheel/scripts/josh-request-tick-promote.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/peer-orch-productivity-watch.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/verify-watcher-launchd-active.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/two-blocker-ticks-escalator.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/storage-headroom-watcher.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/l70-ticks-punted-counter.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/tick-driver-manifest.json
- G3.03: /Users/josh/Developer/flywheel/.flywheel/scripts/inbox-check-tick-step.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/tick-skill-version-check.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/flywheel-codex-stuck-detector-install.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/codex-template-stuck-detector.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/peer-orch-blocker-watch.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/jeff-binary-version-watchtower.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/install-stuck-detector-watchdog.sh; /Users/josh/Developer/flywheel/.flywheel/scripts/fleet-watcher-coverage-probe.sh
- G3.04: /Users/josh/Developer/flywheel/.flywheel/scripts/worker-auto-respawn-watchdog-install.sh

### G4 Templates: `/Users/josh/Developer/flywheel/.flywheel/templates/**`, `/Users/josh/Developer/flywheel/templates/**` (88)
- G4.01: /Users/josh/Developer/flywheel/.flywheel/templates/skill-handoff-to-skillos.md; /Users/josh/Developer/flywheel/templates/josh-request-schema.v1-archive.md; /Users/josh/Developer/flywheel/templates/josh-request-schema.md; /Users/josh/Developer/flywheel/templates/fuckup-heuristics.json; /Users/josh/Developer/flywheel/templates/flywheel-install/.flywheel/reboot-recovery/.gitkeep; /Users/josh/Developer/flywheel/templates/flywheel-install/.flywheel/scripts/idle-pane-mechanical-gate.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/ESCALATION-LADDER.md.tmpl; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/v1/grade-receipt.schema.json
- G4.02: /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/v1/phase-2-audit-verdict.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/v1/close-validation-result.schema.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/v1/latest-summary.schema.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/v1/scope-allowlist.schema.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/v1/replay-output.schema.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/v1/reconcile-output.schema.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/v1/grade-run-result.schema.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/v1/discovery-output.schema.json
- G4.03: /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/v1/manifest.schema.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/replay-to-ledger.py; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/PHASE-3-BROADCAST-COMPLETE.flag; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/PHASE-3-BROADCAST-RECEIPT.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/run-grader.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/discover-surfaces.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/__pycache__/discover-surfaces.cpython-314.pyc; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/__pycache__/replay-to-ledger.cpython-314.pyc
- G4.04: /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/__pycache__/run-grader.cpython-314.pyc; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/README.md; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/PHASE-2-AUDIT.md; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/replay-to-ledger.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/fixtures/audit-only-mode.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/fixtures/bootstrap-mode.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/fixtures/blocking-mode.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/fixtures/scope-allowlist/malformed-no-allowlist.json
- G4.05: /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/fixtures/scope-allowlist/skillos.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/fixtures/scope-allowlist/swarm-daemon.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/fixtures/scope-allowlist/alps.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/fixtures/scope-allowlist/vrtx.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/fixtures/scope-allowlist/mobile-eats.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/fixtures/scope-allowlist/default.json; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/run-grader.py; /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/discover-surfaces.py
- G4.06: /Users/josh/Developer/flywheel/templates/flywheel-install/MISSION.md.tmpl.bak.20260503T021638Z; /Users/josh/Developer/flywheel/templates/flywheel-install/schema.json.bak.20260503T021638Z; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_polish_gate_close_validator.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_polish_gate_schema_inventory_parity.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_polish_gate_reconcile.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_render.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_polish_gate_integration.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_polish_gate_runner.sh
- G4.07: /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_render.sh.bak.20260503T021638Z; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/malformed-manifest/permission-denied/manifest.json; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/malformed-manifest/truncated.json; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/malformed-manifest/missing-required-field.json; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/malformed-manifest/wrong-shape.json; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/malformed-manifest/invalid-utf8.json; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/custom-mode-set/.flywheel/loop.json; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/custom-mode-set/.flywheel/MISSION.md
- G4.08: /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/custom-mode-set/.flywheel/STATE.md; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/fresh/.flywheel/loop.json; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/fresh/.flywheel/MISSION.md; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/fresh/.flywheel/STATE.md; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/malformed/.flywheel/loop.json; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/malformed/.flywheel/MISSION.md; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/malformed/.flywheel/STATE.md; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/rollback/.flywheel/loop.json
- G4.09: /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/rollback/.flywheel/MISSION.md; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/rollback/.flywheel/STATE.md; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/pre-polish-gate/.flywheel/loop.json; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/pre-polish-gate/.flywheel/MISSION.md; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/fixtures/polish-gate-reconcile/pre-polish-gate/.flywheel/STATE.md; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_polish_gate_aggregate_schemas.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_polish_gate_scope_allowlist.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_polish_gate_discovery.sh
- G4.10: /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_polish_gate_ledger_replay.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/tests/test_polish_gate_schemas.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/GOAL.md.tmpl; /Users/josh/Developer/flywheel/templates/flywheel-install/STATE.md.tmpl; /Users/josh/Developer/flywheel/templates/flywheel-install/README.md; /Users/josh/Developer/flywheel/templates/flywheel-install/loop.json.tmpl; /Users/josh/Developer/flywheel/templates/flywheel-install/halt-contract/v1.schema.json; /Users/josh/Developer/flywheel/templates/flywheel-install/halt-contract/fixtures/red-beads-db.json
- G4.11: /Users/josh/Developer/flywheel/templates/flywheel-install/halt-contract/fixtures/yellow-disk.json; /Users/josh/Developer/flywheel/templates/flywheel-install/halt-contract/fixtures/green.json; /Users/josh/Developer/flywheel/templates/flywheel-install/validate-callback-before-close.sh.tmpl; /Users/josh/Developer/flywheel/templates/flywheel-install/render.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/scripts/reconcile-polish-gate.sh; /Users/josh/Developer/flywheel/templates/flywheel-install/schema.json; /Users/josh/Developer/flywheel/templates/flywheel-install/MISSION.md.tmpl; /Users/josh/Developer/flywheel/templates/flywheel-install/AGENTS.md

### G5 Flywheel command surfaces: `/Users/josh/.claude/commands/flywheel/**` (79)
- G5.01: /Users/josh/.claude/commands/flywheel/mission-lock.md.bak.20260503T023132Z; /Users/josh/.claude/commands/flywheel/lock.md; /Users/josh/.claude/commands/flywheel/status.md.bak.20260503T002441Z; /Users/josh/.claude/commands/flywheel/tick.md.bak.20260503T001429Z; /Users/josh/.claude/commands/flywheel/beads.md; /Users/josh/.claude/commands/flywheel/weeklyreflection.md; /Users/josh/.claude/commands/flywheel/tick.md.bak.20260503T082954Z; /Users/josh/.claude/commands/flywheel/tick.md.bak.20260501T083108
- G5.02: /Users/josh/.claude/commands/flywheel/tick.md; /Users/josh/.claude/commands/flywheel/learn.md; /Users/josh/.claude/commands/flywheel/inbox.md; /Users/josh/.claude/commands/flywheel/loop.md; /Users/josh/.claude/commands/flywheel/ntm.md.bak.20260503T014204Z; /Users/josh/.claude/commands/flywheel/research.md.bak.20260503T021415Z; /Users/josh/.claude/commands/flywheel/mission-lock.md; /Users/josh/.claude/commands/flywheel/loop.md.bak.20260503T002121Z
- G5.03: /Users/josh/.claude/commands/flywheel/learn.md.bak.20260503T023132Z; /Users/josh/.claude/commands/flywheel/mem.md; /Users/josh/.claude/commands/flywheel/jeff-intel.md; /Users/josh/.claude/commands/flywheel/skills-best-practices.md; /Users/josh/.claude/commands/flywheel/status.md; /Users/josh/.claude/commands/flywheel/skills-best-practices.md.bak.20260503T021456Z; /Users/josh/.claude/commands/flywheel/learn.md.bak.20260503T022001Z; /Users/josh/.claude/commands/flywheel/tick.md.bak.20260503T083705Z
- G5.04: /Users/josh/.claude/commands/flywheel/newcmd.md; /Users/josh/.claude/commands/flywheel/jeff-status.md; /Users/josh/.claude/commands/flywheel/relock-state.md.bak.20260503T014204Z; /Users/josh/.claude/commands/flywheel/init.md; /Users/josh/.claude/commands/flywheel/jeff-philosophy.md; /Users/josh/.claude/commands/flywheel/worker-tick.md; /Users/josh/.claude/commands/flywheel/README.md; /Users/josh/.claude/commands/flywheel/recovery.md
- G5.05: /Users/josh/.claude/commands/flywheel/fleet-doctor.md; /Users/josh/.claude/commands/flywheel/README.md.bak.20260503T021638Z; /Users/josh/.claude/commands/flywheel/research.md.bak.20260503T001923Z; /Users/josh/.claude/commands/flywheel/plan.md.bak.20260503T014204Z; /Users/josh/.claude/commands/flywheel/jeff-issue.md; /Users/josh/.claude/commands/flywheel/daily-report.md; /Users/josh/.claude/commands/flywheel/research.md; /Users/josh/.claude/commands/flywheel/relock-state.md
- G5.06: /Users/josh/.claude/commands/flywheel/synth.md; /Users/josh/.claude/commands/flywheel/fleet-observatory.md; /Users/josh/.claude/commands/flywheel/onboard.md; /Users/josh/.claude/commands/flywheel/tick.md.bak.flywheel-2xmq.1-20260503T0411Z; /Users/josh/.claude/commands/flywheel/tail.md; /Users/josh/.claude/commands/flywheel/tick.md.bak.flywheel-tbp-20260503T0359Z; /Users/josh/.claude/commands/flywheel/dispatch.md.bak.20260503T000707Z; /Users/josh/.claude/commands/flywheel/plan.md
- G5.07: /Users/josh/.claude/commands/flywheel/plan.md.bak.20260503T021415Z; /Users/josh/.claude/commands/flywheel/_shared/three-judges-publishability-precheck.sh; /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md; /Users/josh/.claude/commands/flywheel/_shared/test-inject-memory-hits.sh; /Users/josh/.claude/commands/flywheel/_shared/orch-callback-artifact-wrapper.sh; /Users/josh/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh; /Users/josh/.claude/commands/flywheel/_shared/dispatch-pre-send-validator.sh; /Users/josh/.claude/commands/flywheel/_shared/dispatch-canonical-cli-precheck.sh
- G5.08: /Users/josh/.claude/commands/flywheel/_shared/inject-skill-auto-routes.sh; /Users/josh/.claude/commands/flywheel/_shared/pane-state.sh; /Users/josh/.claude/commands/flywheel/_shared/pane-state.sh.bak.20260503T001345Z; /Users/josh/.claude/commands/flywheel/_shared/dispatch-delivery-postcheck.sh; /Users/josh/.claude/commands/flywheel/_shared/source-repo-check.sh; /Users/josh/.claude/commands/flywheel/_shared/inject-memory-hits.sh; /Users/josh/.claude/commands/flywheel/_shared/close-handler.md; /Users/josh/.claude/commands/flywheel/_shared/mission-anchor-dispatch-preflight.sh
- G5.09: /Users/josh/.claude/commands/flywheel/bead-new.md.bak.20260503T021415Z; /Users/josh/.claude/commands/flywheel/tick.md.bak; /Users/josh/.claude/commands/flywheel/tick.md.bak.20260503T023132Z; /Users/josh/.claude/commands/flywheel/loop.md.bak.20260503T014204Z; /Users/josh/.claude/commands/flywheel/upgrade.md; /Users/josh/.claude/commands/flywheel/mission-lock.md.bak.20260503T021456Z; /Users/josh/.claude/commands/flywheel/bead-new.md; /Users/josh/.claude/commands/flywheel/handoff.md.bak.20260503T002747Z
- G5.10: /Users/josh/.claude/commands/flywheel/tick.md.bak.20260503T033809Z; /Users/josh/.claude/commands/flywheel/dispatch.md; /Users/josh/.claude/commands/flywheel/storage-prune.md; /Users/josh/.claude/commands/flywheel/respawn.md; /Users/josh/.claude/commands/flywheel/ntm.md; /Users/josh/.claude/commands/flywheel/handoff.md; /Users/josh/.claude/commands/flywheel/fleet-conductor.md

## 2. Rough Literal Counts

Method: socraticode K=10 located relevant code/doctrine/test surfaces, then `rg` ran over the enumerated path sets using the regex bank below. `raw mutable-keyword hits` is broad triage volume. `strict forbidden-literal hits` is exact captured mutable value risk before allow suppression.

| group | files | raw mutable-keyword hits | strict forbidden-literal hits | allow/source hits | files with allow hits |
|---|---:|---:|---:|---:|---:|
| G1 LaunchAgents | 134 | 51 | 0 | 7 | 7 |
| G2 local tick scripts | 2 | 87 | 0 | 45 | 2 |
| G3 repo tick/watch/stuck | 25 | 416 | 0 | 174 | 20 |
| G4 templates | 88 | 444 | 0 | 209 | 23 |
| G5 commands | 79 | 955 | 0 | 210 | 37 |

Interpretation: the first implementation should emit WARN rows for raw mutable-keyword density, but only FAIL on unallowed strict forbidden patterns. Naive keyword fail-closed would violate F4.

## 3. Regex Bank Ready To Ship

Use case-insensitive Rust/`rg`-compatible regex. Treat allow patterns as downgrades only for non-secret findings; `secret_value_literal` is never allow-suppressed.

```yaml
forbidden:
  blocker_literal: '\b(blocker(_id)?|current_blocker|active_blocker)\b[[:space:]]*[:=][[:space:]]*["'']?([A-Za-z0-9_.-]{3,}|[a-z]+-[a-z0-9-]+)'
  literal_pane_arg: '(--pane(=|[[:space:]]+)|\bpane[[:space:]]*[:=][[:space:]]*)[0-9]+\b'
  literal_pane_collection: '\b(worker_panes?|shell_panes|human_pane|orchestrator_pane|callback_pane)\b[[:space:]]*[:=][[:space:]]*(\[[0-9,[:space:]]+\]|[0-9,[:space:]]+)'
  serialized_topology_snapshot: '\b(session_topology|worker_kinds|topology_rows?|latest_topology|effective_at|last_seen_at)\b[[:space:]]*[:=][[:space:]]*["''{[]'
  active_profile_literal: '\b(active_profile|current_profile|selected_profile|profile_name|credential_profile)\b[[:space:]]*[:=][[:space:]]*["'']?[A-Za-z0-9_.-]+'
  recovery_decision_literal: '\b(recovery_decision|recommended_recovery|authorization_outcome|current_recovery)\b[[:space:]]*[:=][[:space:]]*["'']?[A-Za-z0-9_.-]+'
  secret_value_literal: '\b(token|bearer|api[_-]?key|secret|password)\b[[:space:]]*[:=][[:space:]]*["''][^"''$<>{}][^"'']{8,}'
  unguarded_positional_arg: '(^|[^\\])\$[1-9]\b'
allow:
  topology_lookup_flag: '--worker-panes-from-topology'
  topology_source_ref: '--topology-file(=|[[:space:]]+)|FLYWHEEL_SESSION_TOPOLOGY|session-topology\.jsonl'
  mutable_state_path_ref: '(state_file|STATE_FILE|blocker_state_path|BLOCKER_STATE_PATH|STATE_PATH|TOPOLOGY_PATH)[[:space:]]*='
  instruction_to_read_source: '(Read|read)[^\n]*(STATE|MISSION|GOAL|WORK|session-topology|blocker|topology)[^\n]*(then|decide|derive|lookup)'
  template_placeholder: '\{\{[A-Z0-9_]+\}\}|\$\{[A-Z0-9_]+(:-[^}]*)?\}'
  immutable_hash_literal: '\b[a-f0-9]{40,64}\b'
  documented_constant_label: '\b(schema_version|schema_name|command_name|template_version|reason_code)\b'
```

Implementation note: scanner should output both `raw_match_text_redacted` and `capture_class`. For `secret_value_literal`, redact to key name plus hash of value, never emit raw match.

## 4. F4 Warn-Vs-Fail Ladder With Mtime Cutoff

Inputs:
- `cutoff_ts`: explicit ISO timestamp, required for enforcement mode. Default proposal: first merge/install time for this scanner, not current runtime.
- `strict_promoted_at`: null until C4 fleet sweep files/assigns remediation beads for existing debt.
- `file_mtime`: filesystem mtime in UTC for each scanned file.

Ladder:
1. PASS: no strict forbidden hits; raw keyword density only appears with allow/source patterns.
2. WARN existing debt: unallowed strict forbidden hit in a file with `file_mtime <= cutoff_ts`; include `finding_age_sec`, owner `fleet-sweep`, and remediation status `unassigned`.
3. FAIL new debt: unallowed strict forbidden hit in a file with `file_mtime > cutoff_ts`; this covers newly modified templates, plists, commands, and scripts.
4. FAIL always: `secret_value_literal`, unreadable required scan group, malformed plist that prevents extraction, or inline allow receipt with no reason/source.
5. WARN assigned debt: after C4 sweep, pre-cutoff findings with `remediation_bead` and `owner` stay WARN until due date.
6. FAIL overdue debt: after `strict_promoted_at`, any pre-cutoff finding without `remediation_bead`, or assigned finding past due, becomes FAIL.
7. Strict mode: `--strict` treats scanner execution errors as FAIL; audit mode treats execution errors as WARN unless scan group G1 or G2 is missing.

This implements F4: existing fleet debt starts visible as WARN; only newly modified in-scope surfaces and unsafe secret material block immediately.

## 5. Doctor Output Schema

```json
{
  "schema_version": "frozen-projection-invariant/v1",
  "status": "pass|warn|fail",
  "mode": "audit|strict",
  "repo": "/Users/josh/Developer/flywheel",
  "observed_at": "2026-05-06T00:00:00Z",
  "cutoff_ts": "2026-05-06T00:00:00Z",
  "strict_promoted_at": null,
  "socraticode_queries": 10,
  "indexed_chunks_observed": 978,
  "scan_files": 328,
  "scan_inputs": [
    {"group":"launchagents","glob":"/Users/josh/Library/LaunchAgents/*.plist","files":134,"raw_mutable_keyword_hits":51,"strict_forbidden_hits":0,"allow_hits":7},
    {"group":"local_tick_scripts","glob":"/Users/josh/.local/bin/*flywheel-loop-tick","files":2,"raw_mutable_keyword_hits":87,"strict_forbidden_hits":0,"allow_hits":45},
    {"group":"repo_tick_watch_stuck","glob":"/Users/josh/Developer/flywheel/.flywheel/scripts/*{tick,watch,stuck}*","files":25,"raw_mutable_keyword_hits":416,"strict_forbidden_hits":0,"allow_hits":174},
    {"group":"templates","glob":"/Users/josh/Developer/flywheel/{.flywheel/templates,templates}/**","files":88,"raw_mutable_keyword_hits":444,"strict_forbidden_hits":0,"allow_hits":209},
    {"group":"commands","glob":"/Users/josh/.claude/commands/flywheel/**","files":79,"raw_mutable_keyword_hits":955,"strict_forbidden_hits":0,"allow_hits":210}
  ],
  "frozen_projection_count": 0,
  "frozen_projection_by_target": {},
  "literal_payload_targets": [],
  "path_named_payload_targets": [],
  "oldest_literal_age_sec": null,
  "newest_fail_mtime": null,
  "warnings": [],
  "errors": [],
  "findings": [
    {
      "finding_id": "fp-0001",
      "severity": "warn|fail",
      "group": "templates",
      "path": "/abs/path",
      "line": 1,
      "pattern_id": "literal_pane_arg",
      "allow_pattern_id": null,
      "file_mtime": "2026-05-06T00:00:00Z",
      "mtime_relation": "pre_cutoff|post_cutoff",
      "reason_code": "frozen_projection_literal|secret_value_literal|scanner_input_unreadable",
      "remediation_bead": null,
      "raw_match_text_redacted": "--pane=3"
    }
  ]
}
```

Doctor should expose summary fields directly at top level for `flywheel-loop doctor --json`: `frozen_projection_count`, `frozen_projection_status`, `frozen_projection_by_target`, `literal_payload_targets`, `path_named_payload_targets`, `oldest_literal_age_sec`, `frozen_projection_scan_files`, and `frozen_projection_cutoff_ts`.

Mission-anchor: self-sustaining-company-architecture-health

L112 marker: OK_c2_invariant_deep_research
