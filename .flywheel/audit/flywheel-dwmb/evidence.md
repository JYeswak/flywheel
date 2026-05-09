# flywheel-dwmb Evidence

Task: `flywheel-dwmb-a1ee9d`
Bead: `flywheel-dwmb`
Date: 2026-05-09

## Result

Diagnostic complete. Root cause is validation-surface conflation, not a Path A
receipt mirror regression.

The Path A canonical receipt exists and matches the bridge's tick-shaped schema,
but the historical apply callback treated full `flywheel-loop doctor` status as
the Path A success signal. Full repo doctor health is broader than receipt
mirror health and can fail or hang for unrelated mobile-eats conditions.

Follow-up bead filed:

- `flywheel-dwmb.1` — `[mobile-eats] split receipt-mirror validation from full doctor health`

## Worker Observations

The requested `/tmp/apply-mobile-eats-receipt-mirror_findings.md` file is no
longer present on disk. I recovered the durable worker observation from
`.flywheel/dispatch-log.jsonl` and `/tmp/flywheel-7nmls-history.json`:

- `canonical_receipt_written=yes`
- `doctor_status=FAIL`
- `rollback_invoked=no`
- `receipt=/tmp/apply-mobile-eats-receipt-mirror_findings.md`

`br show flywheel-rzk3 --json` now reports the earlier decision bead closed with
`Path A applied; canonical receipt mirror live; doctor PASS`, which means the
original warning was superseded operationally but the validation contract still
needed clarification.

## Doctor Source

Relevant source surfaces read:

- `/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop`
- `/Users/josh/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh`
- `/Users/josh/.claude/skills/.flywheel/lib/canonical.sh`
- `.flywheel/scripts/mobile-eats-receipt-bridge.sh`
- `.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh`

`canonical_last_tick_json` in `lib/canonical.sh` reads
`~/.local/state/flywheel-loop/last_tick_<project>.json` and extracts `ts`,
`task_id`, `exit_code`, `session`, `pane`, and `project`. The mobile-eats
specific check is the bridge:
`.flywheel/scripts/mobile-eats-receipt-bridge.sh --doctor --json`.

Full `flywheel-loop doctor --repo /Users/josh/Developer/mobile-eats --json`
enters the generic portable doctor pipeline, which includes many unrelated
subsystems such as Beads DB health, daily report, loop driver, storage, callback
validation, identity registry, and other fleet checks.

## Expected vs Actual

Canonical receipt:

- Path: `/Users/josh/.local/state/flywheel-loop/last_tick_mobile-eats.json`
- Schema/version: `mobile-eats-receipt-bridge.v1`
- `status`: `ok`
- `session`: `mobile-eats`
- `project`: `mobile-eats`
- `exit_code`: `0`
- `ts`: `2026-05-05T15:25:49Z`
- `mobile_eats.last_run_ts`: `2026-05-05T15:25:49Z`
- `mobile_eats.tick_count`: `46`
- `mobile_eats.run_count`: `684`
- `mobile_eats.dispatch_count`: `679`

Bridge doctor:

- `.flywheel/scripts/mobile-eats-receipt-bridge.sh --doctor --json` returned
  `status=ok` during this diagnostic.

Full doctor:

- `timeout 20s ~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/mobile-eats --json` exited `124`.

Historical fixture:

- `tests/halt-disease/fixtures/incident-2026-05-04/mobile-eats-doctor.json`
  shows mobile-eats full doctor failure from `beads_db_health_failed` and
  `daily_report_missing`, with `agent_mail_fd_doctor_warn` as a warning. Those
  are global health conditions, not receipt mirror schema failures.

## Root Cause

The apply worker used a global doctor signal for a narrow receipt-mirror
acceptance check. Path A only promised that the product tick wrapper would write
a canonical `last_tick_mobile-eats.json` bridge receipt. It did not promise to
clear all mobile-eats doctor health gates.

Minimal fix: make the Path A apply/validation path pass or fail on the bridge
doctor and canonical receipt schema/freshness. Preserve full repo doctor as a
bounded advisory field with its own failure class.

## L52 Receipt

Filed `flywheel-dwmb.1` for the actual patch. No further bead is needed from
this diagnostic.

## Skill Auto-Routes

- `canonical-cli-scoping`: n/a, no CLI source changed.
- `rust-best-practices`: n/a, no Rust changed.
- `python-best-practices`: n/a, no Python changed.
- `readme-writing`: n/a, no README changed.

## L61 Receipt

- `agents_md_updated`: not_applicable
- `readme_updated`: not_applicable
- `no_touch_reason`: diagnostic evidence and Beads routing only; no doctrine,
  AGENTS, README, or source patch landed.

## Four-Lens Self-Grade

- brand: 8
- sniff: 8
- jeff: 8
- public: 8

Three Judges check: a skeptical operator can rerun the bridge doctor, a
maintainer can inspect the follow-up bead and receipt schema, and a future
worker can implement the narrow validator without rediscovering the global
doctor conflation.
