---
title: beads-substrate lane wave 1 — canonical-cli SCAFFOLD-ONLY for 4 P0+P1 surfaces
type: evidence
bead: flywheel-gf2rj
task: flywheel-gf2rj-414763
sister: flywheel-frm53 (doctrine wave 1) / flywheel-2bz0v (storage wave 1) / flywheel-q92io (mission wave 1)
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Beads-substrate lane wave 1 — 4 P0+P1 surfaces scaffolded

## Outcome at a glance

| Surface | Shebang | Scaffold | Lint | Test 13/13 | Inventory |
|---|---|---:|---|---|---|
| beads-db-recover.sh         | bash | apply_ok | clean | 13/13 PASS | jloib_wave="beads-w1", passing |
| br-authority-probe.sh       | bash | apply_ok | clean | 13/13 PASS | jloib_wave="beads-w1", passing |
| br-close-with-gate.sh       | bash | apply_ok | clean | 13/13 PASS | jloib_wave="beads-w1", passing |
| br-db-corruption-monitor.sh | bash | apply_ok | clean | 13/13 PASS | jloib_wave="beads-w1", passing |

4/4 scaffolded; 4/4 lint clean; 4/4 13/13 PASS. Post-x4e3s scaffolder
continues clean (no L2/L4 hand-cleanup needed).

## Acceptance gate

> 4 P0+P1 beads-substrate surfaces scaffolded canonical-cli 13/13 PASS,
> inventory stamped, 4 fillin sub-beads filed at close. CRITICAL BOUNDARY:
> do NOT fill TODOs in this dispatch.

Reality:
- 4/4 surfaces scaffolded with apply_ok rc=0
- 4/4 lint clean (zero violations)
- 4/4 canonical-cli 13/13 PASS
- 4/4 inventory rows stamped (`jloib_wave="beads-w1"`, `canonical_cli_scoping_status=passing`)
- 18 TODO markers per surface remain in scaffold stubs (72 total) — fillin
  sub-beads filed at close, NOT touched in this dispatch

## Per-surface evidence

- Scaffold receipts: `.flywheel/audit/flywheel-gf2rj/scaffold-receipts.jsonl` (4 rows, all apply_ok)
- Lint results:      `.flywheel/audit/flywheel-gf2rj/lint-results.jsonl`     (4 rows, all clean)
- Test results:      `.flywheel/audit/flywheel-gf2rj/test-results.jsonl`     (4 rows, 13/13 each)
- Smoke (info+doctor): `.flywheel/audit/flywheel-gf2rj/smoke.jsonl` (8 rows, 2 per surface)
- Inventory stamp:   `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` (4 rows where jloib_wave="beads-w1")
- Scaffold-runs append: `.flywheel/state/scaffold-runs.jsonl` (4 new rows)
- Backups (PID-suffixed per x4e3s):
  `.flywheel/scripts/<surface>.bak.scaffold-<ISOts>-<pid>`

## Beads-substrate leverage

The 4 surfaces split across two function categories:

- **Recovery-class P0** (load-bearing for orch substrate health):
  - `beads-db-recover.sh` — rebuilds .beads/beads.db from JSONL when integrity check fails
  - `br-db-corruption-monitor.sh` — periodic SQLite integrity probe + early-warning surface

- **Workflow-discipline P0** (load-bearing for orch dispatch quality):
  - `br-authority-probe.sh` — verifies the local `br` binary matches expected version/hash
  - `br-close-with-gate.sh` — wraps `br close` with pre-close validation gates

Scaffolding the canonical-cli surfaces here gives operators / orchestrators
the standard doctor/health/repair/validate/audit/why entry points to debug
beads-substrate health without reading the bespoke production code.

## Filed fillin sub-beads (4)

- flywheel-qprlj — beads-db-recover
- flywheel-eqcsa — br-authority-probe
- flywheel-dsrq1 — br-close-with-gate
- flywheel-ut3ng — br-db-corruption-monitor

Each carries the wgitr-chain pattern (5 acceptance gates, ~30 min wall clock).

## Mission fitness

Class: `direct`. Beads-substrate is load-bearing for orchestrator workflow:
br is how orchestrators track in-flight work; corruption-monitor +
db-recover keep the substrate healthy. Direct work on the
continuous-orchestrator-uptime mission anchor.

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli matching frm53/2bz0v/q92io sister waves
- **Sniff**: 10/10 — every surface scaffolded clean, inventory stamped, 4 sub-beads filed
- **Jeff**: 9/10 — pathspec staging only; no scaffolder/helper-lib churn; legacy beads code preserved
- **Public**: 9/10 — three judges check passes: skeptical operator can replay receipts; maintainer can re-lint; future fillin worker has clean stubs to fill

## L112 verify probe

```bash
jq -c 'select(.jloib_wave=="beads-w1") | .name' \
  .flywheel/audit/flywheel-cli-inventory/inventory.jsonl | wc -l
# expected: 4
```
