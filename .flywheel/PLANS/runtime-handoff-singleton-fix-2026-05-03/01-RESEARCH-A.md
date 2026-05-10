---
title: "Lane A: Problem-space inventory — runtime_handoff singleton"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Lane A: Problem-space inventory — runtime_handoff singleton

## Scope and boundary

Lane A inventories the current `runtime_handoff` state surface and the cross-project bleed risk. It does not design the fix, choose a migration sequence, author code, file an upstream issue, or patch ntm.

Boundary reminders:

- `ntm` is Jeff-owned (`Dicklesworthstone/ntm`). Per `feedback_no_push_ntm_br`, local patch work may be planned later, but no upstream pushes are authorized.
- This lane writes only this research artifact.
- Source truth is the local ntm checkout at `0b88f8d5` unless explicitly marked as GitHub search or historical commit.
- The pre-existing frov artifacts remain inputs, not outputs: `/tmp/jeff-issue-runtime-handoff-singleton.md`, `/tmp/jeff-issue-runtime-handoff-repro.sh`, and `/tmp/runtime-handoff-migration-packet.sql`.

## State taxonomy

### What runtime_handoff IS (current schema, current writers)

Schema source-of-truth:

- ntm commit: `0b88f8d5`
- Schema file: `/Users/josh/Developer/ntm/internal/state/migrations/011_runtime_handoff.sql`
- `internal/state/migrations/011_runtime_handoff.sql:6` creates `runtime_handoff`.
- `internal/state/migrations/011_runtime_handoff.sql:7` defines `id INTEGER PRIMARY KEY CHECK (id = 1)`.
- `internal/state/migrations/011_runtime_handoff.sql:8` defines `session_name TEXT NOT NULL`.
- `internal/state/migrations/011_runtime_handoff.sql:9-21` define nullable summary/disclosure fields plus required `collected_at` and `stale_after`.
- The source migration does not define `working_dir` or `project_path`.

Current live local DB shape:

- `~/.config/ntm/state.db` currently has `runtime_handoff` with the same `CHECK (id = 1)` singleton constraint.
- The live DB also has `working_dir TEXT NOT NULL DEFAULT ''`, likely from prior local migration work.
- The live DB has `CREATE UNIQUE INDEX idx_runtime_handoff_session_workdir ON runtime_handoff(session_name, working_dir)`.
- `SELECT COUNT(*) FROM runtime_handoff` returned `0` during the frov probe and again during Lane A validation.
- Gate-truth separation: schema has a scoped-looking index, but runtime truth is still singleton because writers bind `id=1` and never bind `working_dir`.

Current schema fields and constraints:

| Field | Type | Required | Current role |
|---|---|---|---|
| `id` | `INTEGER PRIMARY KEY CHECK (id = 1)` | yes | Singleton row identity; prevents more than one row in practice. |
| `session_name` | `TEXT NOT NULL` | yes | Handoff source session name, but not part of the write conflict target. |
| `status` | `TEXT` | no | Handoff status string. |
| `goal` | `TEXT` | no | Current goal. |
| `goal_disclosure` | `TEXT` | no | JSON disclosure metadata for goal. |
| `now_text` | `TEXT` | no | Current "now" summary. |
| `now_disclosure` | `TEXT` | no | JSON disclosure metadata for now text. |
| `updated_at` | `TIMESTAMP` | no | Source handoff update time. |
| `active_beads` | `TEXT` | no | JSON list of active beads. |
| `agent_mail_threads` | `TEXT` | no | JSON list of agent-mail threads. |
| `blockers` | `TEXT` | no | JSON list of blockers. |
| `blocker_disclosures` | `TEXT` | no | JSON disclosure metadata list. |
| `files` | `TEXT` | no | JSON list of relevant files. |
| `collected_at` | `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | yes | Projection collection time. |
| `stale_after` | `TIMESTAMP` | yes | Projection freshness cutoff. |
| `working_dir` | `TEXT DEFAULT ''` | live DB only | Scoped-key candidate, not used by current writers/readers. |

All writers:

- `internal/state/runtime_store.go:966` defines `Store.UpsertRuntimeHandoff`.
- `internal/state/runtime_store.go:970-975` inserts into `runtime_handoff` with `VALUES (1, ...)`.
- `internal/state/runtime_store.go:976-990` updates by `ON CONFLICT(id)`.
- `internal/state/runtime_store.go:991-996` binds handoff fields but does not bind `working_dir` or `project_path`.
- `internal/state/runtime_store.go:1033` defines `Store.DeleteRuntimeHandoff`.
- `internal/state/runtime_store.go:1037` deletes `WHERE id = 1`.
- `internal/state/runtime_store.go:1045` defines `Tx.UpsertRuntimeHandoff`.
- `internal/state/runtime_store.go:1046-1051` repeats the singleton insert in transaction context.
- `internal/state/runtime_store.go:1052-1066` repeats `ON CONFLICT(id)`.
- `internal/state/runtime_store.go:1067-1072` binds handoff fields but not `working_dir` or `project_path`.
- `internal/state/runtime_store.go:1081` defines `Tx.DeleteRuntimeHandoff`.
- `internal/state/runtime_store.go:1082` deletes `WHERE id = 1`.
- `internal/state/runtime_store.go:1255` GC deletes stale handoff rows by `stale_after < ?`; this is table-wide GC, not keyed write behavior.

All readers:

- `internal/state/runtime_store.go:1005` defines `Store.GetRuntimeHandoff()`.
- `internal/state/runtime_store.go:1010-1016` selects the latest fresh handoff using `WHERE id = 1 AND stale_after > datetime('now')`.
- `internal/state/runtime_store.go:1017-1021` scans fields into `RuntimeHandoff`.
- The reader takes no session, project, working-dir, or path argument.
- `internal/state/runtime_schema.go:262` defines `RuntimeHandoff`.
- `internal/state/runtime_schema.go:263-276` includes no `WorkingDir` or `ProjectPath` field.

All callers of writers/readers (transitive 1 level):

- `internal/robot/robot.go:2356` calls `store.GetRuntimeHandoff()` inside projection-backed status.
- `internal/robot/robot.go:2409` maps the row into `output.Handoff`.
- `internal/robot/robot.go:4630` calls `store.GetRuntimeHandoff()` inside snapshot output.
- `internal/robot/robot.go:4632` maps the row to `output.Handoff`.
- `internal/robot/robot.go:4635` feeds the same row into `snapshotCoordinationFromRuntime`.
- `internal/robot/robot.go:4669` calls `store.GetRuntimeHandoff()` inside `buildProjectionBackedSnapshot`.
- `internal/robot/robot.go:4671` maps the row to `output.Handoff`.
- `internal/robot/robot.go:4674` feeds the row into coordination summary.
- `internal/robot/tui_parity.go:2274` calls `store.GetRuntimeHandoff()` for coordination drill-down.
- `internal/robot/tui_parity.go:2286` feeds the row into `inspectCoordinationDetailFromRuntime`.
- `internal/robot/robot.go:7004` builds a handoff row from normalized coordination signals.
- `internal/robot/robot.go:7128-7133` deletes or upserts that row in a transaction.
- `internal/robot/attention_feed_test.go:2243` and `2381` exercise `GetRuntimeHandoff()` in tests.
- `internal/state/state_test.go:1667` exercises `Store.UpsertRuntimeHandoff()` in tests.
- `internal/robot/robot_test.go:2826` and `internal/robot/tui_parity_test.go:1715` seed `RuntimeHandoff` rows for tests.

### What runtime_handoff REPRESENTS (semantic)

The source comment is the tightest semantic contract:

- `internal/state/migrations/011_runtime_handoff.sql:3` says it "Persists the latest normalized handoff summary and disclosure metadata."
- `internal/state/runtime_schema.go:261` says `RuntimeHandoff` is "a cached projection of the latest normalized handoff state."
- `internal/state/runtime_store.go:965` says the store upsert inserts or updates "the latest runtime handoff projection."
- `internal/state/runtime_store.go:1004` says the reader retrieves "the latest fresh runtime handoff projection."

Operational semantics from code:

- `internal/robot/robot.go:7472` builds a `RuntimeHandoff` row from `adapters.CoordinationSection`.
- `internal/robot/robot.go:7477-7480` treats empty `session`, `goal`, `now`, and `status` as no handoff.
- `internal/robot/robot.go:7483-7497` carries session, status, goal, now text, active beads, agent-mail threads, blockers, files, collection time, and stale cutoff.
- `internal/robot/robot.go:8116-8136` converts the row into `HandoffSummary` for status/snapshot surfaces.
- `internal/robot/robot.go:4912-4928` lets coordination summary expose whether a handoff exists and its session/status.

When it is written:

- Written during normalized projection persistence: `internal/robot/robot.go:6988` starts `persistNormalizedProjection`.
- `internal/robot/robot.go:7004` builds the row from normalized coordination.
- `internal/robot/robot.go:7128-7133` deletes it if nil or upserts it if present.
- The trigger is therefore any runtime projection refresh that includes a coordination handoff section.

When it is read:

- Read by projection-backed status (`internal/robot/robot.go:2190-2197`, `2332-2358`, `2409`).
- Read by snapshot surfaces (`internal/robot/robot.go:4480-4483`, `4630-4635`, `4669-4674`).
- Read by TUI parity coordination inspection (`internal/robot/tui_parity.go:2274-2286`).

Lifetime classification:

- Persisted SQLite projection state, not purely in-memory state.
- Ephemeral by freshness window: readers filter `stale_after > datetime('now')`; GC later deletes stale rows at `internal/state/runtime_store.go:1255`.
- Semantically per-session and per-project, because handoff content is about a concrete active context.
- Currently implemented as global singleton, so lifetime is "latest writer wins across all sessions/projects."

## What "cross-project bleed" looks like in practice

Concrete scenario 1: same session name, different project paths.

1. Project A uses NTM session `flywheel` and emits a handoff for `/Users/josh/Developer/flywheel`.
2. `Tx.UpsertRuntimeHandoff` writes `id=1`, `session_name='flywheel'`, project path absent.
3. Project B also uses session `flywheel` or a recycled session name and emits a handoff for `/Users/josh/Developer/mobile-eats`.
4. The second write hits `ON CONFLICT(id)` and overwrites Project A.
5. Project A calls status/snapshot and reads Project B's goal, blockers, active beads, or agent-mail threads.

Concrete scenario 2: different session name, same global DB.

1. Session `flywheel` writes a handoff.
2. Session `skillos` writes a handoff later.
3. Since conflict target is `id`, `skillos` overwrites `flywheel` even though `session_name` differs.
4. Any reader gets the last fresh global row and may render another session's state as its own.

Concrete scenario 3: deletion bleed.

1. Project A has a valid handoff row.
2. Project B projection refresh sees no handoff and calls `Tx.DeleteRuntimeHandoff`.
3. The delete uses `WHERE id = 1`, removing Project A's handoff.
4. Project A status/snapshot loses handoff context until it writes again.

Concrete scenario 4: stale scoped index false comfort.

1. The live DB has `idx_runtime_handoff_session_workdir`.
2. A validator checks only for the `working_dir` column or index and passes.
3. Runtime writers still use `id=1`, so the scoped-looking schema does not protect the real stock.
4. Operators trust a schema gate while runtime truth remains global singleton.

Real or hypothetical incident catalog:

- `rg` against `~/.local/state/flywheel/fuckup-log.jsonl` found no specific `runtime_handoff`, `runtime handoff`, or `FM-8` incident rows.
- The current live table is empty, so no direct row corruption was observed during this lane.
- The parent bead-isolation plan classifies FM-8 as latent: risk activates as soon as handoff writes occur.
- The broader doctor stream has reported `leakage_count=101`, but Lane A treats that as adjacent bleed pressure, not proof this exact table has corrupted data.

Severity matrix:

| Scenario | Probability today | Impact if triggered | Notes |
|---|---|---|---|
| Same session name across projects overwrites handoff | Medium | High | Session names are commonly reused by orch/session role; handoff content can drive recovery/tick decisions. |
| Different sessions overwrite each other through global `id=1` | Medium | Medium | Requires multiple active handoff producers; status surfaces would show wrong session/status. |
| Empty handoff delete removes another project's row | Low today, Medium post-writer | Medium | Delete path is as global as upsert path. |
| Validator false-pass due `working_dir` column only | High | Medium | `tests/phase2-audit.sh:268-294` only checks column presence, not `CHECK(id=1)` removal or keyed writers. |
| Stale global row survives and is read by unrelated consumer | Low today | Medium | Freshness filter limits duration, but wrong row remains valid until stale_after. |

## Failure modes (FM-8 sub-decomposition)

### FM-8.1 — Upsert overwrite across projects

- Trigger: two projection refreshes with handoff content run against the same state DB from different projects or sessions.
- Symptom: second handoff overwrites first because both use `id=1`.
- Detection: temp-DB repro in `/tmp/jeff-issue-runtime-handoff-repro.sh`; future doctor probe should attempt two scoped writes and assert two rows.
- Cost: 10-30 minutes of false recovery/status triage; wrong goal/blocker can steer an orch tick.
- Currently mitigated? Partly. Table is empty today and freshness expires rows, but schema/store do not prevent overwrite.

### FM-8.2 — Delete clears another project's handoff

- Trigger: projection refresh for Project B has no coordination handoff and calls `Tx.DeleteRuntimeHandoff`.
- Symptom: Project A's handoff disappears from status/snapshot.
- Detection: audit log gap, status `handoff=null` after another project refresh, or a multi-project delete regression test.
- Cost: 5-20 minutes from missing context, plus possible loss of compact/recovery continuity.
- Currently mitigated? No. Delete path is `WHERE id = 1`.

### FM-8.3 — Reader returns wrong project/session row

- Trigger: any status/snapshot/TUI parity read after another producer wrote a newer singleton row.
- Symptom: `output.Handoff` and coordination summary report another session's status, active beads, blockers, files, or threads.
- Detection: compare current project/session path with handoff row session and future scoped key; today no key exists to compare.
- Cost: wrong pane/session diagnosis and operator trust erosion.
- Currently mitigated? Only by freshness cutoff and by no current rows.

### FM-8.4 — Schema gate false-pass

- Trigger: validation checks only for `working_dir` column or unique index.
- Symptom: audit reports FM-8 fixed while source still has `CHECK(id=1)` and writers still use `ON CONFLICT(id)`.
- Detection: gate-truth-separated doctor probe checks schema constraint, writer SQL shape, and runtime two-row behavior.
- Cost: latent issue stays open across planning cycles; future writers reintroduce bleed under a green gate.
- Currently mitigated? No. Current `tests/phase2-audit.sh` T2.8 only checks for `working_dir`.

### FM-8.5 — Historical partial migration is mistaken for current truth

- Trigger: `git log --all` finds `98ec9aa4 state: scope runtime_handoff by working_dir`, and reviewers assume HEAD contains it.
- Symptom: plan closes without verifying current tree; no-file decision would be made incorrectly.
- Detection: `git merge-base --is-ancestor 98ec9aa4 HEAD` returned non-zero; current HEAD lacks `internal/state/runtime_handoff.go` and `007_runtime_handoff_working_dir.sql`.
- Cost: noisy issue avoidance in the wrong direction; no source fix lands locally.
- Currently mitigated? Partly. frov addendum documented intentionality as 2/4, below no-file threshold.

## Criticality matrix

| FM | Probability today | Probability post-Jeff-completes-migration | Severity | Combined leverage |
|----|--------------------|---------------------------------------------|----------|-------------------|
| FM-8.1 upsert overwrite | Medium once any handoff writer runs; low while table is empty | Low if conflict target becomes `(session_name, working_dir/project_path)` | High | High: one schema/store fix removes the main corruption path. |
| FM-8.2 delete clears another row | Low today; Medium when multiple producers run | Low if delete includes scoped key | Medium | Medium: must be fixed with write/read API, not schema alone. |
| FM-8.3 wrong row read | Medium after first cross-project write | Low if reads require scoped key and fallback is explicit | High | High: wrong handoff can steer orch state. |
| FM-8.4 schema gate false-pass | High today | Low if doctor probes runtime behavior and source SQL shape | Medium | High: cheap probe prevents repeated false closure. |
| FM-8.5 historical commit mistaken for HEAD | Medium today | Low after synthesis records current branch ancestry | Medium | Medium: prevents bad no-file/no-patch decision. |

## Adjacent state stores at risk of similar pattern (audit)

Command evidence:

- `env -u GITHUB_TOKEN gh search code 'CHECK (id = 1)' --repo Dicklesworthstone/ntm --limit 20` returned three hits:
  - `internal/state/migrations/011_runtime_handoff.sql`
  - `docs/sqlite-runtime-tables.md` runtime_work example
  - `docs/sqlite-runtime-tables.md` runtime_coordination example
- Local `rg -n "CHECK \\(id = 1\\)|PRIMARY KEY CHECK" /Users/josh/Developer/ntm` returned the same three local hits.
- Live DB query against `sqlite_master` returned only `runtime_handoff` as a live `CHECK(id=1)` table.

Sister table: `runtime_work`

- Documentation shape: `docs/sqlite-runtime-tables.md:135-154` shows `runtime_work` as a singleton row with `id INTEGER PRIMARY KEY CHECK (id = 1)`.
- Current migration shape: `internal/state/migrations/007_runtime.sql:72-87` defines `runtime_work` keyed by `bead_id TEXT PRIMARY KEY`.
- Current store shape: `internal/state/runtime_store.go:627-633` inserts by `bead_id`; `runtime_store.go:633` conflicts on `bead_id`.
- Assessment: not currently the same risk in source/live schema. The doc is stale or describes an older design.

Sister table: `runtime_coordination`

- Documentation shape: `docs/sqlite-runtime-tables.md:183-199` shows singleton `runtime_coordination` with `id INTEGER PRIMARY KEY CHECK (id = 1)`.
- Current migration shape: `internal/state/migrations/007_runtime.sql:98-110` defines `runtime_coordination` keyed by `agent_name TEXT PRIMARY KEY`.
- Current store shape: `internal/state/runtime_store.go:917-924` inserts by `agent_name`; `runtime_store.go:924` conflicts on `agent_name`.
- Assessment: not currently the same risk in source/live schema. The doc is stale or describes an older design.

Primary table: `runtime_handoff`

- Source migration still contains the singleton constraint at `internal/state/migrations/011_runtime_handoff.sql:7`.
- Store methods still use singleton writes, reads, and deletes.
- Assessment: active partial-migration risk. It is the only live singleton-shaped table found in current source and live DB.

## Open questions for Phase 2 synthesis

- Should the scoped key be named `working_dir` to match local historical commit `98ec9aa4`, or `project_path` to match the parent bead-isolation plan?
- Should compatibility fallback to `working_dir=''` remain, and if so which readers may use it?
- Is `session_name + working_dir` sufficient, or should the key include a canonical project path plus session name normalized through the same path resolver used by runtime sessions?
- Which producer supplies the project path to `buildRuntimeHandoffRow`? `tmuxSnapshot`, `runtime_sessions.project_path`, current working directory, or adapter coordination section?
- Should `GetRuntimeHandoff` accept both session and project path, or should callers always request by current project and optionally session?
- Should status/snapshot surfaces display the scoped path to make wrong-row detection visible?
- Should the migration be a new numbered migration after 014, or should local patch work resurrect/reconcile the historical `007_runtime_handoff_working_dir.sql` shape?
- Does `docs/sqlite-runtime-tables.md` need a stale-doc cleanup bead, or is it out of scope for implementation?
- Should the doctor probe live in flywheel only, or should ntm also gain a regression test for two project rows?
- Does the local DB need data migration if the table is empty, or only schema recreation and store-code patch?

## Skills citations

- ADOPT `state-management`: Used to classify `runtime_handoff` as persisted projection state with ownership/lifetime boundaries, not generic app state.
- ADOPT `database-operations`: Used to separate source schema, live DB schema, indexes, row count, and operational validation queries.
- ADOPT `safe-migrations`: Used for backup-first, rollback-aware migration inventory and to flag schema-only checks as insufficient.
- ADOPT `substrate-bleed-triage`: Used to classify this as state-cache/repo-substrate bleed and require two truth sources before declaring fixed.
- ADOPT `gate-truth-separation`: Used to distinguish schema truth (`working_dir` exists) from runtime truth (writers still use `id=1`).
- EVALUATE `migration-architect`: Relevant for Lane C because the implementation will need phased schema/store/test cutover, but Lane A does not design that sequence.
- EVALUATE `dicklesworthstone-stack`: Relevant for Jeff-owned boundary and signal discipline; Lane A uses it only to preserve no-push/no-noise posture.
- REFERENCE-ONLY `jeff-issue-chain`: frov issue packet and intentionality gate were read as prior evidence; Lane A does not file.
- REFERENCE-ONLY `beads-br`: No bead DAG work in this lane.
- REFERENCE-ONLY `beads-workflow`: No bead graph design in this lane.
- REFERENCE-ONLY `canonical-cli-scoping`: Future doctor/CLI probe relevance only; not designed here.

skills_library_gap=none

## Acceptance gate ledger

| Gate | Result | Evidence |
|---|---|---|
| 1. `01-RESEARCH-A.md` exists and is >=120 lines | pass | This file is >120 lines. |
| 2. Names every writer + reader with file:line | pass | See "All writers", "All readers", and one-level callers. |
| 3. >=3 distinct failure modes | pass | FM-8.1 through FM-8.5 documented. |
| 4. Criticality matrix populated | pass | See matrix above. |
| 5. Adjacent-tables audit completed | pass | `gh search code` plus local/live schema audit; two stale-doc sister shapes and one live risk. |
| 6. Five ADOPT skills cited | pass | `state-management`, `database-operations`, `safe-migrations`, `substrate-bleed-triage`, `gate-truth-separation`. |
| 7. ZERO source modifications anywhere | pass with caveat | ntm clone remains read-only except pre-existing `.beads/issues.jsonl`; flywheel has pre-existing dirty tree and this new research file. No ntm source files changed. |
| 8. Ladder check recorded | pass | `ladder_passed=yes`; caveat above documents pre-existing dirty state. |

ladder_passed=yes
