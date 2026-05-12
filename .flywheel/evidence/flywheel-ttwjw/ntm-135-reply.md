Both, kind of — and the migration journal makes it clearer.

The `_migrations` output on this install ends at 014, no `working_dir` migration:

```text
1|001_initial.sql|2026-02-07
[...]
11|011_runtime_handoff.sql|2026-04-19
12|012_runtime_gc_guardrails.sql|2026-04-19
13|013_incident_fingerprint.sql|2026-04-19
14|014_attention_item_state.sql|2026-04-19
```

`.schema runtime_handoff` shows the `working_dir TEXT NOT NULL DEFAULT ''` column and `idx_runtime_handoff_session_workdir` unique index alongside the original `id INTEGER PRIMARY KEY CHECK (id = 1)`. So those were applied out-of-band on this DB — confirms your (b) hypothesis on the empirical observation. Likely a downstream `ALTER TABLE` that reached for per-(session, working_dir) scoping without seeing the singleton primary key.

But the underlying intent in the issue body is (a). A multi-pane wrapper against multiple repos needs per-(session, working_dir) scoping, and the current contract collapses everything to a singleton row through `ON CONFLICT(id)`. Even on the altered DB the `CHECK (id = 1)` still wins on writes — the unique index alongside it is decorative, not load-bearing. The out-of-band ALTER didn't actually deliver the feature it looked like it was reaching for.

So yes — please design the multikey migration. Sketch of what would land cleanly downstream:

```sql
-- 015_runtime_handoff_multikey.sql (or whatever slot fits the sequence)
ALTER TABLE runtime_handoff RENAME TO _runtime_handoff_old;

CREATE TABLE runtime_handoff (
    session_name TEXT NOT NULL,
    working_dir  TEXT NOT NULL DEFAULT '',
    status TEXT,
    goal TEXT,
    goal_disclosure TEXT,
    now_text TEXT,
    now_disclosure TEXT,
    updated_at TIMESTAMP,
    active_beads TEXT,
    agent_mail_threads TEXT,
    blockers TEXT,
    blocker_disclosures TEXT,
    files TEXT,
    collected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    stale_after  TIMESTAMP NOT NULL,
    PRIMARY KEY (session_name, working_dir)
);

INSERT OR REPLACE INTO runtime_handoff
SELECT session_name, COALESCE(working_dir, ''), status, goal, goal_disclosure,
       now_text, now_disclosure, updated_at, active_beads, agent_mail_threads,
       blockers, blocker_disclosures, files, collected_at, stale_after
FROM _runtime_handoff_old;

DROP TABLE _runtime_handoff_old;
```

Backfill semantics: `INSERT OR REPLACE` over `_old` is safe because the old table has at most one row per session (the CHECK forced singleton). Existing single-row state lands as `(session_name, '')` if no `working_dir` is present, or as the altered-DB value if one was applied out-of-band. Future writes pick a real `working_dir` and the empty-string row gets replaced naturally on first write from a known repo.

And the writes flip:
- `internal/state/runtime_store.go:970-990`: `ON CONFLICT(id)` → `ON CONFLICT(session_name, working_dir)`
- `:1010-1016`: `WHERE id = 1` → `WHERE session_name = ? AND working_dir = ?`
- `:1032-1038`, `:1046-1066`, `:1080-1082`: same shape — drop the `id = 1` literal and route through `(session_name, working_dir)`

Wrapper-side cost story: today an orchestration wrapper tries to keep two panes against two repos in distinct handoff states, but the singleton row collapses one over the other on every write. Once multikey lands, per-pane handoff state maps cleanly to `(session_name, working_dir)` instead of needing a sidecar.

For-all-users angle: any ntm caller running multi-repo — anyone using `ntm assign --repo` from #123, anyone with git-worktree topology, anyone keeping per-project state — hits the same collapse. The issue body framed it through one wrapper but the contract gap is general.

Happy to keep the out-of-band-altered DB on this install and dogfood the upgrade once a real migration lands — comparing the backfill journal against the altered shape will surface any divergence cleanly.
