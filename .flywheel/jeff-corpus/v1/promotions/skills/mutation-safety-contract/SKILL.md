---
name: mutation-safety-contract
description: Candidate skill for idempotency, lock metadata, append-only audit, backup, rollback, and storage preflight on mutating flywheel surfaces.
status: approval_only
source_bead: flywheel-w3pr.3
phase4_verdict: EXTEND
---

# Mutation Safety Contract

Use this candidate skill before changing a script that writes shared state,
updates a manifest, repairs a database, prunes storage, or edits durable
runtime ledgers.

## Contract

Mutating surfaces should define:

- idempotency key
- request fingerprint
- TTL or replay window
- conflict receipt
- lock owner/PID/path/timeout
- stale-lock diagnosis
- append-only audit row
- backup-before-write or explicit no-backup reason
- rollback receipt
- storage headroom preflight for growth-heavy work

## Source Evidence

- Phase 4 verdict: `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`, "Idempotency, dry-run, lock files, append-only lineage" = EXTEND.
- `asupersync/src/remote.rs:1426` is cited for idempotency-key handling.
- `franken_engine/crates/franken-engine/src/idempotency_key.rs:212` is cited for idempotency-key semantics.
- `agentic_coding_flywheel_setup/scripts/lib/state.sh:688` is cited for lock-file behavior.
- `remote_compilation_helper/install.sh:366` records lock PID metadata.
- `franken_engine/crates/franken-engine/tests/replacement_lineage_log.rs:297` tests lineage/audit logging.

## Approval Gates

- Install only after `flywheel-l1vl` audits at least two mutating flywheel scripts.
- Do not use this draft to justify broad host cleanup. Host-tier mutations still need Joshua approval.
