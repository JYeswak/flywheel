# FM-8: dispatch during input-deaf

**Class:** audit-only-retraction + quarantine + fuckup-log (Shape B spec-extractor over-extracts)
**Test mode:** RUN — `flywheel-loop doctor fm8 --dispatch <JSON> --validation-tail <PATH> --apply` (.2.5 ship)
**MEMORY sources:** `feedback_post_callback_stale_chevron_input_deaf_class.md`, `feedback_dispatch_post_send_verify_for_silent_deaf.md`, `feedback_chevron_visible_does_not_mean_submits_work.md`

## Detect predicate
- Read dispatch row's `pane` + `chevron_visible`
- Grep validation-tail for input-ack signals: `input-acknowledged|input_ack|prompt-accepted`
- If `chevron_visible=true` AND no input-ack signal → INPUT-DEAF

## Fix strategy (triple-ledger write)
1. Append retraction row to `~/.local/state/flywheel/fm8-retractions.jsonl`
2. Append quarantine row to `~/.local/state/flywheel/fm8-quarantine.jsonl`
3. Append fuckup-log row to `~/.local/state/flywheel/fuckup-log.jsonl`

All 3 ledgers sandboxable via env vars for tests.

## Round-trip protocol
1. Read `corrupt-dispatch.json` + `corrupt-validation-tail.txt`
2. Invoke `flywheel-loop doctor fm8 --dispatch "$DISPATCH_JSON" --validation-tail <tail-path> --apply --json`
3. Expect rc=1 + `detected=true`
4. Verify each of 3 ledgers has matching row (timestamps dynamic; class + pane + task_id must match)

## Fixture files
- `corrupt-dispatch.json` — dispatch row with `chevron_visible=true`
- `corrupt-validation-tail.txt` — pane tail with no submits-work signal
- `expected-retraction.jsonl` — fm8-retractions row shape
- `expected-quarantine.jsonl` — fm8-quarantine row shape
- `expected-fuckup-log.jsonl` — fuckup-log row shape
- `undo-original.bak` — byte-exact baseline (= corrupt-dispatch; audit-only)
