# Git Workflow Fleet Analysis — Why Branches Go Stale Waiting on Joshua

**Author:** flywheel:1
**Date:** 2026-05-20
**Trigger:** Joshua-direct "every one of my fucking repos is struggling right now to keep git history in check... why is saving our work to git and merging our branches so god damn hard?"

---

## TL;DR

You are the bottleneck on merges because **8 distinct gates** all require human keystrokes when 6 of them could be machine-gated. Fix in 3 phases over ~3 days:

1. **Phase 0 (today, 15min):** Enable auto-merge fleet-wide (DONE for 4/5 repos) + branch-protection rules with required-status-checks-only (no required reviews) + delete-branch-on-merge.
2. **Phase 1 (week 1):** Short-lived branch discipline + worker-commit boundary + stale-branch reaper + merge-back-to-main cadence for long-lived review branches.
3. **Phase 2 (week 2-3):** Auto-reviewer bot (codex via /flywheel:review) for trivial PRs + merge queue for multi-PR coordination + CI substrate gates.

---

## Current state (fleet measurement)

| Repo | Local branches | Commits ahead of main | Unmerged | Open PRs | Auto-merge | Comment |
|---|---|---|---|---|---|---|
| flywheel | 34 | 632 | 0 | 3 | ✅ (today) | Long-lived review branch carries today's 60+ commits |
| skillos | 50 | **1132** | **48** | 2 | ✅ (today) | **Bankruptcy territory** — 48 unmerged branches |
| zesttube | unknown | unknown | unknown | 0 | ✅ (today) | Largest repo at 94GB |
| mobile-eats | unknown | unknown | unknown | 2 | ✅ (today) | Active client repo |
| picoz | unknown | unknown | unknown | ? | ❌ (perms) | Different org? |
| clutterfreespaces | unknown | unknown | unknown | 1 | ✅ (today) | Has `.failed-rebase-20260519T194057` orphan = 3.7GB |

**Open PRs across fleet: ~10. Two of three flywheel PRs were green-mergeable, sitting waiting because auto-merge wasn't enabled.**

---

## Root cause taxonomy — 8 gates that bottleneck on Joshua

### Gate 1: Auto-merge disabled in GitHub repo settings (✅ FIXED today)

**Symptom:** PR shows MERGEABLE + green CI + you have to run `gh pr merge` manually.

**Fix:** `gh api -X PATCH repos/<org>/<repo> -f allow_auto_merge=true`. Done for flywheel + skillos + zesttube + mobile-eats + clutterfreespaces. Picoz needs perm investigation.

### Gate 2: Required review approval (PROBABLY ACTIVE)

**Symptom:** Auto-merge queued but blocks on "Code owner review required" or "1 approval required".

**Fix:** For solo-developer repos OR repos where Claude/codex are the only "reviewers", set `required_pull_request_reviews=null` in branch protection rules. Replace human-review gate with required-status-checks gate (CI is the reviewer).

**Decide:** Some repos (client-facing legal, billing) probably WANT human review. Most internal flywheel substrate repos don't.

### Gate 3: No required status checks (CI is decorative not gating)

**Symptom:** Auto-merge fires immediately even when CI hasn't run / failed. OR CI runs but doesn't gate merge.

**Fix:** Set branch protection `required_status_checks` to the CI workflow names (e.g., `Test / shellcheck`, `Test / smoke`). Auto-merge then waits for green CI before firing.

### Gate 4: Long-lived review branches accreting commits

**Symptom:** Current `review/flywheel-2.0-private-20260513` has 632 commits and is "CONFLICTING" with main. PR #3 ("Post-merge readiness and handoff follow-up") is stuck because of this.

**Fix:** Long-lived review branches should periodically merge BACK from main + push forward to main in chunks. Daily-merge-train cron: at end of day, rebase review branch on main, push, file follow-up PRs for any conflicts.

**This is the biggest source of "branches going stale" — you're working on a branch that diverges from main faster than it can be merged.**

### Gate 5: Workers stashing each other's work

**Symptom (Joshua-direct earlier today):** Workers stash other workers' uncommitted changes to save THEIR work to git. Original work gets lost in the stash pile. Stashes accrete (per `git-stash-janitor` skill).

**Fix:** Worker discipline doctrine — **never stash. Never check out a branch that has another worker's WIP.** If you find dirty tree, surface it (`git status` callback) and skip. Each worker commits to own branch only. Per `AGENTS.md` axiom 8 (already in repo doctrine).

**Belt-and-suspenders:** PreToolUse hook that blocks `git stash` and `git checkout` when working tree has changes not authored by current worker.

### Gate 6: Delete-branch-on-merge disabled (LOCAL CLUTTER)

**Symptom:** 34 local branches in flywheel, 50 in skillos. Workers create branches, PRs get merged, but local branches never get deleted. Tab-complete becomes useless.

**Fix:** `delete_branch_on_merge=true` (done today for 4 repos). For LOCAL branches: weekly cron `git branch --merged main | grep -v main | xargs git branch -d`. Or: `gh repo sync` + branch-prune on every fetch.

### Gate 7: Workers race on `.beads/issues.jsonl` writes (FIXED today)

**Symptom:** Two workers running `br create` simultaneously → both modify .beads/issues.jsonl → one worker's bead vanishes → merge conflict → manual resolve.

**Fix:** `br-stage-wrapper.sh` (shipped today) auto-stages on every br create/close/update. Doesn't fully solve race but reduces lost-write class.

**Upstream needed:** `br` should use SQLite WAL or file lock on writes. Filed as flywheel-wvpd3 today (br doesn't EXIT-trap its tempdb either).

### Gate 8: Joshua manually pushing to remote (CI substrate gap)

**Symptom:** Workers commit locally + write a callback. Orchestrator validates. Then... Joshua manually pushes to main.

**Fix:** Auto-push v0.1 already shipped (flywheel-vgldw soak through 2026-05-26). 4-tier auto-push validates locally before pushing. Tier 4.5 GitGuardian secret-scan. Tier 4.5.1 Supabase mirror gate. The auto-push *exists* but its adoption across the fleet is incomplete (skillos-96x73 propagation phase, queued T1+48..72h).

---

## Solution stack (recommended deployment order)

### Phase 0 — Today (under 30min, mostly done)

| Action | Status | Impact |
|---|---|---|
| Enable `allow_auto_merge` fleet-wide | ✅ 4/5 repos | Removes Gate 1 |
| Enable `delete_branch_on_merge` fleet-wide | ✅ 4/5 repos | Removes Gate 6 |
| Merge the 2 currently-green flywheel PRs (#24, #25) | ✅ #24 merged, #25 queued | Clears immediate queue |
| Investigate picoz auto-merge perm issue | TODO | Check org membership |
| File branch-protection-rules-needed bead | TODO | Phase 1 prep |

### Phase 1 — Week 1 (4 deliverables)

| Deliverable | Owner | Estimated effort |
|---|---|---|
| Branch protection rules (required CI checks, no required review, allow auto-merge) per repo | flywheel:1 + skillos:1 | 2-3h fleet-wide |
| `git-stash-janitor` hygiene cadence per repo (every 6h reap stashes >24h old that aren't tagged "keep") | flywheel:1 | 1h |
| Long-lived-review-branch merge-back-to-main daily cadence | flywheel:1 | 2h |
| Worker discipline doctrine v0.1 (NEVER stash other workers' work; PreToolUse hook to enforce) | skillos:1 (canonical-doctrine) | 4h |

### Phase 2 — Week 2-3 (3 deliverables)

| Deliverable | Owner | Estimated effort |
|---|---|---|
| Auto-reviewer bot (codex via /flywheel:review) — auto-approves trivial PRs (docs, formatting, single-file) | flywheel:1 | 1d |
| Merge queue for multi-PR coordination (GitHub merge queue OR auto-rebase-train) | skillos:1 | 1d |
| CI substrate gates per repo (shellcheck + smoke + canary as required checks) | flywheel:1 + per-repo owners | 2-3d fleet-wide |

---

## Anti-patterns to avoid

| Anti-pattern | Why it's wrong | What to do instead |
|---|---|---|
| Disable CI to skip the wait | Removes the gate but also removes the safety net — broken main propagates | Make CI fast (<5min) so it's not painful to wait |
| Worker creates branch + lets it sit for days waiting on review | Stale branches = merge conflicts = manual rebase | Short-lived branches (hours not days); merge fast; iterate via follow-up PRs |
| Worker commits to main directly to skip PR | Loses CI gate + loses PR-review audit trail + loses callback discipline | Commit to branch + open PR + auto-merge on green |
| Use `git pull --rebase` blindly in scripts | Rewrites local commits; if worker had unpushed work it gets lost | `git fetch + git rebase --abort-on-conflict` OR explicit merge |
| Force-push to shared branch | Destroys other workers' commits | Force-push only to own short-lived branches; `--force-with-lease` always |
| Long-lived `review/*` branches > 100 commits ahead of main | Becomes its own forked main; merge-back impossible | Merge in chunks; cap at ~50 commits before forced merge-back |

---

## Specific repo recommendations (post-audit)

### flywheel
- **Current branch `review/flywheel-2.0-private-20260513`** has 632 commits ahead of main. PR #3 marked CONFLICTING. **Recommend: stop accreting here. Merge what's mergeable + open follow-up PRs.**
- 34 local branches → run `git branch --merged main | xargs git branch -d` (safe — only deletes merged-to-main)
- Auto-merge: ENABLED today

### skillos
- **1132 commits ahead of main, 48 unmerged branches** — bankruptcy territory.
- Recommend: file a bead `skillos-merge-debt-bankruptcy` that classifies the 48 branches into (a) merge to main, (b) abandon-and-tag, (c) reactivate-and-PR.
- Auto-merge: ENABLED today

### picoz
- Auto-merge enable FAILED. Different org / different perms. Investigate.

### clutterfreespaces
- `clutterfreespaces.failed-rebase-20260519T194057` orphan at 3.7GB. Recoverable.

### Cross-repo
- `~/.cargo` at 7GB, `~/Library/Caches` at 5.5GB, `~/.cache` at 3GB → not git-related but eating disk
- `~/Developer/zesttube` at **94GB** — by far largest single repo. Probably build artifacts not in .gitignore.

---

## The foundational architectural pattern (what "doesn't require Joshua manual commands" looks like)

```
WORKER                       ORCHESTRATOR                  GITHUB
  │                                │                          │
  │ commit to feat/X-bead-id       │                          │
  ├───────────────────────────────►│                          │
  │                                │ open PR + add labels     │
  │                                ├─────────────────────────►│
  │                                │                          │
  │                                │                          │ CI runs
  │                                │                          │ (gh actions)
  │                                │                          │      │
  │                                │                          │◄─────┘ green
  │                                │                          │
  │                                │                          │ auto-merge fires
  │                                │                          │ (squash)
  │                                │                          │
  │                                │                          │ delete branch
  │                                │                          │
  │                                │ post-merge callback      │
  │◄───────────────────────────────┤◄─────────────────────────│
  │                                │                          │
  │ br close + new bead            │                          │
  ▼                                ▼                          ▼

Joshua keystrokes: ZERO between commit-on-branch and merged-to-main.
Joshua keystrokes only on: (a) review of substantive design changes, (b) emergency reverts, (c) sign-off on releases.
```

The flywheel-rule-of-fleet: **if a step requires Joshua's keyboard and the step doesn't require Joshua's judgment, the step is a bug.**

---

## Anti-flywheel rules (the things we ARE doing wrong)

1. **Working on a 632-commit-ahead review branch** without periodic merge-back to main → main has fallen behind itself
2. **Auto-merge was disabled** in repo settings → PRs sit forever
3. **Workers race on .beads/issues.jsonl** writes → manual conflict resolution
4. **Workers stash each other's work** → manual recovery
5. **No CI gates** → merges happen with broken tests
6. **No stale-branch reaper** → 50 branches accrete per repo
7. **No fleet-wide branch protection** → each repo has different rules
8. **No merge queue** → multi-PR coordination requires manual ordering

---

## Beads to file from this analysis

| ID | Priority | Title |
|---|---|---|
| TBD | P0 | Branch protection rules fleet-wide (required CI checks, no required review for substrate repos) |
| TBD | P0 | Merge-back-to-main daily cadence for long-lived review branches |
| TBD | P1 | Worker discipline doctrine v0.1 — never stash other workers' work |
| TBD | P1 | git-stash-janitor hourly cadence install across all flywheel-managed repos |
| TBD | P1 | Local branch reaper — auto-delete merged-to-main branches weekly |
| TBD | P2 | Auto-reviewer bot via /flywheel:review for trivial PRs |
| TBD | P2 | CI substrate gates per repo (shellcheck + smoke + canary) |
| TBD | P2 | Investigate picoz auto-merge permission failure |
| TBD | P2 | clutterfreespaces.failed-rebase-20260519T194057 recovery (3.7GB) |

---

## Why this is solvable

You're not the bottleneck because the work is hard. You're the bottleneck because **6 of the 8 gates are GitHub config toggles or short scripts**. Phase 0 alone (which is mostly done) removes the auto-merge gate AND the delete-branch gate. Phase 1 fixes the long-lived-branch class + worker-stash class + stale-branch class. Phase 2 is the optional 80/20 polish.

After Phase 1, your only required keystrokes per PR are:
- (a) Reviewing the substantive design decision (judgment call)
- (b) Emergency overrides

Both are RIGHT to keep human-gated. Everything else is machine-gated.
