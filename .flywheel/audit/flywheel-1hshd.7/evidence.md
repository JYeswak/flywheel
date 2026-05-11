# Compliance Evidence Pack — flywheel-1hshd.7

Surface: `.flywheel/scripts/callback-envelope-schema-validator.sh`
Bead: flywheel-1hshd.7 (wave-4-general-7)
Parent bead: flywheel-1hshd
Identity: MagentaPond

## Summary — 20-line minimal patch

767-line existing bash-wrapped python script with FULL canonical-CLI family already in place: positional `doctor`/`health`/`repair`/`validate`/`audit`/`why`/`schema`/`quickstart`/`help`/`completion` AND dash-flag `--doctor`/`--health`/`--repair`/`--info`/`--examples`/`--idempotency-key` (legacy --apply rc=3 gate already enforced). Inventory flagged `has_schema:false` because **--schema dash-flag form was missing** (positional `schema <topic>` worked, but `--schema` was rejected as "unknown argument").

20-line surgical patch (smallest of session after 1hshd.2): added `--schema` translation in the bash wrapper to convert `--schema [topic]` and `--schema=topic` into the positional `schema topic` form before the python heredoc parses argv. Plus magic comment.

Size: 767 → 787 lines (+20 lines, ~2.6% growth). 21/21 PASS, AG1+AG3 strict, lint RC=0 (was RC=0 too — script was already lint-clean except for inventory-derived AG3 gap).

## Gaps closed (2)

1. **L6 magic comment** → added `# flywheel-cli-surface: true` + `# canonical-cli-scoping: passing`
2. **--schema dash flag missing** → added bash-level argv translation:
   ```bash
   if [[ $# -gt 0 ]] && { [[ "$1" == "--schema" ]] || [[ "$1" == --schema=* ]]; }; then
     _topic="envelope"
     if [[ "$1" == --schema=* ]]; then _topic="${1#*=}"; shift
     else shift; if [[ $# -gt 0 && "${1:-}" != --* ]]; then _topic="$1"; shift; fi
     fi
     set -- schema "$_topic" "$@"
   fi
   ```
   The python heredoc's existing `mode == "schema"` dispatch handler serves the translated argv unchanged.

## AG3 acceptance gates

| Gate | Status |
|---|---|
| `--info --json` | PASS (pre-existing) |
| `--schema --json` | PASS (**NEW** — bash translation to positional `schema envelope`) |
| `--schema=ledger --json` | PASS (**NEW** — emits ledger-specific .required_fields[]) |
| `--examples --json` | PASS (pre-existing) |
| `doctor --json \| jq -e '.status'` | PASS (pre-existing — full canonical family already) |
| canonical-cli-lint.sh RC=0 | PASS (preserved) |

## Per-binary AG3 coverage (PRE-EXISTING)

This script already had FULL canonical-CLI coverage in python. The fillin did NOT touch python — only added bash-level dispatcher patches:
- doctor (pre-existing): emits status + violations + top_missing_fields envelope
- health (pre-existing): wraps doctor with health field
- repair (pre-existing): scopes ledger/substrate-contract/all with --apply gate
- validate (pre-existing): envelope subject with --callback-envelope/--callback-envelope-file/--stdin inputs; --apply requires --idempotency-key (rc=3 path inside python)
- audit (pre-existing): ledger tail
- why (pre-existing): explains field/violation by id
- schema (pre-existing positional): envelope/doctor/ledger/contract topics

## Test suite

`tests/callback-envelope-schema-validator-canonical-cli.sh` — 21/21 PASS:
- 4 NEW --schema dash flag (with/without topic, =topic= form, ledger-specific fields)
- 2 BACKWARD-COMPAT positional schema (envelope, ledger)
- 9 pre-existing canonical surfaces verified (--info, --examples, doctor, --doctor, health, repair, audit, why, quickstart)
- 1 validate envelope dispatch (with explicit argument)
- 1 repair --apply reachable
- 2 lint + magic comment
- 1 --help
- 1 bash -n syntax

## Pre-existing test regression

No `tests/callback-envelope-schema*.sh` or `tests/test_callback_envelope*.sh` files. Backward-compat verified by 2 dedicated positional-schema assertions.

## Compliance score

| Axis | Score |
|---|---:|
| AG1 envelope shape | 200/200 |
| AG3 per-binary acceptance | 200/200 |
| Fillin completeness | 200/200 (2 gaps closed) |
| Heredoc fallback preserved | 150/150 — python heredoc untouched; positional schema preserved |
| Test coverage (21/21) | 100/100 |
| Documentation | 50/50 |
| Style / Bash hygiene | 100/100 (lint RC=0; minimal 20-line bash wrapper change) |
| **TOTAL** | **1000/1000** |

## Four-Lens Self-Grade

- **brand:10** — minimal surgical bash-translation patch; python heredoc untouched.
- **sniff:10** — `--schema` translates to positional form, so the rich python schema handler serves both dash and no-dash uniformly.
- **jeff:10** — 20-line patch in bash wrapper; doesn't duplicate python logic.
- **public:10** — Three Judges check: operator gets both `--schema --json` AND `schema envelope --json` working identically.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes**
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a** — python heredoc unchanged
- `readme-writing`: **n/a**

## Files reserved/released (L107)

`.flywheel/scripts/callback-envelope-schema-validator.sh` reserved + released.

## Backup

`.flywheel/scripts/callback-envelope-schema-validator.sh.bak.scaffold-20260511T031112303399000Z-37572` (gitignored).
