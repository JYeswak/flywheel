# flywheel-k8gcv.14 — jeff-intel-digest-actionable.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.14 (wave-3-14, P0)
Surface: `.flywheel/scripts/jeff-intel-digest-actionable.sh`
Lane: jeff-corpus
mutates_state: yes (appends to digest_file + emission ledger in `--apply` mode)

## AG3 acceptance gate

20/20 PASS. AG3 strict 4/4. Lint clean (was 3 violations: L5+L6+L7).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L5 missing-strict-mode | `set -uo pipefail` → `set -euo pipefail` |
| 2 | L6 magic comment | Added (since `--apply` exists) |
| 3 | L7 --apply without --idempotency-key | Added `IDEMPOTENCY_KEY` var + flag + rc=3 refusal block (canonical envelope) |
| 4 | `--info` missing `.name`+`.capabilities` | Enriched: name+capabilities (6 items)+subcommands+env_vars+exit_codes (legacy fields preserved: owns, consumer) |
| 5 | `--schema` missing `.input_schema`+`.output_schema` | Added both (legacy ledger-row-required-fields/proxy-metrics/enum fields preserved) |
| 6 | `--examples` flag absent | Added text + JSON envelope variants |
| 7 | positional `doctor` absent | Added `emit_canonical_doctor` with 5 checks (jq, digest_file, fixture, snapshot_dir, ledger). Legacy `--doctor` flag preserved with `mode:"doctor"` envelope. |
| 8 | No-dash family absent | health (digest_row_count), validate, audit, why (3 topics: actionable-row-class, no-actionable-receipt, fixture-fallback), quickstart, repair (ledger-prime + digest-prime scopes) |

## Backward compatibility

5 regression tests:
- Legacy `--doctor` flag preserved.
- `--info` legacy fields (`owns`, `consumer`) preserved.
- `--help` shows usage.
- `--examples` (no `--json`) text mode.
- Default `--from-fixture --json` emits JSON.

Behavior change: `--apply` now requires `--idempotency-key` (rc=3 if missing).

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeff-intel-digest-actionable.sh` | 301 → 630 lines (+329) |
| `tests/jeff-intel-digest-actionable-canonical-cli.sh` | NEW (20 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.14/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
