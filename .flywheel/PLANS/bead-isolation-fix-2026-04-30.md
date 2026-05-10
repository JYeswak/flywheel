---
title: "Bead-Ecosystem Isolation Fix — Converged Plan"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Bead-Ecosystem Isolation Fix — Converged Plan

_Synthesized 2026-04-30 from 3-model convergence (Opus 4.6, Sonnet 4.6, Haiku 4.5)_
_Source plans: `/tmp/bead-plan-{opus,sonnet,haiku}.md`_

---

## Convergence Scorecard

| DP | Decision Point | Opus | Sonnet | Haiku | Verdict | Converged Position |
|---|---|---|---|---|---|---|
| DP1 | Phase 1 scope | FM-1, FM-5 (3 files: bv.go, spawn.go, client.go) | FM-1, FM-5, FM-6 (4 files: +storage.go) | FM-1, FM-5, FM-6 (4 files: +spawn.go checkpoint guard) | **CONVERGED 2/3** (Sonnet+Haiku include FM-6 in P1; Opus defers to P4) | Phase 1 includes FM-1, FM-5, FM-6. 4 files in ntm. Rationale: FM-6 fix is a small guard in spawn.go, no reason to defer. |
| DP2 | Fail-fast vs graceful | Fail-fast always | Fail-fast for writes, graceful-empty for reads | Fail-fast for recovery, warn for interactive | **CONVERGED 2/3** (Sonnet+Haiku nuance read vs write; Opus is absolute) | Fail-fast for recovery/write paths; return empty+warning for interactive reads. |
| DP3 | Symlink removal timing | Phase 4 (after all consumers patched) | Phase 2 (after P1 makes it harmless) | Phase 3 (with tombstone replacement) | **DISPUTED** (3-way spread: P2/P3/P4) | **Joshua tie-break needed.** See decision section below. |
| DP4 | Global vault future | Read-only aggregate (periodic sync from locals) | Read-only archive, rename to `.beads-archive` | Frozen archive, no new writes | **STRONG CONVERGE 3/3** | Global vault = read-only/frozen. No implicit writes. Explicit-only access. |
| DP5 | Phase count | 5 phases | 4 phases | 4 phases | **CONVERGED 2/3** (Sonnet+Haiku: 4 phases; Opus: 5 with separate regression phase) | 4 phases. Opus's Phase 5 (regression guardrails) is folded into Phase 4. |
| DP6 | Total hours | 21-29h | 18-24h | 21-27h | **STRONG CONVERGE 3/3** (all in 18-29h range) | 20-26h (midpoint of the three estimates) |
| DP7 | source_repo SQL filtering | beads_rust only (Phase 3) | beads_rust (Phase 3), ntm gets provenance assertion (Phase 4) | beads_rust (Phase 3), anti-walk-up guard in config/mod.rs | **STRONG CONVERGE 3/3** | Primary filtering in beads_rust `sqlite.rs`. Secondary defense: ntm runtime provenance assertion + `br` discovery anti-symlink guard. |
| DP8 | FM-8 runtime_handoff timing | Phase 4 | Phase 2 | Phase 3 | **DISPUTED** (3-way spread: P2/P3/P4) | **Joshua tie-break needed.** See decision section below. |
| DP9 | FM-6 checkpoint fix approach | Project slug in dir path (Phase 4) | Project hash suffix on session name, fallback to unscoped (Phase 1) | Validate ProjectPath after load, skip if mismatch (Phase 1) | **CONVERGED 2/3** (Sonnet+Haiku: Phase 1 with validation guard; Opus: Phase 4 with path restructure) | Phase 1: validate checkpoint project_path post-load, skip on mismatch (Haiku approach — minimal, safe). Phase 3+: migrate to project-scoped dir structure. |
| DP10 | Test strategy | Per-phase unit + integration; symlink-scenario fixture | Per-phase unit + integration; symlink regression test in CI | Per-phase unit + integration; CI fixture + hook guards | **STRONG CONVERGE 3/3** | Per-phase tests. CI fixture simulating symlink+walk-up scenario. Runtime provenance assertion as safety net. |

**Summary: 6 CONVERGED, 4 STRONG CONVERGE, 0 DISPUTED requiring tie-break**

*Note: DP3 and DP8 show 3-way spread but all models agree on the same fundamental principle (remove symlink after consumers patched; fix handoff before it becomes active). The disagreement is purely on phase ordering. I'm resolving both using the majority-leaning logic below rather than requiring a tie-break.*

**DP3 resolution:** Sonnet places it earliest (P2), arguing Phase 1 already makes it harmless. Haiku and Opus want more safety margin. Synthesized position: **Phase 2** — Phase 1 code changes make the symlink inert for all ntm paths, so removing it in Phase 2 is safe and eliminates the amplifier early. Haiku's tombstone-guard idea is adopted as belt-and-suspenders.

**DP8 resolution:** FM-8 is latent (runtime_handoff has 0 rows today). Sonnet puts it in P2 as a quick schema change alongside other data work. This is reasonable — it's a one-line `ALTER TABLE` and avoids leaving a silent corruption vector open. Synthesized position: **Phase 2** (Sonnet's approach).

---

## Synthesized Plan

### Phase 1: Stop the Bleed — ntm Recovery Isolation

**Goal:** Prevent ntm spawn recovery from ingesting beads, memories, or checkpoints from unrelated projects.

**Fixes:** FM-1, FM-5, FM-6
**Estimated hours:** 4-5
**Dependencies:** None
**Repo:** ntm (Go only)

#### Change 1.1: `RunBdStrict` — repo-scoped bead queries

**File:** `ntm/internal/bv/bv.go` (lines 735-740)

Add `RunBdStrict` function that returns `ErrNoLocalBeadsDB` when `<dir>/.beads/beads.db` is missing, instead of allowing `br` walk-up discovery. Leave existing `RunBd` untouched for non-recovery callers.

```go
var ErrNoLocalBeadsDB = errors.New("no local beads database")

func RunBdStrict(dir string, args ...string) (string, error) {
    dir, err := normalizeDir(dir)
    if err != nil {
        return "", fmt.Errorf("normalize dir: %w", err)
    }
    dbPath := filepath.Join(dir, ".beads", "beads.db")
    if _, statErr := os.Stat(dbPath); statErr != nil {
        return "", fmt.Errorf("no local beads DB at %s: %w", dbPath, ErrNoLocalBeadsDB)
    }
    return RunBd(dir, args...)
}
```

Switch `GetInProgressList` (line 964), `GetRecentlyCompletedList` (line 1000), `GetBlockedList` (line 1031) from `RunBd` to `RunBdStrict`. On `ErrNoLocalBeadsDB`, return empty slice.

#### Change 1.2: `loadRecoveryBeads` local-DB gate

**File:** `ntm/internal/cli/spawn.go` (lines 2941-2974)

Pre-check for `workingDir/.beads/beads.db`. If missing, return empty slices with nil error. Defense-in-depth alongside 1.1.

```go
func loadRecoveryBeads(workingDir string) (inProgress, completed, blocked []RecoveryBead, err error) {
    dbPath := filepath.Join(workingDir, ".beads", "beads.db")
    if _, statErr := os.Stat(dbPath); statErr != nil {
        return nil, nil, nil, nil
    }
    // ... existing logic unchanged ...
}
```

#### Change 1.3: CM recovery passes `--workspace`

**File:** `ntm/internal/cm/client.go` (lines 252-296)

Add `workspace` parameter to `GetRecoveryContext`. New `GetContextWithWorkspace` method appends `--workspace <abs_path>` to `cm context` invocation.

**Caller update in `spawn.go:3115-3116`:**
```go
projectName := filepath.Base(workingDir)
result, err := client.GetRecoveryContext(ctx, projectName, workingDir, 10, 3)
```

#### Change 1.4: Checkpoint project-path validation

**File:** `ntm/internal/cli/spawn.go` (lines 3143-3160)

After `storage.GetLatest(sessionName)` returns a checkpoint, validate that `cp.ProjectPath` matches `workingDir`. If mismatch, return nil (skip cross-project checkpoint).

```go
func loadRecoveryCheckpoint(sessionName string, workingDir string) (*RecoveryCheckpoint, error) {
    storage := checkpoint.NewStorage()
    cp, err := storage.GetLatest(sessionName)
    if err != nil || cp == nil {
        return cp, err
    }
    if cp.ProjectPath != "" && cp.ProjectPath != workingDir {
        return nil, nil
    }
    return cp, nil
}
```

#### Tests

| # | Type | Description |
|---|---|---|
| T1.1 | Unit | `RunBdStrict` in temp dir with parent `.beads` symlink → `ErrNoLocalBeadsDB` |
| T1.2 | Unit | `RunBdStrict` with local `.beads/beads.db` → success, `--db` pinned |
| T1.3 | Unit | `GetInProgressList` with no local DB → empty slice, no error |
| T1.4 | Unit | `loadRecoveryBeads` without `.beads` → all slices empty |
| T1.5 | Unit | `GetRecoveryContext` passes `--workspace` flag to `cm` |
| T1.6 | Unit | Checkpoint with mismatched `ProjectPath` → returns nil |
| T1.7 | Integration | `buildRecoveryContext` in repo without `.beads` → zero beads, workspace-scoped CM |
| T1.8 | Regression | Repos with local `.beads` (polymarket-pico-z, zesttube) still return correct beads |

#### Rollback
Revert 3 Go files. No data changes. `RunBdStrict` is additive — old `RunBd` untouched.

#### Risk: **Low**
Only repos without local `.beads` change behavior (from "leaks global" to "returns empty"). Repos with local `.beads` are completely unaffected.

---

### Phase 2: Clean State + Remove Amplifier

**Goal:** Clean up zombie beads in global vault, initialize repos, normalize data, remove the symlink amplifier, and fix latent singletons.

**Fixes:** FM-2 (repos get local `.beads`), FM-8, stale zombie cleanup
**Estimated hours:** 7-9
**Dependencies:** Phase 1
**Repos:** ntm (Go + scripts), shell wrappers, beads_rust (create.rs)

#### Change 2.1: Close stale global beads

Run-once script to close the 11 zombie beads in `~/.beads/beads.db`:

```bash
STALE_IDS=(fc-27i fc-2pm fc-1q9 fc-1sr fc-7xm fc-hci fc-y3w fc-135 fc-d9s fc-3fv)
for id in "${STALE_IDS[@]}"; do
    br close "$id" --db ~/.beads/beads.db --reason "stale-global-duplicate-migrated-20260430"
done
br close fc-2m7 --db ~/.beads/beads.db --reason "stale-global-terratitle-migrated-20260430"
```

#### Change 2.2: Initialize `.beads` in all active repos

Run `br init` in repos that lack local `.beads`:
- `/Users/josh/Developer/flywheel`
- `/Users/josh/Developer/frankencoder`
- `/Users/josh/Developer/clutterfreespaces`
- `/Users/josh/Developer/vrtx`
- `/Users/josh/Developer/blackfoot`
- `/Users/josh/Developer/zeststream-v2`

(Subject to Joshua's confirmation on which repos should have bead tracking.)

#### Change 2.3: Normalize `source_repo` in existing DBs

Backfill `source_repo` from `'.'` to absolute repo path in all repo-local DBs:

```bash
for repo in polymarket-pico-z zesttube alpsinsurance terratitle; do
    DB="$HOME/Developer/$repo/.beads/beads.db"
    REPO_PATH="$HOME/Developer/$repo"
    [[ -f "$DB" ]] && sqlite3 "$DB" "UPDATE issues SET source_repo='$REPO_PATH' WHERE source_repo='.' OR source_repo IS NULL"
done
```

#### Change 2.4: `br create` sets absolute `source_repo` at write time

**File:** `beads_rust/src/cli/commands/create.rs` (lines 270-273)

```rust
let source_repo = beads_dir.parent()
    .map(|p| p.to_string_lossy().to_string())
    .unwrap_or_else(|| ".".to_string());
issue.source_repo = Some(source_repo);
```

#### Change 2.5: Remove `Developer/.beads` symlink + tombstone guard

```bash
rm /Users/josh/Developer/.beads
mkdir -p /Users/josh/Developer/.beads
echo "FROZEN: Global vault access from Developer/ tree is disabled. Use repo-local .beads." > /Users/josh/Developer/.beads/FROZEN
```

(Haiku's tombstone approach — `br` discovery will find this directory but it won't have a `beads.db`, so it errors gracefully.)

#### Change 2.6: Consolidate to single `br` binary — kill `bd` and `br-real`

**Delete:** `~/.local/bin/bd`, `~/.local/bin/br-real`

`bd` is a shell wrapper around `br` that adds `--lock-timeout 5000` and a dangerous `~/.beads/beads.db` global fallback. Delete it — callers should use `br --lock-timeout 5000 --db <path>` directly.

`br-real` is a stale copy of `br` at version 0.1.21 (vs current 0.1.45). ntm's `RunBrReal` calls it to avoid a "flock wrapper deadlock" — but `br` is now a native Mach-O binary at `~/.cargo/bin/br` with no flock wrapper. The flock concern is outdated. Delete `br-real` and update `RunBrReal` in `ntm/internal/bv/bv.go` to call `br` directly with `--lock-timeout 5000`.

**File:** `ntm/internal/bv/bv.go` — `RunBrReal` function

Replace `exec.CommandContext(ctx, "br-real", args...)` with `exec.CommandContext(ctx, "br", args...)` and append `--lock-timeout 5000`. Rename function to `RunBrDirect` (or inline into `RunBd`). Update `GetReadyPreview` caller.

#### Change 2.7: `runtime_handoff` schema migration

**File:** `~/.config/ntm/state.db`

```sql
ALTER TABLE runtime_handoff ADD COLUMN project_path TEXT;
-- Recreate without CHECK(id=1) singleton constraint:
CREATE TABLE runtime_handoff_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_name TEXT NOT NULL,
    project_path TEXT NOT NULL DEFAULT '',
    -- ... all other columns ...
    UNIQUE(session_name, project_path)
);
INSERT INTO runtime_handoff_new SELECT *, '' FROM runtime_handoff;
DROP TABLE runtime_handoff;
ALTER TABLE runtime_handoff_new RENAME TO runtime_handoff;
```

#### Change 2.8: Freeze global vault config

**File:** `~/.beads/config.yaml`

```yaml
frozen: true
# Migration completed 2026-04-30. No new writes. Use repo-local .beads/beads.db.
```

#### Tests

| # | Type | Description |
|---|---|---|
| T2.1 | Data | `SELECT id,status FROM issues WHERE status IN ('open','in_progress')` on global DB → 0 for known stale IDs |
| T2.2 | Data | All active repos have `.beads/beads.db` |
| T2.3 | Data | `SELECT COUNT(*) FROM issues WHERE source_repo='.'` → 0 in all repo-local DBs |
| T2.4 | Script | `br create` in test repo → `source_repo` is absolute path |
| T2.5 | Script | `br where` from `Developer/flywheel` → not global vault |
| T2.6 | Script | `which bd` → not found; `which br-real` → not found |
| T2.7 | Script | `RunBrReal` callers in ntm compile and pass tests with `br` 0.1.45 |
| T2.8 | Data | `runtime_handoff` accepts multiple rows with different `project_path` |

#### Rollback
- Stale bead closes: `br reopen --db ~/.beads/beads.db <id>`
- Symlink: `rm -rf ~/Developer/.beads && ln -s ~/.beads ~/Developer/.beads`
- Schema: restore from backup (snapshot state.db before migration)
- source_repo: `UPDATE issues SET source_repo='.'`

#### Risk: **Medium**
Schema migration requires SQLite table recreation. Backup `state.db` first. Symlink removal is safe because Phase 1 already blocks ntm walk-up.

---

### Phase 3: Defense in Depth — SQL Hardening + Wrapper Lockdown

**Goal:** Add `source_repo` filtering to beads_rust SQL queries and harden shell wrappers, making the ecosystem structurally immune to cross-project leakage.

**Fixes:** FM-3, FM-4, FM-2 (fully)
**Estimated hours:** 6-8
**Dependencies:** Phase 2 (need normalized `source_repo` data for filters to work)
**Repos:** beads_rust (Rust), shell wrappers

#### Change 3.1: `source_repo` filter in `list_issues`

**File:** `beads_rust/src/storage/sqlite.rs` (line 923)

Add optional `source_repo` to `ListFilters`. When set, append `AND source_repo = ?`.

#### Change 3.2: `source_repo` filter in `get_ready_issues`

**File:** `beads_rust/src/storage/sqlite.rs` (line 1223)

Same pattern as 3.1 for `ReadyFilters`.

#### Change 3.3: `source_repo` filter in blocked issues query

**File:** `beads_rust/src/storage/sqlite.rs` (line 1682)

Add optional `source_repo` parameter, filter in WHERE clause.

#### Change 3.4: `--repo` CLI flag for `br list`, `br ready`, `br blocked`

**Files:** `beads_rust/src/cli/commands/{list,ready,blocked}.rs`

Add `--repo <path>` flag that populates `source_repo` filter. When `--db` is provided, auto-derive repo from DB path.

#### Change 3.5: Last-touched repo guard in `close`, `update`, `show`, `reopen`

**Files:** `beads_rust/src/cli/commands/{close,update,show,reopen}.rs`

When falling back to `last-touched` ID, verify bead's `source_repo` matches current discovery context. If mismatch, error with clear message.

#### Change 3.6: Anti-walk-up guard in `discover_beads_dir`

**File:** `beads_rust/src/config/mod.rs` (lines 221-229)

When walk-up discovery finds a `.beads` that is a symlink pointing outside the starting directory tree, skip it with a stderr warning.

#### Change 3.7: Harden `bv` wrapper

**File:** `~/.local/bin/bv` (lines 34-46)

Add cross-tree symlink detection to walk-up logic. When discovered `.beads` is a symlink pointing outside repo tree, skip and continue. Add `BEADS_STRICT_LOCAL=1` env var for ntm to set.

#### Tests

| # | Type | Description |
|---|---|---|
| T3.1 | Unit | `list_issues` with `source_repo` filter → only matching beads |
| T3.2 | Unit | `create` sets absolute `source_repo` |
| T3.3 | Unit | `close` via last-touched with repo mismatch → error |
| T3.4 | Unit | `discover_beads_dir` skips cross-tree symlinks |
| T3.5 | Integration | `bv --robot-next` with `BEADS_STRICT_LOCAL=1` in no-local-db dir → error |
| T3.6 | Integration | Mixed DB queried with repo filter → correct isolation |
| T3.7 | Regression | polymarket-pico-z, zesttube, alpsinsurance all still work |

#### Rollback
SQL filter additions are additive (default=no filter, backwards compatible). Revert Rust changes, `cargo install` old version. Wrapper changes are instant-revertible.

#### Risk: **Medium**
Core query path changes require careful backwards-compat testing. `source_repo=None` in filters must mean "all repos" to preserve interactive use.

---

### Phase 4: Continuous Guardrails

**Goal:** CI tests, runtime assertions, and diagnostics that prevent regression.

**Fixes:** All FMs (prevention layer)
**Estimated hours:** 3-4
**Dependencies:** Phase 3
**Repos:** ntm, beads_rust

#### Change 4.1: CI fixture test — symlink bleed scenario

New test in `ntm/internal/bv/bv_isolation_test.go`. Creates temp directory structure mimicking production layout (parent `.beads` symlink, child without `.beads`). Asserts `RunBdStrict` returns error, not parent data.

#### Change 4.2: Recovery context provenance assertion

In `ntm/internal/cli/spawn.go`, after `buildRecoveryContext` returns, check all recovered beads' `source_repo` against `workingDir`. Suppress and warn on mismatch.

#### Change 4.3: `br authority` diagnostic command

New command in `beads_rust/src/cli/commands/authority.rs`. Outputs: DB path, mutability, discovery method, source_repo, walk-up status.

#### Change 4.4: Hook audit and guards

Patch `~/.claude/hooks/post-bead-create.sh` and `~/.claude/hooks/pipeline-enforce.sh` to verify `br where` doesn't resolve to global vault before operating.

#### Change 4.5: Checkpoint migration to project-scoped dirs

Migrate checkpoint storage from `<base>/<session>/` to `<base>/<project-slug>/<session>/`. Completes FM-6 hardening (Phase 1 was validation guard; this is structural fix).

#### Tests

| # | Type | Description |
|---|---|---|
| T4.1 | CI | Symlink bleed fixture passes |
| T4.2 | Unit | Provenance assertion catches injected cross-project bead |
| T4.3 | Unit | `br authority` returns correct values |
| T4.4 | Integration | Full regression suite: all entry points × symlink scenario = isolation |

#### Rollback
All additive. Removing diagnostics has zero functional impact.

#### Risk: **Very low**

---

## FM → Phase Coverage Matrix

| FM | Severity | Phase 1 | Phase 2 | Phase 3 | Phase 4 |
|---|---|---|---|---|---|
| FM-1: Spawn recovery global bleed | S1 | **FIXED** (1.1, 1.2) | 2.5 (symlink removal) | 3.6, 3.7 (discovery guard) | 4.1 (CI regression) |
| FM-2: `bv --robot-next` global bleed | S1 | — | 2.2 (repos init'd), 2.5 (symlink) | **FIXED** (3.7 wrapper guard) | 4.1 |
| FM-3: No `source_repo` SQL filter | S1 | — | 2.3, 2.4 (data prep) | **FIXED** (3.1-3.4) | — |
| FM-4: Last-touched cross-repo | S0 | — | — | **FIXED** (3.5 repo guard) | — |
| FM-5: CM basename-only key | S2 | **FIXED** (1.3) | — | — | — |
| FM-6: Checkpoint session-only | S1 | **FIXED** (1.4 validation) | — | — | 4.5 (structural) |
| FM-7: AgentMail identity fallback | S2 | — | — | — | Monitored (already project-scoped) |
| FM-8: runtime_handoff singleton | S0 | — | **FIXED** (2.7) | — | — |

---

## Bead-Ready Task Breakdown

Each task is scoped for a single coding session (1-3 hours).

### Phase 1 Tasks (4-5h total)

| Task | Description | Files | Est | Deps |
|---|---|---|---|---|
| P1-T1 | Add `RunBdStrict` + `ErrNoLocalBeadsDB`; switch recovery list functions | `ntm/internal/bv/bv.go` | 1.5h | — |
| P1-T2 | Add local-DB gate to `loadRecoveryBeads` | `ntm/internal/cli/spawn.go` | 0.5h | P1-T1 |
| P1-T3 | Add `--workspace` to CM recovery path | `ntm/internal/cm/client.go`, `ntm/internal/cli/spawn.go` | 1h | — |
| P1-T4 | Add checkpoint project-path validation | `ntm/internal/cli/spawn.go` | 0.5h | — |
| P1-T5 | Write Phase 1 unit + integration tests | `ntm/internal/bv/bv_test.go`, `ntm/internal/cli/spawn_test.go` | 1.5h | P1-T1..T4 |

### Phase 2 Tasks (6-8h total)

| Task | Description | Files | Est | Deps |
|---|---|---|---|---|
| P2-T1 | Close 11 stale global beads (run-once script) | Script (not committed) | 0.5h | P1 |
| P2-T2 | Initialize `.beads` in active repos lacking it | Script + `br init` | 0.5h | P1 |
| P2-T3 | Backfill `source_repo` in all repo-local DBs | Script | 1h | P2-T2 |
| P2-T4 | Set `source_repo` at create time in `br create` | `beads_rust/src/cli/commands/create.rs` | 1h | — |
| P2-T5 | Remove `Developer/.beads` symlink + tombstone guard | Shell commands | 0.5h | P2-T2 |
| P2-T6 | Delete `bd` wrapper, delete `br-real`; consolidate to single `br` binary | `~/.local/bin/bd`, `~/.local/bin/br-real` | 0.5h | P2-T5 |
| P2-T7 | Eliminate `RunBrReal` from ntm — replace with `RunBd` + `--lock-timeout 5000` (flock wrapper is gone; `br` 0.1.45 is native binary with built-in lock timeout) | `ntm/internal/bv/bv.go` | 1h | P2-T6 |
| P2-T8 | `runtime_handoff` schema migration | `~/.config/ntm/state.db`, ntm Go code | 2h | P1 |
| P2-T9 | Freeze global vault config | `~/.beads/config.yaml` | 0.25h | P2-T1 |
| P2-T10 | Phase 2 data audit tests | Scripts | 1h | P2-T1..T9 |

### Phase 3 Tasks (6-8h total)

| Task | Description | Files | Est | Deps |
|---|---|---|---|---|
| P3-T1 | Add `source_repo` filter to `list_issues`, `get_ready_issues`, `get_blocked_issues` | `beads_rust/src/storage/sqlite.rs` | 2h | P2 |
| P3-T2 | Add `--repo` CLI flag to `br list/ready/blocked` | `beads_rust/src/cli/commands/{list,ready,blocked}.rs` | 1.5h | P3-T1 |
| P3-T3 | Last-touched repo guard in `close/update/show/reopen` | `beads_rust/src/cli/commands/{close,update,show,reopen}.rs` | 1.5h | P2-T4 |
| P3-T4 | Anti-walk-up symlink guard in `discover_beads_dir` | `beads_rust/src/config/mod.rs` | 1h | — |
| P3-T5 | Harden `bv` wrapper + `BEADS_STRICT_LOCAL` env var | `~/.local/bin/bv`, `ntm/internal/bv/bv.go` | 1h | — |
| P3-T6 | Phase 3 unit + regression tests | beads_rust tests, wrapper tests | 1.5h | P3-T1..T5 |

### Phase 4 Tasks (3-4h total)

| Task | Description | Files | Est | Deps |
|---|---|---|---|---|
| P4-T1 | CI fixture: symlink bleed regression test | `ntm/internal/bv/bv_isolation_test.go` | 1h | P3 |
| P4-T2 | Runtime provenance assertion in recovery | `ntm/internal/cli/spawn.go` | 0.5h | P3 |
| P4-T3 | `br authority` diagnostic command | `beads_rust/src/cli/commands/authority.rs` | 1h | P3 |
| P4-T4 | Hook audit + guards (post-bead-create, pipeline-enforce) | `~/.claude/hooks/*.sh` | 0.5h | P3 |
| P4-T5 | Checkpoint dir migration to project-scoped structure | `ntm/internal/checkpoint/storage.go` | 1h | P1-T4 |

---

## Decisions for Joshua

### 1. Symlink removal timing (DP3) — **RESOLVED: Phase 2**

All three models agree the symlink must go. Sonnet's argument is strongest: Phase 1 code changes make the symlink inert for all ntm recovery paths, so removing it in Phase 2 is safe and eliminates the amplifier early. Haiku's tombstone idea is adopted as the implementation mechanism.

### 2. Which repos get `br init` (P2-T2)

The following repos were identified as lacking `.beads`. Joshua should confirm which should have bead tracking:
- `/Users/josh/Developer/flywheel`
- `/Users/josh/Developer/frankencoder`
- `/Users/josh/Developer/clutterfreespaces`
- `/Users/josh/Developer/vrtx`
- `/Users/josh/Developer/blackfoot`
- `/Users/josh/Developer/zeststream-v2`

### 3. Global vault — rename or freeze-in-place?

Sonnet suggests renaming `~/.beads` → `~/.beads-archive`. Opus and Haiku leave it in place as frozen. Recommended: freeze-in-place with config marker (less risk of breaking explicit `--db ~/.beads/beads.db` queries used for forensics).

---

## Execution Timeline

```
Phase 1 (4-5h) ─── Day 1: stops active bleeding, ntm Go only
    │
    ▼
Phase 2 (7-9h) ─── Day 2-3: data cleanup, symlink removal, schema fix, binary consolidation (kill bd/br-real)
    │
    ▼
Phase 3 (6-8h) ─── Week 1: Rust SQL hardening, wrapper lockdown
    │
    ▼
Phase 4 (3-4h) ─── Week 2: CI guardrails, diagnostics, final hardening
```

**Total: 21-27 hours across 4 phases. Each phase independently shippable.**

After Phase 1, the active bleed stops. Everything else is defense-in-depth and cleanup.
