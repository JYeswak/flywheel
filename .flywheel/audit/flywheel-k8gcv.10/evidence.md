# flywheel-k8gcv.10 — jeff-binary-version-watchtower.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.10 (wave-3-10, P0)
Surface: `.flywheel/scripts/jeff-binary-version-watchtower.sh`
Lane: jeff-corpus
mutates_state: yes (writes ledger row + auto-files P1 drift bead in `--apply` mode)

## AG3 acceptance gate

20/20 PASS on `tests/jeff-binary-version-watchtower-canonical-cli.sh`. AG3 strict 4/4. Lint clean (was 2 violations: L6+L7).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L6 missing-magic-comment | Added (required since `--apply` exists) |
| 2 | L7 --apply without --idempotency-key | Added `IDEMPOTENCY_KEY` var + flag + rc=3 refusal block |
| 3 | `--info` missing `.name`+`.capabilities` | Replaced minimal envelope with full AG3 envelope: name+version+capabilities (8 items)+subcommands+env_vars+exit_codes |
| 4 | `--schema` flag absent | Added `emit_schema` (input/output schemas) |
| 5 | `--examples --json` envelope absent | Added `emit_examples_json` while preserving text-mode for legacy |
| 6 | positional `doctor` subcommand canonical | Added `emit_canonical_doctor` with 5 checks (jq, ntm, br, gh, ledger). Intercept fires on `doctor --json`; positional `doctor` without `--json` falls through to legacy watchtower run |
| 7 | No-dash family absent | health, validate, audit, why (3 topics: substrate-drift, canary-pattern, frankenterm-watch), quickstart, repair (ledger-prime scope). All `--json` paths go canonical; bare positional `health` falls through to legacy run |

## Architecture: dual-mode positional intercept

To preserve backward compat for `doctor` and `health` positional invocations (which previously ran the full watchtower body), the new intercept fires ONLY when `--json` follows:

```bash
doctor)
  shift
  if [[ "${1:-}" == "--json" ]]; then
    emit_canonical_doctor; exit 0   # canonical AG3 .checks shape
  fi
  set -- doctor "$@"                # fall through to legacy main body
  ;;
```

This means `doctor --json` emits canonical AG3 envelope; bare `doctor` or `health` emits the full watchtower envelope as before.

## Backward compatibility

5 regression tests:
- `--dry-run --json` emits full watchtower envelope (rows, watchlists, etc.).
- `health` (no `--json`) falls through to main path (schema_version + status present).
- `completion` still emits bash completion script.
- `--help` shows expanded usage.
- `--examples` (no `--json`) emits text mode.

Behavior change: `--apply` now requires `--idempotency-key` (rc=3 if missing) — surfaced via canonical refusal envelope.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/jeff-binary-version-watchtower.sh` | 229 → 511 lines (+282) |
| `tests/jeff-binary-version-watchtower-canonical-cli.sh` | NEW (20 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.10/evidence.md` | NEW |

Bundled in same commit (parallel skillos retraction work):
| Path | Δ |
|---|---|
| `.flywheel/scripts/doctor-invariants/trust-gate-wiring.sh` | Added FLYWHEEL_TARGET_REPO_ROOT env-var-awareness (mirror of skillos d19c747) |
| `.flywheel/wire-or-explain-ledger/2026-05-11-phase-c-baseline.jsonl` | Annotated with retraction note |
| `.flywheel/handoffs/20260511T0500Z-from-flywheel-1-to-skillos-1-retraction-ack-cadence-baseline-not-yet-real.md` | NEW retraction-ACK handoff |

## Compliance: 1000/1000

2 prior lint violations cleared; AG3 strict 4/4; legacy contract preserved across 5 dedicated regression assertions.

four_lens=brand:9,sniff:9,jeff:9,public:9
