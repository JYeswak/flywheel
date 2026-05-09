## L79 — STORAGE-OVERRIDE-RECEIPTS-ARE-MECHANICAL

---
id: L79
title: Storage override receipts are mechanical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: manual-storage-threshold-override
---

Joshua-disposed storage threshold exceptions MUST be represented as
`storage-override/v1` receipts, not as prose or one-off environment tweaks.
`flywheel-loop doctor` is the gate owner: it reads active receipts, applies the
lowest valid temporary threshold, exposes override counters, fails closed when
no active receipt applies, and appends `STORAGE-CLEARED` when storage recovers
above the base threshold.

**How to apply:**
- Receipt schema lives at
  `.flywheel/validation-schema/v1/storage-override.schema.json`.
- Active receipts live under
  `~/.local/state/flywheel/storage-overrides/*.json`; event rows live in
  `~/.local/state/flywheel/storage-overrides/events.jsonl`.
- `flywheel-loop doctor --json` MUST expose top-level
  `storage_override_active_count` and `storage_override_expiring_in_min`, plus
  `.storage_override.effective_min_free_pct`.
- `flywheel-loop doctor --storage-min-free-pct N` and
  `FLYWHEEL_STORAGE_MIN_FREE_PCT=N` are explicit base-threshold controls; active
  receipts may only lower the gate temporarily and must expire.
- `sync-canonical-doctrine.sh --apply` propagates the storage override schema to
  flywheel-installed repos alongside canonical doctrine.

**Forbidden outputs:**
- Lowering storage thresholds in pane prose without a schema-valid receipt and
  expiry.
- Treating an expired, wrong-target, or unsigned-but-signature-present receipt
  as active.
- Continuing to apply an override after a `STORAGE-CLEARED` event or after the
  base storage gate passes.

**Evidence:** bead `flywheel-vso8`; schema
`.flywheel/validation-schema/v1/storage-override.schema.json`; tests
`tests/storage-override.sh`; receipts
`~/.local/state/flywheel/storage-overrides/`.

**Companion rules:** L60 (doctor signal contract), L61 (wire-in), L70 (chain
repair), L71 (validate every surface), L72 (storage discipline), and L77 (daily
report surfaces).

