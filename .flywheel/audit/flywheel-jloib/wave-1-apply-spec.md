# Wave 1 Apply-Spec — P0 missing × non-general lanes

Parent bead: flywheel-jloib
Wave bead: flywheel-jloib.1
Surfaces:       21
Inventory filter: ownership=own AND priority=P0 AND canonical_cli_scoping_status=missing AND lane=non-general (jeff-corpus, doctrine, testing, recovery, beads, agent-mail, quality)
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

When this wave is dispatched, file       21 per-binary sub-beads (flywheel-jloib.1.1 through flywheel-jloib.1.      21) following wzjo9.1.{1..9} pattern. Each sub-bead is a single-binary scaffold+fillin task with the AG3 acceptance gate.

## Surfaces in scope (lane | path | name)

| # | lane | path | name |
|---|---|---|---|
| 1 | agent-mail | `.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh` | `caam-auto-rotate-on-usage-limit.sh` |
| 2 | agent-mail | `.flywheel/scripts/fleet-rotate-on-caam-swap.sh` | `fleet-rotate-on-caam-swap.sh` |
| 3 | beads | `.flywheel/scripts/bead-evidence-indexer.sh` | `bead-evidence-indexer.sh` |
| 4 | beads | `.flywheel/scripts/plan-to-bead-auto-trigger.sh` | `plan-to-bead-auto-trigger.sh` |
| 5 | doctrine | `.flywheel/scripts/fleet-comms-health-probe.sh` | `fleet-comms-health-probe.sh` |
| 6 | doctrine | `.flywheel/scripts/test-doctor-empty-errors.sh` | `test-doctor-empty-errors.sh` |
| 7 | doctrine | `.flywheel/scripts/test-loop-driver-doctor.sh` | `test-loop-driver-doctor.sh` |
| 8 | doctrine | `.flywheel/scripts/verify-watcher-launchd-active.sh` | `verify-watcher-launchd-active.sh` |
| 9 | jeff-corpus | `.flywheel/scripts/jeff-daily-diff.sh` | `jeff-daily-diff.sh` |
| 10 | jeff-corpus | `.flywheel/scripts/jeff-issue-response-poll.sh` | `jeff-issue-response-poll.sh` |
| 11 | jeff-corpus | `.flywheel/scripts/jeff-philosophy-mine.sh` | `jeff-philosophy-mine.sh` |
| 12 | jeff-corpus | `.flywheel/scripts/jeff-verdict-heuristic.sh` | `jeff-verdict-heuristic.sh` |
| 13 | quality | `.flywheel/scripts/polish-preflight-quality-gate.sh` | `polish-preflight-quality-gate.sh` |
| 14 | recovery | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-summarize` | `flywheel-summarize` |
| 15 | recovery | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-sync` | `flywheel-sync` |
| 16 | recovery | `/Users/josh/.claude/skills/.flywheel/bin/flywheel-trauma-check` | `flywheel-trauma-check` |
| 17 | recovery | `/Users/josh/.claude/skills/.flywheel/bin/flywheel.bak-2026-04-28-pre-substrate-intake` | `flywheel.bak-2026-04-28-pre-substrate-intake` |
| 18 | testing | `.flywheel/scripts/test-fuckup-join.sh` | `test-fuckup-join.sh` |
| 19 | testing | `.flywheel/scripts/test-safe-probe.sh` | `test-safe-probe.sh` |
| 20 | testing | `.flywheel/scripts/test-sync-stamped-repos-coverage.sh` | `test-sync-stamped-repos-coverage.sh` |
| 21 | testing | `/Users/josh/.claude/commands/flywheel/_shared/test-inject-memory-hits.sh` | `test-inject-memory-hits.sh` |

## Helper primitives consumed

- `scaffold-canonical-cli.sh` (flywheel-ws02m, P0 closed)
- `canonical-cli-helpers.sh` (flywheel-tiugg, P0 closed)
- `canonical-cli-lint.sh` (flywheel-etp5n, P0 closed)
- `/canonical-cli-scoping` skill

## Boundary

- own-binaries only (jeff-stack excluded by inventory filter)
- baseline only — doctor-mode hardening is bead 3 (chained from flywheel-jloib)
- inventory-row update is part of acceptance, not optional
