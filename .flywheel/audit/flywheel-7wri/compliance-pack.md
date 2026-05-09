# flywheel-7wri Compliance Pack

Task: `flywheel-7wri-34a392`
Bead: `flywheel-7wri`
Date: 2026-05-09

## Result

Skillos scheduled dispatches now mirror proof rows into the canonical
`last_tick_skillos.json` path and the per-loop `last_run.json` path.

Evidence: `.flywheel/audit/flywheel-7wri/evidence.md`

## Acceptance Gates

- AG1: artifact/command surface updated with close evidence:
  `/Users/josh/Developer/skillos/.flywheel/run-30m-loop.sh`.
- AG2: targeted validator passed:
  `python3 -m pytest tests/test_run_30m_loop_contract.py -q`.
- AG3: `flywheel-7wri` remained open until the evidence artifact existed.

## Validation

- L112 probe: `.flywheel/audit/flywheel-7wri/l112-probe.sh`
- Dispatch audit:
  `bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-7wri-34a392.md`
- Receipt parser:
  `bash .flywheel/validation-schema/v1/parse.sh .flywheel/audit/flywheel-7wri/validation-receipt.json`

## Quality

Compliance score: 880/1000.

The live production scheduler was not fired from this worker. The behavioral
test uses an isolated temp repo and fake `ntm` binary, then validates the
receipt files directly.
