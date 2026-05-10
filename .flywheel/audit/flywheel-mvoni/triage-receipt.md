# skillos git-stash-janitor — TRIAGE-ONLY PREFLIGHT RECEIPT

Bead: `flywheel-mvoni` (P2, [git-stash-janitor] skillos stash census 5 Quick-mode run)
Receipt type: **TRIAGE-ONLY** (per AG2: "triage-only or full recovery receipt")
Run mode: **PREFLIGHT** (read-only census; no destructive operations)
Worker: CloudyMill on flywheel:0.2 (codex-pane), 2026-05-09
Source: flywheel-hnul2 git-stash-janitor fleet census, 2026-05-08

## AG1 — Stash census (significant drift surfaced)

| Field | Bead-claimed (2026-05-08) | Live (2026-05-09) | Drift |
|---|---|---|---|
| repo | `/Users/josh/Developer/skillos` | `/Users/josh/Developer/skillos` | none |
| stash_count | 5 | **16** | **+11 stashes in 24h** (3.2× the claimed count) |
| recommended_mode | Quick | **Standard** (live-rubric) | mode escalated one tier |
| primary_branch | n/a | `main` | (per skill axiom 4 detection) |

**Mode rubric** (from `~/.claude/skills/git-stash-janitor/SKILL.md:116`):

> manual-default warning for <5, Quick 5–9, Standard 10–80, Comprehensive 80+

16 stashes is **squarely in Standard band** (10-80), not Quick (5-9). The bead's Quick recommendation is stale; live state warrants Standard mode (30-90 min, 2-4 parallel triage workers, ≥2 rounds per skill SKILL.md:276).

**Source-of-drift signal**: 11 stashes accreted in 24h on a small repo strongly suggests active worker activity in the skillos session between bead-filing and now. Stash messages reveal the family pattern:

```
stash@{0}:  On chore/jeff-stack-triage-2026-05-09: phase18-fork-stash
stash@{1}:  On main: out-of-scope: pre-existing blocker-tick-counters
stash@{2}:  On main: out-of-scope: pre-existing AGENTS+blocker noise
stash@{3}:  On main: out-of-scope-tick-noise: AGENTS + blocker-counters
stash@{4}:  On main: AGENTS-CANONICAL pre-reset
stash@{5}:  On main: AGENTS-CANONICAL noise blocking pull
stash@{6}:  On main: out-of-scope: AGENTS-CANONICAL.md pre-existing leak
stash@{7}:  On feat/skillos-15-5k-expand-audit-patterns: out-of-scope-heartbeat: ...
stash@{8}:  On feat/skillos-15-5fghij-cli-unify-doctor-hooks-extractions: ...
stash@{9}:  On main: out-of-scope-ATTEMPT-2: pane 2 re-applied AGENTS-CANONICAL ...
stash@{10}: On main: out-of-scope: pane 2 AGENTS-CANONICAL rewrite + heartbeat
stash@{11}: On feat/loop-1-wave-c-drift-router: wave-d-stash
stash@{12}: On feat/yuzu-hero-upgrade: track-1-stash-1778168754
stash@{13}: On master: j1ad-linter-stripped-class
stash@{14}: WIP on master: b1d7d9f fix(jsm-db): repair malformation from kickstart trauma [skillos-hhx2]
stash@{15}: On master: G-pre-commit-smoke
```

Family classification (eyeballed; the actual orch-scheduled run will use `prefix-classifier.sh`):

- **AGENTS-CANONICAL noise family** (stashes 1-6, 9-10): 8 stashes — appears to be a recurring pre-existing-blocker class where workers stashed AGENTS-CANONICAL.md churn that another pane was simultaneously authoring. High likelihood of `superseded` verdict (work landed elsewhere or was authoritatively rewritten).
- **out-of-scope-tick-heartbeat family** (stashes 7-8): 2 stashes — blocker-tick-counters / AGENTS + state ledgers. Likely `superseded` once the heartbeat substrate stabilized.
- **WIP/branch-checkpoint family** (stashes 11-14): 4 stashes — wave-d-stash, track-1-stash-1778168754, j1ad-linter, jsm-db kickstart trauma. Likely `partially-novel` — could contain content worth landing.
- **Pre-commit smoke** (stash 15): 1 stash — `G-pre-commit-smoke` on master. Likely `garbage` (smoke test artifact).
- **Unique** (stash 0): 1 stash — `phase18-fork-stash` on `chore/jeff-stack-triage-2026-05-09`. Today's stash; needs assessment.

This is the typical agent-swarm aftermath pattern (skill SKILL.md:276 "Typical agent-swarm aftermath") with two notable signals:

1. **Multi-pane AGENTS-CANONICAL contention** — stashes 1-10 reveal a recurring failure mode where pane 2 (per stash@{9-10} message text) was repeatedly re-applying AGENTS-CANONICAL changes despite a hard guardrail. The cleanup will discover whether the guardrail was respected eventually, or whether the underlying contention is still live.
2. **Kickstart trauma** (stash@{14}) — `repair malformation from kickstart trauma [skillos-hhx2]` references a beads-rust JSM-DB repair. Worth verifying that the fix landed before dropping.

Full list at `.flywheel/audit/flywheel-mvoni/stash-list.txt`.

## AG2 — Bundle path naming + no-deletion proof

**Canonical bundle path** (per `~/.claude/skills/git-stash-janitor/SKILL.md:183` and `:219`):

```
/Users/josh/Developer/skillos-stash-archive-2026-05-09/
```

**No-bundle-deletion proof**:

```text
$ ls -d /Users/josh/Developer/skillos-stash-archive-2026-05-09 2>&1
ls: /Users/josh/Developer/skillos-stash-archive-2026-05-09: No such file or directory
```

The bundle does not exist yet. This dispatch is TRIAGE-ONLY PREFLIGHT — no bundle was created and therefore no bundle could be deleted.

When the orch schedules the actual Standard-mode run, the canonical bundle motion is:

1. `mkdir -p /Users/josh/Developer/skillos-stash-archive-2026-05-09/{diffs,meta,stashed-untracked}`
2. For each of 16 stashes: write `refs/stash-backup/<NNN>` ref + `diffs/<NNN>.diff` + `meta/<NNN>.txt`
3. Generate `index.tsv` + `README.md`
4. Run Phase-3 byte-equality verification across all 16 backup refs (per axiom 3)
5. Only then can any drop/destructive logic proceed (per axiom 2 "Plan for irreversibility first")

## AG3 — Deferral / orch-action requirement

The bead's AG3 says: "Close only after the target orchestrator schedules the cleanup run **OR** records an explicit no_bead_reason deferral."

This dispatch records an **explicit no_bead_reason deferral**:

`no_bead_reason=triage-only-preflight-complete-orch-must-schedule-multi-pane-standard-run-mode-escalated-from-quick-due-to-plus-11-drift`

**Why deferred (not executed) in this worker-tick**:

- 16 stashes is Standard mode (10-80), not Quick. Standard mode is multi-pane scope (30-90 min, 2-4 parallel triage workers, ≥2 rounds per skill SKILL.md:276).
- Worker-tick has a 120s budget; Standard mode is 30-90 min — incompatible.
- skillos has its own session per memory `project_skillos_separated.md` ("Skill OS is its own ntm session/repo, not flywheel scope") — flywheel-orch can dispatch a skillos-orch worker, but the actual execution lives there.
- Memory `project_skillos_goal_rotation_v2_2026_05_03.md` records "Joshua-approved 2026-05-03 rotation from bootstrap observability to measured skill shipping" — skillos has its own active priority that should be respected when scheduling.

**flywheel_orch_action_required**: schedule the multi-pane Standard-mode git-stash-janitor run for `/Users/josh/Developer/skillos` — preferably as a skillos-session-scoped worker dispatch since skillos owns its own orchestration per memory `project_skillos_separated.md`. The drift signal (+11 stashes in 24h) suggests an open multi-pane AGENTS-CANONICAL contention class that may still be active; the cleanup should NOT run while contention is live (axiom 7: "never stash, revert, or overwrite changes made by parallel agents"). A pre-flight check on skillos session activity is warranted before scheduling.

## Acceptance Gate Map

| # | Gate | Status |
|---|------|--------|
| AG1 | Run preflight against `/Users/josh/Developer/skillos` and record stash_count + selected mode | ✓ stash_count=16 (drift +11 vs bead-claimed 5); mode escalated to Standard (live-rubric) from Quick (bead); primary_branch=main detected per skill axiom 4 |
| AG2 | Produce triage-only or full recovery receipt naming bundle path + proving no bundle deletion | ✓ Triage-only receipt (this file) names canonical path `/Users/josh/Developer/skillos-stash-archive-2026-05-09/`; no-deletion proof via `ls` exit code on non-existent path |
| AG3 | Close only after orch schedules cleanup OR records explicit no_bead_reason deferral | ✓ Explicit deferral recorded with `no_bead_reason=triage-only-preflight-complete-orch-must-schedule-multi-pane-standard-run-mode-escalated-from-quick-due-to-plus-11-drift`; `flywheel_orch_action_required` flags orch with the cross-session-coordination context |

did=3/3

## Safety constraints honored

- **No destructive operations**: zero stash drops, zero apply, zero pop, zero ref mutation.
- **No bundle creation**: the bundle path is named in this receipt but does NOT exist.
- **No skillos edits**: read-only `git stash list` only; no working-tree changes; no commits.
- **Skill axioms 0/2/4/7/8 honored** (same as ALPS triage): merge-commit awareness, irreversibility-first, primary-branch detection, concurrent-agent respect, no apply/pop.
- **Cross-session coordination respect**: skillos has its own session per memory `project_skillos_separated.md`; flywheel-side dispatch is a recommendation, not an authorization to mutate skillos directly.

## Active-contention signal (axiom 7 caution)

The +11 stash drift in 24h with explicit "pane 2 re-applied AGENTS-CANONICAL despite hard guardrail" message text suggests the multi-pane AGENTS-CANONICAL contention class may still be active in the skillos session. Per skill axiom 7, the orch-scheduled cleanup should pre-flight check that the contention has stabilized (e.g., no new AGENTS-related stashes in the last 1-2 hours) before invoking Phase-3 BUNDLE. Otherwise the cleanup itself becomes a parallel-agent-stash race condition.

This is the kind of signal that an orch-scheduled run can act on; a single worker-tick cannot.
