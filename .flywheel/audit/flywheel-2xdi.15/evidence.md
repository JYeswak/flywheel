# flywheel-2xdi.15 Evidence

Task: `flywheel-2xdi.15-0d888c`
Bead: `flywheel-2xdi.15`
Gap: `loop-integrity:mobile-eats`
Date: 2026-05-09

## Disposition

This is a real loop-integrity gap, routed to follow-up bead
`flywheel-2xdi.15.1`.

The fleet marker is fresh, but the callback and canonical receipt signals are
stale:

- `/Users/josh/.flywheel/loops/mobile-eats.json` reports
  `last_tick=2026-05-09T08:59:10Z`, `last_run_status=ok`, and
  `last_run_exit_code=0`.
- `/Users/josh/Developer/mobile-eats/.flywheel/dispatch-log.jsonl` last
  `callback_received_at` is `2026-05-05T15:18:09Z`; the latest dispatch row is
  `2026-05-09T06:53:09Z`.
- `/Users/josh/.local/state/flywheel-loop/last_tick_mobile-eats.json` still
  reports `task_id=20260505T152545Z` and `ts=2026-05-05T15:25:49Z`.
- `.flywheel/scripts/mobile-eats-receipt-bridge.sh --doctor --json` returns
  `status=ok` despite the stale bridge timestamp.
- `timeout 8s ~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo
  /Users/josh/Developer/mobile-eats --json` exited `124` during this triage.

## Follow-Up Filed

`flywheel-2xdi.15.1`:
`[mobile-eats] callback receipt signal stale behind fresh loop marker`

This follow-up owns the classifier/validator split between:

- fresh fleet marker writeback,
- `callback_received_in_last_2_ticks`, and
- canonical mobile-eats bridge receipt freshness.

It intentionally does not replace `flywheel-dwmb.1`, which owns the narrower
receipt-mirror/full-doctor validation split.

## L52 Receipt

`beads_filed=flywheel-2xdi.15.1`.

No doctrine or source surface was edited by this worker. The next actionable is
the follow-up bead, not a same-turn patch, because the task body is a P3
gap-triage closeout and the repair has separate implementation scope.

## Four-Lens Self-Grade

- Brand: 8 - keeps mobile-eats flagship loop health honest instead of letting a
  fresh marker hide stale work completion signals.
- Sniff: 8 - separates three measurable surfaces and avoids conflating bridge
  doctor `ok` with actual callback freshness.
- Jeff: 8 - creates a direct, bounded repair bead with exact evidence.
- Public: 8 - a skeptical operator, maintainer, and future worker can rerun the
  L112 probe and see the same marker-fresh/callback-stale case.
