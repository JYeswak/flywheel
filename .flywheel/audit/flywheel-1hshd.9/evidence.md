# Compliance Evidence Pack — flywheel-1hshd.9

Surface: `.flywheel/scripts/callback-receipt-validator.sh`
Bead: flywheel-1hshd.9 (wave-4-general-9)
Parent bead: flywheel-1hshd
Identity: MagentaPond

## Summary — sister of 1hshd.8 (this IS the validator that 1hshd.8 wraps)

288-line callback receipt validator. The script that the 1hshd.8 wrapper delegates to via `check --callback-stdin`. Wave-4 partial classification was generous — effectively missing-baseline (only `--info`/`--examples`/`--help` worked; no doctor/health/repair/validate/audit/why/--schema).

288 → 584 lines (+296 lines, ~103% growth). 22/22 PASS, AG1+AG3 strict, lint RC=0 (was RC=1).

## Wrapper-validator chain verified intact

Test #18 explicitly verifies the wrapper→validator chain: pipes a malformed callback through `~/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh` (the 1hshd.8 surface), which delegates to this validator. Output contains `UNVERIFIABLE` (tri-state response). The 1hshd.9 scaffold did NOT break the wrapper's dependency on the `check` subcommand.

## Gaps closed (6)

1. L5 missing-strict-mode → `set -uo` → `set -euo pipefail` (safe — existing `set +e` block preserves verify-rc capture)
2. L6 missing-magic-comment → `# flywheel-cli-surface: true`
3. **--schema dash flag** → emits canonical schema with decision_row + decisions enum + exit_codes
4. **No-dash subcommand family** → doctor / health / repair / validate / audit / why / quickstart / help
5. **--apply contract** → repair --apply requires --idempotency-key (rc=3)
6. **Substrate probes** → doctor 5 probes: jq, fix_bead_opener_executable, ledger_writable, repo_dir_present, flywheel_root_resolvable

## AG3 acceptance gates

| Gate | Status |
|---|---|
| `--info --json` | PASS (pre-existing) |
| `--schema --json` | PASS (**NEW** dash flag) |
| `--examples` | PASS (pre-existing) |
| `doctor --json \| jq -e '.checks \| length >= 5'` | PASS (**NEW**) |
| `repair --apply` without `--idempotency-key` → rc=3 | PASS (**NEW**) |
| canonical-cli-lint.sh RC=0 | PASS (**NEW** — was RC=1 from L5) |
| wrapper→validator chain intact | PASS (Test #18) |

## Per-binary fillin coverage

- **doctor (5 probes)**: jq, fix_bead_opener_executable (callback-fix-bead-opener.sh), ledger_writable, repo_dir_present, flywheel_root_resolvable.
- **health**: tails ledger; counts decision distribution (PASS/REFUSE/UNVERIFIABLE).
- **repair (2 scopes)**: ledger-rotate (5MB; rc=3) + fix-bead-opener-prime (read-only).
- **validate (4 subjects)**: row (4 required fields: schema_version/version/ts/decision) + schema + config + ledger (with decision-counts breakdown).
- **audit / why / quickstart / help**: full canonical family.
- **`check` subcommand UNCHANGED** — tri-state PASS/REFUSE/UNVERIFIABLE preserved. Verified by Tests #17 (direct invocation) and #18 (through 1hshd.8 wrapper).

## Test suite

`tests/callback-receipt-validator-canonical-cli.sh` — 22/22 PASS:
- 10 NEW canonical surfaces
- 5 fillin-specific (doctor probes, repair ledger-rotate + fix-bead-opener-prime, validate ledger decision counts, validate row 4-field schema)
- 4 backward-compat (--info preserved, check command tri-state, wrapper→validator chain, magic comment present)
- 3 lint + style (--help, lint RC=0, magic comment)

## Wrapper-validator chain verification

The 1hshd.8 wrapper at `~/.claude/commands/flywheel/_shared/callback-receipt-validator-wrapper.sh` calls THIS validator via:
```bash
"$VALIDATOR" check --callback-stdin --dispatch-file "$DISPATCH_FILE" --repo "$REPO" --json <"$tmp"
```
The `check` subcommand handler is in the script's original argparse loop (BELOW the new canonical scaffold). Scaffold intercepts NO-dash canonical args + `--schema`/`--examples`; `check` falls through to original logic. Test #18 verifies chain intact.

## Compliance score

| Axis | Score |
|---|---:|
| AG1 envelope shape | 200/200 |
| AG3 per-binary acceptance | 200/200 |
| Fillin completeness | 200/200 (6 gaps closed; full canonical family) |
| Heredoc fallback preserved | 150/150 (check command + tri-state + wrapper chain) |
| Test coverage (22/22) | 100/100 |
| Documentation | 50/50 |
| Style / Bash hygiene | 100/100 (lint RC=0 was RC=1; safe strict-mode) |
| **TOTAL** | **1000/1000** |

## Four-Lens Self-Grade

- **brand:10** — sister of 1hshd.8 with documented wrapper chain.
- **sniff:10** — tri-state behavior + fix-bead-opener integration unchanged.
- **jeff:10** — scaffold doesn't touch the validator's core verify-rerun logic.
- **public:10** — Three Judges check: wrapper-validator chain explicitly tested.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes**
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a**
- `readme-writing`: **n/a**

## Files reserved/released (L107)

`.flywheel/scripts/callback-receipt-validator.sh` reserved + released.

## Backup

`.flywheel/scripts/callback-receipt-validator.sh.bak.scaffold-20260511T032505188473000Z-4107` (gitignored).
