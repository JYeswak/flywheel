# Wave 2 Apply-Spec — P0 missing × general lane

Parent bead: flywheel-jloib
Wave bead: flywheel-jloib.2
Surfaces:       21
Inventory filter: ownership=own AND priority=P0 AND canonical_cli_scoping_status=missing AND lane=general
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

When this wave is dispatched, file       21 per-binary sub-beads (flywheel-jloib.2.1 through flywheel-jloib.2.      21) following wzjo9.1.{1..9} pattern. Each sub-bead is a single-binary scaffold+fillin task with the AG3 acceptance gate.

## Surfaces in scope (lane | path | name)

| # | lane | path | name |
|---|---|---|---|
| 1 | general | `.flywheel/scripts/agents-md-shard-extract.sh` | `agents-md-shard-extract.sh` |
| 2 | general | `.flywheel/scripts/append-safe-write.sh` | `append-safe-write.sh` |
| 3 | general | `.flywheel/scripts/auto-refill-decision-log.sh` | `auto-refill-decision-log.sh` |
| 4 | general | `.flywheel/scripts/bleed-ledger-watch.sh` | `bleed-ledger-watch.sh` |
| 5 | general | `.flywheel/scripts/codex-budget-watchdog.sh` | `codex-budget-watchdog.sh` |
| 6 | general | `.flywheel/scripts/daily-report.sh` | `daily-report.sh` |
| 7 | general | `.flywheel/scripts/disk-reclaim-batch-2026-05-07.sh` | `disk-reclaim-batch-2026-05-07.sh` |
| 8 | general | `.flywheel/scripts/fleet-canonical-rule-freshness-probe.sh` | `fleet-canonical-rule-freshness-probe.sh` |
| 9 | general | `.flywheel/scripts/fleet-coherence-alert.sh` | `fleet-coherence-alert.sh` |
| 10 | general | `.flywheel/scripts/fleet-coherence-lib.sh` | `fleet-coherence-lib.sh` |
| 11 | general | `.flywheel/scripts/fleet-conformance-probe.sh` | `fleet-conformance-probe.sh` |
| 12 | general | `.flywheel/scripts/fleet-process-gap-detector.sh` | `fleet-process-gap-detector.sh` |
| 13 | general | `.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh` | `mobile-eats-loop-with-receipt-mirror.sh` |
| 14 | general | `.flywheel/scripts/orch-worker-identity-manifest.sh` | `orch-worker-identity-manifest.sh` |
| 15 | general | `.flywheel/scripts/picoz-archive-and-fresh-2026-05-07.sh` | `picoz-archive-and-fresh-2026-05-07.sh` |
| 16 | general | `.flywheel/scripts/promotion-candidate-stale-fire-reaper.sh` | `promotion-candidate-stale-fire-reaper.sh` |
| 17 | general | `.flywheel/scripts/rule-hint-lifecycle.sh` | `rule-hint-lifecycle.sh` |
| 18 | general | `.flywheel/scripts/shared-surface-reservation-check.sh` | `shared-surface-reservation-check.sh` |
| 19 | general | `.flywheel/scripts/state-md-miner.sh` | `state-md-miner.sh` |
| 20 | general | `.flywheel/scripts/topology-tick-refresh.sh` | `topology-tick-refresh.sh` |
| 21 | general | `.flywheel/scripts/worker-tick-jsm-outcomes.sh` | `worker-tick-jsm-outcomes.sh` |

## Helper primitives consumed

- `scaffold-canonical-cli.sh` (flywheel-ws02m, P0 closed)
- `canonical-cli-helpers.sh` (flywheel-tiugg, P0 closed)
- `canonical-cli-lint.sh` (flywheel-etp5n, P0 closed)
- `/canonical-cli-scoping` skill

## Boundary

- own-binaries only (jeff-stack excluded by inventory filter)
- baseline only — doctor-mode hardening is bead 3 (chained from flywheel-jloib)
- inventory-row update is part of acceptance, not optional
