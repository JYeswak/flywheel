# flywheel-k8gcv.1 — callback-fix-bead-opener.sh canonical-cli partial→passing

Bead: flywheel-k8gcv.1 (wave-3-01, P0)
Parent: flywheel-k8gcv (wave-3 P0-partial × non-general lanes)
Surface: `.flywheel/scripts/callback-fix-bead-opener.sh`
Lane: beads
mutates_state: yes (creates beads via `br create`, falls back to `.beads/issues.jsonl` append)

## AG3 acceptance gate (wave-3 apply-spec)

```bash
callback-fix-bead-opener.sh --info --json | jq -e '.name and .version and .capabilities'   # exit 0
callback-fix-bead-opener.sh --schema --json | jq -e '.input_schema and .output_schema'     # exit 0
callback-fix-bead-opener.sh --examples --json | jq -e '.examples | length > 0'             # exit 0
callback-fix-bead-opener.sh doctor --json | jq -e '.checks'                                # exit 0  (mutates_state=yes)
```

All four AG3 probes return exit 0. Verified by `tests/callback-fix-bead-opener-canonical-cli.sh` (20/20 PASS).

## Lint state

Before: `canonical-cli-lint.sh` reported 1 violation (L5 missing-strict-mode).
After: `canonical-cli-lint.sh` reports 0 violations.

```bash
$ .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/callback-fix-bead-opener.sh --json | jq .status
"clean"
```

## Gaps closed

| # | Gap | Fix |
|---|---|---|
| 1 | L5 missing-strict-mode (`set -uo pipefail` → no `-e`) | Upgrade to `set -euo pipefail` with note about explicit `set +e/set -e` around `br create` |
| 2 | L6 missing-magic-comment | Add `# flywheel-cli-surface: true` at top |
| 3 | `--info` missing `.capabilities` (AG3) | Enrich envelope with `subcommands`, `canonical_flags`, `capabilities`, `apply_supported`, `idempotency_key_required_for_apply`, etc. |
| 4 | `--schema` flag absent | Add emitter returning `{input_schema, output_schema}` per AG3 |
| 5 | `--examples` returned plain text only | Add `--examples --json` path returning `{command:"examples", examples:[{name, invocation, purpose}, ...]}`; preserve text-mode for backward compat |
| 6 | `doctor` subcommand absent | Add doctor with 4 checks: jq, br_binary, ledger_writable, repo_dir |
| 7 | `health`, `repair`, `validate`, `audit`, `why`, `quickstart` absent | Add full canonical no-dash family |
| 8 | apply contract missing | Add `--apply`, `--dry-run`, `--idempotency-key` for `repair` scope-routed apply gate (rc=3 if `--apply` without key) |

## Backward compatibility

The legacy run_open invocation is fully preserved:
- `callback-fix-bead-opener.sh --task-id ID --reason REASON [--bead ID] [--expected TEXT] [--actual TEXT] [--repo PATH] [--json]`
- Existing caller: `.flywheel/scripts/callback-receipt-validator.sh` via `CALLBACK_RECEIPT_FIX_BEAD_OPENER`
- Pre-existing test `.flywheel/tests/test-callback-receipt-validator.sh` 16/16 PASS (zero regression).
- New test `tests/callback-fix-bead-opener-canonical-cli.sh` includes legacy-shape PASS + idempotent-dedupe PASS to lock the contract.

## Files touched

| Path | Δ |
|---|---|
| `.flywheel/scripts/callback-fix-bead-opener.sh` | 85 → 372 lines (+287) |
| `tests/callback-fix-bead-opener-canonical-cli.sh` | NEW (75 lines, 20 assertions) |
| `.flywheel/audit/flywheel-cli-inventory/inventory.jsonl` | row 34 partial→passing |
| `.flywheel/audit/flywheel-k8gcv.1/evidence.md` | NEW |

## Verification commands

```bash
# AG3 gate (verbatim from wave-3-apply-spec.md)
.flywheel/scripts/callback-fix-bead-opener.sh --info --json | jq -e '.name and .version and .capabilities'
.flywheel/scripts/callback-fix-bead-opener.sh --schema --json | jq -e '.input_schema and .output_schema'
.flywheel/scripts/callback-fix-bead-opener.sh --examples --json | jq -e '.examples | length > 0'
.flywheel/scripts/callback-fix-bead-opener.sh doctor --json | jq -e '.checks'

# Lint
.flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/callback-fix-bead-opener.sh --json | jq .status   # → "clean"

# Canonical-cli test
bash tests/callback-fix-bead-opener-canonical-cli.sh   # 20/20 PASS

# Pre-existing regression
bash .flywheel/tests/test-callback-receipt-validator.sh   # 16/16 PASS
```

## Compliance score

| Dimension | Score |
|---|---|
| AG1 info/schema/examples present and valid | PASS (3/3) |
| AG3 strict (name+version+capabilities; input_schema+output_schema; examples>0; doctor.checks) | PASS (4/4) |
| Lint RC=0 | PASS |
| Pre-existing regression zero | PASS (16/16) |
| Backward-compat (legacy run_open shape) | PASS (2/2 dedicated tests) |
| Magic comment present | PASS |
| apply contract gated by --idempotency-key (rc=3 refusal) | PASS |
| Inventory row updated partial→passing | PASS |

**Compliance: 1000/1000.**

## Four-Lens Self-Grade

- brand: 9 — surface reads as Joshua's flywheel doctrine (schema-versioned envelopes, dedupe-by-task-reason, jsonl-fallback). Names are domain-specific.
- sniff: 9 — passes canonical-cli-lint clean, AG3 gate, pre-existing regression, new dedicated test. No theater.
- jeff: 8 — single-purpose binary with idempotent run + dedupe ledger + jsonl-fallback; would survive `br` outage. (Not 10 because it doesn't yet read `BEADS_DB` env to discover the issues.jsonl path the way Jeff's br does — uses repo-relative path.)
- public: 9 — Three Judges: (a) skeptical operator can run `doctor`/`health`/`audit` to verify wiring without reading source; (b) maintainer can extend via the inline subcommand dispatcher; (c) future worker can re-derive contract from `--schema --json` output.

four_lens=brand:9,sniff:9,jeff:8,public:9
