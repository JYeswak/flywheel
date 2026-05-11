# flywheel-k8gcv.15 — jeff-intel-network.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.15 (wave-3-15, P0)
Surface: `.flywheel/scripts/jeff-intel-network.sh`
Lane: jeff-corpus
mutates_state: yes (`pull/x-poll/repair --apply` paths)

## AG3 acceptance gate

16/16 PASS. AG3 strict 4/4. Lint clean (was 1 violation: L6).

## Starting state

Script already had extensive canonical surface: `--info`/`--schema`/`--examples` flags emitting envelopes; positional `doctor`/`health`/`repair`/`validate`/`audit`/`pull`/`x-poll`/`quickstart`/`completion`/`why`; `--idempotency-key` flag; bash completion. But:
- `--info` missing `.name` and `.capabilities` (AG3.1 fail)
- `--schema` missing `.input_schema` and `.output_schema` (AG3.2 fail — had different shape with source_cadence/canonical_paths)
- `doctor --json` emitted `.deps` but NOT `.checks` (AG3.4 fail under strict gate)
- L6 magic comment missing

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 magic comment | Added |
| 2 | `--info` missing AG3 fields | Enriched envelope: `command:"info"`, `name`, `capabilities` (8 items), `subcommands`, `canonical_flags`, `apply_supported`, `idempotency_key_required_for_apply`, `mutates_state`, `env_vars`, `exit_codes`. Legacy fields preserved (`root`, `runner`, `daily_ingest`, etc.) |
| 3 | `--schema` missing AG3 fields | Added `input_schema`+`output_schema` blocks. Legacy fields preserved (`source_cadence`, `canonical_paths`, `required`). Added `target_command` to clarify the subcommand being described. |
| 4 | `doctor` envelope missing `.checks` | Added `checks:($daily.deps // [])` alias alongside existing `deps` field (zero data change; both fields point to the same array). Legacy consumers reading `.deps` unchanged. |

## Backward compatibility

6 regression tests:
- Legacy doctor envelope: `deps` + `scheduled_runner` + `daily_ingest` + `paths` + `exit_codes` all preserved.
- Legacy `--doctor` flag still routes to canonical doctor.
- `--help` shows usage.
- `completion` still emits bash completion script.
- `repair --dry-run` envelope preserved.
- `x-poll --dry-run` envelope preserved.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeff-intel-network.sh` | 246 → 288 lines (+42) |
| `tests/jeff-intel-network-canonical-cli.sh` | NEW (16 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.15/evidence.md` | NEW |

This is the **smallest delta** of any wave-3 surface so far (+42 lines) — substrate was already mostly canonical. Just needed AG3-shape conformance + magic comment.

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
