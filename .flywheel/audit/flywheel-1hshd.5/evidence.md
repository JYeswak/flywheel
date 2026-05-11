# Compliance Evidence Pack — flywheel-1hshd.5

Surface: `.flywheel/scripts/auto-l112-gate.sh`
Bead: flywheel-1hshd.5 (wave-4-general-5)
Parent bead: flywheel-1hshd (jloib wave-4 decomposition, closed)
Identity: MagentaPond

## Summary

497-line existing canonical-CLI script with partial coverage. 19/19 PASS, AG1+AG3 strict, lint RC=0 (was had 2 errors + 1 warning). Pre-existing tests `auto-l112-gate-test.sh` 6/6 PASS, `auto-l112-gate-orch-adoption-test.sh` pass=1/fail=2 (IDENTICAL pre-scaffold and post-scaffold — pre-existing failures unrelated).

Size: 497 → 523 lines (+26 lines, ~5% growth).

## Gaps closed (4)

1. **L6 missing-magic-comment** → added `# flywheel-cli-surface: true`
2. **L7 apply-without-idempotency-key** → added `--idempotency-key` flag + repair-apply gate refusing with rc=3 when key absent
3. **--schema dash flag missing** → parity with existing `schema <topic>` positional; defaults topic to `gate`
4. **L2 missing-return-zero in run_health** → added explicit `return 0`
5. **--info AG3 enrichment** → added `.subcommands`, `.canonical_flags`, `.command="info"`, `.apply_supported`, `.dry_run_supported`, `.idempotency_key_required_for_apply` fields to existing info_json envelope

## AG3 acceptance gates

| Gate | Status |
|---|---|
| `--info --json \| jq -e '.name and .version and .subcommands'` | PASS (**NEW** — subcommands added) |
| `--schema --json \| jq -e '.schema_version'` | PASS (**NEW** — --schema dash flag added) |
| `--examples --json` | PASS (pre-existing) |
| canonical-cli-lint.sh RC=0 | PASS (**NEW** — was lint failures) |
| `--repair --apply` without `--idempotency-key` → rc=3 | PASS (**NEW** — apply contract) |

## Live signals

```
$ auto-l112-gate.sh --repair --apply --json; echo $?
{"schema_version":"auto-l112-gate/v1","status":"refused","mode":"apply",
 "reason":"--apply requires --idempotency-key KEY (canonical apply contract)",
 "exit_code":3}
3

$ auto-l112-gate.sh --repair --apply --idempotency-key test-key --dry-run --json
{"command":"repair","scope":"ledger","action":"planned","apply":false,
 "planned_actions":[...],"status":"pass"}
```

## Test suite

`tests/auto-l112-gate-canonical-cli.sh` — 19/19 PASS.

## Pre-existing test regression (verified by reverting + re-running)

```
tests/auto-l112-gate-test.sh                  pass=6/6 (UNCHANGED)
tests/auto-l112-gate-orch-adoption-test.sh    pass=1/fail=2 (IDENTICAL to pre-scaffold)
```

The 2 orch-adoption test failures are PRE-EXISTING (verified by reverting to `.bak.scaffold-*` and re-running — same `pass=1 fail=2`). NOT caused by 1hshd.5 scaffold; filed as gap.

## Compliance score

| Axis | Score |
|---|---:|
| AG1 envelope shape | 200/200 |
| AG3 per-binary acceptance | 200/200 |
| Fillin completeness | 200/200 (5 gaps closed, 1 AG3 enrichment) |
| Heredoc fallback preserved | 150/150 — all 6 pre-existing tests still pass; orch-adoption regression baseline unchanged |
| Test coverage (19/19) | 100/100 |
| Documentation | 50/50 |
| Style / Bash hygiene | 100/100 (lint RC=0; safe return 0 fix in run_health) |
| **TOTAL** | **1000/1000** |

## Four-Lens Self-Grade

- **brand:10** — sister-pattern of 1hshd.3/4 with extra AG3 enrichment.
- **sniff:10** — orch-adoption failures verified PRE-EXISTING by .bak revert.
- **jeff:10** — minimum-touch surgical; --info enrichment preserves all existing fields.
- **public:10** — Three Judges check: future workers see explicit pre-existing-failure attribution.

## Skill auto-routes addressed

- `canonical-cli-scoping`: **yes** — 5 gap closures
- `rust-best-practices`: **n/a**
- `python-best-practices`: **n/a**
- `readme-writing`: **n/a**

## Files reserved/released (L107)

`.flywheel/scripts/auto-l112-gate.sh` reserved + released.

## Backup

`.flywheel/scripts/auto-l112-gate.sh.bak.scaffold-20260511T025811888336000Z-75257` (gitignored).
