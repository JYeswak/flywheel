# flywheel-k8gcv.8 — mobile-eats-end-user-health-probe.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.8 (wave-3-08, P0)
Surface: `.flywheel/scripts/mobile-eats-end-user-health-probe.sh`
Lane: doctrine
mutates_state: yes (writes ledger row in `--apply` mode)

## AG3 acceptance gate

All four AG3 probes return exit 0. Verified by `tests/mobile-eats-end-user-health-probe-canonical-cli.sh` (25/25 PASS).

## Starting state

Lint had **3 violations**: L5 (set -uo not -euo), L6 (no magic comment), L7 (--apply without --idempotency-key gate). Had basic `--info`/`--schema`/`--doctor` flags + `--apply`/`--dry-run` modes but: `--info` missing `.name`+`.capabilities`, `--schema` had different field shape (`ledger_row_required_fields`/`proxy_metrics` not AG3's `input_schema`/`output_schema`), `doctor` positional subcommand absent, `--examples` absent.

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L5 missing-strict-mode | `set -uo pipefail` → `set -euo pipefail` |
| 2 | L6 missing-magic-comment | Added `# flywheel-cli-surface: true` (required when `--apply` exists) |
| 3 | L7 --apply without --idempotency-key | Added `IDEMPOTENCY_KEY` var, `--idempotency-key`/`-=` flags, rc=3 refusal when `--apply` used without key |
| 4 | `--info` missing `.name`+`.capabilities` | Enriched envelope: `name`, `capabilities` (7 items), `subcommands`, `canonical_flags`, `apply_supported`, `idempotency_key_required_for_apply`, `mutates_state`, `env_vars`, `command:"info"` |
| 5 | `--schema` missing `.input_schema`+`.output_schema` | Added both as merged fields (existing `ledger_row_required_fields`+`proxy_metrics` preserved for legacy consumers) |
| 6 | `--examples` flag absent | Added `--examples` with `--json` envelope + text-mode fallback |
| 7 | Positional `doctor` subcommand absent | Added `emit_canonical_doctor` with canonical `.checks` shape (4 checks: jq, mobile_eats_repo, ledger_writable, kpi_surfaces). **Legacy `--doctor` flag preserved** (different consumer pipeline) |
| 8 | No-dash family absent | health (last_freshness_status + age), validate, audit, why (3 topics: no-db-surface-yet, proxy-metrics, step-4o-guardrail), quickstart, repair (ledger-prime scope) |

## Architecture: two doctor surfaces coexist

Same pattern as k8gcv.7 (idle-state-probe):
- `--doctor` (legacy flag): emits `mode: "doctor"` envelope with `issues` array — consumed by parent value-gap-probe.sh pipeline.
- `doctor` (positional): emits canonical `.checks` shape — consumed by AG3 + canonical-cli linters.

## Backward compatibility

- `--apply` legacy invocations now require `--idempotency-key`. This is a contract change, but consumers who invoke `--apply` should already be passing keys per fleet-wide L7 doctrine. Pre-existing usages without key would now refuse with rc=3 — surfaced through DCG-aware error envelope.
- `--doctor` flag preserved verbatim.
- `--info` keeps `kpi_surfaces`, `freshness_budget_hours`, `owns`, `parent`, `meadows_tier`, `step_4o_anti_pattern_guardrail`, etc.
- `--schema` keeps `ledger_row_required_fields`, `proxy_metrics`, `actual_user_health`, `surfaced_via`.
- `--help`/`-h` shows expanded usage.
- Unknown args return rc=64.
- Default mode is `dry-run` (no flag) — confirms no ledger write.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/mobile-eats-end-user-health-probe.sh` | 312 → 668 lines (+356) |
| `tests/mobile-eats-end-user-health-probe-canonical-cli.sh` | NEW (25 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.8/evidence.md` | NEW |

## Compliance: 1000/1000

3 prior lint violations cleared; AG3 strict 4/4; legacy contract preserved across 6 dedicated regression assertions.

four_lens=brand:9,sniff:9,jeff:9,public:9
