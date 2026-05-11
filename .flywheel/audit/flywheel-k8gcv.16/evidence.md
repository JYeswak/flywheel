# flywheel-k8gcv.16 — jeff-intel-scheduled-runner.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.16 (wave-3-16, P0)
Surface: `.flywheel/scripts/jeff-intel-scheduled-runner.sh`
Lane: jeff-corpus
mutates_state: yes (appends per-run receipts; launchd-driven 4-cadence runner)

## AG3 acceptance gate

19/19 PASS. AG3 strict 4/4. Lint clean (was 2 violations: L6+L7).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 magic comment | Added |
| 2 | L7 --apply not gated | Added `--apply` flag + `--idempotency-key` flag + rc=3 refusal block |
| 3 | `--info` flag absent | Added `emit_info` (name+version+capabilities (8)+subcommands+legacy_modes+env_vars+exit_codes) |
| 4 | `--schema` missing AG3 fields | Existing schema_json enriched with `input_schema`+`output_schema` (legacy launchd_labels, source_cadence, receipt_paths preserved) |
| 5 | positional `doctor` absent | Added `emit_canonical_doctor` with 8 checks (4 launchd labels via `launchctl list` + 4 plist presence). Legacy `--mode doctor` preserved with different envelope shape. |
| 6 | No-dash family absent | health (schedule+x_poll row counts), validate, audit (ledger tail), why (3 topics: launchd-cadences, storage-precheck, receipt-paths), quickstart, repair (ledger-prime + state-dir-prime scopes) |

## Backward compatibility

5 regression tests:
- Legacy `--mode doctor --json` envelope preserved (jeff-intel-schedule/v1 schema).
- `--schema` legacy fields preserved (launchd_labels + source_cadence + receipt_paths).
- `--help` shows usage.
- `--examples` (no `--json`) emits text mode (5 example invocations).
- Unknown args still rejected with rc=64.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeff-intel-scheduled-runner.sh` | 367 → 643 lines (+276) |
| `tests/jeff-intel-scheduled-runner-canonical-cli.sh` | NEW (19 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.16/evidence.md` | NEW |

## Compliance: 1000/1000

Two fuckups logged + caught locally:
1. **Bash nested function definitions**: I initially wrote `local check_label() {...}` inside `emit_canonical_doctor()`. Bash doesn't allow nested `function() {}` inside another function via `local` — caused `syntax error near unexpected token '('`. Fix: inline the if-then-else logic per call site.
2. **L3 brace-default-ambiguity** (`${X:-{}}`): introduced when I tried `--argjson existing "${existing:-{}}"`. Fix: switched to direct probe (no subshell delegation), avoiding the `{}` default-empty-object literal entirely.

Both caught by `bash -n` syntax + lint pre-commit before commit.

four_lens=brand:9,sniff:9,jeff:9,public:9
