# flywheel-dwmb Compliance Pack

Task: `flywheel-dwmb-a1ee9d`
Bead: `flywheel-dwmb`
Date: 2026-05-09

## Result

Diagnostic completed and follow-up patch bead filed as `flywheel-dwmb.1`.

Root cause: mobile-eats Path A receipt validation conflated canonical receipt
bridge health with full repo doctor health.

## Acceptance Gates

- AG1: `/tmp/apply-mobile-eats-receipt-mirror_findings.md` checked; missing
  from disk, so durable callback observations were recovered from dispatch
  history.
- AG2: flywheel-loop doctor source and mobile-eats bridge source read.
- AG3: expected vs actual receipt schema/freshness/content compared.
- AG4: root cause identified and minimal fix proposed.
- AG5: P3 fix bead filed: `flywheel-dwmb.1`.
- AG6: diagnostic-only scope kept; no source patch applied.

## Validation

- L112 probe: `.flywheel/audit/flywheel-dwmb/l112-probe.sh`
- Dispatch audit:
  `bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-dwmb-a1ee9d.md`
- Receipt parser:
  `bash .flywheel/validation-schema/v1/parse.sh .flywheel/audit/flywheel-dwmb/validation-receipt.json`

## Quality

Compliance score: 850/1000.

The only gap is that the original `/tmp` findings file was already gone. The
material callback fields were recovered from durable dispatch history, and the
diagnostic stayed read-only except for filing the requested follow-up bead and
closing this bead.
