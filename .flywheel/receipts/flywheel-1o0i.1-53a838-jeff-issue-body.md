## What happened

`runtime_handoff` appears intended to be scoped by session and working directory,
but the current schema and store path still make it singleton-scoped. The live
table has a unique index over `(session_name, working_dir)`, but the table keeps
`id INTEGER PRIMARY KEY CHECK (id = 1)`, and the runtime store writes through
`ON CONFLICT(id)`.

Observed with `ntm version dev` against source revision `06114a5d`.
Dedup probe: `gh issue list --repo Dicklesworthstone/ntm --state all --search
"runtime_handoff singleton id working_dir" --limit 20` returned no matches on
2026-05-09T00:29Z.

## Repro

Shell: `zsh`; SQLite CLI available.

Starting from a copy of the NTM state DB, or from a fixture DB created with the
current `runtime_handoff` schema:

```bash
sqlite3 <state-db-copy> ".schema runtime_handoff"

sqlite3 <fixture-db> '
  INSERT INTO runtime_handoff (
    id, session_name, status, updated_at, collected_at, stale_after, working_dir
  ) VALUES (
    1, "session-a", "ok", datetime("now"), datetime("now"),
    datetime("now", "+5 minutes"), "/path/to/repoA"
  );
  INSERT INTO runtime_handoff (
    id, session_name, status, updated_at, collected_at, stale_after, working_dir
  ) VALUES (
    2, "session-b", "ok", datetime("now"), datetime("now"),
    datetime("now", "+5 minutes"), "/path/to/repoB"
  );
'
```

The second insert fails:

```text
CHECK constraint failed: id = 1
```

## Expected vs observed

```diff
- runtime_handoff can only represent one row through id = 1
+ runtime_handoff can represent distinct rows by session_name + working_dir
```

Expected: two rows for two distinct `(session_name, working_dir)` pairs should
be representable at the schema/store layer.

Observed: the schema rejects any row with `id != 1`, and the store's upsert path
continues to overwrite via `ON CONFLICT(id)`.

## File:line citations

- `internal/state/migrations/011_runtime_handoff.sql:6-22` creates
  `runtime_handoff` with `id INTEGER PRIMARY KEY CHECK (id = 1)`.
- `internal/state/runtime_store.go:970-990` inserts `id` as `1` and updates via
  `ON CONFLICT(id)`.
- `internal/state/runtime_store.go:1010-1016` reads only `WHERE id = 1`.
- `internal/state/runtime_store.go:1032-1038` deletes only `WHERE id = 1`.
- `internal/state/runtime_store.go:1046-1066` repeats the same singleton upsert
  path in transaction scope.
- `internal/state/runtime_store.go:1080-1082` repeats the singleton delete path
  in transaction scope.

## Why this matters

Any downstream guard that wants to prove handoff state is isolated by session
and working directory cannot do that from the current contract. A table-level
`(session_name, working_dir)` unique index is not enough while the primary key
and store methods still force a single row. The failure mode is state collapse:
two independent sessions or project roots can be projected as a singleton
handoff.

## Out of scope

Not asking for a broader runtime-handoff expansion or prescribing the
implementation. This is a contract mismatch between the session/workdir scoping
implied by the schema surface and the singleton `id = 1` store path.
