# Phase 3 AUDIT r1 Lens 2 - Idempotency, Recovery, Schema Versioning

Plan: `orchestrator-workforce-supervision-2026-05-04`
Lens: idempotency + recovery contracts + schema versioning
Input: `00-PLAN.md` r2, Jeff corpus code-pattern learnings, `safe-migrations`, `jeff-convergence-audit`
Mode: READ-ONLY audit; no beads created in this phase

## Audit Summary

The r2 plan names the right safety posture: recovery is dry-run by default,
idempotent, cooldown-bound, source-arbitrated, and backed by append-only
receipts. The main gap is that those words are not yet hard contracts. Phase 4
must turn them into exact keys, leases, schemas, migrations, and replay tests or
the supervisor can still double-send, race itself, or recover against stale
state.

Findings total: 11
P0 findings: 3
P1 findings: 6
P2 findings: 2

No gap beads are filed in this Phase 3 lens because the dispatch is READ-ONLY.
These findings should become amendments or beads during Phase 4 DECOMPOSE.

## Findings Register

| finding_id | severity | section_of_plan | description | proposed_mitigation | requires_joshua_decision |
|---|---|---|---|---|---|
| F1 | P0 | Section 2 invariants lines 123-125; Section 5 Layer 4 lines 338-340; Section 8 B07 line 502 | The plan says recovery is idempotent, but it does not define the idempotency key, request fingerprint, TTL, replay behavior, or conflict behavior. A retry of `--auto-recover --apply` can become a second prompt, second interrupt, second bead update, or contradictory recovery row. | Amend B01/B07 to require `idempotency_key`, `request_fingerprint`, `fingerprint_hash`, `first_seen_at`, `expires_at`, and `result_ref` for every mutating recovery. Replays return the original result; same key with different fingerprint fails closed. Cite Jeff `idempotency-key-fail-closed`: `asupersync/src/remote.rs:1426`, `asupersync/docs/tokio_retry_idempotency_failure_contracts.json:181`, `franken_engine/crates/franken-engine/src/idempotency_key.rs:212`. | no |
| F2 | P0 | Section 5 architecture lines 237-247; Section 5 Layer 4 lines 326-340; Section 7 dependency rules lines 448-454 | The plan composes watcher v4, auto-nudge, and the new supervisor but does not require a single-owner lease before recovery. Two supervisor instances, or supervisor plus legacy watcher, can classify and recover the same pane concurrently. | Add a supervisor owner lease in B01/B07 before any mutating recovery: lock path, owner session, pane, PID, command, lease epoch, acquired_at, expires_at, stale-lock diagnosis, and release receipt. Recovery without the active lease is refused. Cite Jeff `lock-file-convention`: `agentic_coding_flywheel_setup/scripts/lib/state.sh:688`, `franken_node/CONCURRENCY.md:1`, `remote_compilation_helper/rch/src/state/mod.rs:1`. | no |
| F3 | P0 | Section 4 failure catalog lines 203 and 211-213; Section 5 Layer 4 lines 335-336; Section 8 B06/B07 lines 501-502 | `dispatch_stalled` and callback recovery can double-dispatch or double-recover if a worker is slow, callback verification lags, or remote bead state disagrees with local debt. The plan lacks a compare-and-set assignment contract against task/bead status. | B06/B07 must require a dispatch assignment ledger keyed by `task_id:bead_id:session:pane:assignment_epoch`. Before dispatch/recovery, compare local debt, pane assignment, and `br` status; if any source changed since classification, emit `source_conflict` and do not mutate. Replays with the same assignment key must be no-ops. | no |
| F4 | P1 | Section 2 invariants lines 123-125; Section 5 current-state fields lines 304-318; Section 8 B07 line 502 | Cooldown exists as a field, but scope, duration, reset rule, and escalation threshold are underspecified. A recovery loop can run every watch tick under a new implicit key. | Define cooldown key as `failure_class:session:pane:task_id:assignment_epoch`, default TTL per class, exponential backoff after repeated strikes, and reset only after a healthy reclassification with fresh evidence. Doctor should expose `recovery_in_cooldown_count` and `recovery_strike_count`. | no |
| F5 | P1 | Section 5 Layer 4 recovery table lines 326-336; Section 6 CLI lines 367-386 | Recovery actions are still semantic labels such as "benign ping", "surface MCP recovery instruction", and "watcher-style dispatch." Without exact command templates, arguments, expected output, and success criteria, fixtures cannot prove safe behavior. | B07 must add a recovery action registry with one contract per class: command/template, required args, dry-run output schema, apply output schema, success criterion, timeout, rollback/no-op posture, and audit event shape. Fixtures should assert the exact outbound payload for every class. | no |
| F6 | P1 | Section 5 Layer 1 line 288; Section 5 Layer 2 lines 293-300; Section 7 version rules lines 448-454 | Samples include `schema_version`, but the plan does not define a version registry, compatibility matrix, migration adapters, or a doctor signal for mixed-version ledger/state skew. | Amend B01/B03 with `supervisor-schema/v1` registry, per-sample schema IDs, reader compatibility tests for v1/v2 mixed ledgers, `supervisor_schema_skew_count`, and a migration policy. Cite Jeff `schema-version-migration`: `franken_engine/crates/franken-engine/src/migration_compatibility.rs:1757`, `frankenterm/crates/frankenterm-core/src/storage/migrations.rs:768`, `mcp_agent_mail_rust/crates/mcp-agent-mail-db/tests/schema_migration.rs:1529`. | no |
| F7 | P1 | Section 5 Layer 2 lines 293-300; Section 8 B03 line 498; Section 10 Q5 lines 558-560 | SQLite is described as rebuildable current state, but schema evolution for `state.sqlite3` lacks backup, rollback, validation query, and expand/contract posture. A bad migration could corrupt the dashboard and recovery decisions even if JSONL survives. | B03 must use safe-migrations discipline: backup `state.sqlite3` before migration, expand/contract phases for incompatible changes, validation query for row counts/schema epoch/freshness, rollback by restoring backup or rebuilding from JSONL, and a migration receipt. `safe-migrations` requires rollback SQL/plan and validation query for every migration. | no |
| F8 | P1 | Section 5 Layer 2 lines 293-300; Section 5 Layer 5 lines 342-346; Section 8 B03/B10 lines 498 and 505 | Append-only JSONL paths are named, but integrity, ordering, retention, and compaction rules are not. Postmortems may fail if rows are truncated, reordered, duplicated, or compacted without lineage. | B03/B10 should require monotonic sequence numbers per ledger, writer id, previous-row hash or segment checksum, doctor checks for gaps/corruption, retention/compaction policy, and replay fixtures that reconstruct current state from ledger only. Cite Jeff `append-only-audit-log`: `franken_engine/crates/franken-engine/tests/replacement_lineage_log.rs:297`, `franken_node/tests/integration/frankensqlite_adapter_conformance.rs:217`, `mcp_agent_mail/src/mcp_agent_mail/storage.py:1888`. | no |
| F9 | P1 | Section 5 Layer 4 lines 326-340; Section 5 Layer 5 lines 342-346; Section 8 B05/B07 lines 500 and 502 | Recovery outcome semantics are not precise enough. "Recovery attempt logged and later reclassified healthy" does not define `success`, `failed`, `unknown`, `expired`, or `superseded`, so success-rate and strike counts can lie. | Add a recovery-outcome enum and timeout contract: `dry_run_only`, `applied_pending_probe`, `success`, `failed`, `unknown_timeout`, `superseded_by_new_assignment`, `refused_by_guard`. Every outcome must cite the sample IDs used for reclassification. | no |
| F10 | P2 | Section 6 CLI lines 391-399; Section 10 Q1 lines 546-547 | Human silence/override and `--auto-recover --apply` approval are not idempotency-scoped. Re-running an approval command can extend suppression or authorize a new mutation unintentionally. | Require override/silence receipts with stable idempotency keys, scope, expiry, approver, and risk text. Replays return the same receipt; changed scope requires a new receipt and explicit acknowledgment. | yes |
| F11 | P2 | Section 7 version/drift rules lines 437-454; Section 9 rollout lines 460-464 | The plan says watcher v4 and auto-nudge are migration inputs, not final owners, but it does not define cutover detection. Legacy recovery daemons can remain active and compete with supervisor recovery. | Add a rollout gate and doctor signal `legacy_recovery_daemons_active_count`. Phase 4 should either disable legacy mutators before supervisor apply mode or wrap them so they delegate to the supervisor owner lease. | no |

## Lens Coverage

### 1. Idempotency Violations

Covered by F1, F3, and F10.

The plan uses the word `idempotency`, but Phase 4 must define key derivation,
fingerprint conflict behavior, TTL, and original-result replay. The Jeff corpus
pattern is fail-closed idempotency, not best-effort dedupe.

### 2. Cooldown And Rate-Limit Gaps

Covered by F4 and F9.

Cooldown must be keyed to the same failure and assignment identity that recovery
uses. Otherwise every watch tick can create a new implicit recovery opportunity.

### 3. Schema Versioning Of State Ledger

Covered by F6 and F7.

`schema_version` on samples is necessary but insufficient. The state ledger and
SQLite projection need a registry, mixed-version tests, migration receipts, and
doctor-visible skew.

### 4. Recovery Contract Clarity

Covered by F5 and F9.

Recovery labels need to become executable contracts before implementation:
command, args, dry-run output, apply output, timeout, success criterion, and
audit row. Without this, the test harness can only validate prose.

### 5. Append-Only Audit Lineage

Covered by F8.

JSONL paths are named, but postmortem-grade lineage requires sequence and
integrity checks. Rebuildable current state is only credible when the raw ledger
can prove it has not silently lost or reordered events.

### 6. Concurrency And Race Conditions

Covered by F2, F3, and F11.

The highest concurrency risk is not internal threading; it is multiple external
drivers deciding they own recovery. The implementation needs an owner lease and
legacy-daemon cutover gate before any mutating recovery can run.

## Jeff Pattern Crosswalk

| Jeff pattern | Audit use | Required Phase 4 consequence |
|---|---|---|
| `idempotency-key-fail-closed` | F1/F3/F10 | Recovery and dispatch assignment mutations need key + fingerprint + TTL + replay semantics. |
| `lock-file-convention` | F2/F11 | Mutating recovery requires a single-owner lease with stale-lock diagnosis. |
| `schema-version-migration` | F6/F7 | Samples, ledgers, and SQLite projection need schema registry, compatibility tests, and migration receipts. |
| `append-only-audit-log` | F8/F9 | Recovery attempts and outcomes need ordered, integrity-checked, replayable audit rows. |
| `doctor-health-repair-triad` | F4-F9 | Doctor observes skew/cooldown/lineage; repair remains dry-run/apply and idempotent. |

## Phase 4 Amendments

- B01 `supervisor-state-contract`: add schema registry, idempotency record shape, owner lease shape, recovery outcome enum, and JSONL integrity fields.
- B03 `state-index-and-dashboard-query`: add safe migration receipt gates, rebuild validation query, mixed-schema fixture, and append-only replay hash.
- B06 `supervisor-classifier`: require assignment compare-and-set inputs before dispatch/recovery classes become actionable.
- B07 `recovery-dispatcher`: add action registry, idempotency fail-closed semantics, cooldown key rules, owner lease requirement, and recovery outcome transitions.
- B10 `conformance-and-daemon-smoke`: include competing-supervisor and legacy-daemon fixtures before apply mode can be enabled.

## Three-Q Audit

- VALIDATED: all six requested audit areas are covered by findings above; each P0/P1 finding cites plan sections and a concrete implementation risk.
- DOCUMENTED: Jeff pattern citations are included when invoking idempotency, lock, schema migration, and append-only lineage patterns.
- SURFACED: Phase 4 amendments identify which beads should absorb each finding; no beads were created because Phase 3 is READ-ONLY.

## Closeout Ledger

did=6/6
didnt=none
gaps=none
tests=PASS pending file existence and callback delivery verification
