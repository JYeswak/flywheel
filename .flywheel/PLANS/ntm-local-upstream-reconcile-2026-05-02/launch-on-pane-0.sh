#!/usr/bin/env bash
# launch-on-pane-0.sh — wrapper that pre-checks state, then runs 04-RUNBOOK.sh
#
# Run this on pane 0 (your user shell), NOT via /Users/josh/.local/bin/ntm send.
# DCG blocks agents from rebase/destructive ops — this is a Joshua-only launcher.
#
# Usage:
#   bash ~/Developer/flywheel/.flywheel/PLANS/ntm-local-upstream-reconcile-2026-05-02/launch-on-pane-0.sh
#
# Or copy these commands directly to pane 0:
#   cd ~/Developer/flywheel/.flywheel/PLANS/ntm-local-upstream-reconcile-2026-05-02
#   bash launch-on-pane-0.sh
#
# Behavior:
# - Phase 1: pre-flight (read-only) — shows current state, expected state, requires y/N to proceed
# - Phase 2: invokes 04-RUNBOOK.sh with bash -x (verbose tracing)
# - The runbook itself has confirm prompts at every irreversible step
# - Tee'd output to /tmp/ntm-reconcile-launcher-<TS>.log

set -uo pipefail

TS="$(date +%Y%m%dT%H%M%S)"
LAUNCHER_LOG="/tmp/ntm-reconcile-launcher-${TS}.log"
RUNBOOK="$(cd "$(dirname "$0")" && pwd)/04-RUNBOOK.sh"
NTM_REPO="$HOME/Developer/ntm"

# Tee everything from this script to a log
exec > >(tee -a "$LAUNCHER_LOG") 2>&1

confirm() {
    local prompt="$1"
    read -r -p "Confirm: ${prompt} (y/N) " ans
    [[ "$ans" == "y" || "$ans" == "Y" ]]
}

phase() {
    echo
    echo "===== $* ====="
}

phase "Launcher start at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Launcher log: $LAUNCHER_LOG"
echo "Runbook:      $RUNBOOK"
echo "Repo:         $NTM_REPO"

if [[ ! -x "$RUNBOOK" ]]; then
    echo "ERROR: $RUNBOOK not found or not executable"
    exit 1
fi

if [[ ! -d "$NTM_REPO/.git" ]]; then
    echo "ERROR: $NTM_REPO is not a git repo"
    exit 1
fi

phase "Pre-flight read-only state check"
cd "$NTM_REPO"
echo "branch:    $(git rev-parse --abbrev-ref HEAD)"
echo "HEAD:      $(git rev-parse --short HEAD)"
echo "ahead/behind vs origin/main: $(git rev-list --left-right --count HEAD...origin/main)"
echo ""
echo "uncommitted (tracked + untracked):"
git status --short --untracked-files=all | head -30 || true
LINES=$(git status --short --untracked-files=all | wc -l | tr -d ' ')
echo "  total lines: $LINES"
echo ""
echo "last 3 commits:"
git log --oneline | head -3 || true
echo ""

phase "Expected state per audit (2026-05-02)"
cat <<'EOF'
  branch       = main
  HEAD         = 5bbcaf7c (Scope checkpoint dirs by project slug)
  ahead/behind = 63       521
  uncommitted  = ~10 lines (M AGENTS.md, untracked .flywheel/, .mcp.json, etc.)
  classification: 43 KEEP / 20 DROP-upstream-duplicate / 0 NEEDS-JOSHUA
  review:        /tmp/ntm_runbook_63commit_review.md (already written)

If your actual state above DOES NOT match this, abort and ping orchestrator-cc
before proceeding — the runbook expects this baseline.
EOF
echo ""

phase "What the runbook will do"
cat <<'EOF'
  1. Preflight: print state + create timestamped backup bundle/diffs/untracked-tarball
  2. Create backup branch: backup/pre-reconcile-main-<TS>
  3. Stash dirty work (with -u for untracked) — restorable via `git stash list`
  4. Fetch origin --prune
  5. Create vendor branch: vendor/upstream-main-<TS> (= origin/main)
  6. Create local overlay: local/bead-isolation-reconciled-<TS>
  7. Cherry-pick 43 commits one-by-one with explicit confirm at each
     - Conflict path: prints `git cherry-pick --continue` and `--abort` instructions
  8. Verify local invariants (BEADS_STRICT_LOCAL, no RunBrReal, SourceRepo, working_dir)
  9. go build with version stamps
  10. go test ./internal/{bv,checkpoint,state,cli}
  11. Config validation smoke test
  12. Install candidate binary to ~/.local/bin/ntm (with backup of prior binary)
  13. Optional: rename main → local/pre-reconcile-main-<TS>, recreate main from origin/main
      RECOMMENDATION: skip this (answer 'n') for first run — keep main on the new branch

  Total expected duration: 30 min - 3 hours (depends on cherry-pick conflicts)
  Estimated conflict surfaces: internal/cli/assign.go, watcher, spawn, tmux subsystems
EOF
echo ""

phase "Safety guarantees"
cat <<'EOF'
  - `set -euo pipefail` in runbook: any error halts immediately
  - `trap rollback_hint ERR`: prints rollback instructions on any failure
  - confirm prompts at every destructive step (you can `n` to bail any time)
  - Backup branch + bundle written BEFORE any mutation
  - Old binary saved to /tmp/ntm-installed-before-reconcile-<TS> before install
  - All output tee'd to /tmp/ntm-reconcile-<TS>.log

  Worst-case rollback (paste in another terminal if anything goes catastrophically wrong):
    cd ~/Developer/ntm
    git cherry-pick --abort 2>/dev/null || true
    git switch backup/pre-reconcile-main-<TS>     # use the actual TS from log output
    install -m 755 /tmp/ntm-installed-before-reconcile-<TS> ~/.local/bin/ntm  # if binary was installed
    git stash list                                  # find your stashed dirty work
    git stash pop                                   # restore it (after switching back to a working branch)
EOF
echo ""

phase "Confirm and launch"
echo "About to invoke: bash -x $RUNBOOK"
echo "This is the point where you can still bail with no changes."
echo ""
if ! confirm "proceed to runbook (this starts the destructive sequence with confirm prompts at each step)"; then
    echo "Cancelled by user. No changes made."
    exit 0
fi

phase "Invoking runbook"
echo "Each phase below comes from 04-RUNBOOK.sh — it has its own confirm prompts."
echo "Read each prompt carefully before answering y/N."
echo ""

# Use bash -x for trace visibility; the runbook's own tee captures phase output
bash -x "$RUNBOOK"
RUNBOOK_RC=$?

if [[ $RUNBOOK_RC -eq 0 ]]; then
    phase "Reconcile postcheck"

    # Postcheck — L59: reconcile-script-postcheck-step
    # Ensures worktree is clean (no UU files, no in-progress cherry-pick)
    # before reporting success.
    final_status=$(cd "$NTM_REPO" && git status --porcelain)
    if [[ -n "$final_status" ]]; then
        echo "RECONCILE INCOMPLETE — worktree not clean:" >&2
        echo "$final_status" >&2
        echo "Action: resolve, skip, or abort the in-progress cherry-pick before declaring reconcile done." >&2
        exit 1
    fi

    in_progress=$(cd "$NTM_REPO" && git rev-parse --git-path CHERRY_PICK_HEAD 2>/dev/null || true)
    if [[ -n "$in_progress" && -f "$in_progress" ]]; then
        echo "RECONCILE INCOMPLETE — cherry-pick in progress" >&2
        exit 1
    fi

    echo "Reconcile postcheck PASS — worktree clean."
fi

phase "Launcher complete at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Runbook exit code: $RUNBOOK_RC"
echo "Launcher log: $LAUNCHER_LOG"
if [[ $RUNBOOK_RC -eq 0 ]]; then
    echo ""
    echo "Post-run verification commands (paste these to confirm success):"
    echo "  cd ~/Developer/ntm"
    echo "  git log --oneline | head -10"
    echo "  git rev-list --left-right --count HEAD...origin/main"
    echo "  git branch -vv | head -10"
    echo "  ntm version"
    echo "  ntm health flywheel"
fi

exit $RUNBOOK_RC
