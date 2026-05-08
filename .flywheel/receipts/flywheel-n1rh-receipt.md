# flywheel-n1rh Receipt

## Scope

Implemented the flywheel-loop revive and reboot-survival flow:

- `/flywheel:revive` command doc.
- `flywheel-loop revive` portable subcommand.
- `flywheel-loop-revive.py` dry-run/apply planner.
- Launchd keepalive opportunity scanner pattern.
- Reboot fixture covering candidate, blocked, apply-simulated, and no-notify paths.

## Contract

Loop state files are markers, not drivers. Revive reads
`~/.flywheel/loops/*.json` and selects only markers with
`auto_revive_on_reboot=true` and `active=true`, but it keeps
`state_marker_not_driver=true` until the normal `/flywheel:loop` driver proof
lands.

## Validation

- `tests/test_flywheel_loop_revive.sh`
- `tests/test_flywheel_loop_activation_contract.sh`
- `tests/test_flywheel_loop_start_fixtures.sh`
- `plutil -lint .flywheel/launchd/com.zeststream.flywheel-loop-revive.plist`

## Joshua-Lens Check

Reboot is the operator-pain test for this substrate. A five-person ops team
will stop trusting autonomous loops within a week if a power cycle leaves
silent markers behind. This flow gives a new operator a day-one command that
shows which loops need revival, which are blocked by missing setup data, and
which checks are routine enough to stay silent.
