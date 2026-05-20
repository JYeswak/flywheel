# Git Workflow Runbook (Fleet-Wide Canonical)

**Authority:** flywheel-m9yxr research (`.flywheel/PLANS/git-workflow-foundation-2026-05-20/00-research.md`).
**Doctrine cluster:** sister to `templates/flywheel-install/doctrine/{git-repo-discipline.md, git-stash-discipline.md, repo-hygiene-operational-protocol.md, cross-pane-git-discipline.md, git-main-sync-discipline.md, gitguardian-gate-discipline.md}`.
**Sister bead:** flywheel-jrpfn (auto-push doctrine) owns push-side enforcement; this runbook covers everything else.
**Status:** v0.1 draft. Sections below are decision-tree-shaped; never run a command before resolving the decision its section names.

---

## Decision Tree — Which Section Do I Need?

```
Starting new work?                                  → §1 start-feature
Dispatching a worker?                               → §2 dispatch-worker-to-feature
Worker returned a callback?                         → §3 integrate-worker-callback
Branch is ready for main?                           → §4 merge-to-main
Worktree work is done OR worker abandoned?          → §5 cleanup-worktree
About to `git stash`?                               → §6 stash-discipline (almost certainly DON'T)
Failed merge / lost commits / dirty after rebase?   → §7 recover-from-failed-integration
Just made a bad commit?                             → §8 undo-bad-commit
Considering `git push --force`?                     → §9 force-push-safety (probably NO)
```

---

## §1. start-feature

**When:** new feature/fix/refactor begins. Mission-anchor: Duty 3 (publishable substrate state).

```bash
# 1. Verify clean baseline (Axiom 8: concurrent-agent drift is normal but must be acknowledged)
git status --short
bash .flywheel/scripts/repo-discipline-check.sh --json | jq '.dirty_class'
# if dirty_class != "clean", route through §7 BEFORE branching.

# 2. Sync main
git fetch --prune origin
git checkout master   # or main — detect via `git symbolic-ref refs/remotes/origin/HEAD`

# 3. File the bead FIRST (beads-centric per CLAUDE.md Axiom 2)
br create -p <0|1|2> -t <feature|bug|chore> "concise outcome-shaped title"
# capture BEAD_ID

# 4. Branch from sync'd main with bead-prefix naming
BEAD_ID=flywheel-xxxxx
git checkout -b "feature/${BEAD_ID}-short-slug"

# 5. Declare lifecycle (NEW — extends git-repo-discipline)
cat >> .flywheel/BRANCH-MANIFEST.json <<EOF
  // add entry per .flywheel/schemas/BRANCH-MANIFEST.schema.json
EOF
```

**Anti-patterns** — never:
- Branch from a dirty working tree (hides untracked files inside the new branch's commits).
- Branch from stale local main (without `git fetch` first).
- Create a worktree on uncommitted work (per git-worktree-manager SKILL.md L128).

**Cross-ref:** git-commit-craftsman SKILL.md §"Before Committing".

---

## §2. dispatch-worker-to-feature

**When:** orch sends a worker to do bounded work. Mission-anchor: Duty 3 + Duty 5a.

```bash
# 1. ORCH-SIDE preflight (Forever-Rule from INCIDENTS shared-repo-dirty-preflight)
#    Orchestrator owns dirty-tree gating for every shared repo it dispatches into.
bash .flywheel/scripts/repo-discipline-check.sh --repo <shared-repo> --json
# Resolve/route/waive every dirty path BEFORE writing the dispatch packet.

# 2. Decide worktree shape:
#    a) Worker shares the orch's working tree    → only if --pathspec-scoped staging discipline is in dispatch packet
#    b) Worker gets an isolated worktree          → CANONICAL when worker runs full-repo validation
#       (Forever-Rule from INCIDENTS concurrent-dirty-validation-drift)
WT=/tmp/<repo>-<bead-id>-<role>-$$
git worktree add -q "$WT" "<branch-or-sha>"

# 3. Worker-side bead sync (Forever-Rule from INCIDENTS bead-missing-from-local-db)
br show <bead-id> --json || br sync --import-only
# if still missing, the worker MUST surface bead-missing-from-local-db in callback,
# NEVER fabricate a br close by writing .beads/issues.jsonl directly.

# 4. Dispatch via ntm (per flywheel:dispatch contract)
flywheel:dispatch ...
```

**Anti-patterns:**
- Dispatching with shared dirty state (orch error per INCIDENTS).
- Worker validating against a poisoned shared tree (worker error per INCIDENTS) — escape via §2 step 2b isolated worktree.
- Worker calling `br close` without `br show` first (bead-missing trauma).

**Cross-ref:** `.flywheel/skills/flywheel:dispatch`, ntm canonical contract, `dispatch-tool-contracts` skill.

---

## §3. integrate-worker-callback

**When:** worker callback arrives DONE/BLOCKED.

```bash
# 1. Pull worker's commits
git fetch origin "<worker-branch>"
git log --oneline origin/<worker-branch> ^HEAD

# 2. Verify commit messages do not carry zsh-expanded leaks ($0, $cost, etc.)
#    Forever-rule from git-commit-craftsman SKILL.md L321
git log --grep='/bin/\(zsh\|bash\)\.[0-9]' --oneline origin/<worker-branch>
# any hit = REJECT callback, route back to worker with §8 undo-bad-commit recipe.

# 3. Verify test/lint/build gates passed on worker's tip
gh pr view <pr-num> --json statusCheckRollup,mergeStateStatus

# 4. Merge OR rebase per branch lifecycle (declared in BRANCH-MANIFEST.json)
#    lifecycle=merge_to_main  → §4 merge-to-main
#    lifecycle=abandon        → §5 cleanup-worktree (no merge)
#    lifecycle=extract_to_repo → coordinate with target repo; do not merge here.
```

**Anti-patterns:**
- Merging worker output without statusCheckRollup green.
- Trusting worker's `br close` without `git log` confirmation that commits exist on the branch.

---

## §4. merge-to-main

**When:** branch ready for trunk. Mission-anchor: Duty 5a.

```bash
# 1. Pre-merge sync
git fetch --prune origin
git rebase origin/master  # OR `git merge --no-ff` for branches >1 commit — pick one per repo policy in .flywheel/auto-push-policy.yaml

# 2. Re-run local CI per .flywheel/ci-policy.json (local-first spend guard)
bash .flywheel/scripts/local-actions-preflight.sh --dry-run

# 3. Merge via gh (delete-branch on merge)
gh pr merge <pr-num> --squash --delete-branch   # OR --merge per repo policy

# 4. Auto-push the merge to remote per jrpfn doctrine
#    DO NOT manually `git push` if .flywheel/auto-push-policy.yaml exists for this repo.
#    The post-commit hook (or auto-push.sh) handles upstream sync.

# 5. Update BRANCH-MANIFEST.json: lifecycle_state=merged, merged_at=<now>
# 6. Trigger §5 cleanup-worktree if a worktree existed for this branch.
```

**Anti-patterns:**
- Merging into a stale main (no `fetch --prune` first).
- Manual `git push` when auto-push policy is active for this repo (per codex-21869 ref-drift guard).
- Force-pushing the merge (see §9).

**Cross-ref:** flywheel-jrpfn (auto-push doctrine), `.flywheel/auto-push-policy.yaml`.

---

## §5. cleanup-worktree

**When:** branch is merged, abandoned, or extracted. Mission-anchor: Duty 3.

```bash
# 1. Verify the worktree is clean (Axiom 5: dirty cleanup destroys work)
cd "$WT"
git status --short
# any output → route to §7 BEFORE removing.

# 2. Verify branch state per BRANCH-MANIFEST.json lifecycle:
#    merged: confirm `gh pr view <num> --json mergedAt` returns non-null
#    abandoned: confirm BRANCH-MANIFEST.lifecycle=abandon + worker BLOCKED callback exists
#    extracted: confirm cross-repo handoff receipt exists

# 3. Remove worktree via canonical command (NEVER rm -rf)
#    Per git-worktree-manager L128 + INCIDENTS dcg-worktree-remove-block
cd /Users/josh/Developer/flywheel   # exit the worktree path first
git worktree remove "$WT"
# if remove fails due to dirty tree → §7

# 4. Prune metadata
git worktree prune

# 5. Update BRANCH-MANIFEST.json: lifecycle_state=closed, worktree_removed_at=<now>
# 6. Delete branch:
git branch -d "<branch-name>"        # safe-delete (refuses if unmerged)
# git branch -D requires verbatim authorization per repo-janitor Axiom 9
```

**Anti-patterns** (verbatim from git-worktree-manager SKILL.md L124-136):

| Anti-pattern | Why fails | Fix |
|---|---|---|
| `rm -rf <worktree-path>` | Leaves stale metadata in `.git/worktrees/`; DCG blocks; no reflog backstop | `git worktree remove` + `git worktree prune` |
| `git worktree remove -f` on dirty tree | Uncommitted changes lost — only reflog archaeology recovers | `git status` check; route to §7 if dirty |
| `git branch -D` without verbatim auth | Unmerged commits become orphans recoverable only via reflog | `git branch -d` first; -D only with verbatim auth |
| Worktree outliving its branch | Default state of accretion (285 fleet-wide as of 2026-05-20) | Run §5 on every merged/abandoned branch within 24h |

**Cross-ref:** `.flywheel/scripts/stale-worktree-detector.sh` (read-only audit), follow-up bead `flywheel-git-worktree-reaper` (apply path).

---

## §6. stash-discipline

**When:** you're tempted to `git stash`. Mission-anchor: Duty 3.

**Default verdict: DON'T.** Per `templates/flywheel-install/doctrine/git-stash-discipline.md`: stash is a 24h scratch buffer, not durable storage.

```
Decision tree:
├── "I need to test a quick thing in a different state for <30min"  → OK, `git stash push -m "scratch:<context>:<expires-by>"`
│   └── pop within the same session. If forgotten >24h → §6 stash-cleanup.
├── "I found out-of-scope work mid-task"                            → STOP. File a bead via `br create`. Stash is wrong tool.
│                                                                       (Named trauma class: out-of-scope-leak, 44% of one fleet audit.)
├── "Tick noise / AGENTS-CANONICAL drift is in my way"              → `git restore <paths>`. Stash is wrong tool.
│                                                                       (Named trauma class: AGENTS-CANONICAL-pane-leak, 25%.)
├── "I want to save this for tomorrow"                              → `git checkout -b wip/<context>` and commit. Stash is wrong tool.
└── otherwise                                                       → Probably commit-and-amend-later.
```

**Stash-cleanup (when piles accumulate):**

```bash
# Audit:
bash .flywheel/scripts/stash-discipline-check.sh --json | jq '.classification,.count'
# classification ∈ clean | notable | bead_filing_class | halt

# At N≥5 (bead_filing_class), file a stash-cleanup bead and route to /git-stash-janitor skill.
# At N≥10 (halt), refuse close and HALT the current lane until cleaned.

# Per-stash inspection:
git stash list
git stash show -p stash@{N}   # inspect without applying
git stash pop stash@{N}       # apply + drop
git stash drop stash@{N}      # discard
```

**Anti-patterns:**
- Stashing for >24h.
- Stashing out-of-scope discoveries instead of filing as bead.
- Stashing tick noise / AGENTS-CANONICAL drift instead of `git restore`.
- Letting stash pile cross N=10 (halt threshold).

**Cross-ref:** `templates/flywheel-install/doctrine/git-stash-discipline.md`, `.flywheel/scripts/stash-discipline-check.sh`, `/git-stash-janitor` skill, follow-up bead `flywheel-git-stash-archiver`.

---

## §7. recover-from-failed-integration

**When:** rebase died, merge left conflicts, tree is dirty, or commits look missing.

```bash
# 1. STOP. Snapshot the wreckage before any "fix":
git status --short > /tmp/wreckage-status.txt
git log --oneline -20 > /tmp/wreckage-log.txt
git reflog -50 > /tmp/wreckage-reflog.txt
# reflog is the universal backstop — recover any commit within ~90d default

# 2. Identify the wreckage class:
#    a) Mid-rebase   → `git rebase --abort` returns to pre-rebase HEAD
#    b) Mid-merge    → `git merge --abort` returns to pre-merge HEAD
#    c) Conflicted   → resolve conflicts THEN continue, OR --abort
#    d) Dirty tree   → `git stash push -m "recover:<ts>"` then continue, OR `git restore <paths>` if intentionally discardable
#    e) Lost commit  → `git reflog`, find SHA, `git cherry-pick <sha>` or `git reset --hard <sha>`

# 3. NEVER:
#    `git reset --hard` without DCG/SLB authorization (dcg blocks this by default — that's the safety)
#    `git clean -fdx` without verbatim authorization (kills untracked work)
#    Force-push to "fix" a bad rebase on a shared branch (rewrites peer history)

# 4. If the wreckage involves a worker's branch with their commits:
#    Coordinate via Agent Mail BEFORE any history rewrite. Their reflog ≠ your reflog.
```

**Cross-ref:** DCG safety stack (`claude-md-safety.md`), `git-repo-janitor` Axiom 3 (`git rm`, never `rm`), SLB two-person rule for destructive ops.

---

## §8. undo-bad-commit

**When:** last commit is wrong (message, content, scope).

```bash
# A) BEFORE PUSH — amend is safe
git commit --amend            # rewrite the last commit
git commit --amend --no-edit  # add staged files to the last commit

# B) AFTER PUSH — DO NOT amend (per CLAUDE.md git safety protocol: "Always create NEW commits rather than amending")
git revert <bad-sha>          # create a NEW commit that undoes the bad one. PR-friendly.

# C) BAD-MESSAGE CLASS — zsh expanded $0 or $cost into the commit message
#    Forever-rule from git-commit-craftsman L321. Detect:
git log --grep='/bin/\(zsh\|bash\)\.[0-9]' --oneline
# Fix by §8.A (if unpushed) or §8.B (if pushed).
# Author future messages via one of three safe shapes:
#   1. Single-quoted heredoc:  git commit -F - <<'EOF' ... $0.50 ... EOF
#   2. Single-quoted -m:       git commit -m 'fix: cost is $0.50'
#   3. stdin pipe from file:   printf '%s\n' "$msg" | git commit -F -
```

**Anti-patterns:**
- `git commit --amend` after push (rewrites history; breaks peers).
- Constructing commit messages via double-quoted shell heredocs with `$N` tokens (the zsh-expansion trauma).
- `git reset --hard HEAD~1` to "undo" a pushed commit (deletes work; rewrites shared history).

**Cross-ref:** git-commit-craftsman SKILL.md §"Amending (Before Push Only)" + L321-352.

---

## §9. force-push-safety

**When:** considering `git push --force` or `--force-with-lease`. **Default verdict: DON'T.**

```
Decision tree:
├── target branch is main/master/trunk             → NEVER force-push. Period.
├── target branch is shared with peer workers      → Coordinate via Agent Mail FIRST. Then `--force-with-lease`.
├── target branch is your own short-lived feature  → `--force-with-lease` (refuses if remote moved); never `--force`.
├── you found a leaked secret in history           → Switch modes to `git-repo-janitor harden-secret-leak`
│                                                     (Axiom 15: secret halts cleanup and switches modes)
│                                                   → BEFORE filter-repo, verify shallow-clone invariant
│                                                     (Axiom 16: `git rev-list --count <branch> == origin/<branch>`)
│                                                   → Mirror-backup → rotate key → filter-repo → force-push-with-lease
│                                                   → THEN install pre-commit hook to prevent re-leak
└── otherwise                                      → REVERT instead (§8.B). Force-push is rarely the right tool.
```

**Codex post-push ref-drift guard (dormant):** when codex workers gain `workspace-write + network_access=true`, the post-push reconciliation probe activates per `.flywheel/doctrine/codex-21869-post-push-ref-drift-rule.md`. Until then, NO worker-driven `git push` surface exists in `.flywheel/scripts/`. Test `tests/codex-21869-post-push-ref-drift-guard.sh` asserts this dormancy invariant.

**Anti-patterns:**
- Force-push to main/master (history rewrite; CI churn; peer trauma).
- `--force` (clobbers concurrent commits silently); always `--force-with-lease`.
- Force-pushing to "fix" a bad rebase on a shared branch without Agent Mail coordination.
- `filter-repo` against shallow/partial clone (Axiom 16 violation).

**Cross-ref:** `git-repo-janitor` Axiom 15 (secret-leak playbook), Axiom 16 (shallow-clone guard), `.flywheel/doctrine/codex-21869-post-push-ref-drift-rule.md`, DCG/SLB two-person rule.

---

## Anti-Patterns — Fleet-Wide Table

| Anti-pattern | Cost | Fix | Source |
|---|---|---|---|
| `rm -rf` a worktree | Stale `.git/worktrees/` metadata; DCG block | `git worktree remove` + `git worktree prune` | git-worktree-manager L128 |
| Stash >24h | Out-of-scope discoveries lost in noise (44% trauma class) | `br create` for OOS work; `git checkout -b wip/...` for >1d work | git-stash-discipline doctrine |
| `git commit -m "...$cost..."` in zsh | zsh expands `$0` → `/bin/zsh`, silently corrupts message | Single-quote OR stdin pipe | git-commit-craftsman L321 |
| Worker validates in poisoned shared tree | False-fail validation; rework cycle | Isolated `/tmp/<repo>-<bead>-validate-$$` worktree | INCIDENTS concurrent-dirty-validation-drift |
| Orch dispatches to shared repo with dirty state | Worker BLOCKED; orch slot burned | Orch-side dirty-preflight before packet | INCIDENTS shared-repo-dirty-preflight |
| Worker `br close` without `br show` | Bead-state desync; ghost-closed beads | `br show` → `br sync --import-only` if absent → BLOCKED if still absent | INCIDENTS bead-missing-from-local-db |
| `git push --force` to main | Peer trauma; CI churn; history rewrite | Never; revert (§8.B) instead | CLAUDE.md git safety |
| `git push --force` (without lease) | Clobbers concurrent commits silently | `--force-with-lease` only | gh-cli SKILL.md, codex-21869 |
| Manual `git push` under auto-push policy | Bypasses gitguardian / supabase-mirror gates | Let auto-push hook run | flywheel-jrpfn |
| `git reset --hard` to "undo" pushed commit | Destroys work; rewrites shared history | `git revert` | CLAUDE.md git safety |
| Branch with no declared lifecycle | Accumulates indefinitely (177 fleet-wide unpushed) | BRANCH-MANIFEST.json entry at creation | this runbook §1 |

---

## Cross-Refs

- **Doctrine cluster (substrate-hygiene):** templates/flywheel-install/doctrine/{git-repo-discipline.md, git-stash-discipline.md, repo-hygiene-operational-protocol.md, blocker-discipline.md, cross-pane-git-discipline.md, git-main-sync-discipline.md, gitguardian-gate-discipline.md, codex-21869-post-push-ref-drift-rule.md}.
- **Skills:** `git-worktree-manager`, `git-commit-craftsman`, `git-repo-janitor`, `git-stash-janitor`, `gh-cli`, `git-worktree-isolation-for-parallel-bg-agents`, `git-worktree-branch-rationalization`, `git-repo-janitor`.
- **Scripts (in-tree):** `.flywheel/scripts/{repo-discipline-check.sh, stash-discipline-check.sh, stale-worktree-detector.sh, branch-protection-apply.sh, auto-push.sh, fleet-git-inventory.sh}`.
- **Schemas:** `.flywheel/schemas/{WORKTREE-MANIFEST.schema.json, BRANCH-MANIFEST.schema.json, STASH-POLICY.schema.json}`.
- **Sister bead:** flywheel-jrpfn (auto-push doctrine), flywheel-dycce (local-first CI/CD).
- **Follow-up beads:** see `.flywheel/PLANS/git-workflow-foundation-2026-05-20/00-research.md` §5.

---

## Versioning

- v0.1 (2026-05-20) — Draft from research bead flywheel-m9yxr. Decision-tree shape; cites existing canon; introduces 3 new schemas + 1 new inventory script.
- Future revs: live as implementation beads land (worktree-reaper, stash-archiver, branch-reaper).
