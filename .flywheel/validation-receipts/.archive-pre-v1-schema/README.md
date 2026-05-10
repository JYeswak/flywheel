# Pre-v1-schema validation receipts (archived)

This directory holds validation receipts written before the
`.flywheel/validation-schema/v1/schema.json` v1 contract was finalized
(May 3-8 2026). They violate the v1 contract in three ways:

- `artifact_checks_not_array` (6 files): `artifact_checks` written as object/string
- `failure_missing_failure_class` (1 file): missing required `failure_class` on failure rows
- `recovery_hint_missing` (1 file): missing required `recovery_hint`

Archived 2026-05-10 by flywheel-zh43y to clear the
`validation_receipts_schema_invalid_count` gate that was forcing
`flywheel-loop doctor --json` to top-level `status=fail` even though no
new receipts have been written in violation of v1 schema since 2026-05-08.

These are NOT deleted — they're historical evidence preserved for audit.
The pre-v1 receipt writers have already been replaced; the active receipt
ledger at `.flywheel/validation-receipts/` only contains v1-conformant rows.
