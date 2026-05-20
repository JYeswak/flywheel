# Worker Discipline — Auto-Push BLOCKED ≠ "I'll just leave it"

**Joshua-direct 2026-05-20:** *"workers just say - oh can't do it, i'll just leave it"* — this is a SUBSTRATE INTELLIGENCE GAP. Workers must KNOW the auto-push policy + recognize blocks as ACTIONABLE.

## The trauma class

`auto-push-blocked-worker-abandonment` — worker commits its scope, sees `auto-push status=blocked reason=dirty_tree exit_code=12`, treats it as "not my problem", moves on. Result: 4+ commits accrete on local branch with NO push. Other workers + orchestrator see stale state. Eventually Joshua intervenes manually.

## Why auto-push blocks

The 4-tier auto-push (`.flywheel/scripts/auto-push.sh`) refuses to push when working tree contains files NOT on the `known_dirty_paths_allow_list` in `.flywheel/auto-push-policy.yaml`. This is a SAFETY feature — prevents accidentally pushing unrelated WIP. But it requires the allow-list to keep pace with legitimately-accreting substrate paths.

## What workers MUST do when they see `auto-push status=blocked`

### 1. READ the ledger entry

```bash
tail -1 .flywheel/runtime/auto-push-ledger.jsonl | jq .
```

Look at `dirty_paths`. Classify each:
- **Worker-owned WIP** (paths the worker just edited but didn't commit) → commit them in this sprint
- **Substrate-accreting state** (state ledgers, runtime files, evidence, handoffs) → these are EVERYONE's responsibility to keep moving
- **Other-worker WIP** (files modified by another worker's in-flight goal) → ESCALATE to orchestrator, never commit/stash

### 2. ACT on the classification

For substrate-accreting state files that aren't worker-owned:

```bash
# Stage only the known-accreting paths (NEVER `git add -A` or `git add .`)
git add .flywheel/state .flywheel/runtime .flywheel/evidence .flywheel/handoffs \
        .flywheel/dispatches .flywheel/josh-requests-archive \
        .flywheel/dispatch-log.jsonl .beads/issues.jsonl

# Commit with the canonical sweep message (orchestrator-routable)
git commit -m "chore(state): auto-sweep accreting substrate paths [auto-push]"

# Push manually since auto-push fires on NEXT commit, not retroactively
git push origin "$(git branch --show-current)"
```

### 3. UPDATE the policy if a new accreting class appeared

If you find a path that's legitimately accreting every tick but isn't on the allow-list:

```bash
# Edit .flywheel/auto-push-policy.yaml — add the glob to known_dirty_paths_allow_list
# Commit the policy change
git add .flywheel/auto-push-policy.yaml
git commit -m "policy(auto-push): allow-list <new-class> — accreting substrate"
git push
```

The allow-list is doctrine. Updating it IS part of the work.

### 4. SUFFICIENT TEST — `auto-push status=ok` on next commit

After the sweep, your NEXT actual work-commit should trigger auto-push success:
```bash
tail -1 .flywheel/runtime/auto-push-ledger.jsonl | jq '.status'  # expect "ok"
```

If still blocked, escalate via callback — `auto-push-still-blocked-after-sweep` is a substrate fire that needs orchestrator + Joshua attention.

## What workers MUST NOT do

| ❌ | Why wrong |
|---|---|
| Ignore the block and continue dispatching | Stale local branch, work doesn't propagate, fleet visibility breaks |
| `git add -A` then commit everything dirty | May commit other workers' WIP — silent data loss class |
| `git stash` to "clean" the tree | AGENTS.md doctrine violation — other workers' WIP gets buried |
| Run `git push --force` to skip checks | Destroys remote work + bypasses the safety net |
| Disable auto-push by setting `enabled: false` in policy | Removes the gate without addressing the root cause |
| Say "I delivered my bead, not my problem" in callback | YOUR DELIVERY didn't reach origin. Substrate didn't move. |

## The trained-worker invariant

A worker who completes a sprint must verify TWO things before declaring DONE:

1. **All worker-owned commits landed on origin** (`git log @{push}..` shows zero commits)
2. **Auto-push status on last commit is `ok`** (`tail -1 ledger | jq '.status'`)

If either fails, the worker has UNFINISHED WORK. The callback must reflect this:
- `auto_push_status=blocked` → callback marks `did_not_complete=push_propagation`
- `commits_unpushed=N` → callback marks `did_not_complete=N_commits_local_only`

## Trauma-corpus row

| Date | Event | Resolution |
|---|---|---|
| 2026-05-20T02:11Z | auto-push BLOCKED 5×, 21 dirty paths accreted, workers ignored | Policy allow-list expanded + sweep committed + this doctrine written + memory pinned |

## Related skills + memory

- `agentic-coding-flywheel-setup` — the broader doctrine
- `feedback_auto_push_blocked_worker_abandonment` (this doc's memory pin)
- `feedback_substrate_loss_worker_commit_orphan` — sister class (worker commits but doesn't push)
- `feedback_validate_redispatch_foundational_discipline` — analog discipline for callbacks

## Propagation

This doctrine applies to ALL flywheel-managed orchs. skillos:1 should absorb into canonical-doctrine lane + propagate fleet-wide. Implementation: extend `auto-push.sh` to AUTO-SWEEP allow-list paths when `auto_sweep_on_dirty_tree: true` is set in policy (bead TBD — flywheel-side ship, then propagate).
