# MP Scaffolder Apply Log - 2026-05-19

Status: HALTED after validation.

Scope: scoped to scaffolder apply across flywheel surfaces, Joshua-authorized at
2026-05-19T16:25Z. Consumer repos and Track 1/2 mission/goal/legal surfaces were
not touched.

## Boundary Finding

The prior +50.2% projection used all 3529 fleet-wide failing rows. The loop
contract for this apply sprint narrowed write scope to `repo=flywheel` only.
The v2 failing rows split as:

| Repo class | Rows |
|---|---:|
| flywheel repo rows after Track 1/2 exclusions | 2067 |
| existing in clean apply worktree | 1928 |
| absent from clean apply worktree and skipped | 139 |
| non-flywheel rows refused by contract | 1462 |

Because 1462 non-flywheel rows were intentionally not mutated, the full-fleet
ratio could not reach the projected `0.5468`.

## Apply Commits

| MP | Commit | Existing Rows Applied | Unique Paths | v2 PASS -> v3 PASS | v3 Coverage |
|---|---|---:|---:|---:|---:|
| MP-90 | `c739cc33` | 578 | 578 | 0 -> 578 | 0.6208 |
| MP-91 | `ce07aa63` | 477 | 477 | 0 -> 477 | 0.5495 |
| MP-89 | `6930a825` | 369 | 369 | 0 -> 369 | 0.4701 |
| MP-82 | `b590d9ad` | 251 | 251 | 0 -> 251 | 0.5081 |
| MP-97 | `9b78383d` | 253 | 253 | 0 -> 253 | 0.5500 |
| Total | 5 commits | 1928 | 1928 | 0 -> 1928 | n/a |

## Skips

Skipped rows were v2 target rows whose files existed in the original v2 scan but
were absent from the clean commit worktree used for isolated application.

| MP | Missing Rows |
|---|---:|
| MP-90 | 38 |
| MP-91 | 30 |
| MP-89 | 25 |
| MP-82 | 26 |
| MP-97 | 20 |
| Total | 139 |

Skip list: `.flywheel/audits/mp-scaffolders-apply-2026-05-19/target-lists/missing-in-clean-worktree.jsonl`

## V3 Fleet Audit

Output: `.flywheel/audits/fleet-conformance-2026-05-19-v3-post-scaffolders/SCORECARD.md`

| Metric | v2 | v3 | Delta |
|---|---:|---:|---:|
| skill_quality_bar_coverage_ratio | 0.3641 | 0.4574 | +0.0933 |
| PASS | 7031 | 9041 | +2010 |
| FAIL | 12280 | 10725 | -1555 |
| Applicable | 19311 | 19766 | +455 |

Result: v3 ratio is below the requested `>= 0.50` floor, for the write-scope
reason above.

## Regression Gate

The no-regression gate failed. Non-targeted MP coverage dropped in the v3 audit:

| MP | v2 Coverage | v3 Coverage | PASS Delta |
|---|---:|---:|---:|
| MP-01 | 0.0118 | 0.0095 | 18 -> 14 |
| MP-03 | 0.3886 | 0.3872 | 696 -> 666 |
| MP-04 | 0.8920 | 0.8526 | 1230 -> 1192 |
| MP-33 | 0.7966 | 0.7926 | 1300 -> 1261 |
| MP-88 | 0.0225 | 0.0137 | 14 -> 14 |

Regression receipt:
`.flywheel/audits/mp-scaffolders-apply-2026-05-19/non-target-regression-check.json`

## Track Boundary Validation

- Target-list repos: `flywheel` only.
- Excluded path prefixes: `AGENTS.md`, `CLAUDE.md`, `README.md`, `CHARTER.md`,
  `.flywheel/MISSION*`, `.flywheel/GOAL*`, `.flywheel/STATE*`,
  `.flywheel/WORK*`, `.flywheel/rules/**`, `.flywheel/handoffs/**`,
  `.flywheel/legal/**`, `.flywheel/doctrine/legal/**`.
- Consumer repo writes: 0.
- `~/.claude/skills` writes: 0.

## Halt Reason

Stopped per loop contract because the non-target regression gate failed and the
full-fleet v3 ratio remained below `0.50`. The five MP apply commits are present
on branch `mp-scaffolders-apply-20260519` for inspection or revert.
