---
title: "Plan STATE Lens Merge Ledger Contract"
type: doctrine
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Plan STATE Lens Merge Ledger Contract

Version: `plan-state-lens-merge-ledger/v1`
Owner: `/flywheel:dispatch` and any parallel plan STATE writer
Status: canonical Wave 2 contract, shipped 2026-05-06

This contract closes IDEM-004 for parallel plan writers. It consumes the Wave 1
idempotency sibling primitive `.flywheel/scripts/idempotency-replay-guard.sh`
as read-only precedent for identity keys, replay-safe retries, and transaction
receipts.

## 1. Scope

Every parallel writer to a plan `STATE.json` must use this ledger shape. Current
examples are Phase 3 audit lenses and Phase 4 wave beads; future close writers,
polish passes, and readiness probes use the same contract whenever multiple
workers can observe and write the same plan state.

The writer's job is not to hand-edit summary fields. It appends one per-lens row
and lets readers compute the merged view.

## 2. Per-lens Append-only Rows

Rows live under `lens_merge_rows[]`. Each row is keyed by:

- `lens`
- `ts`
- `audit_lens_identity_key`

Required row fields:

- `schema_version=plan-state-lens-row/v1`
- `lens`
- `ts`
- `state_observed_sha`
- `state_written_sha`
- `audit_lens_identity_key`
- `findings_by_severity`
- `audit_disposition`

Writers append rows only. They never edit or reorder existing rows.

## 3. state_observed_sha

`state_observed_sha` is the canonical SHA of `STATE.json` as the writer observed
it before appending the row. It lets a later reader distinguish "I wrote against
the latest state" from "I raced another writer and retried."

The canonical hash ignores `state_written_sha` fields to avoid recursive hash
changes. The value is still a stable race-detection marker for the surrounding
STATE payload and all prior append rows.

## 4. Merge Semantics

Derived fields are computed by walking `lens_merge_rows[]`:

- `audit_lenses_complete[]`
- `audit_findings_count`
- `audit_findings_by_severity`
- `audit_disposition_by_lens`
- `effective_lenses_count`

If multiple rows exist for the same lens, the latest non-superseded row wins.
If a row has `supersedes=<audit_lens_identity_key>`, the superseded row remains
in the ledger but is ignored by derived summary computation.

## 5. Derived STATE Summary Preservation

Non-audit summary fields already present in `STATE.json` must survive every
append:

- `refine_round`
- `convergence_streak`
- `current_phase`
- `phase2_refine_task_id`
- `artifacts`

The merge helper may append `lens_merge_rows[]`; it must not erase unrelated
summary keys while adding audit rows.

## 6. Race Detection + Retry

Append flow:

1. Read `STATE.json`.
2. Compute canonical `state_observed_sha`.
3. Compare it with the row's supplied `state_observed_sha`, when present.
4. If the supplied value differs, reload, record `race_detected=true`, and retry
   with the fresh observed hash.
5. Write via temp file plus rename.

Retry is bounded. A permanent schema or validation error fails fast; only hash
mismatch is retryable.

## 7. Append-only Invariant

Deleting or in-place editing a lens row is forbidden. Corrections are new rows
with `supersedes` pointing at the old `audit_lens_identity_key`.

Readers that need the current truth use the derived view. Auditors that need
history inspect every row.

## 8. Conformance Probe

Canonical helper:

```bash
.flywheel/scripts/plan-state-lens-merge.sh append --plan <plan-or-state-path> --lens <name> --row-json '<json>' --json
.flywheel/scripts/plan-state-lens-merge.sh derived --plan <plan-or-state-path> --json
.flywheel/scripts/plan-state-lens-merge.sh validate --plan <plan-or-state-path> --json
```

The helper supports `--info`, `--help`, `--examples`, `--json`, and `--quiet`.
The golden fixture suite is
`.flywheel/tests/test_plan_state_lens_merge.sh`.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-09 — info-source watchtower:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md` for the canonical pattern.
- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
