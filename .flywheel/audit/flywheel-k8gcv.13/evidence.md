# flywheel-k8gcv.13 — jeff-corpus-delta-reindex.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.13 (wave-3-13, P0)
Surface: `.flywheel/scripts/jeff-corpus-delta-reindex.sh`
Lane: jeff-corpus
mutates_state: yes (writes v2 delta-index.jsonl in `--apply` mode)

## AG3 acceptance gate

20/20 PASS. AG3 strict 4/4. Lint clean (was 2 violations: L6+L7).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 magic comment | Added |
| 2 | L7 --apply without --idempotency-key | Added `IDEMPOTENCY_KEY` var + flag + rc=3 refusal block (canonical envelope) |
| 3 | `--info` flag absent | Added `emit_info` (name+version+capabilities+subcommands+env_vars+exit_codes) |
| 4 | `--schema` flag absent | Added `emit_schema` |
| 5 | `--examples` flag absent | Added text + JSON envelope variants |
| 6 | positional `doctor` absent | Added `emit_canonical_doctor` with 6 checks (jq, python3, git, manifest, pending, ledger) |
| 7 | No-dash family absent | health (last_mode + ledger row count), validate, audit, why (3 topics: delta-driven-reindex, pending-reindex-jsonl, git-diff-name-only), quickstart, repair (ledger-prime scope) |

## Backward compatibility

5 regression tests:
- Legacy "must choose --dry-run or --apply" returns rc=2.
- `--help` shows usage.
- `--examples` (no `--json`) text mode.
- `--dry-run` with synthetic empty manifest+pending fixtures emits JSON.
- `--dry-run` does NOT require `--idempotency-key`.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeff-corpus-delta-reindex.sh` | 155 → 466 lines (+311) |
| `tests/jeff-corpus-delta-reindex-canonical-cli.sh` | NEW (20 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.13/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
