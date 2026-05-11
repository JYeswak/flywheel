# flywheel-k8gcv.23 — plan-state-lens-merge.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.23 (wave-3-23, P0)
Surface: `.flywheel/scripts/plan-state-lens-merge.sh`
Lane: mission
mutates_state: yes (atomic STATE.json writes; ledger append on apply)

## AG3 acceptance gate

18/18 PASS. AG3 strict 4/4. Lint clean (was 1 violation: L4).

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L4 state_path short-circuit | Replaced `[[ ]] && X || Y` with `if/then/else/fi` + explicit `return 0` |
| 2 | L6 magic comment | Added |
| 3 | `--apply` flag absent | Added with `--idempotency-key` gate (rc=3 refusal) |
| 4 | `--info` missing AG3 fields | Enriched (name+version+capabilities (6)+subcommands (9)+env_vars+exit_codes; legacy row_schema preserved) |
| 5 | `--schema` flag absent | Added with input/output schemas |
| 6 | positional `doctor` absent | Added emit_canonical_doctor (3 checks: jq, shasum, ledger_writable) |
| 7 | No-dash family absent | health, audit, why (3 topics: lens-merge-pattern, audit-lens-identity-key, state-sha-self-recompute), quickstart, repair (ledger-prime scope) |

## Architectural note: validate positional reserved for legacy

The script's existing `validate` positional subcommand validates a plan STATE.json file (different semantics from canonical `validate` which emits a ledger-validation envelope). I deliberately did NOT intercept `validate` in the canonical no-dash family — it falls through to the legacy validate-state-file path. Documented in `--info.subcommands` array (lists both legacy `append`/`derived`/`validate` and canonical `doctor`/`health`/etc.).

## Backward compatibility

5 regression tests:
- Legacy `validate` positional still parses (emits "state file not readable" on missing plan).
- `--info` preserves `row_schema:"plan-state-lens-row/v1"`.
- `--examples` (no `--json`) text mode preserved.
- `--help` shows usage.
- `append --apply` now requires `--idempotency-key` (new gate — operator must adopt).

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/plan-state-lens-merge.sh` | 165 → 533 lines (+368) |
| `tests/plan-state-lens-merge-canonical-cli.sh` | NEW (18 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | partial→passing |
| `.flywheel/audit/flywheel-k8gcv.23/evidence.md` | NEW |

## Compliance: 1000/1000

four_lens=brand:9,sniff:9,jeff:9,public:9
