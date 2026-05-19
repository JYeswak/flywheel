---
title: "Orchestrator Reset Safety: Prevent Worker-Commit Orphans"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Orchestrator Reset Safety: Prevent Worker-Commit Orphans

Version: `orchestrator-reset-safety-orphan-prevention/v1`
Owner: orchestrators (reset path authors) + workers (side-branch dispatch)
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.151 (memory-without-cross-link wire-in)

## TL;DR

Before any orchestrator resets a repo that has accepted worker commits,
it MUST prove there are no orphan-risk commits via:

```bash
git log origin/main..HEAD --oneline
```

If non-empty: **STOP** the reset path until ahead commits are either
verified-absorbed by the remote squash OR pushed to a side branch for
PR/recovery. ALPS hit this twice on 2026-05-04 — manual reconstruction
was the recovery cost.

## Canonical memory source

This doctrine summarizes
`feedback_substrate_loss_worker_commit_orphan.md` — the META-rule memory
(2026-05-08) documenting the discipline. Read the memory for the full
evidence chain (ALPS commits `2e43df2` Supabase migration + `641d926`
Workato inventory) and the B13/B14 structural-receipt wire-in.

## The rule (formal)

For ANY orchestrator reset of a repo that has accepted worker commits:

1. Probe `git log origin/main..HEAD --oneline` BEFORE the reset.
2. If non-empty, **verify-or-preserve** each ahead commit:
   - Either prove the commit's content is already in `origin/main` via
     `git diff origin/main..HEAD --stat` returning empty/identical
   - OR push the ahead commits to a recovery side branch
3. Only after step 2 confirms no loss-risk: execute reset.
4. Prefer `git pull --ff-only` over `git reset --mixed origin/main` —
   fast-forward refusal is a useful signal.

## Worker discipline (side-branch dispatch)

To prevent worker commits landing on local `main` where reset can orphan them:

1. **Dispatch contract:** workers are dispatched to
   `worker-pane-${PANE}-${TASK_ID}` side branches, NOT local `main`,
   when their output will be integrated by an orchestrator.
2. **Callback contract:** worker callbacks include `side_branch=<name>`
   when a commit exists.
3. **B13 structural receipt:** `flywheel-dt2w` closed with
   `commit_tag=[worker-branch-contract]` wired this discipline.

## Orchestrator discipline (reset-guard)

To prevent destructive resets from orphaning worker output:

1. **Pre-reset probe (mandatory):** `git log origin/main..HEAD --oneline`
2. **Diff verification:** if ahead-commits exist, run
   `git diff origin/main..HEAD --stat` to confirm content-equivalent to
   upstream squash, OR push to recovery branch
3. **Fast-forward preference:** use `git pull --ff-only` not `git reset
   --mixed origin/main`
4. **B14 structural receipt:** `flywheel-2bfg` closed with
   `commit_tag=[dcg-orphan-reset-blocker]` wired DCG to surface ahead
   commits instead of silently losing substrate.

## Recovery procedure (if orphan detected post-loss)

```bash
# 1. Identify the orphan SHA from reflog
git reflog | head -20
# Note the SHA prior to the destructive reset

# 2. Read file content from orphan SHA into /tmp (safe)
git show <orphan-sha>:<file-path> > /tmp/recover-<file>.txt

# 3. Copy back to working tree
cp /tmp/recover-<file>.txt <file-path>

# 4. Recommit with the orphan SHA cited
git commit -m "recover from orphan <orphan-sha>: <reason>"
```

**Do NOT use destructive ref checkout paths** (`git checkout <orphan-sha>
-- <file>` can lose more than intended). Read-and-copy via `git show` is
the safe primitive.

## Empirical incidents (2026-05-04, ALPS)

Two confirmed orphan/reset incidents recorded in
`~/.local/state/flywheel/fuckup-log.jsonl#L578`:

| Worker commit | Class | Recovery cost |
|---|---|---|
| `2e43df2` | Supabase prod migration push | manual reconstruction |
| `641d926` | Workato inventory | manual reconstruction |

Both incidents drove the B13 + B14 structural-receipt wire-in.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| Blanket `git reset --hard origin/main` to "sync with remote" | Silently destroys ahead commits whose content may or may not be in the upstream squash |
| Dispatching workers to local `main` | If multiple workers commit to main, ANY subsequent reset risks orphaning ALL of their commits |
| Skipping `git log origin/main..HEAD` probe | The probe is the only deterministic signal that ahead commits exist; reflog inspection is post-hoc and harder |
| Recovering via `git checkout <orphan-sha> -- <file>` | Destructive primitives compound the loss; use `git show` read-and-copy |
| Assuming squash merge preserved all content | Squash merges collapse multiple commits into one — content can be reorganized or partially absorbed |

## Conformance

An orchestrator reset proves conformance via:
- Receipt cites `git log origin/main..HEAD --oneline` output (empty OR pre-reset preservation evidence)
- If preservation was needed, the recovery branch ref is named in the receipt
- Fast-forward attempted first (`git pull --ff-only`)

A worker dispatch proves conformance via:
- Side branch identity in callback (`side_branch=worker-pane-${PANE}-${TASK_ID}`)
- Commit SHA + branch ref in callback envelope

## Structural receipts

- **B13** `flywheel-dt2w` — `commit_tag=[worker-branch-contract]` wires worker-side-branch dispatch + callback fields for branch/ref identity proof
- **B14** `flywheel-2bfg` — `commit_tag=[dcg-orphan-reset-blocker]` wires DCG to surface ahead commits instead of silently losing substrate

The structural receipts mechanize this doctrine; the doctrine doc
codifies the discipline + recovery procedure.

## Sister doctrine + memory

- `feedback_substrate_loss_worker_commit_orphan` (above-cited canonical memory)
- Per-project memory:
  `/Users/josh/.claude/projects/-Users-josh-Developer-alpsinsurance/memory/feedback-substrate-loss-worker-commit-orphan.md`
- Handoff evidence:
  `/Users/josh/Developer/alpsinsurance/.flywheel/handoffs/2026-05-04T2309-eod.md`
- Sister memory: `feedback_worker_close_requires_git_commit` — every
  worker close MUST commit (otherwise the close is hollow); pairs with
  this doctrine's worker-side-branch contract

## Conformance receipts (cross-reference)

- Worker callbacks already include `git_committed=yes|no_changes|skipped`
- B13 + B14 receipts are the mechanization layer
- This doctrine codifies the procedural layer that B13+B14 mechanize

## Lifecycle

This is a HARD RULE. The 2 ALPS incidents drove canonical mechanization
(B13 + B14); future workers + orchs inherit the discipline. New orphan
incidents should be added to the empirical-incidents table as additional
evidence.

When N=4 orphan incidents land, promote to trauma class with mandatory
DCG block at the reset code path (currently B14 surfaces; trauma class
would forbid).


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
