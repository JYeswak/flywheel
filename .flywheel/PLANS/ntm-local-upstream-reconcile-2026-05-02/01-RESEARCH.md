# NTM Reconcile Research

Mode: read-only research. Commands used: `git status`, `git log`, `git show`, `git diff`, `git branch`, file reads, and Socraticode search. No git mutation was performed.

## Current State Observed

Prompt state:

- Local `HEAD`: `5bbcaf7c Scope checkpoint dirs by project slug`
- Upstream named target: `65602811 fix(config,cli): wire [coordinator] section... (#111)`
- Five named local commits.
- Three named upstream commits.

Live repo state:

```text
main 5bbcaf7c [origin/main: ahead 63, behind 521]
merge-base HEAD origin/main = 158436b58d2e935fc726e79947851c03f8fcfd6a
origin/main = 65602811
```

Finding: the named commits are correct, but ancestry is materially more divergent than "5 local vs 3 upstream." The runbook must start with a backup and an ahead/behind preflight, then use a branch overlay rather than blind rebase/merge.

## Local Commits: Diff Research

### `ccb68356 fix(bv): set BEADS_STRICT_LOCAL=1 for all br/br-real invocations`

Stat:

```text
internal/bv/bv.go | 2 ++
1 file changed, 2 insertions(+)
```

Files:

- `internal/bv/bv.go`

Intent:

- Add `BEADS_STRICT_LOCAL=1` to both `RunBrReal` and `RunBd`.
- Prevent `br` discovery from walking up to parent `.beads`.
- Addresses cross-project bead contamination.

Preserve invariant:

- Every NTM invocation of `br`/beads must set strict local mode.

### `f199a69f refactor(bv): remove RunBrReal, consolidate to single br binary`

Stat:

```text
internal/bv/bv.go | 47 +----------------------------------------------
1 file changed, 1 insertion(+), 46 deletions(-)
```

Files:

- `internal/bv/bv.go`

Intent:

- Remove `RunBrReal`.
- Use `RunBd` for `GetReadyPreview`.
- Consolidate onto single `br` binary after local br wrapper/br-real split was retired.

Preserve invariant:

- `RunBrReal` should remain absent.
- BV readers should use `RunBd`, which passes explicit `--db` and strict local env.

### `98ec9aa4 state: scope runtime_handoff by working_dir`

Stat:

```text
internal/state/migrations/007_runtime_handoff_working_dir.sql | 88 ++++++++++
internal/state/runtime_handoff.go                              | 182 +++++++++++++++++++++
internal/state/state_test.go                                   | 111 +++++++++++++
3 files changed, 381 insertions(+)
```

Files:

- `internal/state/migrations/007_runtime_handoff_working_dir.sql`
- `internal/state/runtime_handoff.go`
- `internal/state/state_test.go`

Intent:

- Add `working_dir` to `runtime_handoff`.
- Enforce `UNIQUE(session_name, working_dir)`.
- Add store methods for per-session/per-working-dir handoff snapshots.
- Preserve fallback to `working_dir=""` for compatibility.

Preserve invariant:

- Runtime handoff state must not leak across repos sharing a session name.

### `8ac8bfee fix(spawn): enforce source_repo provenance in recovery beads`

Stat:

```text
internal/bv/bv.go                   | 39 ++++++++++++++------------
internal/bv/types.go                | 16 ++++++-----
internal/cli/spawn.go               | 55 +++++++++++++++++++++++++++++++++----
internal/cli/spawn_recovery_test.go | 36 ++++++++++++++++++++++++
4 files changed, 117 insertions(+), 29 deletions(-)
```

Files:

- `internal/bv/bv.go`
- `internal/bv/types.go`
- `internal/cli/spawn.go`
- `internal/cli/spawn_recovery_test.go`

Intent:

- Carry `source_repo` through in-progress/recent/blocked bead views.
- Require source repo provenance in spawn recovery beads.
- Stop recovery mechanisms from injecting beads from the wrong repo.

Preserve invariant:

- Any recovery bead emitted from NTM must be tied to the source repo that produced it.

### `5bbcaf7c Scope checkpoint dirs by project slug`

Stat:

```text
internal/checkpoint/incremental.go          | 109 +++++---
internal/checkpoint/incremental_test.go     | 6 +-
internal/checkpoint/recovery_errors_test.go | 13 +-
internal/checkpoint/scrollback_test.go      | 2 +-
internal/checkpoint/storage.go              | 316 ++++++++++++++++++++++++++--
internal/cli/checkpoint.go                  | 24 +--
6 files changed, 408 insertions(+), 62 deletions(-)
```

Files:

- `internal/checkpoint/incremental.go`
- `internal/checkpoint/incremental_test.go`
- `internal/checkpoint/recovery_errors_test.go`
- `internal/checkpoint/scrollback_test.go`
- `internal/checkpoint/storage.go`
- `internal/cli/checkpoint.go`

Intent:

- Store checkpoint dirs under project slug rather than only session.
- Avoid cross-project checkpoint collision when sessions/recovery paths overlap.
- Let incremental checkpoint lookup scan project-scoped session dirs.

Preserve invariant:

- Checkpoints for different working directories must not collide under a shared session name.

## Upstream Commits: Diff Research

### `7c4c9efc fix(cli/health): align Error-set exit code with non-JSON cobra default`

Stat:

```text
internal/cli/health.go | 10 +++++-----
1 file changed, 5 insertions(+), 5 deletions(-)
```

Intent:

- JSON soft failure with `output.Error != ""` exits 1, not 2.
- Align JSON behavior with non-JSON Cobra returned-error default.

Jeff's mental model:

- JSON and human paths should have a lockstep exit-code contract.
- Severity ladder remains: OK=0, Error status=2, warning/soft failure=1.

### `4119a662 fix(health): skip exit-code escalation in --json --watch`

Stat:

```text
internal/cli/health.go | 12 ++++++++++++
1 file changed, 12 insertions(+)
```

Intent:

- In `ntm health --json --watch`, emit JSON for the current tick and return nil.
- Keep the watch loop alive across transient non-OK ticks.

Jeff's mental model:

- Watch mode is a stream, not a one-shot health gate.
- Non-watch JSON still exits according to severity.

### `65602811 fix(config,cli): wire [coordinator] section so config.toml settings are honored (#111)`

Stat:

```text
internal/cli/coordinator.go               | 35 +++++++++-
internal/config/config.go                 | 42 ++++++++++++
internal/config/coordinator_repro_test.go | 104 ++++++++++++++++++++++++++++++
3 files changed, 180 insertions(+), 1 deletion(-)
```

Intent:

- Add `Config.Coordinator` TOML mirror.
- Default missing `[coordinator]` to runtime defaults.
- Load coordinator config in `runCoordinatorStatus`.
- Add regression tests for the issue #111 TOML payload and drift between mirror/runtime defaults.

Jeff's mental model:

- Config loader should mirror runtime structs where direct import would create cycles.
- Missing config must preserve runtime defaults.
- Duration TOML strings decode into `time.Duration`.
- Broader schema-loader drift remains out of scope for this commit.

## File-Level Overlap Matrix

Named five local commits vs named three upstream commits:

| File | Local | Upstream | Conflict Risk |
|---|---:|---:|---|
| `internal/bv/bv.go` | X |  | none against named upstream; high against full live origin because branch is behind 521 |
| `internal/bv/types.go` | X |  | none against named upstream |
| `internal/checkpoint/incremental.go` | X |  | none against named upstream; medium/high against full origin checkpoint changes |
| `internal/checkpoint/incremental_test.go` | X |  | none against named upstream |
| `internal/checkpoint/recovery_errors_test.go` | X |  | none against named upstream |
| `internal/checkpoint/scrollback_test.go` | X |  | none against named upstream |
| `internal/checkpoint/storage.go` | X |  | none against named upstream; medium/high against full origin checkpoint changes |
| `internal/cli/checkpoint.go` | X |  | none against named upstream |
| `internal/cli/spawn.go` | X |  | none against named upstream; medium against full origin spawn changes |
| `internal/cli/spawn_recovery_test.go` | X |  | none against named upstream |
| `internal/state/migrations/007_runtime_handoff_working_dir.sql` | X |  | possible migration-number conflict against full origin, inspect before cherry-pick |
| `internal/state/runtime_handoff.go` | X |  | possible overlap with full origin state schema evolution |
| `internal/state/state_test.go` | X |  | medium against full origin tests |
| `internal/cli/health.go` |  | X | none against local named commits |
| `internal/cli/coordinator.go` |  | X | none against local named commits |
| `internal/config/config.go` |  | X | none against local named commits, but local older ancestry touched config historically |
| `internal/config/coordinator_repro_test.go` |  | X | none against local named commits |

Specific checks requested:

- `internal/cli/coordinator.go`: upstream only in named set.
- `internal/config/config.go`: upstream only in named set.
- `internal/cli/health.go`: upstream only in named set.
- BV/bead-isolation files: local only in named set.

Important qualification: applying local commits onto current `origin/main` may still conflict because `origin/main` has 521 commits absent from local `main`.

## Working Tree Surfaces

| Path | What it is | Preserve? | Recommended placement |
|---|---|---:|---|
| `AGENTS.md` | Modified by adding pointer to global ZestStream doctrine. | yes | local-only doctrine overlay; preserve via dirty archive/stash; do not upstream. |
| `.beads/.write.lock` | Beads lock file. | no as source | leave untracked; do not commit; ignore/clean only with explicit confirmation. |
| `.beads/beads.lock` | Beads lock file. | no as source | leave untracked; do not commit; ignore/clean only with explicit confirmation. |
| `.flywheel/MISSION.md` | Repo-local flywheel placeholder, owner review needed. | yes local | local operational substrate; stash/archive, possibly commit to local overlay only after owner review. |
| `.flywheel/GOAL.md` | Repo-local flywheel placeholder. | yes local | same as above. |
| `.flywheel/LOOP.md` | Full flywheel loop contract copied into ntm. | yes local but heavy | local substrate; consider keeping outside Jeff branch or local overlay. |
| `.mcp.json` | Local MCP server config pointing at universal-doc-rag. | yes local | stash/local-only; add to local ignore if recurring. |
| `AGENTS.md.bak-pre-agents-pointer-20260427` | Backup copy of AGENTS before pointer edit. | no source | archive outside repo, then delete only with explicit Joshua confirmation. |
| `cmd/test_detect/main.go` | Scratch detector repro for Cubcode/status parsing. | maybe | move to local scratch branch or convert to test if still needed; otherwise archive. |
| `internal/tmux/frankenterm.go` | Untracked Go integration for frankenterm robot API capture. | maybe high | do not lose; put on separate local branch/bead before reconcile. |
| `scripts/bead-status-cron.sh` | Launchd/user-agent bead status JSON writer. | maybe | local operational script; do not upstream until issue/architecture decision. |
| `scripts/bead-status-emitter.sh` | Watcher sidecar status emitter with br/sqlite fallbacks. | maybe | local operational script; likely superseded by registry/autoloop work; archive/stash. |
| `scripts/post-bead-commit.sh` | Auto-commit safety net after bead close. | risky | do not upstream; preserve separately if still used. |
| `scripts/write-bead-status.sh` | Sidecar bead status writer. | maybe | local operational script; archive/stash. |

Recommendation: before any branch changes, create both a git bundle and a dirty-work archive. Then stash all uncommitted/untracked surfaces with `git stash push -u`. After the reconciled branch builds, re-apply only the surfaces Joshua still wants, preferably as separate local commits.

## Build Provenance

Makefile:

```make
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS := -ldflags "-s -w -X github.com/Dicklesworthstone/ntm/internal/cli.Version=$(VERSION)"
```

Makefile only sets `internal/cli.Version`.

GoReleaser:

```yaml
ldflags:
  - -s -w
  - -X github.com/Dicklesworthstone/ntm/internal/cli.Version={{.Version}}
  - -X github.com/Dicklesworthstone/ntm/internal/cli.Commit={{.Commit}}
  - -X github.com/Dicklesworthstone/ntm/internal/cli.Date={{.Date}}
  - -X github.com/Dicklesworthstone/ntm/internal/cli.BuiltBy=goreleaser
```

Manual local build should set at least:

- `Version=$(git describe --tags --always --dirty)`
- `Commit=$(git rev-parse --short HEAD)`
- `Date=$(date -u +%Y-%m-%dT%H:%M:%SZ)`
- `BuiltBy=manual-reconcile`

## Socraticode Findings

Socraticode search confirmed:

- `internal/cli/validate.go` owns `ntm config validate`.
- `internal/cli/coordinator.go` has coordinator toggle/status surfaces.
- Local bead isolation is visible in `internal/bv/bv.go` around `RunBd`: explicit `--db`, `BEADS_STRICT_LOCAL=1`, no `RunBrReal`.
- Runtime handoff scoping is visible in `internal/state/runtime_handoff.go` and migration `007_runtime_handoff_working_dir.sql`.

## Research Conclusion

Named local and upstream commit sets have no direct file overlap. The real risk is not those eight commits; it is the live branch divergence. Therefore the safe plan is not a merge on current `main`. It is a backup-first vendor-branch reconciliation with manual conflict gates and explicit binary provenance.
