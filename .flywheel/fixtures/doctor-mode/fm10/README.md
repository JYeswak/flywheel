# FM-10: recovery probe stale-chevron false-positive

**Class:** audit-only-retraction (Shape D phantom-requirement)
**Test mode:** RUN — `flywheel-loop doctor fm10 --candidate <JSON> --validation-tail <PATH> --apply` (.2.3 ship)
**MEMORY sources:** `feedback_chevron_visible_does_not_mean_submits_work.md`, `feedback_l91_auto_retry_helper_failed_4_data_points.md`

## Detect predicate
- Read candidate's `chevron_visible`
- Grep validation-tail for submits-work signals: `THINKING|WORKING|user-prompt-submit-hook|input-acknowledged`
- If `chevron_visible=true` AND submits-work signal present → FALSE-POSITIVE (pane alive; chevron is stale-display)

## Fix strategy (audit-only retraction)
- Append retraction row to `~/.local/state/flywheel/fm10-retractions.jsonl`
- Mark `demote_to=monitoring-only` (pane stays alive; chevron-recovery suppressed)

## Round-trip protocol
1. Read `corrupt-candidate.json` + `corrupt-validation-tail.txt`
2. Invoke `flywheel-loop doctor fm10 --candidate "$CANDIDATE_JSON" --validation-tail <tail-path> --apply --json`
3. Expect rc=1 + `detected=true` + `submits_work=true`
4. Verify retraction ledger has matching row (timestamps dynamic; class + pane + demote_to must match)

## Fixture files
- `corrupt-candidate.json` — candidate with `chevron_visible=true`
- `corrupt-validation-tail.txt` — pane tail with 3 submits-work signals (THINKING + WORKING + user-prompt-submit-hook)
- `expected-retraction.jsonl` — retraction ledger row shape
- `undo-original.bak` — byte-exact baseline (audit-only; not used for undo)
