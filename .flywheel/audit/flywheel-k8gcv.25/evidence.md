# flywheel-k8gcv.25 — orchestrator-callback-artifact-validator.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.25 (wave-3-25, P0)
Surface: `.flywheel/scripts/orchestrator-callback-artifact-validator.sh`
Lane: orchestration
mutates_state: yes (appends decisions to ledger; may shell out to fix-bead opener on REFUSE)

## AG3 acceptance gate

18/18 PASS. AG3 strict 4/4. Lint already clean.

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 magic comment | Added preventively |
| 2 | `--info` missing `.capabilities`+`.subcommands`+command:"info" | Override Python `info()` via bash intercept emitting AG3-compliant envelope (legacy min_bytes table, ledger, purpose preserved) |
| 3 | `--schema` flag absent | bash intercept `emit_schema` (input/output schemas) |
| 4 | `--examples --json` envelope absent | bash intercept emits JSON envelope on `--json`; otherwise falls through to existing Python text-mode |
| 5 | positional `doctor` absent | bash intercept `emit_canonical_doctor` (4 checks: jq, python3, ledger, fix_bead_opener) |
| 6 | No-dash family absent | health, validate, audit, why (3 topics: fail-closed-vs-fail-open, extension-byte-thresholds, fix-bead-opener-integration), quickstart, repair (ledger-prime scope) |

## Architecture: bash intercept overrides Python --info

The Python core has its own `info()` and `examples()` functions. Rather than modifying the Python code, the bash wrapper intercepts `--info`, `--schema`, and canonical subcommands BEFORE delegating to Python. The legacy `check` subcommand still routes through Python untouched.

`--examples` is dual-mode:
- `--examples --json`: bash emits canonical JSON envelope
- `--examples` (no `--json`): falls through to Python's text-mode

## Companion to k8gcv.24

This surface is paired with k8gcv.24 (`orchestrator-callback-artifact-fix-bead.sh`). When the validator decides REFUSE, the fix-bead opener (referenced via `ORCH_CALLBACK_ARTIFACT_FIX_BEAD_OPENER` env) auto-opens a fix bead. Both surfaces now pass AG3 strict; both lint clean.

## Backward compatibility

5 regression tests:
- Legacy `check` command emits `.decision` envelope (Python core untouched).
- `--info` preserves `min_bytes` table + `ledger` field.
- `--help` shows usage.
- `--examples` (no `--json`) falls through to Python text-mode.
- Lint stays clean.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/orchestrator-callback-artifact-validator.sh` | 352 → 624 lines (+272) |
| `tests/orchestrator-callback-artifact-validator-canonical-cli.sh` | NEW (18 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.25/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
