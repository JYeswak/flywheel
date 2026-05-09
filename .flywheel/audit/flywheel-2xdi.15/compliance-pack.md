# flywheel-2xdi.15 Compliance Pack

Task: `flywheel-2xdi.15-0d888c`
Bead: `flywheel-2xdi.15`
Class: `loop-integrity`
Date: 2026-05-09

## Result

The mobile-eats loop marker is fresh, but callback receipt freshness is not.
This was routed to follow-up bead `flywheel-2xdi.15.1`.

Evidence: `.flywheel/audit/flywheel-2xdi.15/evidence.md`

## Acceptance Gates

- AG1: checked `flywheel-2xdi.15` and dependency context.
- AG2: checked `/Users/josh/.flywheel/loops/mobile-eats.json`.
- AG3: checked mobile-eats dispatch log callback and dispatch timestamps.
- AG4: checked canonical mobile-eats bridge receipt and bridge doctor output.
- AG5: filed `flywheel-2xdi.15.1` for the unresolved repair.
- AG6: targeted validator passes:
  `.flywheel/audit/flywheel-2xdi.15/l112-probe.sh`.

## Validation

- L112 probe: `.flywheel/audit/flywheel-2xdi.15/l112-probe.sh`
- Dispatch audit:
  `bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-2xdi.15-0d888c.md`
- Receipt parser:
  `bash .flywheel/validation-schema/v1/parse.sh .flywheel/audit/flywheel-2xdi.15/validation-receipt.json`

## Quality

Compliance score: 850/1000.

The closeout leaves a concrete repair bead instead of declaring a live
loop-integrity signal healthy from marker freshness alone.
