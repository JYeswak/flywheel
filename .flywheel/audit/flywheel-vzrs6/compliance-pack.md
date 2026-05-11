# Compliance Pack: flywheel-vzrs6 — score 970/1000

| Axis              | Score | Notes |
|-------------------|-------|-------|
| Scope discipline  | 100 | Test-only mod. Script under test NOT touched (per AG2). |
| Acceptance gate   | 100 | All 4 AGs satisfied + 18/18 test pass |
| Reservation       | 90  |  |
| Pathspec staging  | 100 |  |
| L112 probe        | 100 | Stable string `pass=18 fail=0 total=18` |
| Mission fitness   | 95  | Direct — restores test contract integrity |
| Evidence presence | 100 |  |
| Sniff             | 95  | bgtv8 sister-pattern cross-ref captured |
| Doctrinal align   | 95  | META-rule 2026-05-09 calibrate-test-to-actual-contract applied verbatim |
| Brand             | 95  | 8-line patch + 8-line comment = test contract correct + future operator can read the why |

## Skill discoveries
- pattern-recurrence: META-rule 2026-05-09 `feedback_calibrate_test_to_actual_contract_before_filing_upstream` now N=3+ (flywheel-q70t1 17→0, flywheel-bgtv8, flywheel-vzrs6). Pattern is fully load-bearing for canonical-CLI scaffolder-induced test drift.
- meta-observation: when a canonical-CLI scaffolder (flywheel-oozt3/0pkcf) is applied to a script with existing introspection (`--schema` already emits a result schema), the scaffolder REPURPOSES `--schema` to emit canonical-CLI introspection and the original native --schema handler becomes dead code. Tests asserting on the original --schema surface ALL need calibration. There may be other surface scripts with the same drift class.
