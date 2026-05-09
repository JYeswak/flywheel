# flywheel-v1q2 Evidence

task_id=flywheel-v1q2-8a0e98
bead=flywheel-v1q2
mission_fitness=adjacent
evidence_redacted=yes

## Outcome

Implemented a separate skillos callback reaper driver:

- `/Users/josh/Developer/skillos/.flywheel/scripts/reap-pane-callbacks.py`
- `/Users/josh/Developer/skillos/tests/test_callback_reaper.py`
- skillos commit: `844fe9b`

The driver reads pane-visible callback text from either a live `ntm copy` capture or a fixture path/text, parses `DONE`, `BLOCKED`, and `PARTIAL` envelopes, and appends an idempotent `worker_callback_received` row with `callback_received_at` to `.flywheel/dispatch-log.jsonl` when `--apply` is used.

## Signal 4 Distinction

The reaper returns stable states so loop-integrity Signal 4 can distinguish:

- `no_callback_visible`: pending dispatch rows exist but no callback envelope is visible in the pane capture.
- `callback_visible_unreaped`: a callback envelope is visible but not yet represented in dispatch-log.
- `callback_reaped`: `--apply` appended a callback row with `callback_received_at`.
- `already_reaped`: the same callback hash/task is already in dispatch-log.

This directly addresses the skillos/mobile-eats gap where `ntm_dispatch_sent` rows existed without a durable callback-reaping path.

## Verification

Commands run:

```bash
cd /Users/josh/Developer/skillos
git diff --check -- .flywheel/scripts/reap-pane-callbacks.py tests/test_callback_reaper.py
python3 -m py_compile .flywheel/scripts/reap-pane-callbacks.py
python3 -m unittest tests.test_callback_reaper
```

Result: PASS, 3 tests.

Probe commands run:

```bash
/Users/josh/Developer/skillos/.flywheel/scripts/reap-pane-callbacks.py --repo /Users/josh/Developer/skillos --capture-text 'DONE skillos-v1q2-demo task_id=skillos-v1q2-demo-123 verdict=PASS tests=PASS' --received-at 2026-05-09T08:45:00Z --json
/Users/josh/Developer/skillos/.flywheel/scripts/reap-pane-callbacks.py --repo /Users/josh/Developer/skillos --capture-text 'working only' --json
```

Observed `callback_visible_unreaped` for the callback fixture and `no_callback_visible` with `pending_dispatch_count=16` for no visible callback.

## Reservation Note

The direct scheduled-runner file `/Users/josh/Developer/skillos/.flywheel/run-30m-loop.sh` and its contract test were actively reserved by `flywheel-jg1j-f5a39d` on pane 4 while this task ran. I did not edit through that reservation. The v1q2 acceptance path used the allowed separate reaper driver branch of the requirement.

## Acceptance

did=3/3
didnt=none
gaps=none
beads_filed=none
beads_updated=none
no_bead_reason=separate_reaper_driver_satisfies_current_bead; runner_wire_reserved_by_sibling_flywheel-jg1j

AG1: Separate callback reaper driver added and committed in skillos (`844fe9b`).
AG2: Targeted unittest and py_compile passed.
AG3: Evidence existed before `br close flywheel-v1q2`.

## Four-Lens Self-Grade

brand: 8
sniff: 8
jeff: 8
public: 8

Three Judges check: skeptical operator can rerun the L112 probe, maintainer can inspect the small script/test pair, and future worker can tell no visible callback from visible-unreaped callback without reading pane prose.
