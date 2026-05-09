## L94 — SHARED-SQLITE-WRITES-MUST-SERIALIZE

---
id: L94
title: Shared SQLite writes must serialize
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: sqlite-concurrent-writers
---

Any dispatch, hook, probe, import, rebuild, or repair that can write a shared SQLite database MUST prove single-writer ownership before the write starts. Shared SQLite substrates include repo-local `.beads/beads.db`, flywheel state databases, JSM/skillos state databases, and any SQLite DB read or written by multiple panes, sessions, hooks, or launchd jobs. Parallel workers may read from immutable snapshots; live writes require a named lock or a serialized queue.

Required write receipt fields are `db_path`, `db_fingerprint`, `operation_class`, `writer_owner`, `lock_path`, `lock_acquired_at`, `lock_timeout_seconds`, `competing_writer_count`, `pre_integrity_state`, `post_integrity_state`, and `release_status`. If the lock is unavailable, the work becomes queued or snapshot-read-only; it must not retry live writes in parallel. Repair/reindex paths must treat `br`, `jsm`, and direct `sqlite3` writes as the same write family, not separate safe channels.

**Why:** 2026-05-04 produced a same-day SQLite writer family: v2a1 substrate REINDEX/repair moved live Beads state through b-tree/WAL failure modes, skillos beads-import rebuild did not rewrite malformed pages, and skillos source-refresh hit a parallel state DB lock. Each incident looked local, but the common system failure was unsynchronized writes against shared SQLite state.

**How to apply:** add a pre-dispatch/pre-hook probe equivalent to `pre-dispatch-state-db-lock-check.sh --db <path> --operation <class> --json`; doctor should expose `sqlite_concurrent_writer_risk_count`, `sqlite_write_lock_conflict_count`, and `.sqlite_write_locks.top_conflicts`. A valid receipt should satisfy `jq -e '.lock_acquired == true and .competing_writer_count == 0 and .post_integrity_state != "worse"'` before mutating work is called safe.

**Boundary note:** L94 covers shared-writer concurrency. A single-writer
`br dep add` failure immediately after JSONL rebuild is the adjacent
version-drift/write-path class; apply L93 first, then prefer `br 0.2.4+` or a
validated direct-SQL/flush/rebuild fallback over filing a duplicate upstream
issue.

**Cross-references:** L51 (file reservations), L56 (promotion ladder), L60 (doctor signal contract), L71 (validate-and-redispatch), L72 (storage and repo-local state discipline), L90 (live capture before pane action), `feedback_shared_sqlite_writes_must_serialize.md`, and the 2026-05-04 SQLite trauma rows in `~/.local/state/flywheel/fuckup-log.jsonl`.

