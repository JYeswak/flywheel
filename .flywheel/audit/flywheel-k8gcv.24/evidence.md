# flywheel-k8gcv.24 — orchestrator-callback-artifact-fix-bead.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.24 (wave-3-24, P0)
Surface: `.flywheel/scripts/orchestrator-callback-artifact-fix-bead.sh`
Lane: orchestration
mutates_state: yes (appends to fix-bead ledger; direct JSONL append to `.beads/issues.jsonl`)

## AG3 acceptance gate

18/18 PASS. AG3 strict 4/4. Lint clean (was 1 violation: L5).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L5 missing-strict-mode | `set -uo pipefail` → `set -euo pipefail` |
| 2 | L6 magic comment | Added |
| 3 | `--info` missing AG3 fields | Enriched (name+version+capabilities (5)+subcommands+env_vars+exit_codes; legacy ledger+purpose preserved) |
| 4 | `--schema` flag absent | Added emit_schema (input/output schemas) |
| 5 | `--examples --json` envelope absent | Added emit_examples_json (text-mode preserved) |
| 6 | positional `doctor` absent | Added emit_canonical_doctor (3 checks: jq, shasum, ledger_writable) |
| 7 | No-dash family absent | health, validate, audit, why (3 topics: artifact-validator-companion, dedupe-key-format, jsonl-fallback-only), quickstart, repair (ledger-prime scope) |

## Backward compatibility

3 regression tests:
- First call with new (task, reason, artifact) → action="jsonl_fallback" with `flywheel-fix-<sha12>` ID.
- Second call with same dedupe key → action="reused".
- `--help` and `--examples` text-mode preserved.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/orchestrator-callback-artifact-fix-bead.sh` | 80 → 379 lines (+299) |
| `tests/orchestrator-callback-artifact-fix-bead-canonical-cli.sh` | NEW (18 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.24/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
