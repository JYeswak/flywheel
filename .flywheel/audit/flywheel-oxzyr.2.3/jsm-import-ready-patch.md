# JSM-Import-Ready Patch — flywheel-oxzyr.2.3

**Target:** `/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop`
**Patch type:** `jsm-import-ready` (`.flywheel` skill is unmanaged)
**Operation:** add 2 FM detect/fix functions + 2 dispatcher intercept branches
**Source bead:** `flywheel-oxzyr.2.3`
**Sister:** chokepoint .2.1 + doctor undo .2.2

## What this patch ships

### 1. `_flywheel_loop_fm5_detect_fix()` function (~70 lines)

Class: stale-prompt-heartbeat (Shape D phantom-requirement).
MEMORY source: feedback_orch_wake_event_driven_not_time_based.md.

Surface: `flywheel-loop doctor fm5 --row JSON --prior-row JSON [--dry-run|--apply] [--json]`
Schema: `fm5-detect-fix/v1`
Exit codes: 0=clean, 1=STALE+retracted, 2=usage, 3=STALE+dry-run

### 2. `_flywheel_loop_fm10_detect_fix()` function (~70 lines)

Class: stale-chevron-false-positive (Shape D).
MEMORY source: feedback_chevron_visible_does_not_mean_submits_work + feedback_l91_auto_retry_helper_failed_4_data_points.

Surface: `flywheel-loop doctor fm10 --candidate JSON --validation-tail PATH [--dry-run|--apply] [--json]`
Schema: `fm10-detect-fix/v1`
Exit codes: 0=clean, 1=FP+retracted, 2=usage, 3=FP+dry-run

### 3. Native dispatcher intercepts

Added after .2.2's `doctor undo` intercept:

```bash
if [[ "${1:-}" == "fm5" ]]; then
    shift; _flywheel_loop_fm5_detect_fix "$@"; exit $?
fi
if [[ "${1:-}" == "fm10" ]]; then
    shift; _flywheel_loop_fm10_detect_fix "$@"; exit $?
fi
```

## Verification post-patch (validated live)

4 end-to-end test cases verified:

| FM | Case | Detected? | Retraction Written? | rc |
|---|---|---|---|---|
| FM-5 | STALE+apply (cur_sha==prior_sha + heartbeat) | true | true | 1 |
| FM-5 | Clean (different SHA) | false | n/a | 0 |
| FM-10 | FP+apply (chevron + THINKING in tail) | true | true | 1 |
| FM-10 | Clean (no submits-work) | false | n/a | 0 |

Retraction ledgers populated correctly:
- FM-5: `{tick_ts, retraction_ts, applied:false, retraction_reason:"stale_prompt_heartbeat", stale_sha}`
- FM-10: `{pane, retraction_ts, applied:false, retraction_reason:"stale_chevron_false_positive", demote_to:"monitoring-only"}`

## File-length receipt

Pre-patch: 1147 lines (.2.2 baseline)
Post-patch: 1295 lines
Delta: +148 lines (2 functions ~70 each + 8 lines dispatcher intercepts)

## JSM management state

`.flywheel` skill UNMANAGED. Direct mutation allowed + this paired patch artifact provided.

`no_direct_skill_mutation_reason=skill_unmanaged_direct_mutation_with_paired_jsm_import_ready_patch`

## Sister-bead status

- .2.1 chokepoint: ✓ shipped
- .2.2 doctor undo: ✓ shipped
- .2.3 FM-5+FM-10 (this): ✓ shipped
- .2.4 FM-6+FM-9: UNBLOCKED (byte-exact undo class; sister-shape)
- .2.5 FM-8 input-deaf quarantine: UNBLOCKED
- .2.6 real fixture data: progressively unblocked (FM-5+FM-10 logic exercisable)

## Canonical-CLI compliance

Both surfaces follow canonical-cli-scoping triad:
- `--help`/`-h`: usage emitted
- `--dry-run` (default): plan only, no retraction
- `--apply`: write retraction
- `--json`: machine-readable output
- Stable exit codes (0/1/2/3 per FM)
- Schemas declared (`fm5-detect-fix/v1`, `fm10-detect-fix/v1`)

`cli_canonical=yes`
