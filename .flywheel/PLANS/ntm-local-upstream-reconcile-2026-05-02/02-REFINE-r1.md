# REFINE r1: Chosen Model B Runbook Design

Chosen model: **Model B, vendor branch + local overlay**.

## Why Model B

Model B separates concerns:

- Jeff upstream stays inspectable.
- Joshua local patches stay local.
- Daily binary is built from the local overlay branch.
- Future upstream intake becomes a repeatable replay/verify/install operation.

This is stronger than Model A because `main` no longer hides whether it is upstream-pristine or local-mutated. It is cheaper than Model C because no fork governance is required yet.

## Branch Naming

Recommended branches:

- `vendor/upstream-main-<timestamp>`: exact `origin/main` at reconcile time.
- `backup/pre-reconcile-main-<timestamp>`: current local `main` before any work.
- `local/bead-isolation-reconciled-<timestamp>`: candidate daily-use branch.
- Optional final: rename old `main` to `local/pre-reconcile-main-<timestamp>` and create new `main` from `origin/main`.

Do not push any of these to `Dicklesworthstone/ntm`.

## Pre-Flight Checklist

Before touching branch state:

1. Confirm repo:

   ```bash
   cd /Users/josh/Developer/ntm
   git rev-parse --show-toplevel
   git status --short --untracked-files=all
   git branch -vv
   ```

2. Create all-references bundle:

   ```bash
   git bundle create /tmp/ntm-pre-reconcile-<ts>.bundle --all
   ```

3. Capture dirty tracked diff:

   ```bash
   git diff > /tmp/ntm-pre-reconcile-<ts>.tracked.diff
   git diff --cached > /tmp/ntm-pre-reconcile-<ts>.staged.diff
   ```

4. Capture untracked list and archive:

   ```bash
   git ls-files --others --exclude-standard > /tmp/ntm-pre-reconcile-<ts>.untracked.txt
   tar -czf /tmp/ntm-pre-reconcile-<ts>.untracked.tgz -T /tmp/ntm-pre-reconcile-<ts>.untracked.txt
   ```

5. Record ancestry:

   ```bash
   git rev-parse HEAD origin/main
   git merge-base HEAD origin/main
   git rev-list --left-right --count HEAD...origin/main
   ```

6. Stash dirty work only after archive exists:

   ```bash
   git stash push -u -m "pre-ntm-reconcile-<ts>"
   ```

## Step-By-Step Runbook

### Phase 1: Preserve Current Main

Command:

```bash
git branch backup/pre-reconcile-main-<ts> HEAD
```

Expected:

- New branch points at `5bbcaf7c`.
- If branch exists, choose a new timestamp.

Rollback:

- `git switch backup/pre-reconcile-main-<ts>`.

### Phase 2: Fetch Upstream

Command:

```bash
git fetch origin --prune
```

Expected:

- `origin/main` resolves to latest Jeff commit.
- No local branch pointer moves.

Rollback:

- No rollback needed; fetch only updates remote refs.

### Phase 3: Create Vendor Branch

Command:

```bash
git switch -c vendor/upstream-main-<ts> origin/main
```

Expected:

- Worktree is on a branch whose HEAD equals `origin/main`.

Rollback:

- `git switch backup/pre-reconcile-main-<ts>`.

### Phase 4: Create Local Overlay Branch

Command:

```bash
git switch -c local/bead-isolation-reconciled-<ts>
```

Expected:

- New branch starts from upstream-pristine base.

Rollback:

- `git switch backup/pre-reconcile-main-<ts>`.

### Phase 5: Replay Local Commits

Apply the five named commits in original chronological order:

```bash
git cherry-pick -x ccb68356
git cherry-pick -x f199a69f
git cherry-pick -x 98ec9aa4
git cherry-pick -x 8ac8bfee
git cherry-pick -x 5bbcaf7c
```

Expected:

- Best case: all apply cleanly because the named upstream commits do not touch the same files.
- Realistic case: conflicts may occur due to the 521-commit live divergence.

Rollback per conflict:

```bash
git cherry-pick --abort
git switch backup/pre-reconcile-main-<ts>
```

Do not use `git rebase`.

### Phase 6: Resolve Conflicts If They Occur

Conflict strategy:

| File family | Strategy |
|---|---|
| `internal/bv/*` | Manual merge. Preserve upstream API changes, but keep `BEADS_STRICT_LOCAL=1`, explicit `--db`, and no `RunBrReal`. |
| `internal/checkpoint/*` | Manual merge. Preserve upstream security/checkpoint changes and local project-slug directory scoping. |
| `internal/state/migrations/*` | Do not blindly keep migration number `007` if upstream already uses it. Rename local migration to next unused number and update tests accordingly. |
| `internal/state/runtime_handoff.go` | Manual merge. Preserve upstream store patterns and local `(session_name, working_dir)` uniqueness. |
| `internal/cli/spawn.go` | Manual merge. Preserve upstream spawn fixes and local `source_repo` recovery provenance. |
| `internal/config/config.go` | Prefer upstream for coordinator #111. Local named commits should not touch it. |
| `internal/cli/health.go` | Prefer upstream for health exit-code/watch fixes. Local named commits should not touch it. |

### Phase 7: Verification Gates

Build:

```bash
go build -trimpath -ldflags "-s -w \
  -X github.com/Dicklesworthstone/ntm/internal/cli.Version=$(git describe --tags --always --dirty) \
  -X github.com/Dicklesworthstone/ntm/internal/cli.Commit=$(git rev-parse --short HEAD) \
  -X github.com/Dicklesworthstone/ntm/internal/cli.Date=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  -X github.com/Dicklesworthstone/ntm/internal/cli.BuiltBy=manual-reconcile" \
  -o /tmp/ntm-reconcile-<ts> ./cmd/ntm
```

Version:

```bash
/tmp/ntm-reconcile-<ts> version
```

Coordinator config:

```bash
/tmp/ntm-reconcile-<ts> config validate --json | jq '.valid'
```

Health watch compile-path smoke:

```bash
go test ./internal/cli -run 'Test.*Health|Test.*Coordinator' -count=1
```

Bead-isolation invariants:

```bash
grep -R "BEADS_STRICT_LOCAL=1" -n internal/bv
! grep -R "func RunBrReal" -n internal/bv
grep -R "SourceRepo" -n internal/bv internal/cli/spawn.go internal/cli/spawn_recovery_test.go
grep -R "working_dir" -n internal/state internal/checkpoint
```

Broader tests:

```bash
go test ./internal/bv ./internal/checkpoint ./internal/state ./internal/cli -count=1
```

### Phase 8: Install Candidate Binary

Only after gates pass:

```bash
cp ~/.local/bin/ntm /tmp/ntm-installed-before-reconcile-<ts>
install -m 755 /tmp/ntm-reconcile-<ts> ~/.local/bin/ntm
~/.local/bin/ntm version
```

Rollback:

```bash
install -m 755 /tmp/ntm-installed-before-reconcile-<ts> ~/.local/bin/ntm
```

### Phase 9: Optional Main Pristine Rename

If Joshua wants the full Model B branch shape:

```bash
git branch -m main local/pre-reconcile-main-<ts>
git switch -c main origin/main
git switch local/bead-isolation-reconciled-<ts>
```

This preserves old `main` under a local branch and creates a new upstream-pristine `main`. It does not delete commits and does not use `reset --hard`.

## Post-Reconcile Actions

1. Update memory:
   - local daily NTM binary comes from `local/bead-isolation-*`.
   - never push to Jeff.
   - reconciliation pattern is Model B.
2. File upstream follow-up issue for schema-loader drift sweep.
3. Subscribe/watch Jeff's `ntm` repo for future config/health changes.
4. If any mobile-eats plist or launchd job depends on `ntm`, reload it only if the binary path changed or process holds old binary.
5. Record installed binary provenance:

   ```bash
   ~/.local/bin/ntm version > /tmp/ntm-reconcile-<ts>.installed-version.txt
   ```

## Why Not Model A

Model A keeps the daily binary branch and the vendor branch in one name. That is exactly where push-to-Jeff and bead-isolation drift happen. It is too easy to run a generic merge/rebase and lose why local commits exist.

## Why Not Model C

Model C is reasonable later, but it introduces remote governance before it is necessary. Today's goal is safe local reconciliation. A fork is useful if Joshua wants off-machine backup or multiple machines building the same local overlay.
