# flywheel-id41 Evidence

Dispatch: flywheel-id41-1b1ab3
Bead: flywheel-id41
Status: DONE-ready
Checked at: 2026-05-09T06:53:58Z

## Changes

- Updated `/Users/josh/.claude/commands/flywheel/status.md` to render one compact mission lock line after mission fitness:
  `Mission lock: <fresh|stale|unknown> age=<Nh|unknown> warning=<code|none>`.
- Preserved the pane dashboard table contract:
  `# | agent | state | ctx | last action`.
- Added `tests/test_mission_lock_status_dashboard.sh` to assert mission lock age/status/warning fields and pane table shape.

## Validation

- `bash -n tests/test_mission_lock_status_dashboard.sh`: PASS
- `bash tests/test_mission_lock_status_dashboard.sh`: PASS, 10 checks
- `bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-id41-1b1ab3.md`: PASS
- `.flywheel/audit/flywheel-id41/l112-probe.sh`: PASS, emits `OK_status_mission_lock_age_dashboard`

## Reservations

Shared-surface reservations checked and acquired before edits:

- `/Users/josh/.claude/commands/flywheel/status.md`
- `tests/test_mission_lock_status_dashboard.sh`
- `.flywheel/audit/flywheel-id41`
- `.beads/issues.jsonl`

Reservations are released before callback.
