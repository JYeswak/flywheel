# git-main-sync — keep local main fresh fleet-wide (flywheel-dtf7l)

## Context

Joshua-direct 2026-05-20T02:25Z (zesttube non-fast-forward rejection). Local main falls behind origin/main as auto-merges accrete on remote. Currently Joshua manually pulls then pushes. Anti-flywheel.

## Deliverables

### A. .flywheel/scripts/git-main-sync.sh
Bash, idempotent, safe, JSON-emitting. Behavior:

| Working state | Action |
|---|---|
| On main/master, clean tree | git fetch --all --prune + git pull --rebase --autostash origin <branch> |
| On main/master, dirty tree | autostash via rebase.autoStash |
| On feature branch (review/*, arc/*, feat/*) | git fetch --all --prune only. Optional --rebase-feature flag to also rebase against origin/main. Default skip — long-lived review branches must NOT auto-rebase. |
| Detached HEAD / merge or rebase in progress | refuse + emit outcome=skipped reason=conflict-recovery-in-progress |

Flags: --repo PATH --rebase-feature --apply --json --dry-run
Schema: git_main_sync.v1 with outcome, branch, local_ahead, remote_ahead, fetched_refs, rebase_applied.

### B. .flywheel/scripts/install-git-main-sync-launchd.sh
Per-repo launchd cadence. Every 30min runs git-main-sync.sh against that repo. Logs at ~/.local/state/flywheel/git-main-sync/<repo-name>.log. Idempotent install.

### C. .flywheel/scripts/git-main-sync-fleet-rollout.sh
Iterates 5 flywheel-managed repos (flywheel, skillos, zesttube, mobile-eats, clutterfreespaces). Installs launchd cadence in each. Skips picoz (perms).

### D. One-time global config
Set:
- git config --global pull.rebase true
- git config --global rebase.autoStash true
Document in .flywheel/doctrine/git-main-sync-discipline.md.

### E. tests/git-main-sync-smoke.sh
6+ assertions: clean-tree-sync, dirty-tree-autostash, feature-branch-no-touch, detached-HEAD-skip, dry-run-no-mutation, JSON envelope shape.

## Acceptance

- 4 scripts + 1 doctrine + smoke ship
- shellcheck PASS
- Smoke 6+ assertions PASS
- Live dry-run on flywheel + skillos repos shows correct planned actions
- launchd plists installed locally BUT fleet rollout NOT RUN (Joshua-gate to apply)
- Bead flywheel-dtf7l closed

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits
- socraticode K>=10 with 2 phrasings
- Bridge daemon LIVE — auto-routes callback. Belt+suspenders: ntm send flywheel --pane=1
- SCR event: C7_verification_density + C6_trauma_outflow
- STOP on Track 1/2 breach, BLOCKED, >3h hard cap
- DEEP-WORK validate: shellcheck + smoke + live dry-run on 2 repos
- DO NOT actually start launchd cadence on remote repos — Joshua-gate

## FIRST ACTION

1. br show flywheel-dtf7l.
2. Read .flywheel/audits/git-workflow-fleet-analysis-20260520.md sections "Gate 4" and "Phase 1".
3. ACK row.
4. socraticode existing primitives.
5. Implement 4 scripts + smoke + doctrine.
6. Self-validate.
7. Commit + close + DIRECT pane-1 ntm send.
