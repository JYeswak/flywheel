# flywheel-k8gcv.20 — jeff-workaround-research-gate.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.20 (wave-3-20, P0)
Surface: `.flywheel/scripts/jeff-workaround-research-gate.sh`
Lane: jeff-corpus
mutates_state: no (read-only gate; scans dispatch logs, exits 2 on pending)

## AG3 acceptance gate

18/18 PASS. AG3 strict 4/4. Lint already clean (no violations to fix).

## Starting state

Smallest wave-3 starting size yet (89 lines). Only `--schema` flag worked (with non-AG3 shape); no `--info`/`--examples`/positional `doctor`. Lint clean (script has no `--apply`, so L5+L6+L7 don't fire).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 magic comment | Added preventively |
| 2 | `--info` flag absent | Added `emit_info` (name+version+capabilities (4)+subcommands+canonical_flags+env_vars+exit_codes) |
| 3 | `--schema` missing AG3 fields | Enriched: input_schema + output_schema (legacy required_receipt_fields + doctor_fields preserved) |
| 4 | `--examples` flag absent | Added `emit_examples` (--json envelope + text-mode) |
| 5 | positional `doctor` absent | Added `emit_canonical_doctor` with 4 checks (jq, ripgrep, dispatch_log, ledger_writable) |
| 6 | No-dash family absent | health, validate, audit, why (3 topics: workaround-research-requirement, pattern-scan-keywords, exit-2-pending), quickstart, repair (ledger-prime scope with idem-key gate) |

## Backward compatibility

5 regression tests:
- Legacy `--schema` preserves `required_receipt_fields` + `doctor_fields`.
- Default scan emits gate envelope (predicate + pending count).
- `--help` shows usage.
- `--examples` (no `--json`) text-mode.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeff-workaround-research-gate.sh` | 89 → 393 lines (+304) |
| `tests/jeff-workaround-research-gate-canonical-cli.sh` | NEW (18 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.20/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
