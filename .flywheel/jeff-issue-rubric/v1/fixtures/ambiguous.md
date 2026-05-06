# runtime_handoff singleton overwrites scoped handoff state

**What happened:** Dicklesworthstone/ntm@0b88f8d5 still writes runtime handoff
state as a singleton, so two working directories in the same session overwrite
the same snapshot row.

**Repro:**
```bash
/tmp/jeff-runtime-handoff-repro.sh
```

**Expected vs observed:**
```diff
- project B handoff overwrites project A
+ project A and project B keep separate current handoff snapshots
```

**File:line citations:**
- `internal/state/migrations/011_runtime_handoff.sql:6` creates `runtime_handoff`.
- `internal/state/migrations/011_runtime_handoff.sql:7` pins `id` with `CHECK (id = 1)`.
- `internal/state/runtime_store.go:970` starts the singleton upsert.
- `internal/state/runtime_store.go:975` writes `VALUES (1, ...)`.
- `internal/state/runtime_store.go:1016` reads with `WHERE id = 1`.
- `internal/state/runtime_schema.go:262` has no working-directory field.

**Why this matters / cost citation:** Flywheel runs multiple repos through the
same session name; a current snapshot that bleeds across projects can make one
repo consume another repo's handoff and silently recover the wrong context.

**Prior art, not prescription:** The older `98ec9aa4` branch shaped this as
`working_dir`; that is useful context, not an implementation ask. The fix should
follow your current state model.

**Tracking:** Tracking on flywheel side: bead `flywheel-frov`.

**Duplicate search:** `gh issue list --repo Dicklesworthstone/ntm --search
"runtime_handoff singleton working_dir" --limit 20` returned no visible
duplicate.

**Out of scope:** Not asking for a feature, not submitting a PR, and not asking
you to adopt our local field name. This is only the scoped snapshot contract
violation.
