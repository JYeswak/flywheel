# Wave 5 Apply-Spec — P0 partial × general lane (split B: m-z)

Parent bead: flywheel-jloib
Wave bead: flywheel-jloib.5
Surfaces:       37
Inventory filter: ownership=own AND priority=P0 AND canonical_cli_scoping_status=partial AND lane=general (alphabetic B)
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

When this wave is dispatched, file       37 per-binary sub-beads (flywheel-jloib.5.1 through flywheel-jloib.5.      37) following wzjo9.1.{1..9} pattern. Each sub-bead is a single-binary scaffold+fillin task with the AG3 acceptance gate.

## Surfaces in scope (lane | path | name)

| # | lane | path | name |
|---|---|---|---|
| 1 | general | `.flywheel/scripts/incidents-evidence-link-validator.sh` | `incidents-evidence-link-validator.sh` |
| 2 | general | `.flywheel/scripts/install-stuck-detector-watchdog.sh` | `install-stuck-detector-watchdog.sh` |
| 3 | general | `.flywheel/scripts/integrate-stall-escalator.sh` | `integrate-stall-escalator.sh` |
| 4 | general | `.flywheel/scripts/l70-ticks-punted-counter.sh` | `l70-ticks-punted-counter.sh` |
| 5 | general | `.flywheel/scripts/leverage-ceiling-probe.sh` | `leverage-ceiling-probe.sh` |
| 6 | general | `.flywheel/scripts/memory-rule-gate-parity-detector.sh` | `memory-rule-gate-parity-detector.sh` |
| 7 | general | `/Users/josh/.claude/commands/flywheel/_shared/orch-callback-artifact-wrapper.sh` | `orch-callback-artifact-wrapper.sh` |
| 8 | general | `.flywheel/scripts/orch-donella-trace-gate.sh` | `orch-donella-trace-gate.sh` |
| 9 | general | `.flywheel/scripts/orch-no-punt-output-gate.sh` | `orch-no-punt-output-gate.sh` |
| 10 | general | `.flywheel/scripts/peer-orch-blocker-watch.sh` | `peer-orch-blocker-watch.sh` |
| 11 | general | `.flywheel/scripts/peer-orch-freeze-monitor.sh` | `peer-orch-freeze-monitor.sh` |
| 12 | general | `.flywheel/scripts/probe-registry-audit.sh` | `probe-registry-audit.sh` |
| 13 | general | `.flywheel/scripts/public-artifact-pipeline-probe.sh` | `public-artifact-pipeline-probe.sh` |
| 14 | general | `.flywheel/scripts/publishability-bar.sh` | `publishability-bar.sh` |
| 15 | general | `.flywheel/scripts/quality-bar-close-gate.sh` | `quality-bar-close-gate.sh` |
| 16 | general | `.flywheel/scripts/regenerate-dicklesworthstone-sources.sh` | `regenerate-dicklesworthstone-sources.sh` |
| 17 | general | `.flywheel/scripts/safe-probe.sh` | `safe-probe.sh` |
| 18 | general | `.flywheel/scripts/security-precommit-installer.sh` | `security-precommit-installer.sh` |
| 19 | general | `.flywheel/scripts/session-residue-prune.sh` | `session-residue-prune.sh` |
| 20 | general | `.flywheel/scripts/sister-orch-escalation-capsules.sh` | `sister-orch-escalation-capsules.sh` |
| 21 | general | `.flywheel/scripts/stale-error-auto-ping.sh` | `stale-error-auto-ping.sh` |
| 22 | general | `.flywheel/scripts/stash-discipline-check.sh` | `stash-discipline-check.sh` |
| 23 | general | `.flywheel/scripts/state-store-authority-probe.sh` | `state-store-authority-probe.sh` |
| 24 | general | `.flywheel/scripts/substrate-loop-contract-validator.sh` | `substrate-loop-contract-validator.sh` |
| 25 | general | `.flywheel/scripts/sync-four-lens-validator.sh` | `sync-four-lens-validator.sh` |
| 26 | general | `.flywheel/scripts/tentacle-drift-sweep.sh` | `tentacle-drift-sweep.sh` |
| 27 | general | `.flywheel/scripts/three-judges-publishability-validator.sh` | `three-judges-publishability-validator.sh` |
| 28 | general | `.flywheel/scripts/tick-hook-firing-verifier.sh` | `tick-hook-firing-verifier.sh` |
| 29 | general | `.flywheel/scripts/tick-receipt-validator.sh` | `tick-receipt-validator.sh` |
| 30 | general | `.flywheel/scripts/topology-gap-probe.sh` | `topology-gap-probe.sh` |
| 31 | general | `.flywheel/scripts/two-blocker-ticks-escalator.sh` | `two-blocker-ticks-escalator.sh` |
| 32 | general | `.flywheel/scripts/two-truth-sources-validator.sh` | `two-truth-sources-validator.sh` |
| 33 | general | `.flywheel/scripts/validation-e2e-smoke.sh` | `validation-e2e-smoke.sh` |
| 34 | general | `.flywheel/scripts/value-gap-probe.sh` | `value-gap-probe.sh` |
| 35 | general | `.flywheel/scripts/worker-lifecycle-transaction.sh` | `worker-lifecycle-transaction.sh` |
| 36 | general | `.flywheel/scripts/worker-slot-ledger.sh` | `worker-slot-ledger.sh` |
| 37 | general | `.flywheel/scripts/worker-stall-alert-probe.sh` | `worker-stall-alert-probe.sh` |

## Helper primitives consumed

- `scaffold-canonical-cli.sh` (flywheel-ws02m, P0 closed)
- `canonical-cli-helpers.sh` (flywheel-tiugg, P0 closed)
- `canonical-cli-lint.sh` (flywheel-etp5n, P0 closed)
- `/canonical-cli-scoping` skill

## Boundary

- own-binaries only (jeff-stack excluded by inventory filter)
- baseline only — doctor-mode hardening is bead 3 (chained from flywheel-jloib)
- inventory-row update is part of acceptance, not optional
