# P2-12 f2 Polish-Gate Schema Inventory Discovery

Date: 2026-05-06
Bead: `flywheel-p2-12-f2`
Scope: `templates/flywheel-install/polish-gate/v1/*.schema.json`

## Truth Source Command

```bash
ls /Users/josh/Developer/flywheel/templates/flywheel-install/polish-gate/v1/*.schema.json
```

## On-Disk Schema Set

- `templates/flywheel-install/polish-gate/v1/close-validation-result.schema.json`
- `templates/flywheel-install/polish-gate/v1/discovery-output.schema.json`
- `templates/flywheel-install/polish-gate/v1/grade-receipt.schema.json`
- `templates/flywheel-install/polish-gate/v1/grade-run-result.schema.json`
- `templates/flywheel-install/polish-gate/v1/latest-summary.schema.json`
- `templates/flywheel-install/polish-gate/v1/manifest.schema.json`
- `templates/flywheel-install/polish-gate/v1/reconcile-output.schema.json`
- `templates/flywheel-install/polish-gate/v1/replay-output.schema.json`
- `templates/flywheel-install/polish-gate/v1/scope-allowlist.schema.json`

## RCA

The Phase 2 audit found manifest inventory drift: `templates/flywheel-install/schema.json`
declared 7 polish-gate v1 schema paths, while the directory contains 9 durable
schema contracts. The omitted schemas were:

- `polish-gate/v1/discovery-output.schema.json`
- `polish-gate/v1/reconcile-output.schema.json`

The fix is Donella #5 rules: the template manifest must reflect on-disk schema
reality, and bidirectional parity tests now fail if either side drifts.
