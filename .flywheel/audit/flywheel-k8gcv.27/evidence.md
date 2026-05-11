# Evidence: flywheel-k8gcv.27 — frozen-pane-backtest.sh canonical-CLI partial→passing

**Bead**: flywheel-k8gcv.27 (P0, wave-3) | **Task ID**: flywheel-k8gcv.27-f16419 | **Identity**: MistyCliff
**Surface**: `.flywheel/scripts/frozen-pane-backtest.sh` (replays 7 fixtures through frozen-pane-detector)
**Variant**: PARTIAL-BYPASS — same 4-flag shape as 1hshd.32 frozen-pane-detector (sister surface)

## Per-flag baseline + variant

Native has rich v1 envelopes for --info/--schema/--doctor/--health (similar to sister 1hshd.32 frozen-pane-detector). Scaffold owns --examples (native lacked) + all verbs.

| Flag/verb | Native | Owner |
|-----------|--------|-------|
| --info / --schema / --doctor / --health | YES (v1) | NATIVE |
| --examples | NO | SCAFFOLD |
| verbs (doctor/health/repair/validate/audit/why/quickstart) | NO | SCAFFOLD |
| --apply / --dry-run / --json / --state-dir / --receipt | YES | NATIVE fall-through |

## Doctor probes (5)

bash, jq, detector_script (load-bearing — backtest replays fixtures through it), fixture_set (7 fixtures), audit_log_dir.

## Repair scopes (2)

audit_log_dir, fixture_dir.

## Validate subjects (3)

- **fixture-name**: enum (7 fixtures) — cross-sources native --info .fixtures[]
- **metric-name**: enum (6 metrics) — cross-sources native --info .goal_metrics[]
- **run-mode**: enum {dry_run, apply} — cross-sources native --apply/--dry-run

Three enum subjects each cross-source a different native field. **N=9, N=10, N=11** of native-flags-to-enum projection in one script (META-RULE long since promoted at N=3; pattern is fully load-bearing).

## Test coverage

19/19 PASS. Test 18 verifies PARTIAL-BYPASS native --doctor + --health both preserved.

## Lint

Clean.

## Mission fitness

`adjacent` — frozen-pane-backtest replays canonical fixtures through frozen-pane-detector for regression testing. Sister-surface PARTIAL-BYPASS (same shape as 1hshd.32) demonstrates pattern parity across the detector+backtest pair.

## Files changed

- `.flywheel/scripts/frozen-pane-backtest.sh` (323 → ~870 lines)
- `tests/frozen-pane-backtest-canonical-cli.sh` (94 → ~190 lines)

## L112 verify probe

`bash tests/frozen-pane-backtest-canonical-cli.sh 2>&1 | tail -1`
Expected: `grep:SUMMARY pass=19 fail=0`
