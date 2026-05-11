# flywheel-k8gcv.7 — idle-state-probe.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.7 (wave-3-07, P0)
Surface: `.flywheel/scripts/idle-state-probe.sh`
Lane: capacity
mutates_state: no (read-only probe; writes only to optional ledger via canonical surface)

## AG3 acceptance gate

All four AG3 probes return exit 0. Verified by `tests/idle-state-probe-canonical-cli.sh` (21/21 PASS).

## Starting state

Lint already clean. Had `--info` (basic envelope), `--examples` (text), `--doctor` flag (returns full status envelope, NOT the canonical-cli doctor.checks shape). Missing: `.capabilities`/`.version` in info, `--schema`, positional `doctor` subcommand returning `.checks`, magic comment, full no-dash canonical family.

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 missing-magic-comment | Added `# flywheel-cli-surface: true` |
| 2 | `--info` missing `.name`+`.version`+`.capabilities`+`.subcommands` | Enriched envelope with all AG3 fields + env_vars + exit_codes |
| 3 | `--schema` flag absent | Added `emit_schema` (input/output schemas) |
| 4 | `--examples --json` envelope absent | Added `emit_examples_json` while preserving text-mode |
| 5 | `doctor` positional subcommand absent | Added `emit_doctor` (canonical-cli `.checks` shape, 4 checks: jq, br_binary, ledger_writable, config_schema). **Existing `--doctor` flag preserved** — it emits the full probe envelope (different surface, different consumer). |
| 6 | No-dash family absent | health (last_probe_status), validate, audit, why (3 topics: idle-state-classification, dispatching-threshold, per-session-config), quickstart, repair (ledger-prime scope, --idempotency-key gate) |

## Architecture note: two doctor surfaces coexist

- `--doctor` (legacy flag) emits the **full probe envelope** with `idle_state_summary` and dispatching counts — consumed by flywheel-loop doctor and the watcher pipeline.
- `doctor` (positional subcommand) emits the **canonical-cli doctor.checks** envelope — consumed by canonical-cli linters, fleet audits, and AG3 verification.

Both are intentional. The legacy `--doctor` flag is preserved to avoid breaking downstream consumers; the canonical positional `doctor` adds the AG3-compliant surface.

## Backward compatibility

- `--json` default probe preserved (regression-tested: emits session, repo, br_ready_count).
- `--doctor --json --session NAME` preserved (regression-tested: full envelope with idle_state_summary).
- `--help` shows expanded usage block.
- `--version` emits VERSION string (was `idle-state-probe 1.0.0`, now `idle-state-probe.v1.1.0`).
- Unknown args return rc=64 (preserved).
- `--examples` without `--json` emits text mode (preserved).

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/idle-state-probe.sh` | 324 → 591 lines (+267) |
| `tests/idle-state-probe-canonical-cli.sh` | NEW (21 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.7/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
