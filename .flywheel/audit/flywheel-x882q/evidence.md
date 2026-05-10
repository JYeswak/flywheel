---
title: flywheel-x882q evidence — dispatch-log-backfill-v2.sh substantive 18-TODO fill-in
type: evidence
created: 2026-05-10
bead: flywheel-x882q
parent: flywheel-wgitr (decomposition family — sub-bead 7 of 8)
chain: doctor-mode-integration / dispatch-lane-fillin
---

# flywheel-x882q evidence

**Status:** DONE — all 18 TODO markers replaced; 15/15 tests PASS; lint clean. **Sub-bead 7 of 8 from wgitr decomposition.**

## Acceptance gates

| AG | Status | Evidence |
|---|:-:|---|
| AG1: doctor 5 substrate checks | DID — repo/dispatch-log readable+writable/jq/runs_log |
| AG2: health probe consults real signal | DID — tail runs ledger; total_rows_backfilled_recent; warn stale >7 days |
| AG3: repair scopes with --dry-run/--apply | DID — 2 scopes (dispatch-log-backfill-rerun, runs-log-rotate) |
| AG4: validate <subject> runnable contract | DID — 3 subjects (row, tail-of-dispatch-log, config) |
| AG5: scaffolded test passes | DID — 15/15 PASS |
| AG6: canonical-cli-scoping checker still 13/13 | DID |
| AG7: canonical-cli-lint exits 0 | DID — clean (no pre-existing L2 issues) |

did=7/7, didnt=none.

## Substantive fill-in

- **doctor**: 5 substrate checks (flywheel_repo / dispatch_log readable / dispatch_log parent writable / jq / runs ledger writable)
- **health**: tail runs ledger; recent_count + total_rows_backfilled_recent + last_apply_ts + freshness; warn stale >7 days
- **repair**: 2 scopes — `dispatch-log-backfill-rerun` (count total_rows in live dispatch-log; plan-only points at canonical run path) + `runs-log-rotate` (5MB threshold)
- **validate**: 3 subjects — row (--row-json against v2 required: ts/session/task_id/pane/task_file/channel), **tail** (--tail=N validate last N rows of live dispatch-log.jsonl for v2 schema; per-row breakdown), config (env validation)
- **audit**: tail runs ledger
- **why <task_id>**: lookup in dispatch-log; emit `v2_conformant` boolean + missing_v2_fields list

## Live signals surfaced (substantive bonus)

The substantive fill-in immediately caught **two real fleet signals**:

1. `validate --tail=3` reports **`total_rows: 3, v2_valid_rows: 0`** — the live dispatch-log.jsonl has rows that don't conform to v2 required fields. **Backfill is needed.**
2. `repair --scope dispatch-log-backfill-rerun` reports **`total_rows: 2221`** — the live dispatch-log has 2,221 rows, all candidates for v2 backfill.

This is exactly the surface's purpose — and the substantive fill-in proves it works against real production data while exercising the canonical-CLI surface. Sister to vc3zs's pattern.

## Family progress

This is sub-bead **7 of 8** from the wgitr decomposition I filed early today (vc3zs and 5kjez closed earlier; this is 7 of 8). After this + hpirw + q71jb close, the wgitr decomposition is complete.

## Cross-references

- Parent: `flywheel-wgitr` (decomposition family)
- Sister sub-beads closed today: `flywheel-vc3zs`, `flywheel-5kjez` + 4 by peer panes
- Tooling: scaffold-canonical-cli.sh (flywheel-ws02m), canonical-cli-lint.sh (flywheel-etp5n)
- Subject log: `~/Developer/flywheel/.flywheel/dispatch-log.jsonl` (2,221 rows; 0 v2-conformant in tail-3)
