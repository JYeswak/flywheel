# flywheel-3128 Receipt

## Classification

- Drift class: `version_drift`
- Decision: `both` (local `vibe_cockpit` migration fix + upstream issue)
- Upstream issue: https://github.com/Dicklesworthstone/vibe_cockpit/issues/5
- Existing issue #4 was deduped and rejected as a match; it covered daemon/collect wiring, not this table-shape drift.

## Divergence Trace

- Collector emits `exists`: `/Users/josh/Developer/vibe_cockpit/crates/vc_collect/src/collectors/ntm.rs:239`
- Migration 001 creates `ntm_sessions_snapshot` without `exists`: `/Users/josh/Developer/vibe_cockpit/crates/vc_store/src/migrations/001_initial_schema.sql:231`
- Migration 006 defines the newer table shape with `exists`, but `CREATE TABLE IF NOT EXISTS` cannot reconcile a table already created by migration 001: `/Users/josh/Developer/vibe_cockpit/crates/vc_store/src/migrations/006_ntm_collector.sql:6`

## Action Taken

- Added migration 027: `/Users/josh/Developer/vibe_cockpit/crates/vc_store/src/migrations/027_ntm_sessions_snapshot_reconcile.sql`
- Registered migration 027 in `/Users/josh/Developer/vibe_cockpit/crates/vc_store/src/migrations.rs`
- Added regression coverage in `/Users/josh/Developer/vibe_cockpit/crates/vc_store/src/lib.rs`
- Filed upstream `vibe_cockpit#5` with anonymized public-path-only evidence.
- Updated local upstream issue memory: `/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_upstream_issues.md`

## Validation

- Reproduced original warning using fresh DB before patch: `/tmp/flywheel-3128-vc-collect.err`
- Post-patch fresh collect using `target/debug/vc`:
  - `collect_rc=0`
  - `/tmp/flywheel-3128-vc-collect.err` line count: `0`
  - No `row batch persist failed`, missing-column, or Binder error in collect/query/db-info stderr.
  - `SELECT COUNT(*) FROM ntm_sessions_snapshot` returned `7`
- Tests:
  - `cargo test -p vc_store test_ntm_sessions_snapshot_accepts_collector_shape` passed
  - `cargo test -p vc_store test_migrations_idempotent` passed

## Follow-Up

- Await Jeffrey's response on `vibe_cockpit#5`.
- If upstream lands a different migration shape, reconcile local migration numbering before the next `vc` rebuild.
