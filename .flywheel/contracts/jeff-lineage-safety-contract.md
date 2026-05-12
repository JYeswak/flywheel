---
contract: jeff-lineage-safety-contract
status: locked
source_bead: flywheel-l1vl
parent_synthesis: flywheel-avlj
phase4_verdict: EXTEND
jeff_patterns: [P02, P06, P08, P09, P10]
doctrine_refs: [L71, L72, L78]
related_skills: [safe-migrations, database-operations, storage-health, accretive-file-write, agent-mail]
created: 2026-05-06
---

# Jeff Lineage Safety Contract

Codifies how flywheel scripts that mutate shared state (filesystem, beads DB,
agent-mail reservations, doctrine propagation, fleet settings, ingestion
indexes) inherit Jeff Emanuel's clustered mutation-safety patterns:
idempotency keys, lock metadata, append-only audit chains, backup-first
writes, rollback receipts, and storage-headroom preflight.

This contract is load-bearing for any script under `.flywheel/scripts/` that
writes a path it does not exclusively own (or that other panes/launchd jobs
also write).

## When to apply

ALWAYS apply when the script:

- Writes to `.beads/issues.jsonl` (in fact, only `br` is allowed — see
  `feedback_beads_jsonl_writes_via_br_only`).
- Mutates `.flywheel/AGENTS-CANONICAL.md`, `GOAL.md`, `MISSION.md`, or any
  file under `.flywheel/doctrine/`.
- Writes to a JSONL log under `.flywheel/` consumed by another pane
  (`dispatch-log.jsonl`, `lock-log.jsonl`, `fuckup-log/*`).
- Touches agent-mail reservations, identity registry, or vault state.
- Performs ingestion / indexing under `.flywheel/jeff-corpus/` or Qdrant
  collections.
- Propagates doctrine across the fleet
  (`agents-md-fleet-propagator.sh`, `apply-substrate-tuning.sh`,
  `apply-tmux-tuning.sh`).

DO NOT apply when:

- The script writes only `${TMPDIR}` or `mktemp` paths it created in this
  invocation.
- The mutation is a single-writer launchd plist owned exclusively by the
  script (no peer reads/writes).
- The path is under a per-pane scratch directory and is reset on respawn.

## Pattern (Jeff source)

| Pattern | Jeff source | ZestStream adaptation |
|---|---|---|
| Idempotency key + dedup | `franken_engine/PLAN_TO_CREATE_FRANKEN_ENGINE.md:812`, `:1132`; `asupersync/src/remote.rs:1426`; `franken_engine/crates/franken-engine/src/idempotency_key.rs:212` | every mutation carries `request_fingerprint` + TTL; repeat conflict fails closed |
| Fail-closed on tracked-script drift | `agentic_coding_flywheel_setup/install.sh:1684`; `tests/unit/test_doctor_fix.sh:362` | same posture for `.flywheel/scripts/*.sh` |
| Lock file with PID + stale diagnosis | `remote_compilation_helper/install.sh:364-370`; `test/install.bats:241`; `agentic_coding_flywheel_setup/scripts/lib/state.sh:688` | `.flywheel/locks/<scope>.lock` records `pid`, `owner`, `started_at`, `timeout_s` |
| Append-only hash-linked audit chain | `franken_engine/PLAN_TO_CREATE_FRANKEN_ENGINE.md:584,687,817`; `franken_engine/crates/franken-engine/tests/replacement_lineage_log.rs:297`; `mcp_agent_mail/src/mcp_agent_mail/storage.py:1888` | `.flywheel/lock-log.jsonl` and `dispatch-log.jsonl` rows carry `prev_row_hash` |
| Backup-first / dry-run / rollback by ID | `storage_ballast_helper/README.md:193,199,478`; `agent_settings_backup_script/AGENTS.md:173` | timestamped sidecar (`*.bak.<UTC>`) + rollback-receipt JSON next to mutation |
| Storage headroom preflight | `storage_ballast_helper/AGENTS.md:359`; `README.md:1346,1347`; `scripts/e2e_test.sh:826` | growth-heavy paths (ingestion, Qdrant, JSONL append) probe free space first |

## Required envelope on every mutation receipt

```json
{
  "schema_version": "<surface>-mutation/v1",
  "idempotency_key": "<sha256-of-request-canon>",
  "request_fingerprint": "<inputs hashed>",
  "ttl_seconds": <int>,
  "conflict_action": "fail_closed|merge|noop",
  "lock": {
    "path": "<abs path>",
    "pid": <int>,
    "owner": "<script-id>",
    "started_at": "<UTC>",
    "timeout_s": <int>,
    "stale_action": "diagnose_then_break"
  },
  "audit": {
    "row_id": "<ulid>",
    "prev_row_hash": "<sha256|null>",
    "log_path": "<abs path>",
    "schema_version": "<log>/v1"
  },
  "backup": {
    "path": "<abs path>|null",
    "no_backup_reason": "<string|null>"
  },
  "rollback": {
    "available": true|false,
    "command": "<copy-pasteable>"
  },
  "storage_preflight": {
    "free_gb": <float>,
    "headroom_required_gb": <float>,
    "result": "pass|warn|fail"
  }
}
```

A receipt with any field unset (and no explicit-null reason) MUST fail the
contract probe.

## Lock-file convention

- Path: `.flywheel/locks/<scope>.lock`
- Contents: JSON envelope (`pid`, `owner`, `started_at`, `timeout_s`,
  `parent_pid`, `host`).
- Stale diagnosis: if `pid` is not alive AND `started_at + timeout_s < now`,
  the contract permits break-and-log — the breaking writer MUST append a
  `lock_broken` row to `.flywheel/lock-log.jsonl` per `lock-log-schema.md`.
- Nested-lock rule: a holder of lock `A` MUST NOT acquire lock `B` if any
  peer scope already holds `B` AND its `owner` differs from this writer.

## Existing flywheel surfaces this contract covers (audit set)

These mutating scripts MUST be audited against the contract; missing fields
become beads filed under this contract's owner:

1. `.flywheel/scripts/append-safe-write.sh` — closest reference
   implementation; emits `append-safe-write/v1` envelope already.
2. `.flywheel/scripts/agents-md-fleet-propagator.sh` — propagates AGENTS
   across the fleet; needs explicit backup + rollback receipt.
3. `.flywheel/scripts/apply-substrate-tuning.sh` — sysctl/launchd mutation;
   needs idempotency key.
4. `.flywheel/scripts/beads-db-recover.sh` — substrate rebuild; backup
   before write is mandatory (see
   `feedback_substrate_rebuild_is_disposable_not_class_5`).
5. `.flywheel/scripts/agent-mail-restart.sh` — service mutation; needs lock
   + storage preflight (FD pressure).
6. `.flywheel/scripts/handoff-skill-to-skillos.sh` — already has
   `--dry-run`; needs explicit rollback receipt schema.

## Compliance probe

Per `jeff-doctor-repair-contract`, a doctor surface MUST emit:

```json
{
  "schema_version": "lineage-safety-contract-doctor/v1",
  "status": "pass|warn|fail",
  "scripts_audited": <int>,
  "missing_idempotency": [...],
  "missing_lock_metadata": [...],
  "missing_audit_chain": [...],
  "missing_backup_or_reason": [...],
  "missing_storage_preflight": [...],
  "stale_lock_breakers_unlogged": [...]
}
```

Existing test coverage for related cases lives in
`.flywheel/tests/test-two-blocker-ticks-jsonl-fallback-regression.sh`.
Stale-lock, idempotency-conflict, dry-run-noop, and backup-receipt fixtures
go under `.flywheel/fixtures/lineage-safety/`.

## Anti-patterns (DIVERGE from Jeff)

- Do NOT use a SQLite advisory lock as a stand-in for a lock-file envelope on
  cross-process flywheel mutations — beads_rust already handles `.beads`
  internally; flywheel's coordination scope is filesystem-wide.
- Do NOT compress the audit chain with rotating logs that drop hash
  continuity. Use compaction with checkpoint rows (per P08 EXTEND verdict).

## DOD reference

This contract document satisfies `flywheel-l1vl` acceptance gate 1
(field-level requirements). Gate 2 (audit two scripts), gate 3
(machine-readable findings), and gate 4 (fixture tests) are follow-on beads
filed against this contract path.
