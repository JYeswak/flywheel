# flywheel-2xdi.13 evidence

Task: `flywheel-2xdi.13-e883bf`

## Result

Fixed the two data-decided root causes approved in the scope expansion:

- `gap-hunt-probe.sh` now treats explicit ownership fields as authoritative. A flywheel-owned row that merely mentions a skillos path no longer counts as a skillos fuckup decision gap.
- `skillos/.flywheel/run-30m-loop.sh` now runs the existing pane callback reaper before each scheduled dispatch, so pane-visible callbacks are harvested before the next tick prompt can displace them.

## Live Evidence

- Before patch: skillos loop-integrity verdict was `LIMPING` with `failed_signals=callback_received_in_last_2_ticks,fuckup_log_decisions_made_since_last_tick`.
- After patch: dry-run shows skillos still `LIMPING`, but only on `callback_received_in_last_2_ticks`; `fuckup_log_decisions_made_since_last_tick` is now `ok=true` with `no_recent_project_fuckups_to_decide`.
- Reaper probe before patch returned `status=no_callback_visible`; no synthetic callback row was written.

## Verification

- `bash -n .flywheel/scripts/gap-hunt-probe.sh`
- `bash -n .flywheel/run-30m-loop.sh` in `/Users/josh/Developer/skillos`
- `python3 -m unittest tests.test_run_30m_loop_contract` in `/Users/josh/Developer/skillos` ran 20 tests and passed.
- `.flywheel/scripts/gap-hunt-probe.sh --dry-run --json` completed; skillos failed signal reduced to only `callback_received_in_last_2_ticks`.

## Four-Lens Self-Grade

- brand: 8
- sniff: 8
- jeff: 8
- public: 8

The artifact is narrow, source-grounded, and includes a re-runnable L112 probe. It does not claim skillos is fully healthy because the live callback row is still stale until a future pane-visible callback exists to reap.

