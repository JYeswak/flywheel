---
title: br-db-corruption-monitor — substantive 18-TODO fillin
type: evidence
bead: flywheel-ut3ng
task: flywheel-ut3ng-8b55aa
parent: flywheel-gf2rj (beads-substrate lane wave 1)
sister: flywheel-qprlj / flywheel-eqcsa / flywheel-dsrq1 (other gf2rj children)
worker: MistyCliff
session: flywheel
pane: 4
created: 2026-05-10
---

# Substantive fillin for br-db-corruption-monitor.sh canonical-cli surface

## Acceptance gates (all green)

| Gate | Result | Evidence |
|---|---|---|
| AG1 — 18 TODO markers replaced with substantive impls | 0 TODOs remaining | grep -c TODO = 0 |
| AG2 — bash -n clean | ok | exit 0 |
| AG3 — canonical-cli-lint clean | clean, 0 violations | `lint-result.json` |
| AG4 — canonical-cli scaffold-test 13/13 PASS | 13/13 PASS | `canonical-cli-test-run.txt` |
| AG5 — every subcommand returns concrete output | 6/6 substantive | `smoke-*.json` |

## What got filled in

### `doctor` (smoke-doctor.json) — 12 substrate checks
- **load-bearing**: sqlite3_available (the binary that runs PRAGMA integrity_check)
- **input data**: beads_db_present (.beads/beads.db, the file being monitored)
- **sister primitive**: recover_sister_executable (beads-db-recover.sh, used by --auto-rebuild)
- **ledger**: ledger_dir_present
- **deps (5)**: jq, python3, mktemp, grep, awk
- **config**: audit_log_dir_writable, repo_root_resolved, helper_lib_loaded

### `health` / `repair` / `audit` / `why`
Standard wgitr+beads-chain patterns. health summarizes from $SCAFFOLD_AUDIT_LOG;
repair has 2 scopes with apply-contract gate first; audit routes through
cli_emit_audit_tail; why supports row index OR substring on
status/repo/integrity fields.

### `validate` (smoke-validate-{beads-db,audit-row}.json)
Two subjects:
- `beads-db [PATH]` — runs `sqlite3 PRAGMA integrity_check` (same primitive
  the monitor uses) and reports integrity status. Default = $SCAFFOLD_BEADS_DB.
- `audit-row JSONL_LINE` — verifies JSON parse + required fields.

The beads-db validator self-tested against the real .beads/beads.db on this
repo and returned status=pass with integrity=ok — meaningful confirmation
that the substrate this monitor watches is currently healthy AND that the
validate subject runs the same sqlite3 integrity_check end-to-end (matches
the qprlj sister surface's same finding).

### `--schema <surface>` + topic_help
Per-surface field documentation; concrete topic help for all 6.

## Architecture coexistence

Same pattern as sister surfaces: legacy substantive monitor logic stays
intact (legacy `check` subcommand handled by main case statement); scaffold
stubs provide canonical envelope shape that matches the 13/13 contract.
The legacy `check` is the operator's go-to for actual monitoring with
optional `--auto-rebuild`; the canonical `validate beads-db` is a quick
read-only health probe that uses the same sqlite3 primitive.

## Mission fitness

Class: `direct`. The monitor + recover sister pair is the substrate-health
loop for orchestrator workflow — when sqlite3 reports corruption, the
monitor surfaces it (alone) or auto-invokes beads-db-recover.sh
(--auto-rebuild). Direct work on continuous-orchestrator-uptime.

## Four-Lens Self-Grade

- **Brand**: 9/10 — Joshua-flavored canonical-cli matching beads-chain.
- **Sniff**: 10/10 — every subcommand smoked end-to-end; validate beads-db
  self-tested integrity=ok on real DB (mirrors qprlj sister finding,
  validates the cross-surface consistency).
- **Jeff**: 9/10 — single-file edit; legacy code preserved.
- **Public**: 9/10 — three judges check passes; future fillin worker
  (dsrq1) has 3 sister exemplars in the beads-lane chain.

## L112 verify probe

```bash
bash .flywheel/scripts/br-db-corruption-monitor.sh doctor --json | jq -r '.status'
# expected: pass
```
