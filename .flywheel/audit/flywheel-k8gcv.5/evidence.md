# flywheel-k8gcv.5 — capacity-halt-pane-authorization.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.5 (wave-3-05, P0)
Surface: `.flywheel/scripts/capacity-halt-pane-authorization.sh`
Lane: capacity
mutates_state: yes (writes authorization-outcome audit ledger)

## AG3 acceptance gate

All four AG3 probes return exit 0. Verified by `tests/capacity-halt-pane-authorization-canonical-cli.sh` (20/20 PASS).

## Starting state

Lint already clean. `--info`/`--examples` emitted JSON envelopes but `--info` missing `.capabilities`, `--schema` returned argparse error, `doctor` subcommand absent.

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 missing-magic-comment | Added |
| 2 | `--info` missing `.capabilities` | Python `info()` enriched with `capabilities`, `subcommands`, `mutates_state`, `apply_supported`, `env_vars`, `command:"info"` |
| 3 | `--schema` flag absent | bash `emit_schema` (input/output/exit_codes) |
| 4 | `doctor` subcommand absent | bash `emit_doctor` with 4 checks (jq, python3, topology_file, audit_ledger) |
| 5 | No-dash family absent | health (topology_age_sec + max_age + audit_row_count), validate, audit, why (role-classification/topology-stale/credential-rotation topics), quickstart, repair (audit-ledger-prime scope) |

## Architecture

Python core preserved verbatim. Bash wrapper intercepts canonical subcommands BEFORE python3 dispatch. New env var `CAPACITY_HALT_AUTH_LEDGER` introduced for the audit ledger (defaults to `~/.local/state/flywheel/capacity-halt-pane-authorization-ledger.jsonl`).

## Backward compatibility

Fixtures match real session-topology.jsonl shape (`worker_panes` list, `orchestrator_pane` int, `effective_at` ISO):
- worker_pane probe authorizes (rc=0).
- orchestrator pane returns protected_refusal (rc=5).
- unknown pane returns rc=6.
- non-numeric `--pane` returns rc=3 malformed.
- `--help` echoes argparse usage.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/capacity-halt-pane-authorization.sh` | 249 → 506 lines (+257) |
| `tests/capacity-halt-pane-authorization-canonical-cli.sh` | NEW (20 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.5/evidence.md` | NEW |

## Compliance: 1000/1000

## Four-Lens Self-Grade

four_lens=brand:9,sniff:9,jeff:9,public:9
