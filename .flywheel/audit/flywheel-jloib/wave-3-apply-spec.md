# Wave 3 Apply-Spec — P0 partial × non-general lanes

Parent bead: flywheel-jloib
Wave bead: flywheel-jloib.3
Surfaces:       27
Inventory filter: ownership=own AND priority=P0 AND canonical_cli_scoping_status=partial AND lane=non-general (jeff-corpus, capacity, orchestration, mission, doctrine, beads, testing, recovery)
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

When this wave is dispatched, file       27 per-binary sub-beads (flywheel-jloib.3.1 through flywheel-jloib.3.      27) following wzjo9.1.{1..9} pattern. Each sub-bead is a single-binary scaffold+fillin task with the AG3 acceptance gate.

## Surfaces in scope (lane | path | name)

| # | lane | path | name |
|---|---|---|---|
| 1 | beads | `.flywheel/scripts/callback-fix-bead-opener.sh` | `callback-fix-bead-opener.sh` |
| 2 | beads | `.flywheel/scripts/low-bead-threshold-detector.sh` | `low-bead-threshold-detector.sh` |
| 3 | capacity | `.flywheel/scripts/capacity-halt-auto-continue-primitive.sh` | `capacity-halt-auto-continue-primitive.sh` |
| 4 | capacity | `.flywheel/scripts/capacity-halt-lease-primitive.sh` | `capacity-halt-lease-primitive.sh` |
| 5 | capacity | `.flywheel/scripts/capacity-halt-pane-authorization.sh` | `capacity-halt-pane-authorization.sh` |
| 6 | capacity | `.flywheel/scripts/halt-disease-watchdog.sh` | `halt-disease-watchdog.sh` |
| 7 | capacity | `.flywheel/scripts/idle-state-probe.sh` | `idle-state-probe.sh` |
| 8 | doctrine | `.flywheel/scripts/mobile-eats-end-user-health-probe.sh` | `mobile-eats-end-user-health-probe.sh` |
| 9 | doctrine | `.flywheel/scripts/validate-callback-before-close.sh` | `validate-callback-before-close.sh` |
| 10 | jeff-corpus | `.flywheel/scripts/jeff-binary-version-watchtower.sh` | `jeff-binary-version-watchtower.sh` |
| 11 | jeff-corpus | `.flywheel/scripts/jeff-clone-symlink-converter.sh` | `jeff-clone-symlink-converter.sh` |
| 12 | jeff-corpus | `.flywheel/scripts/jeff-corpus-compact.sh` | `jeff-corpus-compact.sh` |
| 13 | jeff-corpus | `.flywheel/scripts/jeff-corpus-delta-reindex.sh` | `jeff-corpus-delta-reindex.sh` |
| 14 | jeff-corpus | `.flywheel/scripts/jeff-intel-digest-actionable.sh` | `jeff-intel-digest-actionable.sh` |
| 15 | jeff-corpus | `.flywheel/scripts/jeff-intel-network.sh` | `jeff-intel-network.sh` |
| 16 | jeff-corpus | `.flywheel/scripts/jeff-intel-scheduled-runner.sh` | `jeff-intel-scheduled-runner.sh` |
| 17 | jeff-corpus | `.flywheel/scripts/jeff-issue.sh` | `jeff-issue.sh` |
| 18 | jeff-corpus | `.flywheel/scripts/jeff-pattern-citation-probe.sh` | `jeff-pattern-citation-probe.sh` |
| 19 | jeff-corpus | `.flywheel/scripts/jeff-shadow-socraticode.sh` | `jeff-shadow-socraticode.sh` |
| 20 | jeff-corpus | `.flywheel/scripts/jeff-workaround-research-gate.sh` | `jeff-workaround-research-gate.sh` |
| 21 | jeff-corpus | `.flywheel/scripts/jeffrey-comment-watchtower.sh` | `jeffrey-comment-watchtower.sh` |
| 22 | mission | `.flywheel/scripts/escalate-capsule-plan-consumer.sh` | `escalate-capsule-plan-consumer.sh` |
| 23 | mission | `.flywheel/scripts/plan-state-lens-merge.sh` | `plan-state-lens-merge.sh` |
| 24 | orchestration | `.flywheel/scripts/orchestrator-callback-artifact-fix-bead.sh` | `orchestrator-callback-artifact-fix-bead.sh` |
| 25 | orchestration | `.flywheel/scripts/orchestrator-callback-artifact-validator.sh` | `orchestrator-callback-artifact-validator.sh` |
| 26 | recovery | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-verdict` | `flywheel-verdict` |
| 27 | testing | `.flywheel/scripts/frozen-pane-backtest.sh` | `frozen-pane-backtest.sh` |

## Helper primitives consumed

- `scaffold-canonical-cli.sh` (flywheel-ws02m, P0 closed)
- `canonical-cli-helpers.sh` (flywheel-tiugg, P0 closed)
- `canonical-cli-lint.sh` (flywheel-etp5n, P0 closed)
- `/canonical-cli-scoping` skill

## Boundary

- own-binaries only (jeff-stack excluded by inventory filter)
- baseline only — doctor-mode hardening is bead 3 (chained from flywheel-jloib)
- inventory-row update is part of acceptance, not optional
