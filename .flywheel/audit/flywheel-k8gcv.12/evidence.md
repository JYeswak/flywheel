# flywheel-k8gcv.12 — jeff-corpus-compact.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.12 (wave-3-12, P0)
Surface: `.flywheel/scripts/jeff-corpus-compact.sh`
Lane: jeff-corpus
mutates_state: yes (writes v3 manifest, emits qdrant supersede ops, appends ledger)

## AG3 acceptance gate

20/20 PASS. AG3 strict 4/4. Lint clean (was 1 violation: L6).

## Starting state

Script already had `--apply`/`--dry-run`/`--idempotency-key`/receipt-dir-based idempotent-replay machinery. But NO canonical CLI surface: `--info`/`--schema`/`--examples`/`doctor` all rejected as unknown args. Lint flagged L6 missing-magic-comment.

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 missing-magic-comment | Added (required since `--apply` exists) |
| 2 | `--info` flag absent | Added `emit_info` (name+version+capabilities+subcommands+env_vars+exit_codes+recommended_cadence) |
| 3 | `--schema` flag absent | Added `emit_schema` (input/output schemas) |
| 4 | `--examples` flag absent | Added `emit_examples_text` + `emit_examples_json` |
| 5 | positional `doctor` absent | Added `emit_canonical_doctor` with 6 checks (jq, python3, manifest, delta, receipt_dir, ledger) |
| 6 | No-dash family absent | health (receipt_count + ledger_row_count), validate, audit, why (3 topics: compaction-flow, idempotent-replay, qdrant-supersede), quickstart, repair (ledger-prime + receipt-dir-prime scopes) |
| 7 | `--apply` not formally gated | Added rc=3 canonical refusal envelope when `--apply` invoked without `--idempotency-key` (existing IDEMPOTENCY_KEY var already in script — only the gate is new) |

## Backward compatibility

5 regression tests:
- Legacy "must choose --dry-run or --apply" still returns rc=2.
- `--help` shows usage.
- `--examples` (no `--json`) emits text mode.
- `--dry-run` with synthetic fixtures still emits JSON.
- `--dry-run` does NOT require `--idempotency-key` (only `--apply` does).

Receipt-dir idempotent-replay machinery preserved verbatim; canonical apply gate is additive belt-and-suspenders.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeff-corpus-compact.sh` | 244 → 555 lines (+311) |
| `tests/jeff-corpus-compact-canonical-cli.sh` | NEW (20 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.12/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
