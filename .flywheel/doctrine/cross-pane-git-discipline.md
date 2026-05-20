---
name: cross-pane-git-discipline
type: doctrine
created: 2026-05-10
status: active
authority: skillos-1-cross-pane-race-incident-postmortem-2026-05-10T18:56Z + flywheel-1-class-B-clarification-2026-05-10T21:30Z
ratified: 2026-05-10T21:35Z (P3-trivial cross-orch via cross-orch-anti-divergence-v1.0.0; default-accept window 6h)
cluster: substrate-hygiene-doctrine-cluster
sisters:
  - git-stash-discipline.md
  - blocker-discipline.md
trauma_class_promotion: 4th-instance (consistency with frozen-projection-of-mutable-state promotion threshold)
---

# Cross-Pane Git Discipline (Fleet-Wide)

## Substrate-hygiene doctrine cluster

This doctrine is the third member of the **substrate-hygiene doctrine cluster** alongside `git-stash-discipline.md` and `blocker-discipline.md`. All three share a Meadows-lens diagnosis: recursive-self-validation failure modes — substrate that nobody verifies accumulates as silent debt OR collides with its own concurrent operations.

- **git-stash-discipline.md** — stash accumulation as durable storage (paradigm: stash is 24h scratch)
- **blocker-discipline.md** — blocker accumulation as unverified claims (paradigm: blockers are claims, not facts)
- **cross-pane-git-discipline.md** (this doctrine) — concurrent git ops on a shared `.git` directory race silently when nobody scopes the worktree

When you read one, read the others — failure modes overlap.

## Paradigm — `.git` is not concurrency-safe

`git` is a single-writer system. `git checkout`, `git commit`, `git add`, `git stash`, and `git reset` all mutate `.git/HEAD`, `.git/index`, and refs concurrently-unsafely. When two processes share the same `.git` directory and both write at roughly the same moment, the result is undefined: HEAD can point to a ref that doesn't reflect either process's intended state, the index can entangle changes from both, and a commit can land on the "wrong" branch.

The Meadows-lens leverage point at play: **#5 rules of the system, scope of authority**. The "rule" that nobody-stated-but-everyone-assumed is "one process owns the .git at a time." When that rule is violated by parallel workers sharing a worktree, the system silently produces phantom-state — entangled commits that look clean to each individual worker but are actually corrupt at the substrate level.

## Mandate

Every flywheel-installed repo enforces single-writer semantics on `.git`. When parallelism is required, each parallel writer gets its own worktree (via `git worktree add`), with a stable path convention.

## Trauma class — 4-instance ladder (promoted 2026-05-10T21:35Z)

Per cross-orch consistency rule (frozen-projection-of-mutable-state promoted at 4 instances), this class crosses the same threshold:

| # | When | Where | Symptom |
|---|---|---|---|
| 1 | 2026-05-10 PR3 ~16:00Z | skillos pane 3 | broad `git add -A` swept other panes' WIP, single commit entangled |
| 2 | 2026-05-10 (commit 1f7754d) | skillos | concurrent index mutation produced "wrong-files" commit |
| 3 | 2026-05-10 (commit 67cf08e) | skillos | clean batch retroactively contaminated by interleaved commit from sister fork |
| 4 | 2026-05-10 ~18:56Z (commit c2356f8) | skillos orch + fork shared .git | orch commit landed on fork's feature branch via concurrent `git checkout -b`; recovered via `git format-patch` + `git am` on clean branches |

The 4 instances span ~3 hours, all 2026-05-10, all within skillos. Flywheel did NOT hit this pattern in pynxp (foreground-serial) OR janitor forks (separate repos). However, **flywheel's parallel sub-bead dispatch (3-4 codex panes concurrently editing files in `~/Developer/flywheel`) is at risk for class B below**.

## Two scope classes

The doctrine governs two distinct concurrency surfaces:

### Class A — orch + fork shared `.git`

**Definition:** orchestrator dispatches a fork (or sub-agent) into the same repo while orchestrator itself does substrate work concurrently. Fork inherits the orch's `.git` because it operates in the same working directory.

**Symptom:** fork's `git checkout -b feature-branch` moves HEAD; orch's subsequent `git commit -am` lands the orch's WIP on the fork's branch.

**Root cause:** absence of a separate worktree. The fork should have been spawned in `git worktree add /tmp/<repo>-fork-<purpose>` instead of inheriting the orch's worktree.

### Class B — orch + N codex panes concurrent commits

**Definition:** orchestrator dispatches multiple workers (codex panes, claude agents, or subprocess workers) — 2 or more — that each do `git ops` (add, commit, push) simultaneously in the same repo.

**Symptom:** worker 1 commits at T; worker 2 commits at T+200ms; race on `.git/index.lock` produces an interleaved index OR one worker's HEAD becomes invisible to the other's branch.

**Root cause:** absence of pane-scoped worktrees. Each pane should have `cd ~/<repo>-pane-N-wt` set up via `git worktree add` before the dispatched worker begins git ops.

**Both classes share the same mitigation:** pane-scoped worktree.

## Mitigation table — 5 layers

| Layer | Mechanism | Effectiveness | Applies to |
|---|---|---|---|
| 1. Prevention | pane-scoped worktree at dispatch time (`git worktree add /tmp/<repo>-<pane-N-wt>`) | high — race window closed | A + B |
| 2. Pre-commit | flock-style `.git/index.lock` check before commit (advisory) | medium — narrows window but doesn't close | A + B |
| 3. Post-commit | branch-state probe: verify HEAD points at expected branch + matches expected parent SHA | medium — detects within 1-2 ticks | A + B |
| 4. Post-push | remote-side hook rejects unexpected force-push or wrong-branch update | low — protective only against published mistakes | A + B |
| 5. Recovery | `git format-patch` + `git am` on clean branches off `main`; preserves byte-equality of authored changes | high when applied — but reactive, not preventive | A + B |

**Layer 1 is canonical.** Layers 2-4 narrow windows. Layer 5 is recovery, not prevention. Doctrine compliance = layer 1 in place.

### Worktree path conventions

Both forms are sanctioned:

- **Purpose-scoped:** `/tmp/<repo>-<purpose>` — e.g. `/tmp/flywheel-cli-kit-rust-spike`. Used when one fork owns one purpose for one session.
- **Pane-scoped:** `~/<repo>-pane-<N>-wt` (or `/tmp/<repo>-pane-<N>-wt` when ephemeral) — e.g. `~/flywheel-pane-3-wt`. Used when multiple panes need persistent worktrees.

`git worktree list` is the truth source for active worktrees. `git worktree prune` is the cleanup primitive.

## Operator responsibilities (worker rules — 3)

A worker MUST observe:

1. **Refuse `git ops` in a shared worktree without a lock.** Before any `git add`, `git commit`, `git checkout -b`, `git reset`: verify the worktree is the worker's own (per dispatch contract) OR acquire `.git/index.lock` advisory (`flock -n .git/index.lock <op>`) to fail-fast on concurrent contention.

2. **Never `git add -A` or `git add .` in a shared worktree.** Either path-scope every add (`git add path1 path2 path3`) OR work in a pane-scoped worktree where blanket-add is safe. Class A instance #1 was caused by `git add -A` in a shared worktree.

3. **Verify HEAD post-commit.** After `git commit`, run `git rev-parse HEAD --abbrev-ref HEAD` and verify HEAD points at the branch the dispatch contract assigned. If HEAD diverges, abort + escalate (do not push).

## Orchestrator responsibilities (per-tick probes — 3)

The orchestrator MUST probe per tick:

1. **Active worktree census.** `git worktree list --porcelain` per coordinating repo. Log count + paths to STATE.md or tick metadata. Threshold: N≥3 active worktrees per repo is notable; N≥5 is bead-class signal.

2. **Stale worktree garbage.** A worktree whose head ref no longer exists (deleted branch) or whose path is missing (pruned manually) is stale. `git worktree prune --dry-run` surfaces these. Stale worktree count is its own signal.

3. **Concurrent commit detection (5-sec window).** Per tick, scan `git reflog` for entries where two HEAD movements occurred within a 5-second window on the same branch. Two reflog entries `<5s` apart on the same ref is a class A or B candidate; flag for postmortem.

## Pre-migration gate (Rust P3)

Before substrate-rewrite proposals (substrate-rewrite-rust-v1 P3 at T+144h on 2026-05-16T17:00Z), all coordinating flywheel-installed repos must satisfy ALL of:

- Zero stale worktrees (cleaned via `git worktree prune`)
- Zero concurrent-commit-window violations in the last 24h tick window
- Class B mitigation in place: any repo with ≥2 panes doing concurrent git ops has pane-scoped worktrees configured
- **[Extension 2026-05-10T23:15Z]** Zero doctor invariant violations against the 3 design rules from `doctor-invariant-design-discipline.md`:
   - Rule 1: probe paths absolute, not `$0`-relative
   - Rule 2: timeout defaults account for doctor-subshell concurrent load
   - Rule 3: synthetic-fail rows distinguish failure modes via distinct error codes
  AND no provisional Rule 4 (umbrella-default cascade trap) instances in the last 24h tick window.

This gate-condition extends the substrate-hygiene cluster gate (the Rust migration into a worktree that's silently entangled is a guaranteed-corruption ship). The doctor-invariant extension was bilaterally ratified at 2026-05-10T23:15Z (flywheel:1 proposed 22:55Z → skillos:1 ACCEPT byte-identical 23:15Z, 20-min cycle); wire-in beads `doctor_invariant_author_checklist` + `existing_invariant_audit_against_3_rules` are load-bearing for the gate.

## What this is NOT

Three clarifications to scope the doctrine:

1. **Not a ban on parallel work.** Parallel dispatch is fine; what's banned is parallel writers on the SAME worktree without coordination. Pane-scoped worktrees are the path to safe parallelism, not refusal of parallelism.

2. **Not a ban on `git add -A`.** `git add -A` is fine in a worktree where exactly one process owns the index. The doctrine bans `git add -A` only in shared worktrees.

3. **Not the same as `git-stash-discipline`.** Stash discipline addresses accumulated state (stash >24h). This doctrine addresses concurrent state mutation. Different failure modes; same Meadows-lens cluster.

## Cross-references

- `.flywheel/doctrine/git-stash-discipline.md` — sister substrate-hygiene cluster
- `.flywheel/doctrine/blocker-discipline.md` — sister substrate-hygiene cluster
- skillos postmortem 2026-05-10T18:56Z — substrate-discovery source for incident #4
- skillos memory `feedback_cross_pane_git_race_window` (likely; reference upon publication) — substrate-discovery source for the class shape
- `cross-orch-anti-divergence-v1.0.0` (ratified 2026-05-10T16:48Z) — protocols this doctrine is ratified under
- substrate-rewrite-rust-v1 P3 (filing 2026-05-16T17:00Z) — pre-migration gate consumer

## Implementation status

Doctrine ratified P3-trivial 2026-05-10T21:35Z. Default-accept window: 6h (until 2026-05-11T03:30Z) unless amendment. Wire-in: orchestrator per-tick probes (active-worktree census + stale-worktree garbage + concurrent-commit detection) — file as separate bead. Worker close-gate addition (HEAD-verify post-commit) — extend L120 br-close-executed gate. Both wire-in items filed as separate workstream parallel to flywheel-pynxp git-stash impl.

## Cycle stats (this doctrine)

- Trauma class 1st instance: 2026-05-10 ~16:00Z (skillos PR3)
- Trauma class 4th instance: 2026-05-10 ~18:56Z (skillos orch + fork postmortem)
- Postmortem letter to flywheel: 2026-05-10T18:56Z
- Cross-orch ratification ACK + class B clarification (flywheel side): 2026-05-10T21:30Z
- Doctrine v0.1 drafted (skillos side): 2026-05-10T21:35Z
- Flywheel canonical doctrine drafted (parallel authorship): 2026-05-10T21:35Z
- Total class-naming + ratification + doctrine cycle: ~5 hours from 1st instance to bilateral ratified doctrine


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
