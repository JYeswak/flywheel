# Compliance Evidence Pack — flywheel-1hshd.6

Surface: `.flywheel/scripts/bcv-task-harness.sh`
Bead: flywheel-1hshd.6 (wave-4-general-6)
Parent bead: flywheel-1hshd (jloib wave-4 decomposition, closed)
Identity: MagentaPond

## Summary

622-line existing script with strong partial coverage: `--info` / `--schema` / `--examples` / `--apply` / `--idempotency-key` (already with rc=3 gate!) / `--dry-run` / `--json` + ~20 operational flags. Inventory signals were STALE (claimed has_info:false but --info actually works). Gaps: L6 magic comment + no no-dash subcommand family.

Size: 622 → 929 lines (+307 lines, ~49% growth — larger because needed FULL no-dash scaffold family added).

21/21 PASS, AG1+AG3 strict, lint RC=0 (was RC=1).

## Gaps closed

1. **L6 missing-magic-comment** → added `# flywheel-cli-surface: true`
2. **No-dash subcommand family missing** → added `doctor` / `health` / `repair` / `validate` / `audit` / `why` / `help` via additive scaffold block with early-dispatch

The existing dash-flag forms (`--info` / `--schema` / `--examples` / `--apply` / `--idempotency-key` / `--dry-run`) are UNCHANGED. The script's pre-existing `--apply` rc=3 gate (line 487 `exit 3`) is preserved — verified by test #16 (legacy --apply rc=3 envelope).

## AG3 acceptance gates

| Gate | Status |
|---|---|
| `--info --json` | PASS (pre-existing) |
| `--schema --json` | PASS (pre-existing) |
| `--examples --json` | PASS (pre-existing) |
| `doctor --json \| jq -e '.checks'` | PASS (**NEW** — 6 substrate probes) |
| `--apply` without `--idempotency-key` → rc=3 | PASS (pre-existing legacy + NEW repair --apply gate) |
| canonical-cli-lint.sh RC=0 | PASS (**NEW** — was RC=1) |

## Per-binary fillin coverage

- **doctor (6 probes)**: jq_on_path, shasum_on_path (for target_beads_sha), bcv_skill_dir_present (BCV_SKILL_DIR override), audit_log_writable, phase4_subagent_present, flywheel_root_resolvable.
- **health**: tails audit log; 7d staleness threshold.
- **repair (2 scopes)**: audit-log-rotate (5MB; rc=3 refusal) + skill-dir-prime (read-only — probes BCV skill dir with phase4/phase6 subagent presence).
- **validate (4 subjects)**: row (3 required fields: tool + version + status), schema, config, audit-log.
- **audit**: cli_emit_audit_tail.
- **why (3 states)**: greps audit log for id substring.

## Test suite

`tests/bcv-task-harness-canonical-cli.sh` — 21/21 PASS:
- 8 AG1 no-dash subcommands (doctor + health + repair --dry-run + repair --apply rc=3 + validate + audit + why + help)
- 4 fillin-specific (doctor 5+ probes, repair skill-dir-prime non-stub, validate row + audit-log subjects)
- 5 BACKWARD-COMPAT (legacy --info + --schema + --examples + --apply envelope + --apply rc=3 exit code)
- 4 lint + style (L6 magic comment + RC=0 + --help + bash -n)

## Pre-existing test regression

No `tests/bcv-task-harness*.sh` or `tests/test_bcv*.sh` files in the repo. Backward-compat verified by 5 dedicated assertions in the new test suite.

## Compliance score

| Axis | Score |
|---|---:|
| AG1 envelope shape | 200/200 |
| AG3 per-binary acceptance | 200/200 |
| Fillin completeness | 200/200 (no-dash subcommand family added) |
| Heredoc fallback preserved | 150/150 — all 5 legacy dash-flag surfaces unchanged |
| Test coverage (21/21) | 100/100 |
| Documentation | 50/50 |
| Style / Bash hygiene | 100/100 (lint RC=0; --apply rc=3 enforced both legacy + new) |
| **TOTAL** | **1000/1000** |

## Four-Lens Self-Grade

- **brand:10** — additive coexistence with strong pre-existing canonical surfaces.
- **sniff:10** — legacy --apply rc=3 gate preserved + new repair --apply rc=3 added; defense-in-depth.
- **jeff:10** — single-purpose surfaces; legacy fields kept in --info/--schema envelopes.
- **public:10** — Three Judges check: 21/21 tests + explicit BACKWARD-COMPAT assertions for every legacy surface.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes**
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a**
- `readme-writing`: **n/a**

## Files reserved/released (L107)

`.flywheel/scripts/bcv-task-harness.sh` reserved + released.

## Backup

`.flywheel/scripts/bcv-task-harness.sh.bak.scaffold-20260511T030531596368000Z-59585` (gitignored).
