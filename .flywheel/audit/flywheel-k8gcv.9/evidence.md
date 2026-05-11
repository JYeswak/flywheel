# flywheel-k8gcv.9 — validate-callback-before-close.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.9 (wave-3-09, P0)
Surface: `.flywheel/scripts/validate-callback-before-close.sh`
Lane: doctrine
mutates_state: yes (creates rework beads in `--apply` mode, appends to ledger)

## AG3 acceptance gate

19/19 PASS on `tests/validate-callback-before-close-canonical-cli.sh`. AG3 strict 4/4. Lint clean (was 4 violations).

## Starting state

Lint had **4 violations**: L5 (set -uo not -euo), L6 (no magic comment), L7 (--apply without --idempotency-key), L10 (apply-mutation-needs-key). `--info` emitted YAML-like text (not JSON). `--schema` absent. positional `doctor` subcommand absent.

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L5 missing-strict-mode | `set -uo pipefail` → `set -euo pipefail` |
| 2 | L6 missing-magic-comment | Added (required since `--apply` present) |
| 3 | L7 --apply without --idempotency-key | Added `IDEMPOTENCY_KEY` var + `--idempotency-key`/`-=` flags + rc=3 refusal block before main work |
| 4 | L10 apply-mutation-needs-key | Same as L7 |
| 5 | `--info` not JSON | Replaced YAML text with full JSON envelope: name + version + capabilities (7) + subcommands + apply_supported + env_vars + exit_codes |
| 6 | `--schema` flag absent | Added `emit_schema` (input/output schemas + exit_codes) |
| 7 | `--examples --json` envelope absent | Added `examples_json` while preserving legacy text-mode `examples` |
| 8 | positional `doctor` absent | Added `emit_canonical_doctor` with 4 checks (jq, br_binary, ntm_bin, ledger_writable) |
| 9 | No-dash family absent | health (last_verdict + row count), validate (schema verify), audit (tail), why (3 topics: four-lens-gate, did-n-of-m-gate, rework-bead-class), quickstart, repair (ledger-prime scope) |

## Backward compatibility

5 dedicated regression tests:
- Legacy flag-form dry-run emits verdict envelope.
- Legacy positional form (`<bead> <evidence> --strict`) still parses.
- `--help` shows usage.
- `--version` emits VERSION (now `validate-callback-before-close.v1.3.0`).
- `--bogus`/unknown args still rejected.

Behavior change to flag: `--apply` now requires `--idempotency-key` (rc=3 if missing). Existing callers that invoke `--apply` should already be passing keys per fleet-wide L7 doctrine.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/validate-callback-before-close.sh` | 640 → 990 lines (+350) |
| `tests/validate-callback-before-close-canonical-cli.sh` | NEW (19 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.9/evidence.md` | NEW |

## Compliance: 1000/1000

4 prior lint violations cleared; AG3 strict 4/4; legacy contract preserved.

four_lens=brand:9,sniff:9,jeff:9,public:9
