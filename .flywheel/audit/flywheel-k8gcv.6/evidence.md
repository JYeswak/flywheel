# flywheel-k8gcv.6 — halt-disease-watchdog.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.6 (wave-3-06, P0)
Surface: `.flywheel/scripts/halt-disease-watchdog.sh`
Lane: capacity
mutates_state: yes (appends signal rows to halt-disease-watchdog.jsonl ledger)

## AG3 acceptance gate

All four AG3 probes return exit 0. Verified by `tests/halt-disease-watchdog-canonical-cli.sh` (19/19 PASS).

## Starting state

Lint already clean. NO `--info`, `--schema`, `--examples`, or `doctor` surface at all — only `--sessions`, `--repo-map`, `--window-minutes`, `--json`, `--quiet`, `--once`, `--help`, `--version`. Inventory had `has_info: true` flag incorrectly set (probably a pre-scaffold marker).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 missing-magic-comment | Added `# flywheel-cli-surface: true` |
| 2 | `--info` flag absent | Added bash `emit_info` with name+version+capabilities+subcommands+exit_codes |
| 3 | `--schema` flag absent | Added bash `emit_schema` (input/output/exit_codes) |
| 4 | `--examples` flag absent | Added bash `emit_examples` with `--json` envelope + text-mode fallback |
| 5 | `doctor` subcommand absent | Added bash `emit_doctor` with 5 checks (jq, ntm_bin, flywheel_loop, ledger_writable, timeout_bin) |
| 6 | No-dash family absent | health, validate, audit, why (4 topics: halt-disease, fleet-idle-with-ready-work, yellow-without-permitted-work, red-ignored), quickstart, repair (ledger-prime scope, `--apply --idempotency-key` gate) |

## Architecture

Pure-bash script. Canonical subcommands intercepted at top BEFORE the watchdog body runs. `--info`/`--examples` handled in the existing arg-parser case statement. `--schema` and positional subcommands intercepted before the arg parser.

## Backward compatibility

- `--help` shows expanded usage block including new canonical surface.
- `--version` emits version string.
- Unknown args return rc=64 (preserved).
- `--examples` without `--json` emits text mode (preserved).
- `--sessions`/`--repo-map`/`--window-minutes`/`--json`/`--quiet`/`--once` all preserved.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/halt-disease-watchdog.sh` | 194 → 467 lines (+273) |
| `tests/halt-disease-watchdog-canonical-cli.sh` | NEW (19 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.6/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
