# Orch-Uptime 15-Bead Ship Sequence Runbook

Generated: `2026-05-06T21:25:01Z`
Plan: `.flywheel/plans/orch-uptime-2026-05-06/`
Inputs: `00-PLAN.md`, `04-BEADS-DAG.md`, `06-POLISH-r2.md`, `STATE.json`, `02-DEEP-W0-baseline-reconcile.md`
Socraticode: 10 searches against `/Users/josh/Developer/flywheel`
Mission anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`

## Ship Preconditions

- Do not fire implementation until r3 ratifies steady state and Joshua says go.
- After go, each wave uses `/flywheel:dispatch`; no direct pane injection.
- Every source-edit dispatch reserves exact files, validates callback delivery, closes bead before callback, and releases reservations.
- Pause only for `/flywheel:plan` TRUE blocker classes. Routine taste, stale topology before B1/B2, or br BusySnapshot are not Joshua pauses when the runbook has a bounded path.

## Wave Order And Pane Assignments

| Wave | Pane 2 | Pane 3 | Pane 4 | Gate |
|---|---|---|---|---|
| 0 | W0 baseline reconcile | L101 fill work outside this DAG | L101 fill work outside this DAG | A2 blocked until W0 receipt allows it |
| 1 | A1 CAAM primitive | B1 topology refresh primitive | C1 L-rule doctrine | all three independent |
| 2a | A3 auth gate | B2 tick wire | C3 WOE bootstrap | critical-path first |
| 2b | A2 detector subclass | B4 watchers register/load/fire | C2 invariant scanner | same-wave, separate files |
| 2c | B3 mobile-eats arity guard | L101 fill work | L101 fill work | peer-owned file, after B1 |
| 3 | A4 recovery ledger | B5 watcher doctor scope | C4 fleet sweep | all depend on Wave 2 subsets |
| 4 | W4 integration closeout | L101 fill or W4 read-only shadow validation only | L101 fill or W4 read-only shadow validation only | W4 owns closeout and final commit |

Parallel boundaries:
- W0 is singleton. It gates only A2; Wave 1 can fire after Joshua go if W0 is queued first, but safest is W0 complete before any detector work.
- Wave 1 A1/B1/C1 are fully parallel.
- Wave 2 items are same-wave but capacity-limited to three panes; A3/B2/C3 run first because they unblock A4/C4/W4.
- Wave 3 waits for A3, B4, B2, C2, and C3; C4 must not fire before C2+C3.
- W4 waits for A2, A3, A4, B2, B3, B4, B5, C2, C3, and C4 callbacks plus L112 probes.

## Common Dispatch Envelope

Each packet starts:
`Read /tmp/dispatch_<task_id>.md and execute it as /flywheel:worker-tick parity.`

Required packet fields:
- repo `/Users/josh/Developer/flywheel`; callback `flywheel:1 pane 1`
- socraticode preflight K>=3 for implementation beads, K>=10 for W4
- exact L51 file reservations before edits; no broad globs
- validation commands and L112 verify command
- callback: `DONE <task_id> did=<n>/<total> didnt=none gaps=none evidence=<report> tests=PASS l112_probe_command=<cmd> l112_probe_expected=<grep|jq> l112_probe_timeout_sec=30 callback_delivery_verified=true br_close_executed=yes identity_name=<name> files_released=<paths>`

## Per-Bead Packet Outlines

### W0 - detector baseline reconcile, pane 2, ETA 20m
task_id: `flywheel-orch-uptime-detector-baseline-reconcile-2026-05-06`
deliverable: `/tmp/orch-uptime-W0-baseline-reconcile-ship-report-2026-05-06.md` plus receipt `~/.local/state/flywheel/orch-uptime/w0-a2-baseline-reconcile-receipt.json`
scope: read-only br, JSONL, INCIDENTS, detector source probe; no source mutation
acceptance_probe: receipt schema `orch-uptime-w0-baseline-reconcile/v1`; decision `closed_verified|closed_verified_jsonl_fallback`
callback: `DONE <task_id> w0_decision=<decision> a2_unblocked=<true|false> evidence=<deliverable> ...`
abort/rollback: if live br reopens or JSONL/L112 disagree, callback BLOCKED; no rollback because no source edits

### A1 - CAAM auto-rotate primitive, pane 2 Wave 1, ETA 45m
task_id: `flywheel-orch-uptime-caam-auto-rotate-primitive-2026-05-06`
deliverable: `/tmp/orch-uptime-A1-caam-primitive-ship-report-2026-05-06.md`
scope: add `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh`, fake CAAM fixture, `.flywheel/tests/test_caam_auto_rotate_on_usage_limit.sh`
acceptance_probe: dry-run default, no secret values, idempotency TTL, `--allow-unhealthy` refuses without ack
callback: `DONE <task_id> caam_tests=PASS secret_values_observed=0 l112_probe_expected=grep:OK_caam_auto_rotate_primitive ...`
abort/rollback: `git restore --staged/--worktree` owned new files before commit; after commit use `git revert <wave1_sha>`

### B1 - topology tick refresh primitive, pane 3 Wave 1, ETA 45m
task_id: `flywheel-orch-uptime-topology-tick-refresh-script-2026-05-06`
deliverable: `/tmp/orch-uptime-B1-topology-refresh-ship-report-2026-05-06.md`
scope: add `.flywheel/scripts/topology-tick-refresh.sh` and tests/topology fixture
acceptance_probe: append-only latest-wins row, refusal classes, ledger fields, shape-change refusal
callback: `DONE <task_id> topology_refresh_tests=PASS ledger_row_verified=true l112_probe_expected=grep:OK_topology_tick_refresh ...`
abort/rollback: remove owned script/test before commit; after commit `git revert <wave1_sha>`

### C1 - frozen projection L-rule, pane 4 Wave 1, ETA 35m
task_id: `flywheel-orch-uptime-frozen-projection-l-rule-2026-05-06`
deliverable: `/tmp/orch-uptime-C1-lrule-ship-report-2026-05-06.md`
scope: add `templates-name-sources-not-values` to root/canonical/template doctrine surfaces
acceptance_probe: `rg -n 'templates-name-sources-not-values|Templates name sources, not values' AGENTS.md .flywheel/AGENTS-CANONICAL.md templates/flywheel-install/AGENTS.md`
callback: `DONE <task_id> doctrine_3_surface=PASS l112_probe_expected=grep:templates-name-sources-not-values ...`
abort/rollback: revert doctrine hunk on three surfaces; after commit `git revert <wave1_sha>`

### A3 - auth gate credential-rotation class, pane 2 Wave 2a, ETA 35m
task_id: `flywheel-orch-uptime-auth-gate-credential-rotation-2026-05-06`
deliverable: `/tmp/orch-uptime-A3-auth-gate-ship-report-2026-05-06.md`
scope: extend `.flywheel/scripts/capacity-halt-pane-authorization.sh` and nearest tests
acceptance_probe: `--recovery-class credential_rotation` authorizes vault selector swap despite stale topology; unsafe ops refuse
callback: `DONE <task_id> credential_rotation_authorized=true forbidden_ops_refuse=true ...`
abort/rollback: restore auth gate/test files; after Wave 2 commit `git revert <wave2_sha>`

### B2 - topology tick wire, pane 3 Wave 2a, ETA 35m
task_id: `flywheel-orch-uptime-topology-tick-wire-2026-05-06`
deliverable: `/tmp/orch-uptime-B2-topology-wire-ship-report-2026-05-06.md`
scope: wire `.flywheel/flywheel-loop-tick` after L102 and before topology gates; update `.flywheel/scripts/tick-driver-manifest.json`
acceptance_probe: manifest has `topology-tick-refresh`; tick dry-run logs ordering and timeout
callback: `DONE <task_id> tick_order_verified=true manifest_registered=true ...`
abort/rollback: restore tick/manifest files; after Wave 2 commit `git revert <wave2_sha>`

### C3 - WOE ledger bootstrap, pane 4 Wave 2a, ETA 45m
task_id: `flywheel-orch-uptime-woe-ledger-bootstrap-2026-05-06`
deliverable: `/tmp/orch-uptime-C3-woe-bootstrap-ship-report-2026-05-06.md`
scope: bootstrap 11 rows through `.flywheel/scripts/wire-or-explain-ledger-writer.sh`; add/extend WOE tests if needed
acceptance_probe: 11 rows with `identity_key=orch-uptime-c3:<bead_id>` and scope ladder `woe_claim|tick|local|none`
callback: `DONE <task_id> bootstrap_rows=11 closeout_receipts_pattern_confirmed=true ...`
abort/rollback: append compensating supersede rows; do not delete production ledger rows

### A2 - codex usage-limit detector subclass, pane 2 Wave 2b, ETA 45m
task_id: `flywheel-orch-uptime-detector-codex-usage-limit-2026-05-06`
deliverable: `/tmp/orch-uptime-A2-detector-subclass-ship-report-2026-05-06.md`
scope: edit `.flywheel/scripts/codex-template-stuck-detector.sh`, `tests/codex-template-stuck-detector.sh`, `tests/e2e/e2e_oom_classifier.sh`
acceptance_probe: W0 receipt allowed; usage-limit class added before capacity halt; queued-not-submitted and OOM fixtures stay green
callback: `DONE <task_id> w0_receipt_checked=true detector_regression=PASS e2e_oom=PASS ...`
abort/rollback: restore detector/tests; after Wave 2 commit `git revert <wave2_sha>`

### B4 - watchers register/load/fire split, pane 3 Wave 2b, ETA 40m
task_id: `flywheel-orch-uptime-watchers-register-load-fire-2026-05-06`
deliverable: `/tmp/orch-uptime-B4-watchers-register-ship-report-2026-05-06.md`
scope: register two plists through `flywheel-watchers register --apply`; tests prove registered, loaded, recent-fire evidence
acceptance_probe: idempotency keys for `com.flywheel.shutdown-recovery` and `ai.zeststream.flywheel-idle-pane-watch`
callback: `DONE <task_id> registered=true loaded=true recent_fire_evidence=true ...`
abort/rollback: unregister/unload only the two owned watcher entries or revert config commit

### C2 - frozen projection invariant scanner, pane 4 Wave 2b, ETA 45m
task_id: `flywheel-orch-uptime-frozen-projection-scan-2026-05-06`
deliverable: `/tmp/orch-uptime-C2-invariant-scan-ship-report-2026-05-06.md`
scope: add `.flywheel/scripts/frozen-projection-invariant-scan.sh` and `.flywheel/tests/test_frozen_projection_invariant.sh`
acceptance_probe: schema `frozen-projection-invariant/v1`; warn pre-cutoff, fail post-cutoff, fail secret/unreadable always
callback: `DONE <task_id> invariant_tests=PASS cutoff_ladder=PASS ...`
abort/rollback: remove owned scanner/test; after Wave 2 commit `git revert <wave2_sha>`

### B3 - mobile-eats arity guard, pane 2 Wave 2c, ETA 30m
task_id: `flywheel-orch-uptime-mobile-eats-arity-guard-2026-05-06`
deliverable: `/tmp/orch-uptime-B3-mobile-eats-arity-ship-report-2026-05-06.md`
scope: peer-owned `/Users/josh/.local/bin/mobile-eats-flywheel-loop-tick` or mobile-eats repo handoff; prove line-83 guard
acceptance_probe: one-arg invocation survives; `fleet_escalation_capsule_skipped`; `--accept-stall` UX fixture present
callback: `DONE <task_id> peer_patch_or_handoff=<patch|handoff> arity_fixture=PASS ...`
abort/rollback: if peer patch applied, restore prior bytes from receipt; otherwise route to mobile-eats owner without flywheel mutation

### A4 - recovery-ledger CAAM additive fields, pane 2 Wave 3, ETA 35m
task_id: `flywheel-orch-uptime-recovery-ledger-caam-additive-2026-05-06`
deliverable: `/tmp/orch-uptime-A4-recovery-ledger-ship-report-2026-05-06.md`
scope: extend `.flywheel/validation-schema/v1/recovery-ledger.schema.json` and recovery ledger tests
acceptance_probe: optional `recovery_class=credential_rotation`, `profile_selector` fields; existing rows still validate
callback: `DONE <task_id> schema_backcompat=PASS credential_rotation_fields=PASS ...`
abort/rollback: restore schema/tests; after Wave 3 commit `git revert <wave3_sha>`

### B5 - watcher doctor com.flywheel scope, pane 3 Wave 3, ETA 30m
task_id: `flywheel-orch-uptime-watchers-doctor-com-scope-2026-05-06`
deliverable: `/tmp/orch-uptime-B5-watchers-doctor-scope-ship-report-2026-05-06.md`
scope: extend watcher doctor launchctl scope and tests for `com.flywheel.*`
acceptance_probe: doctor counts `ai.zeststream.flywheel-*` and guarded `com.flywheel.*`; unrelated com.* excluded
callback: `DONE <task_id> doctor_scope_tests=PASS com_flywheel_counted=true ...`
abort/rollback: restore watcher doctor/test files; after Wave 3 commit `git revert <wave3_sha>`

### C4 - fleet sweep execution, pane 4 Wave 3, ETA 45m
task_id: `flywheel-orch-uptime-fleet-sweep-execution-2026-05-06`
deliverable: `/tmp/orch-uptime-C4-fleet-sweep-ship-report-2026-05-06.md`
scope: run frozen-projection/WOE/L87/label-drift/dependency sweep dry-run, then route peer-owned debt
acceptance_probe: report names flywheel, mobile-eats, alps, skillos targets; no peer repo mutation unless explicitly owned
callback: `DONE <task_id> fleet_sweep=PASS peer_debt_routed=true l87_not_closed=true ...`
abort/rollback: revert any local route rows via supersede rows; peer packets are append-only coordination records

### W4 - integration validation closeout, pane 2 Wave 4, ETA 60m
task_id: `flywheel-orch-uptime-integration-validation-closeout-2026-05-06`
deliverable: `/tmp/orch-uptime-W4-integration-closeout-ship-report-2026-05-06.md`
scope: aggregate all callbacks, run tests, update INCIDENTS/memory if required, produce final L112 receipt
acceptance_probe: amendment coverage 14/14, founder_pages_avoided metric, all wave commits present, `br dep cycles` or JSONL fallback clean
callback: `DONE <task_id> all_tests=PASS amendment_coverage=14_of_14 l112_observed=OK_orch_uptime_ship_complete ...`
abort/rollback: if integration fails, do not close W4; file fix bead per failed probe and stop before final commit

## Checkpoint Commits

Run one scoped commit after each wave only after all callbacks validate.

- Wave 0: `git commit -m "chore(orch-uptime): reconcile detector baseline before usage-limit work" -m "Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet"`
- Wave 1: `git commit -m "feat(orch-uptime): ship independent uptime primitives" -m "Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet"`
- Wave 2: `git commit -m "feat(orch-uptime): wire detector, topology, watchers, invariant, and WOE gates" -m "Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet"`
- Wave 3: `git commit -m "feat(orch-uptime): ship ledger, watcher doctor, and fleet sweep integration" -m "Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet"`
- Wave 4: `git commit -m "feat(orch-uptime): close integration validation and L112 ship receipt" -m "Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet"`

## Time Estimate

Per-bead total: W0 20 + A1 45 + B1 45 + C1 35 + A3 35 + B2 35 + C3 45 + A2 45 + B4 40 + C2 45 + B3 30 + A4 35 + B5 30 + C4 45 + W4 60 = 590 worker-min.
Wall clock with three panes: Wave0 20 + Wave1 45 + Wave2 120 + Wave3 45 + Wave4 60 = about 290 min, or 4h50m. Parallelism factor: about 2.0x.

## Joshua Decision Boundary By Wave

- Pre-ship: r3 ratified and Joshua go captured. Without that, stop.
- Wave 0: no Joshua decision unless W0 finds live reopened baseline that contradicts append-only/L112 truth; then block A2, not the whole plan.
- Wave 1: no Joshua decision; A1 is dry-run default and selector-only. If live secret generation/rotation is added, pause class 2.
- Wave 2: no Joshua decision for topology repair, detector edits, WOE bootstrap, or watcher registration. Pause only for destructive shared-state changes or peer-repo mutation without owner route.
- Wave 3: no Joshua decision for schema additive fields or dry-run fleet sweep. Pause if C4 proposes closing L87 despite active divergence evidence.
- Wave 4: no Joshua decision for integration closeout. Pause only if W4 discovers one of the six TRUE blocker classes; otherwise file fix beads and keep moving.

Mission-anchor: `continuous-orchestrator-uptime-self-sustaining-fleet`
