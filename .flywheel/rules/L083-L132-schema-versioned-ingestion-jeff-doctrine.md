## L132 — SCHEMA-VERSIONED-INGESTION-JEFF-DOCTRINE

---
id: L132
title: Schema-versioned ingestion is required for Jeff lens pass
status: long_term
shipped: 2026-05-07
review_due: 2026-11-07
trauma_class: unversioned-contract-ingestion
---

Every contract, schema, receipt, and payload artifact carries an explicit
`schema_version=N` field or a `<name>/v1` marker. The four-lens validator's Jeff
lens treats bare unversioned artifacts as close blockers because unversioned
ingestion makes contract evolution silent and unauditable.

**Evidence:** memory
`feedback_validator_must_check_four_lenses.md`; validator reason
`contract_without_version`; bead `flywheel-prtr`; fixtures
`tests/test_four_lens_jeff_version_contract_pass.sh` and
`tests/test_four_lens_jeff_version_contract_fail.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

