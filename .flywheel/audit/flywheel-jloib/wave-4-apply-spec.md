# Wave 4 Apply-Spec — P0 partial × general lane (split A: a-l)

Parent bead: flywheel-jloib
Wave bead: flywheel-jloib.4
Surfaces:       37
Inventory filter: ownership=own AND priority=P0 AND canonical_cli_scoping_status=partial AND lane=general (alphabetic A)
Source inventory: .flywheel/audit/flywheel-cli-inventory/inventory.jsonl

## Goal

Ship canonical-cli baseline (--info / --schema / --examples + doctor if state-mutating) on every binary listed below, per the parent apply-spec at `.flywheel/audit/flywheel-cli-canonical-baseline/apply-spec.md` and the `/canonical-cli-scoping` skill.

## Per-binary acceptance gate (AG3 from parent)

Each binary must pass:

```bash
<bin> --info --json | jq -e '.name and .version and .capabilities'        # exit 0
<bin> --schema --json | jq -e '.input_schema and .output_schema'           # exit 0
<bin> --examples --json | jq -e '.examples | length > 0'                   # exit 0
# If mutates_state=yes per inventory:
<bin> doctor --json | jq -e '.checks'                                       # exit 0
```

## Per-binary execution path

1. `scaffold-canonical-cli.sh --binary <path>` (uses flywheel-ws02m primitive) emits TODO-marker scaffold
2. Fill 18 TODO markers per the wgitr/1fk5f/wzjo9 fillin pattern (~30-60min per binary)
3. Validate via `canonical-cli-lint.sh <path>` (flywheel-etp5n primitive)
4. Validate via the AG3 gate above
5. Update inventory.jsonl row status missing→passing (or partial→passing)
6. One commit per binary; one PR per binary unless <20 lines single file (AGENTS.md exemption)

## Sub-bead decomposition policy

When this wave is dispatched, file       37 per-binary sub-beads (flywheel-jloib.4.1 through flywheel-jloib.4.      37) following wzjo9.1.{1..9} pattern. Each sub-bead is a single-binary scaffold+fillin task with the AG3 acceptance gate.

## Surfaces in scope (lane | path | name)

| # | lane | path | name |
|---|---|---|---|
| 1 | general | `.flywheel/scripts/adversarial-orch-self-audit-probe.sh` | `adversarial-orch-self-audit-probe.sh` |
| 2 | general | `.flywheel/scripts/agents-md-fleet-propagator.sh` | `agents-md-fleet-propagator.sh` |
| 3 | general | `.flywheel/scripts/apply-substrate-tuning.sh` | `apply-substrate-tuning.sh` |
| 4 | general | `.flywheel/scripts/apply-tmux-tuning.sh` | `apply-tmux-tuning.sh` |
| 5 | general | `.flywheel/scripts/auto-l112-gate.sh` | `auto-l112-gate.sh` |
| 6 | general | `.flywheel/scripts/bcv-task-harness.sh` | `bcv-task-harness.sh` |
| 7 | general | `.flywheel/scripts/callback-envelope-schema-validator.sh` | `callback-envelope-schema-validator.sh` |
| 8 | general | `/Users/josh/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh` | `callback-receipt-validator-wrapper.sh` |
| 9 | general | `.flywheel/scripts/callback-receipt-validator.sh` | `callback-receipt-validator.sh` |
| 10 | general | `.flywheel/scripts/callback-spool-reap.sh` | `callback-spool-reap.sh` |
| 11 | general | `.flywheel/scripts/canonical-root-drift-fleet-check.sh` | `canonical-root-drift-fleet-check.sh` |
| 12 | general | `.flywheel/scripts/check-trauma-class-substrate.sh` | `check-trauma-class-substrate.sh` |
| 13 | general | `.flywheel/scripts/cleanup-scratch.sh` | `cleanup-scratch.sh` |
| 14 | general | `.flywheel/scripts/codex-budget-probe.sh` | `codex-budget-probe.sh` |
| 15 | general | `.flywheel/scripts/codex-death-event-classifier.sh` | `codex-death-event-classifier.sh` |
| 16 | general | `.flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh` | `codex-queued-not-submitted-bare-enter-primitive.sh` |
| 17 | general | `.flywheel/scripts/codex-template-stuck-detector.sh` | `codex-template-stuck-detector.sh` |
| 18 | general | `.flywheel/scripts/continuous-productivity-detector-install.sh` | `continuous-productivity-detector-install.sh` |
| 19 | general | `.flywheel/scripts/continuous-productivity-detector.sh` | `continuous-productivity-detector.sh` |
| 20 | general | `.flywheel/scripts/cost-telemetry-token-burn-probe.sh` | `cost-telemetry-token-burn-probe.sh` |
| 21 | general | `.flywheel/scripts/cross-repo-trauma-aggregator.sh` | `cross-repo-trauma-aggregator.sh` |
| 22 | general | `.flywheel/scripts/cross-session-worker-borrow.sh` | `cross-session-worker-borrow.sh` |
| 23 | general | `.flywheel/scripts/cross-time-synthesis-probe.sh` | `cross-time-synthesis-probe.sh` |
| 24 | general | `.flywheel/scripts/customer-facing-observability-probe.sh` | `customer-facing-observability-probe.sh` |
| 25 | general | `.flywheel/scripts/docs-validation-probe.sh` | `docs-validation-probe.sh` |
| 26 | general | `.flywheel/scripts/file-length-probe.sh` | `file-length-probe.sh` |
| 27 | general | `.flywheel/scripts/fleet-coherence-launchd.sh` | `fleet-coherence-launchd.sh` |
| 28 | general | `.flywheel/scripts/fleet-rotate-all-sessions.sh` | `fleet-rotate-all-sessions.sh` |
| 29 | general | `.flywheel/scripts/flywheel-adopt.sh` | `flywheel-adopt.sh` |
| 30 | general | `.flywheel/scripts/flywheel-codex-stuck-detector-install.sh` | `flywheel-codex-stuck-detector-install.sh` |
| 31 | general | `.flywheel/scripts/frozen-pane-detector-fleet.sh` | `frozen-pane-detector-fleet.sh` |
| 32 | general | `.flywheel/scripts/frozen-pane-detector.sh` | `frozen-pane-detector.sh` |
| 33 | general | `.flywheel/scripts/fuckup-coverage-join.sh` | `fuckup-coverage-join.sh` |
| 34 | general | `.flywheel/scripts/gap-hunt-probe.sh` | `gap-hunt-probe.sh` |
| 35 | general | `.flywheel/scripts/headless-browser-reap.sh` | `headless-browser-reap.sh` |
| 36 | general | `.flywheel/scripts/hub-blocker-detect.sh` | `hub-blocker-detect.sh` |
| 37 | general | `.flywheel/scripts/idempotency-replay-guard.sh` | `idempotency-replay-guard.sh` |

## Helper primitives consumed

- `scaffold-canonical-cli.sh` (flywheel-ws02m, P0 closed)
- `canonical-cli-helpers.sh` (flywheel-tiugg, P0 closed)
- `canonical-cli-lint.sh` (flywheel-etp5n, P0 closed)
- `/canonical-cli-scoping` skill

## Boundary

- own-binaries only (jeff-stack excluded by inventory filter)
- baseline only — doctor-mode hardening is bead 3 (chained from flywheel-jloib)
- inventory-row update is part of acceptance, not optional
