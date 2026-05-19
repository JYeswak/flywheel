# MP Scaffolder Projection - 2026-05-19

Scope: scoped to top-5 MP scaffolders authored, not applied.

This sprint ships dry-run-first scaffolders only. It does not apply them to real
fleet surfaces or consumer repos.

## Inputs

- Baseline scorecard: `.flywheel/audits/fleet-conformance-2026-05-19-v2/SCORECARD.md`
- Inventory basis: `.flywheel/inventory/2026-05-19-rebuild/inventory-rebuild.jsonl`
- Baseline audited surfaces: 2128 T1/T2 rows
- Baseline validators: 30
- Baseline PASS/FAIL/SKIP: 7031/12280/44529
- Baseline applicable checks: 19311
- Baseline `skill_quality_bar_coverage_ratio`: 0.3641

## Targeted Zero-Coverage MPs

| MP | Applicable | Current PASS | Current FAIL | Projected PASS After Apply |
|---|---:|---:|---:|---:|
| MP-90 | 969 | 0 | 969 | 969 |
| MP-91 | 898 | 0 | 898 | 898 |
| MP-89 | 662 | 0 | 662 | 662 |
| MP-82 | 520 | 0 | 520 | 520 |
| MP-97 | 480 | 0 | 480 | 480 |
| Total | 3529 | 0 | 3529 | 3529 |

## Projection

If the five scaffolders are later applied across every currently failing
applicable T1/T2 surface and the validators are rerun:

- Projected PASS: 7031 + 3529 = 10560
- Projected FAIL: 12280 - 3529 = 8751
- Applicable checks remain: 19311
- Projected `skill_quality_bar_coverage_ratio`: 10560 / 19311 = 0.5468
- Absolute uplift: +0.1827
- Relative uplift over v2 baseline: 50.2%

This is an upper-bound mechanical projection for this exact validator set. It is
realistic only if each target accepts an appended stance block or directory
sidecar and no new validator applicability rows are added during rerun.

## Apply Gate

Applying to real fleet surfaces is explicitly out of scope for this sprint. A
future Joshua-gated dispatch should run:

```bash
.flywheel/scripts/mp-scaffolder-runner.sh --dry-run --limit-per-mp 5
```

Then inspect diffs before any apply-mode run with per-scaffolder confirmations.
