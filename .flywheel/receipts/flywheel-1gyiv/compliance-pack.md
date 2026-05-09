# flywheel-1gyiv Compliance Pack

## Scope

- Added `tests/security-control-conformance.sh`.
- Added `tests/security-control-fleet-smoke.sh`.
- Wrote `.flywheel/receipts/flywheel-1gyiv/conformance-report.md`.
- Wrote `.flywheel/validation-receipts/flywheel-1gyiv-aae9be.json`.

## Acceptance Evidence

- `bash tests/security-control-conformance.sh`: PASS.
- `bash tests/security-control-fleet-smoke.sh --dry-run`: PASS.
- Conformance report lists 77 schema-derived MUST clauses.
- Strict fixture matrix fails `missing-deny`, `missing-hook`, and `leaked-token`.
- Redaction report records `recall: 1.00`, `precision: 1.00`, and `raw_values_emitted: false`.
- Validation receipt validates with `.flywheel/validation-schema/v1/parse.sh` and routes through `validation-learn` as `ignored_positive`.
- Dispatch packet audit passes for `/tmp/dispatch_flywheel-1gyiv-aae9be.md`.

## Four-Lens Self-Grade

- brand:9 - Provides a durable end-to-end security proof without exposing secret-shaped values.
- sniff:9 - Harness covers positive and negative fixtures and writes a schema-valid receipt.
- jeff:8 - Report is deterministic and schema-derived; dry-run smoke redirects outputs to temp paths.
- public:8 - A skeptical operator, maintainer, and future worker can rerun the two acceptance commands and inspect the receipt.
