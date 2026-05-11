# Evidence: flywheel-zmeir — capture_provenance + WAITING filter in idle-pane-auto-dispatch.sh

**Bead**: flywheel-zmeir (P2) | **Task ID**: flywheel-zmeir-496933 | **Identity**: MistyCliff
**Surface**: `.flywheel/scripts/idle-pane-auto-dispatch.sh`
**Parent**: flywheel-ef8m AG2 (in_progress) | **Sister**: flywheel-255f (closed)
**Doctrine**: AGENTS.md L153 CAPTURE-PROVENANCE-CANONICAL + `.flywheel/rules/L104-L153-capture-provenance-canonical.md`

## Implementation

Added `probe_capture_live_panes()` function (between `run_wait` and `run_assign` in run_dispatch flow) that:
1. Probes `ntm --robot-activity=$SESSION --json`
2. Applies jq filter `select(.state=="WAITING" and .capture_provenance=="live")`
3. Returns array of matching pane indices
4. Returns `[]` when probe unavailable (per L153: "unavailable provenance routes to flywheel-respawn or flywheel-recovery BEFORE classifying the worker")

Wired into `run_dispatch()` after wait succeeds: if `length == 0`, emit `status=no_capture_live_panes` with diagnostic envelope (gate name, filter literal, disposition) and skip `run_assign` entirely. This is the orch-side route requested by AG3.

## Literal-string preservation

Test `tests/pane-capture-provenance.sh` `rg` checks pass:
- `rg -q 'capture_provenance=="live"'` → 4 occurrences in watcher
- `rg -q 'state=="WAITING"'` → 4 occurrences in watcher

## Acceptance gates

- ✅ **AG1**: idle-pane-auto-dispatch.sh adds explicit pre-assign jq filter rejecting panes whose `capture_provenance != live` or `state != WAITING`; literals preserved for `rg` check.
- ✅ **AG2**: `bash tests/pane-capture-provenance.sh` → `PASS pane-capture-provenance fixtures=4 repo=...`
- ✅ **AG3**: orch-side route documented in-line + emitted as `status=no_capture_live_panes` envelope when filter rejects all panes. Disposition matrix per L153: "unavailable provenance routes to flywheel-respawn or flywheel-recovery BEFORE classifying worker".

## Regression check

`tests/idle-pane-auto-dispatch-canonical-cli.sh` → 19/19 PASS (no regression).
`tests/idle-pane-auto-dispatch-work-started-validation-test.sh` → PASS (wait-timeout fast-path doesn't hit new gate).
`tests/idle-pane-auto-dispatch-validated-write-test.sh`:
- `apply_watch_delegates_to_native_ntm_assign_watch` → **NEW PASS** (improved by fixture mock addition)
- `dry_run_waits_then_previews_native_assign` → pre-existing FAIL (schema_version v2/v3 drift, unrelated)
- `info_exposes_native_watch_surface` → pre-existing FAIL (--info path doesn't emit native_surface field; unrelated)

Net: +1 PASS, no new FAILs introduced.

## Files changed

- `.flywheel/scripts/idle-pane-auto-dispatch.sh` (881 → ~920 lines; +probe_capture_live_panes + gate)
- `tests/idle-pane-auto-dispatch-validated-write-test.sh` (added --robot-activity= mock to fake ntm)

## L112 verify probe

`bash tests/pane-capture-provenance.sh 2>&1 | tail -1`
Expected: `grep:PASS pane-capture-provenance fixtures=4`
