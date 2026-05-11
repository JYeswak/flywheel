# flywheel-k8gcv.11 — jeff-clone-symlink-converter.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.11 (wave-3-11, P0)
Surface: `.flywheel/scripts/jeff-clone-symlink-converter.sh`
Lane: jeff-corpus
mutates_state: yes (tar-backups, moves directory, creates symlink — `--mode apply` only)

## AG3 acceptance gate

22/22 PASS. AG3 strict 4/4. Lint clean (was 1 violation: L5).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L5 missing-strict-mode | `set -u` → `set -euo pipefail` |
| 2 | L6 magic comment | Added preventively (since `--apply` alias now exists) |
| 3 | `--info` missing `.capabilities` | Enriched envelope with name+version+capabilities (8 items)+subcommands+env_vars+ledger+backup_dir |
| 4 | `--schema` flag absent | Added `emit_schema` (input/output schemas with full property detail) |
| 5 | `--examples --json` envelope absent | Added `examples_json` while preserving text-mode |
| 6 | positional `doctor` subcommand absent | Added `emit_canonical_doctor` with 6 checks (jq, git, tar, backup_dir, ledger, corpus_base) |
| 7 | No-dash family absent | health (backup_tarball_count), validate, audit, why (3 topics: safety-checks, rollback, canonical-side), quickstart, repair (ledger-prime + backup-dir-prime scopes) |
| 8 | Apply contract not formally gated | `--mode apply` AND `--apply` alias both require `--idempotency-key` (rc=3 refusal). Existing semantics preserved; only the gate is new. |

## Backward compatibility

5 regression tests:
- Legacy `--mode dry-run --json` emits receipt envelope with `schema_version=jeff-clone-symlink-receipt/v1`.
- Legacy `invalid_args` path preserved (empty pair → status=invalid_args, rc=3).
- Legacy `invalid pair` rejection preserved (`../bad/path` → rc=3).
- `--help` shows expanded usage.
- `--examples` (no `--json`) emits text mode.

Behavior change: `--mode apply` (and new `--apply` alias) now require `--idempotency-key` (rc=3 with canonical refusal envelope if missing). Previously, callers could invoke `--mode apply` without key.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeff-clone-symlink-converter.sh` | 169 → 528 lines (+359) |
| `tests/jeff-clone-symlink-converter-canonical-cli.sh` | NEW (22 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.11/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
