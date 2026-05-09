# flywheel-rdqc7.1 Compliance Pack

task_id: flywheel-rdqc7.1-2ba30f
compliance_score: 860/1000

## Acceptance

- Gate 1: PASS. Added a wave allowlist flag: `--l-rules L29,L35,...`.
- Gate 2: PASS. Plain unscoped behavior remains available; allowlist mode narrows append/apply to reviewed rules only.
- Gate 3: PASS. Each wave can use its own existing `--idempotency-key`.
- Gate 4: PASS. Partial wave apply avoids bulk append and avoids full `doctrine_version` stamping until drift is complete.
- Gate 5: PASS. Invalid or unknown L-rule ids fail closed.

## Checks

- `bash -n .flywheel/scripts/doctrine-sync.sh`: PASS
- `.flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-rdqc7.1-2ba30f.md`: PASS
- `.flywheel/receipts/flywheel-rdqc7.1/l112_probe.sh`: PASS
- `canonical-cli-scoping` checker: pre-existing PARTIAL, tracked by `flywheel-ynys`.

## Artifact Checks

- doctrine-sync:.flywheel/scripts/doctrine-sync.sh:exists
- l112-probe:.flywheel/receipts/flywheel-rdqc7.1/l112_probe.sh:exists
- evidence:.flywheel/receipts/flywheel-rdqc7.1/evidence.md:exists
- validation-receipt:.flywheel/validation-receipts/flywheel-rdqc7.1-2ba30f.json:exists

## L61

- agents_md_updated=no
- readme_updated=no
- no_touch_reason=wave-allowlist behavior change only; no new doctrine, L-rule, INCIDENTS entry, or public README contract landed.
