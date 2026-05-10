---
title: "Storage Override Rollback Schema"
type: doctrine
created: 2026-05-07
frontmatter_source: scaffold-doc-frontmatter
---

# Storage Override Rollback Schema

`storage-override/v1` receipts are temporary storage gate changes. The rollback
guard is an object, not a string, so generated pause receipts and validator
fixtures carry the same recovery contract.

## Canonical rollback_guard

```json
{
  "requires_event": "STORAGE-CLEARED",
  "rollback_id": "storage-override-20260507T120000Z",
  "before_state": {
    "storage_gate": "base",
    "min_free_gb": 50,
    "min_free_pct": 10
  },
  "after_state": {
    "storage_gate": "override",
    "min_free_pct": 8
  },
  "idempotency_key": "storage-override-20260507T120000Z",
  "timestamp": "2026-05-07T12:00:00Z",
  "failure_class": "rollback_failed",
  "failure_taxonomy_ref": ".flywheel/doctrine/failure-taxonomy.md",
  "recovery_hint": "If STORAGE-CLEARED is not recorded before expiry, restore the base storage threshold."
}
```

Required fields: `requires_event`, `rollback_id`, `before_state`, `after_state`,
`idempotency_key`, `timestamp`, and `failure_class`.

`requires_event` must be `STORAGE-CLEARED`. The timestamp is RFC 3339 / JSON
Schema `date-time`. `before_state` and `after_state` must be non-empty objects
that make the gate transition inspectable.

## Failure Taxonomy Mapping

`.flywheel/doctrine/failure-taxonomy.md` is the source for canonical failure
classes. It currently defines `dcg_blocked_destructive_command`, `persistent`,
and `correctness` as storage-relevant classes.

Storage override receipts may use:

- `dcg_blocked` as a receipt-local alias for `dcg_blocked_destructive_command`
  when a rollback cannot be executed because DCG blocks a destructive command.
- `rollback_failed` as a receipt-local rollback reason. Until the taxonomy adds
  a dedicated rollback class, route it to `persistent` when the condition keeps
  recurring or `correctness` when the rollback state is internally inconsistent.

Do not add new receipt `failure_class` values without extending the taxonomy and
the schema together.

## Joshua Lens

Rollback receipts that do not validate are the silent ops failure. 25yr ops:
every rollback step is a runbook checkpoint; if the receipt schema drifts, the
rollback chain breaks under load.
