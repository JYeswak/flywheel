# Evidence: flywheel-j3dbv — sibling phantom of 0u9ch; Path B defensive guard shipped

**Bead**: flywheel-j3dbv (P0) | **Task ID**: flywheel-j3dbv-06feab | **Identity**: MistyCliff
**Created**: 2026-05-11T03:25:39Z (2 minutes before 0u9ch at 03:27:26Z)
**Title**: `fix-test-1-l112-mismatch`

## Bug shape

Same class as flywheel-0u9ch (closed earlier this session): phantom prod bead created by `callback-fix-bead-opener.sh` when invoked indirectly via the validator's `open_fix_bead()` side-effect from a test (or manual CLI probe) that piped a fake DONE callback without isolating `REPO` or overriding `CALLBACK_RECEIPT_FIX_BEAD_OPENER`.

Diff vs 0u9ch:
- `task_id`: `test-1` (j3dbv) vs `t-1` (0u9ch)
- `created_at`: 03:25:39Z (j3dbv) vs 03:27:26Z (0u9ch)
- Same `bead=flywheel-test`, same `reason=dispatch_file_missing`, same `expected=foo`, same `actual=""`

The 0u9ch fix (patching `tests/callback-receipt-validator-canonical-cli.sh` line 40 to set `CALLBACK_RECEIPT_FIX_BEAD_OPENER=/bin/true`) addressed ONE polluter. j3dbv has a different `task_id` (`test-1`), suggesting a SECOND polluter — likely a manual CLI probe or untracked test that I couldn't locate via grep.

N=2 of this phantom class → time to ship Path B (recommended in 0u9ch evidence): defensive guard at the opener level.

## Fix (Path B per 0u9ch follow-up)

`.flywheel/scripts/callback-fix-bead-opener.sh` `run_open()`: added two-axis defensive guard.

```bash
# Refuse when REPO resolves to this script's own owning repo (live prod
# flywheel) AND --bead matches a known test-fixture sentinel name.
local _resolved_repo
_resolved_repo="$(cd "$REPO" 2>/dev/null && pwd -P || printf '%s' "$REPO")"
if [[ "$_resolved_repo" == "$REPO_DEFAULT" ]]; then
  case "$BEAD" in
    flywheel-test|flywheel-parent|flywheel-x|flywheel-fixture)
      emit "$(jq -nc ... status:"refused", action:"refused_test_fixture_bead" ...)"
      return 0 ;;
  esac
fi
```

Two-axis: **prod-REPO AND sentinel-bead**. Properly-isolated tests that pass `--repo /tmp/fixture-repo` bypass the guard regardless of bead name — the canonical-cli regression test (legacy run_open + idempotent) uses `--bead flywheel-x` with `--repo /tmp/*` and is unaffected.

Refusal emits a structured row with `status:"refused"`, `action:"refused_test_fixture_bead"`, and a `refusal:` message explaining the three remediation paths:
1. Set `CALLBACK_RECEIPT_FIX_BEAD_OPENER=/bin/true` in the test (preferred upstream fix)
2. Pass `--repo /tmp/fixture-repo` to the opener
3. Use a non-sentinel `--bead` value

## Verification

```bash
$ ./callback-fix-bead-opener.sh --task-id test-1 --bead flywheel-test --reason dispatch_file_missing --expected foo --actual "" --json
{"schema_version":"callback-fix-bead-opener/v1","ts":"2026-05-11T08:52:25Z","status":"refused","action":"refused_test_fixture_bead","task_id":"test-1","bead":"flywheel-test","reason":"dispatch_file_missing","repo":"/Users/josh/Developer/flywheel","refusal":"..."}
# Row delta: 0
```

Reproduces the exact j3dbv-creation-call and proves the guard refuses it now.

## Regression check

- `tests/callback-fix-bead-opener-canonical-cli.sh`: 19/1 PASS (was 17/3 with my pre-refinement guard; now properly isolates via two-axis check). The 1 remaining FAIL is pre-existing lint (unrelated; same with stash-pop verified).
- `.flywheel/tests/test-callback-receipt-validator.sh`: cases=9 assertions=16 failures=0 (was failing `l112_verify_failure_refuses_and_files_fix` with my pre-refinement guard)
- `tests/callback-receipt-validator-canonical-cli.sh`: 21/1 PASS (same pre-existing lint)

## Bead disposition

`flywheel-j3dbv` is another **phantom bead**. Closing as `no_action / test_pollution_stale_artifact`. The actual fix is the Path B defensive guard (above), which also protects against ALL future phantoms of this class (including ones from manual CLI probes that I couldn't track down).

## Combined effect with 0u9ch fix

Layer 1 (0u9ch): test-side env-override for the known-polluting tests
Layer 2 (j3dbv): opener-side defensive guard for any caller (test or manual) that still hits the prod opener with sentinel bead names

Defense in depth: both layers must be defeated to pollute prod beads. A caller would have to use `--bead non-sentinel-name` AND skip the env override to leak.

## Follow-up signals (out-of-scope here)

1. **Audit historical phantoms**: scan `.beads/issues.jsonl` for other `fix-*-l112-mismatch` open beads that may also be phantoms from earlier test runs.
2. **Extend sentinel blocklist** as new test-fixture bead names are added (`flywheel-fixmock-1` from canonical-cli test, etc. — should those be on the blocklist?).

## L112 verify probe

`bash -c '/Users/josh/Developer/flywheel/.flywheel/scripts/callback-fix-bead-opener.sh --task-id phantom-probe --bead flywheel-test --reason l112_probe --json 2>&1 | jq -r .status'`
Expected: `grep:^refused$`
