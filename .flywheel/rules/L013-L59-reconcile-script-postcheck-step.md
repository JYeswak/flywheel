## L59 — RECONCILE-SCRIPT-POSTCHECK-STEP

---
id: L59
title: Reconcile scripts must prove clean worktree before success
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: ntm-worktree-conflicts-post-reconcile
---

**Rule:** Any script or runbook that performs or launches a git reconcile
operation (`merge`, `rebase`, `cherry-pick`, branch replacement, or upstream
overlay) MUST run a final postcheck before reporting success:

1. Verify `git status --porcelain` is empty in the target repo.
2. Verify no in-progress reconcile marker remains, at minimum `CHERRY_PICK_HEAD`
   for cherry-pick flows.
3. If either check fails, print `RECONCILE INCOMPLETE`, show the status or
   marker evidence, give the operator the exact resolve/skip/abort action class,
   and exit nonzero.

Build success, test success, a clean `HEAD`, or a runbook exit code is not
enough. The worktree itself is the source of truth for reconcile completion.

**Why:** On 2026-05-02, Joshua ran
`~/Developer/flywheel/.flywheel/PLANS/ntm-local-upstream-reconcile-2026-05-02/launch-on-pane-0.sh`.
The later pane-2 `ntm_rebuild_l57_2026_05_02` dispatch found four unresolved
`UU` files in `~/Developer/ntm` from a paused cherry-pick of `95ed40e0`
(`internal/agent/types.go`, `internal/cli/ensemble_spawn.go`,
`internal/swarm/agent_launcher.go`, `internal/tmux/session.go`). `HEAD`
compiled from a clean archive, but the live worktree was broken. The eventual
resolution was Joshua's explicit `git cherry-pick --skip`; the reconcile script
should have surfaced the incomplete state before anyone treated the reconcile as
done.

**How to apply:**

- End every reconcile launcher and destructive git runbook with a runtime
  postcheck, not just a printed list of verification commands.
- Use `git status --porcelain` rather than human-formatted status text so `UU`
  files, staged leftovers, and uncommitted reconcile output are machine-visible.
- Check in-progress markers such as `CHERRY_PICK_HEAD` after status; a clean
  final message must be backed by the repo's actual `.git` state.
- Treat any non-empty postcheck as a failed reconcile and preserve the operator's
  recovery choices: resolve and continue, skip, or abort.

Reference shell shape:

```bash
final_status=$(cd "$TARGET_REPO" && git status --porcelain)
if [[ -n "$final_status" ]]; then
  echo "RECONCILE INCOMPLETE — worktree not clean:" >&2
  echo "$final_status" >&2
  echo "Action: resolve, skip, or abort the in-progress reconcile before declaring done." >&2
  exit 1
fi

in_progress=$(cd "$TARGET_REPO" && git rev-parse --git-path CHERRY_PICK_HEAD 2>/dev/null || true)
if [[ -n "$in_progress" && -f "$in_progress" ]]; then
  echo "RECONCILE INCOMPLETE — cherry-pick in progress" >&2
  exit 1
fi
```

**Forbidden outputs:**

- "Reconcile complete", "runbook complete", or "success" before the clean
  worktree postcheck passes.
- Reporting source `HEAD` health while ignoring unresolved worktree paths.
- Printing post-run verification commands as a substitute for running the
  mandatory postcheck.
- Treating `UU` paths as a manual cleanup note instead of a failed reconcile.

**Evidence:** `~/.local/state/flywheel/fuckup-log.jsonl` line 216
(`class=ntm-worktree-conflicts-post-reconcile`);
`/tmp/ntm_rebuild_l57_findings.md`; `/tmp/ntm_worktree_cleanup_findings.md`;
`/tmp/ntm_cherrypick_skip_findings.md`;
`~/Developer/flywheel/.flywheel/PLANS/ntm-local-upstream-reconcile-2026-05-02/launch-on-pane-0.sh`;
`~/.local/state/flywheel/fuckup-processed.jsonl` row written by bead
`flywheel-yxzr`.

**Companion rules:** L57 forbids treating markers as proof of live driver state;
L56 defines the fuckup-log to canonical L-rule promotion ladder; L53 records
the trauma row that this rule processes.

